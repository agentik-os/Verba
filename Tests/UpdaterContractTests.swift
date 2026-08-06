import XCTest
#if canImport(FoundationXML)
import FoundationXML          // Linux: XMLParser lives here, not in Foundation.
#endif
#if canImport(FoundationNetworking)
import FoundationNetworking   // Linux: URLSession lives here (live check only).
#endif

/// Non-destructive contract tests for the Sparkle update path.
///
/// The updater is the one subsystem that can silently strand every installed copy of Verba:
/// a wrong `SUFeedURL`, an appcast item missing its EdDSA signature, or a release stamped with a
/// version that is not strictly greater than the one already installed all produce the SAME
/// symptom — "no update available" — on a machine nobody is watching. These tests turn each of
/// those into a red test instead.
///
/// Deliberate design constraints:
///  * **Read-only.** Nothing here builds, signs, publishes, or mutates anything. The shipped
///    Info.plist keys are read out of `bundle.sh` AS DATA; no production source is touched.
///  * **No network.** Every assertion runs against a local fixture embedded below. The one live
///    check is opt-in (`VERBA_UPDATER_LIVE=1`) and skips itself otherwise, so `swift test` is
///    green on an air-gapped machine and in CI without a network allowance.
///  * **Cross-platform.** Foundation + XCTest only, so the suite runs on Linux as well as macOS
///    (Package.swift exposes the test target on both).
///  * **Not vacuous.** Every positive assertion has a negative twin: a stale appcast, an unsigned
///    enclosure and a malformed feed must all be REJECTED. A checker that accepts everything is
///    worse than no checker, because it reads as coverage.
final class UpdaterContractTests: XCTestCase {

    // MARK: - Version monotonicity

    /// The core rule Sparkle enforces: an update is offered only when the feed carries a version
    /// STRICTLY greater than the installed one. The classic way to break this is to compare
    /// version strings lexicographically, where "0.9.9" > "0.9.10" and every user past .9 stops
    /// receiving updates, silently.
    func testVersionComparisonIsNumericNotLexicographic() {
        XCTAssertLessThan(SemanticVersion("0.9.9"), SemanticVersion("0.9.10"),
                          "0.9.10 must sort above 0.9.9 — lexicographic ordering strands users past .9")
        XCTAssertLessThan(SemanticVersion("0.9.99"), SemanticVersion("0.10.0"))
        XCTAssertLessThan(SemanticVersion("1.0"), SemanticVersion("1.0.1"),
                          "a shorter version pads with zeros: 1.0 == 1.0.0 < 1.0.1")
        XCTAssertEqual(SemanticVersion("1.2"), SemanticVersion("1.2.0"))
        XCTAssertGreaterThan(SemanticVersion("2.0.0"), SemanticVersion("1.99.99"))
        XCTAssertFalse(SemanticVersion("0.9.99") < SemanticVersion("0.9.99"),
                       "equal versions are not an upgrade — the ordering must be strict")
    }

    /// Reordering an appcast must not change which build is "newest": the update decision reads
    /// the maximum version, never the first `<item>` in document order.
    func testNewestItemIsChosenByVersionNotDocumentOrder() throws {
        let items = try Appcast.parse(Fixtures.outOfOrder)
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(try XCTUnwrap(Appcast.newest(of: items)).version, SemanticVersion("0.9.99"),
                       "the newest item is the highest version, even when it is listed last")
    }

    // MARK: - Sparkle fields on a local fixture

    /// Every field Sparkle needs to accept and install a build. A missing `sparkle:edSignature`
    /// is the dangerous one: the appcast still parses, the item still shows up, and the install
    /// fails only on the user's machine at download time.
    func testFixtureAppcastCarriesEverySparkleFieldAnInstallNeeds() throws {
        let items = try Appcast.parse(Fixtures.valid)
        XCTAssertFalse(items.isEmpty, "a feed with no <item> offers no update at all")

        for item in items {
            XCTAssertNotNil(item.rawVersion, "item is missing sparkle:version")
            XCTAssertNotNil(item.shortVersionString, "item is missing sparkle:shortVersionString")
            let url = try XCTUnwrap(item.enclosureURL, "item \(item.title) has no <enclosure url=…>")
            XCTAssertTrue(url.hasPrefix("https://"),
                          "enclosure must be https — Sparkle refuses plain http downloads: \(url)")
            XCTAssertTrue(url.hasSuffix(".dmg"), "enclosure should point at the DMG: \(url)")
            let signature = try XCTUnwrap(item.edSignature,
                                          "item \(item.title) has no sparkle:edSignature — the download would be rejected")
            XCTAssertFalse(signature.isEmpty)
            XCTAssertNotNil(Data(base64Encoded: signature),
                            "sparkle:edSignature must be base64: \(signature)")
            let length = try XCTUnwrap(item.length, "item \(item.title) has no enclosure length")
            XCTAssertGreaterThan(length, 0)
            XCTAssertNotNil(item.minimumSystemVersion,
                            "item \(item.title) has no sparkle:minimumSystemVersion — it would be offered to macOS versions that cannot run it")
        }
    }

    /// Sparkle 2's `generate_appcast` has emitted the version either as a child element of
    /// `<item>` or as an attribute on `<enclosure>` depending on the release. Both are valid and
    /// both must keep parsing, so a Sparkle upgrade cannot quietly blind this suite.
    func testVersionIsReadFromEitherTheItemElementOrTheEnclosureAttribute() throws {
        let asElements = try Appcast.parse(Fixtures.valid)
        let asAttributes = try Appcast.parse(Fixtures.versionOnEnclosure)
        XCTAssertEqual(Appcast.newest(of: asElements)?.version, SemanticVersion("0.9.99"))
        XCTAssertEqual(Appcast.newest(of: asAttributes)?.version, SemanticVersion("0.9.99"),
                       "sparkle:version carried as an enclosure attribute must parse identically")
    }

    /// Items must be strictly ordered with no duplicate version: two items claiming the same
    /// version make "which build is newest" ambiguous, and Sparkle's answer is not the one the
    /// release script assumed.
    func testFixtureAppcastVersionsAreUniqueAndOrdered() throws {
        let versions = try Appcast.parse(Fixtures.valid).map(\.version)
        XCTAssertEqual(Set(versions).count, versions.count, "duplicate versions in the feed: \(versions)")
        XCTAssertEqual(versions, versions.sorted().reversed(),
                       "the feed should list items newest-first: \(versions)")
    }

    // MARK: - The update decision

    /// The whole point of the feed: an older installed build is offered the newest one.
    func testUpdateIsOfferedWhenTheInstalledBuildIsOlder() throws {
        let items = try Appcast.parse(Fixtures.valid)
        let offer = Appcast.update(in: items, forInstalled: SemanticVersion("0.9.93"))
        XCTAssertEqual(offer?.version, SemanticVersion("0.9.99"))
    }

    /// A user already on the newest build must be offered nothing. Offering an "update" to the
    /// version already installed is the re-install loop.
    func testNoUpdateIsOfferedWhenTheInstalledBuildIsCurrent() throws {
        let items = try Appcast.parse(Fixtures.valid)
        XCTAssertNil(Appcast.update(in: items, forInstalled: SemanticVersion("0.9.99")))
    }

    /// A feed that has fallen BEHIND the installed build (a release that published the DMG but
    /// never regenerated the appcast, or a rollback) must offer nothing — never a downgrade.
    func testStaleFeedNeverOffersADowngrade() throws {
        let items = try Appcast.parse(Fixtures.stale)
        XCTAssertNotNil(Appcast.newest(of: items), "the stale fixture is a well-formed feed")
        XCTAssertNil(Appcast.update(in: items, forInstalled: SemanticVersion("0.9.99")),
                     "an appcast older than the installed build must not offer a downgrade")
    }

    // MARK: - Negative twins (the suite must be able to fail)

    /// Proves the field check above is load-bearing: strip the signature and validation must fail.
    func testUnsignedEnclosureIsRejected() throws {
        let items = try Appcast.parse(Fixtures.unsigned)
        XCTAssertFalse(items.isEmpty, "the fixture parses; it is the CONTRACT that must reject it")
        XCTAssertNil(items[0].edSignature)
        XCTAssertThrowsError(try Appcast.validate(items),
                             "an item with no sparkle:edSignature must be rejected")
    }

    /// Proves the parser does not silently swallow a broken feed. A truncated appcast (a partial
    /// upload, a 404 page served with a 200) must raise, not parse to zero items and read as
    /// "no update available" — which is what a bare `XMLParser.parse()` does on Linux.
    func testMalformedFeedRaisesInsteadOfParsingToNothing() {
        for (label, fixture) in [("truncated", Fixtures.truncated), ("mismatched tags", Fixtures.mismatched)] {
            XCTAssertThrowsError(try Appcast.parse(fixture), "\(label) feed parsed as valid") { error in
                XCTAssertTrue(error is Appcast.Failure, "unexpected error type for \(label): \(error)")
            }
        }
    }

    /// An empty but well-formed feed is not a parse error, yet it can never produce an update.
    /// It is called out separately so the two failure modes stay distinguishable.
    func testEmptyFeedOffersNothing() throws {
        let items = try Appcast.parse(Fixtures.empty)
        XCTAssertTrue(items.isEmpty)
        XCTAssertNil(Appcast.update(in: items, forInstalled: SemanticVersion("0.0.1")))
    }

    // MARK: - What the app actually ships

    /// The app half of the contract: the Info.plist that `bundle.sh` stamps into Verba.app must
    /// point at the PUBLIC appcast and carry the EdDSA public key. `bundle.sh` is read as data —
    /// this test never runs it.
    func testShippedInfoPlistPointsAtThePublicFeedAndCarriesTheKey() throws {
        let bundleScript = try RepoFile.contents(of: "bundle.sh")

        let feed = try XCTUnwrap(InfoPlist.string("SUFeedURL", in: bundleScript),
                                 "bundle.sh no longer stamps SUFeedURL — the app would never check for updates")
        XCTAssertEqual(feed, Self.expectedFeedURL,
                       "the shipped feed URL drifted from the public appcast")
        XCTAssertTrue(feed.hasPrefix("https://"), "the feed must be https")
        XCTAssertTrue(feed.hasSuffix("/releases/latest/download/appcast.xml"),
                      "the feed must resolve to the LATEST release asset, not a pinned tag: \(feed)")

        let key = try XCTUnwrap(InfoPlist.string("SUPublicEDKey", in: bundleScript),
                                "bundle.sh no longer stamps SUPublicEDKey — Sparkle would refuse every update")
        let decoded = try XCTUnwrap(Data(base64Encoded: key), "SUPublicEDKey is not valid base64: \(key)")
        XCTAssertEqual(decoded.count, 32, "an Ed25519 public key is 32 bytes, got \(decoded.count)")
    }

    /// The two version keys must come from the same stamp. If they ever diverge, Sparkle compares
    /// `CFBundleVersion` while the UI (and this repo's changelog) shows
    /// `CFBundleShortVersionString`, and the mismatch is invisible until an update is skipped.
    func testBundleVersionKeysAreStampedFromTheSameSource() throws {
        let bundleScript = try RepoFile.contents(of: "bundle.sh")
        let short = InfoPlist.allStrings("CFBundleShortVersionString", in: bundleScript)
        let build = InfoPlist.allStrings("CFBundleVersion", in: bundleScript)

        XCTAssertFalse(short.isEmpty, "bundle.sh stamps no CFBundleShortVersionString")
        XCTAssertEqual(short.count, build.count,
                       "every bundle stamped by bundle.sh needs both version keys")
        XCTAssertEqual(Set(short), ["${VERSION}"],
                       "CFBundleShortVersionString must come from the VERSION stamp, got \(Set(short))")
        XCTAssertEqual(Set(build), ["${VERSION}"],
                       "CFBundleVersion must come from the VERSION stamp, got \(Set(build))")
    }

    /// Regression guard for the documented "installs the next update, not the latest" bug:
    /// Sparkle must keep CHECKING on a schedule but must not silently pre-download in the
    /// background, which could stage an intermediate build. Both halves are asserted, because
    /// turning checks off is the other way to strand every install.
    func testAutomaticCheckingIsOnAndSilentPreDownloadIsOff() throws {
        let bundleScript = try RepoFile.contents(of: "bundle.sh")
        XCTAssertEqual(InfoPlist.bool("SUEnableAutomaticChecks", in: bundleScript), true,
                       "scheduled checks are off — installed copies would never learn about a release")
        XCTAssertEqual(InfoPlist.bool("SUAutomaticallyUpdate", in: bundleScript), false,
                       "silent background download is back on — it can stage an intermediate build")
        let interval = try XCTUnwrap(InfoPlist.integer("SUScheduledCheckInterval", in: bundleScript),
                                     "no SUScheduledCheckInterval — Sparkle falls back to its own default")
        XCTAssertGreaterThan(interval, 0)
    }

    /// The repo's own declared version (the newest numeric changelog entry) must be the highest
    /// one it lists. An out-of-order entry means the release about to be cut is not the newest
    /// version in the feed, so the update it publishes is never offered.
    func testDeclaredAppVersionIsTheHighestInTheChangelog() throws {
        let versions = try Self.changelogVersions()
        let declared = try XCTUnwrap(versions.first, "no numeric version found in Changelog.swift")
        XCTAssertEqual(declared, versions.max(),
                       "the top changelog entry \(declared) is not the highest version listed (\(versions.max()!))")
    }

    // MARK: - Optional live check (opt-in, never required)

    /// Fetches the REAL feed and asserts it offers something at least as new as the version this
    /// repo declares. Skipped unless `VERBA_UPDATER_LIVE=1`, so the suite stays offline by
    /// default; run it on a schedule to catch a published release whose appcast never landed.
    func testLiveFeedOffersAtLeastTheDeclaredVersion() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["VERBA_UPDATER_LIVE"] == "1",
                          "live feed check is opt-in: set VERBA_UPDATER_LIVE=1")

        let url = try XCTUnwrap(URL(string: Self.expectedFeedURL))
        let (data, status) = try Self.fetch(url)
        XCTAssertEqual(status, 200, "the public appcast did not return 200")

        let xml = try XCTUnwrap(String(data: data, encoding: .utf8), "the feed is not UTF-8")
        let items = try Appcast.parse(xml)
        try Appcast.validate(items)

        let newest = try XCTUnwrap(Appcast.newest(of: items), "the live feed carries no items")
        let declared = try XCTUnwrap(Self.changelogVersions().first)
        XCTAssertGreaterThanOrEqual(newest.version, declared,
                                    "the live appcast (\(newest.version)) is behind the declared version (\(declared)) — a release published without regenerating the feed")
    }

    // MARK: - Helpers

    /// Must stay identical to the `SUFeedURL` stamped by bundle.sh.
    static let expectedFeedURL =
        "https://github.com/agentik-os/Verba-releases/releases/latest/download/appcast.xml"

    /// The numeric versions listed in Changelog.swift, in document order. Entries that are not a
    /// plain dotted number (ranges like "0.9.18 → 0.9.19", labels like "website") are ignored.
    static func changelogVersions() throws -> [SemanticVersion] {
        let source = try RepoFile.contents(of: "Sources/Verba/Changelog.swift")
        return Regex.captures(#"ChangelogEntry\(version: "([0-9]+(?:\.[0-9]+)*)"\s*,"#, in: source)
            .map(SemanticVersion.init)
    }

    /// Synchronous GET, used only by the opt-in live check.
    static func fetch(_ url: URL) throws -> (Data, Int) {
        var result: Result<(Data, Int), Error>?
        let done = DispatchSemaphore(value: 0)
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error { result = .failure(error) }
            else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                result = .success((data ?? Data(), status))
            }
            done.signal()
        }.resume()
        _ = done.wait(timeout: .now() + 60)
        guard let result else { throw Appcast.Failure.liveFetchTimedOut }
        return try result.get()
    }
}

// MARK: - Semantic version

/// Dotted numeric version with zero-padded comparison, so 1.0 == 1.0.0 < 1.0.1 and
/// 0.9.9 < 0.9.10. Non-numeric components are treated as 0, which keeps a malformed version
/// sorting BELOW any real one rather than above it.
struct SemanticVersion: Comparable, Hashable, CustomStringConvertible {
    let components: [Int]
    let raw: String

    init(_ raw: String) {
        self.raw = raw
        self.components = raw.split(separator: ".").map { Int($0) ?? 0 }
    }

    private func component(_ index: Int) -> Int { index < components.count ? components[index] : 0 }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        for index in 0..<max(lhs.components.count, rhs.components.count) {
            let left = lhs.component(index), right = rhs.component(index)
            if left != right { return left < right }
        }
        return false
    }

    static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }

    func hash(into hasher: inout Hasher) {
        // Must agree with ==: 1.2 and 1.2.0 are equal, so hash the trimmed form.
        var trimmed = components
        while trimmed.last == 0 { trimmed.removeLast() }
        hasher.combine(trimmed)
    }

    var description: String { raw }
}

// MARK: - Appcast model + parser

enum Appcast {
    struct Item {
        let title: String
        let rawVersion: String?
        let shortVersionString: String?
        let minimumSystemVersion: String?
        let enclosureURL: String?
        let edSignature: String?
        let length: Int?

        /// Sparkle compares `sparkle:version`; the short string is display only.
        var version: SemanticVersion { SemanticVersion(rawVersion ?? shortVersionString ?? "0") }
    }

    enum Failure: Error, CustomStringConvertible {
        case malformedXML(String)
        case itemMissingSignature(String)
        case itemMissingVersion(String)
        case itemMissingEnclosure(String)
        case liveFetchTimedOut

        var description: String {
            switch self {
            case .malformedXML(let detail):       return "malformed appcast: \(detail)"
            case .itemMissingSignature(let title): return "item '\(title)' has no sparkle:edSignature"
            case .itemMissingVersion(let title):   return "item '\(title)' has no sparkle:version"
            case .itemMissingEnclosure(let title): return "item '\(title)' has no <enclosure url=…>"
            case .liveFetchTimedOut:               return "live appcast fetch timed out"
            }
        }
    }

    static func parse(_ xml: String) throws -> [Item] {
        let parser = XMLParser(data: Data(xml.utf8))
        let collector = Collector()
        parser.delegate = collector
        guard parser.parse() else {
            throw Failure.malformedXML(parser.parserError?.localizedDescription ?? "unknown parse error")
        }
        // Do NOT trust `parse()` alone to catch truncation: the libxml2-backed XMLParser on Linux
        // returns true for a feed cut off mid-element and simply reports no items, which is
        // byte-for-byte the same answer as "you are up to date". An <item> that was opened and
        // never closed is the tell, and it is the same on every platform.
        guard !collector.sawUnterminatedItem else {
            throw Failure.malformedXML("truncated feed: <item> was opened and never closed")
        }
        return collector.items
    }

    /// The install-blocking fields, checked as a set so a broken feed fails here rather than on a
    /// user's machine at download time.
    static func validate(_ items: [Item]) throws {
        for item in items {
            guard item.rawVersion != nil || item.shortVersionString != nil else {
                throw Failure.itemMissingVersion(item.title)
            }
            guard let url = item.enclosureURL, !url.isEmpty else {
                throw Failure.itemMissingEnclosure(item.title)
            }
            guard let signature = item.edSignature, !signature.isEmpty else {
                throw Failure.itemMissingSignature(item.title)
            }
        }
    }

    static func newest(of items: [Item]) -> Item? {
        items.max { $0.version < $1.version }
    }

    /// Sparkle's rule, made explicit: offer the newest item, and only when it is STRICTLY newer
    /// than what is installed.
    static func update(in items: [Item], forInstalled installed: SemanticVersion) -> Item? {
        guard let newest = newest(of: items), installed < newest.version else { return nil }
        return newest
    }

    /// XMLParser delegate. Namespace processing stays off, so elements arrive as written in the
    /// feed ("sparkle:version") — which is how `generate_appcast` emits them.
    private final class Collector: NSObject, XMLParserDelegate {
        var items: [Item] = []
        /// True at end of document when the feed stopped inside an `<item>` (a truncated upload).
        var sawUnterminatedItem: Bool { inItem }

        private var inItem = false
        private var title = "", rawVersion: String?, shortVersion: String?, minimumSystem: String?
        private var enclosureURL: String?, edSignature: String?, length: Int?
        private var currentElement = "", text = ""

        func parser(_ parser: XMLParser, didStartElement element: String,
                    namespaceURI: String?, qualifiedName: String?,
                    attributes: [String: String] = [:]) {
            currentElement = element
            text = ""
            switch element {
            case "item":
                inItem = true
                title = ""; rawVersion = nil; shortVersion = nil; minimumSystem = nil
                enclosureURL = nil; edSignature = nil; length = nil
            case "enclosure" where inItem:
                enclosureURL = attributes["url"]
                edSignature = attributes["sparkle:edSignature"]
                length = attributes["length"].flatMap(Int.init)
                // Older generate_appcast releases put the version on the enclosure instead of
                // in the item; accept both so a Sparkle upgrade cannot blind the checks.
                rawVersion = rawVersion ?? attributes["sparkle:version"]
                shortVersion = shortVersion ?? attributes["sparkle:shortVersionString"]
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) { text += string }

        func parser(_ parser: XMLParser, didEndElement element: String,
                    namespaceURI: String?, qualifiedName: String?) {
            let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
            switch element {
            case "title" where inItem:                        title = value
            case "sparkle:version" where inItem:              rawVersion = value
            case "sparkle:shortVersionString" where inItem:   shortVersion = value
            case "sparkle:minimumSystemVersion" where inItem: minimumSystem = value
            case "item":
                items.append(Item(title: title, rawVersion: rawVersion,
                                  shortVersionString: shortVersion,
                                  minimumSystemVersion: minimumSystem,
                                  enclosureURL: enclosureURL, edSignature: edSignature,
                                  length: length))
                inItem = false
            default:
                break
            }
            text = ""
        }
    }
}

// MARK: - Reading repo files as data

enum RepoFile {
    /// The repo root, derived from this file's own path (Tests/UpdaterContractTests.swift), so
    /// the suite does not depend on the working directory the runner happens to use.
    static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // Tests/
        .deletingLastPathComponent()   // repo root

    static func contents(of relativePath: String) throws -> String {
        try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }
}

/// Reads Info.plist entries out of the heredoc `bundle.sh` writes. Parsing the script as text is
/// deliberate: it keeps this suite read-only and free of any build step, and it fails loudly if
/// the plist layout changes rather than asserting against a stale copy.
enum InfoPlist {
    static func allStrings(_ key: String, in source: String) -> [String] {
        Regex.captures(#"<key>\#(key)</key>\s*<string>([^<]*)</string>"#, in: source)
    }

    static func string(_ key: String, in source: String) -> String? {
        allStrings(key, in: source).first
    }

    static func bool(_ key: String, in source: String) -> Bool? {
        Regex.captures(#"<key>\#(key)</key>\s*<(true|false)/>"#, in: source).first.map { $0 == "true" }
    }

    static func integer(_ key: String, in source: String) -> Int? {
        Regex.captures(#"<key>\#(key)</key>\s*<integer>([0-9]+)</integer>"#, in: source).first.flatMap(Int.init)
    }
}

enum Regex {
    /// First capture group of every match, in document order.
    static func captures(_ pattern: String, in source: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(source.startIndex..., in: source)
        return regex.matches(in: source, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let captured = Range(match.range(at: 1), in: source) else { return nil }
            return String(source[captured])
        }
    }
}

// MARK: - Fixtures

/// Local appcasts, shaped like real `generate_appcast` output. Signatures and lengths are
/// synthetic; nothing here is fetched, downloaded or verified against a real key.
enum Fixtures {
    /// A healthy feed: three items, newest first, every install-blocking field present.
    static let valid = """
    <?xml version="1.0" standalone="yes"?>
    <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
      <channel>
        <title>Verba</title>
        <item>
          <title>0.9.99</title>
          <pubDate>Tue, 05 Aug 2026 09:00:00 +0000</pubDate>
          <sparkle:version>0.9.99</sparkle:version>
          <sparkle:shortVersionString>0.9.99</sparkle:shortVersionString>
          <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
          <enclosure url="https://github.com/agentik-os/Verba-releases/releases/download/v0.9.99/Verba-0.9.99.dmg"
                     length="184320000" type="application/octet-stream"
                     sparkle:edSignature="dGVzdFNpZ25hdHVyZUZvcjA5OTlUaGlzSXNOb3RSZWFsMDAwMDAwMDA9"/>
        </item>
        <item>
          <title>0.9.98</title>
          <pubDate>Mon, 04 Aug 2026 09:00:00 +0000</pubDate>
          <sparkle:version>0.9.98</sparkle:version>
          <sparkle:shortVersionString>0.9.98</sparkle:shortVersionString>
          <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
          <enclosure url="https://github.com/agentik-os/Verba-releases/releases/download/v0.9.98/Verba-0.9.98.dmg"
                     length="184310000" type="application/octet-stream"
                     sparkle:edSignature="dGVzdFNpZ25hdHVyZUZvcjA5OThUaGlzSXNOb3RSZWFsMDAwMDAwMDA9"/>
        </item>
        <item>
          <title>0.9.93</title>
          <pubDate>Sun, 03 Aug 2026 09:00:00 +0000</pubDate>
          <sparkle:version>0.9.93</sparkle:version>
          <sparkle:shortVersionString>0.9.93</sparkle:shortVersionString>
          <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
          <enclosure url="https://github.com/agentik-os/Verba-releases/releases/download/v0.9.93/Verba-0.9.93.dmg"
                     length="184300000" type="application/octet-stream"
                     sparkle:edSignature="dGVzdFNpZ25hdHVyZUZvcjA5OTNUaGlzSXNOb3RSZWFsMDAwMDAwMDA9"/>
        </item>
      </channel>
    </rss>
    """

    /// Same three builds, listed oldest-first: the newest must still be found by version.
    static let outOfOrder = """
    <?xml version="1.0" standalone="yes"?>
    <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
      <channel>
        <item>
          <title>0.9.9</title>
          <sparkle:version>0.9.9</sparkle:version>
          <sparkle:shortVersionString>0.9.9</sparkle:shortVersionString>
          <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
          <enclosure url="https://github.com/agentik-os/Verba-releases/releases/download/v0.9.9/Verba-0.9.9.dmg"
                     length="180000000" sparkle:edSignature="c2lnMDk5MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDA9"/>
        </item>
        <item>
          <title>0.9.10</title>
          <sparkle:version>0.9.10</sparkle:version>
          <sparkle:shortVersionString>0.9.10</sparkle:shortVersionString>
          <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
          <enclosure url="https://github.com/agentik-os/Verba-releases/releases/download/v0.9.10/Verba-0.9.10.dmg"
                     length="180100000" sparkle:edSignature="c2lnMDkxMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMD0="/>
        </item>
        <item>
          <title>0.9.99</title>
          <sparkle:version>0.9.99</sparkle:version>
          <sparkle:shortVersionString>0.9.99</sparkle:shortVersionString>
          <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
          <enclosure url="https://github.com/agentik-os/Verba-releases/releases/download/v0.9.99/Verba-0.9.99.dmg"
                     length="184320000" sparkle:edSignature="c2lnMDk5OTAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMD0="/>
        </item>
      </channel>
    </rss>
    """

    /// The older `generate_appcast` layout: version carried as an enclosure attribute.
    static let versionOnEnclosure = """
    <?xml version="1.0" standalone="yes"?>
    <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
      <channel>
        <item>
          <title>Verba 0.9.99</title>
          <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
          <enclosure url="https://github.com/agentik-os/Verba-releases/releases/download/v0.9.99/Verba-0.9.99.dmg"
                     sparkle:version="0.9.99" sparkle:shortVersionString="0.9.99"
                     length="184320000" type="application/octet-stream"
                     sparkle:edSignature="dGVzdFNpZ25hdHVyZUZvcjA5OTlUaGlzSXNOb3RSZWFsMDAwMDAwMDA9"/>
        </item>
      </channel>
    </rss>
    """

    /// A feed left behind by a release that shipped a DMG but never regenerated the appcast.
    static let stale = """
    <?xml version="1.0" standalone="yes"?>
    <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
      <channel>
        <item>
          <title>0.9.93</title>
          <sparkle:version>0.9.93</sparkle:version>
          <sparkle:shortVersionString>0.9.93</sparkle:shortVersionString>
          <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
          <enclosure url="https://github.com/agentik-os/Verba-releases/releases/download/v0.9.93/Verba-0.9.93.dmg"
                     length="184300000" sparkle:edSignature="dGVzdFNpZ25hdHVyZUZvcjA5OTNUaGlzSXNOb3RSZWFsMDAwMDAwMDA9"/>
        </item>
      </channel>
    </rss>
    """

    /// An item whose enclosure lost its EdDSA signature: parses fine, installs never.
    static let unsigned = """
    <?xml version="1.0" standalone="yes"?>
    <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
      <channel>
        <item>
          <title>0.9.99</title>
          <sparkle:version>0.9.99</sparkle:version>
          <sparkle:shortVersionString>0.9.99</sparkle:shortVersionString>
          <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
          <enclosure url="https://github.com/agentik-os/Verba-releases/releases/download/v0.9.99/Verba-0.9.99.dmg"
                     length="184320000" type="application/octet-stream"/>
        </item>
      </channel>
    </rss>
    """

    /// A partial upload: the feed stops mid-item. Note this one is NOT caught by XMLParser on
    /// Linux, which reports success and zero items; the unterminated-<item> check catches it.
    static let truncated = """
    <?xml version="1.0" standalone="yes"?>
    <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
      <channel>
        <item>
          <title>0.9.99</title>
          <sparkle:version>0.9.99
    """

    /// Corruption the XML parser itself must reject: the item closes as a channel.
    static let mismatched = """
    <?xml version="1.0" standalone="yes"?>
    <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
      <channel>
        <item>
          <title>0.9.99</title>
        </channel>
      </item>
    </rss>
    """

    /// Well-formed, but carries no build at all.
    static let empty = """
    <?xml version="1.0" standalone="yes"?>
    <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
      <channel>
        <title>Verba</title>
      </channel>
    </rss>
    """
}

// MARK: - Capture path contract

/// Contract tests for the microphone capture path (`AudioRecorder`, `MicDevices`, and the
/// permission dead-ends in `AppDelegate`).
///
/// These live in this target for the same reason the Sparkle checks do, and with the same
/// technique: the production sources are read AS DATA (`RepoFile`), never imported. The app target
/// is macOS-only — it pulls WhisperKit, FluidAudio, Sparkle and AppKit — so a test that imported
/// `AudioRecorder` could not build on Linux CI at all, and a test that instantiated one would need
/// a real microphone, a real TCC grant and a real CoreAudio device list. What CAN be pinned
/// without any of that is the SHAPE of the decisions, and the shape is exactly what regressed:
/// every failure below was a path that refused to record and said nothing.
///
/// Their limits, stated rather than implied: these prove the guards are present and correctly
/// polarised in the source. They do NOT prove the app records. Only running it on a Mac does that.
/// Every assertion has a negative twin — the specific broken form must be ABSENT — so a checker
/// that would pass on the pre-fix source is a failing checker.
final class CaptureContractTests: XCTestCase {

    private func audioRecorder() throws -> String { try RepoFile.contents(of: "Sources/Verba/AudioRecorder.swift") }
    private func micDevices() throws -> String { try RepoFile.contents(of: "Sources/Verba/MicDevices.swift") }
    private func appDelegate() throws -> String { try RepoFile.contents(of: "Sources/Verba/AppDelegate.swift") }

    /// THE regression this suite exists for. `recorder != nil` and "a recording is live" are not
    /// the same fact: AVAudioRecorder stops itself on an encode error, a route change, or when its
    /// input device disappears, none of which run our `stop()`. Refusing on the nil-check alone
    /// therefore latches, and from that moment every `start()` in every mode — Raw included, since
    /// this sits below the mode layer — returns false until the app is relaunched.
    func testStartRecoversFromARecorderThatStoppedItself() throws {
        let source = try audioRecorder()
        XCTAssertFalse(source.contains("guard recorder == nil else"),
                       "start() must not refuse on `recorder != nil` alone — a recorder that stopped itself is not a live recording, and refusing on it blocks every mode until relaunch")
        XCTAssertTrue(source.contains("guard !live.isRecording, !isPaused else"),
                      "the refusal must be conditioned on isRecording, so a dead recorder is torn down instead of latching")
        XCTAssertTrue(Regex.captures(#"guard !live\.isRecording, !isPaused else \{[^}]*\}\s*\n[\s\S]{0,600}?(recorder = nil)"#, in: source).count == 1,
                      "the recovery branch must actually clear `recorder`, otherwise start() still refuses on the next press")
    }

    /// The other half of that fact, and the one the recovery above can destroy: a recorder the user
    /// PAUSED also reports `isRecording == false`. Testing isRecording alone therefore reads a
    /// paused dictation as a corpse and tears it down — `live.stop()` flushes the file, `recorder`
    /// is cleared and the audio the user is still holding is gone, silently. Paused is a live
    /// recording waiting for `resume()`, so it must refuse exactly like a running one.
    func testStartDoesNotDiscardAPausedRecording() throws {
        let source = try audioRecorder()
        XCTAssertFalse(source.contains("guard !live.isRecording else"),
                       "the isRecording-only form is the regression: a paused recorder reports isRecording == false and would be torn down as stale")
        XCTAssertEqual(Regex.captures(#"guard !live\.isRecording, (!isPaused) else"#, in: source).count, 1,
                       "the staleness test must ask isPaused too, so a paused recording is preserved rather than discarded")
        // Polarity: the paused case takes the REFUSAL branch (return false), never the teardown.
        // The teardown must stay strictly below the guard, where only a genuinely dead recorder reaches it.
        XCTAssertTrue(Regex.captures(#"guard !live\.isRecording, !isPaused else \{[^}]*(return false)[^}]*\}"#, in: source).count == 1,
                      "a paused recorder must make start() return false, not fall through to `live.stop()`")
    }

    /// A recorder that is discarded without restoring the default input leaves the user's system
    /// mic switched to Verba's chosen device for every other app.
    func testStaleRecorderRecoveryRestoresTheDefaultInput() throws {
        let source = try audioRecorder()
        let recovery = try XCTUnwrap(Regex.captures(#"discarding a stale recorder[\s\S]{0,400}?\n(\s*\})"#, in: source).first,
                                     "the stale-recorder recovery branch should be identifiable by its log line")
        XCTAssertFalse(recovery.isEmpty)
        XCTAssertTrue(source.contains("restoreMic()   // it held a default-input switch we never restored"),
                      "tearing down a stale recorder must restore whatever input device was default before it ran")
    }

    /// A saved mic that is unplugged, powered off, or came from another Mac is the NORMAL case.
    /// It must degrade to the system default input, never fail the recording.
    func testAnUnresolvableMicUIDFallsBackToTheSystemDefault() throws {
        let recorder = try audioRecorder()
        let devices = try micDevices()
        XCTAssertTrue(recorder.contains("falling back to the system default input"),
                      "an unresolvable mic UID must be logged and fall back, not fail the capture")
        // Polarity check: the fallback branch returns nil (= use the default), it does not propagate
        // a failure. `chosenMicToApply` returning nil is what makes start() take the default path.
        XCTAssertTrue(Regex.captures(#"guard let chosen = MicDevices\.id\(forUID: uid\) else \{[\s\S]{0,300}?(return nil)"#, in: recorder).count == 1,
                      "the unresolved-UID branch must `return nil` (record from the default input)")
        XCTAssertTrue(devices.contains("guard !uid.isEmpty else { return nil }"),
                      "MicDevices.id(forUID:) must treat an empty UID as 'no choice' rather than scanning for a device named \"\"")
    }

    /// macOS never re-prompts once microphone access is denied, so a flash that disappears in two
    /// seconds leaves every mode permanently silent with no next step.
    func testARefusedMicrophoneGrantOffersTheSettingsPane() throws {
        let recorder = try audioRecorder()
        let delegate = try appDelegate()
        XCTAssertTrue(recorder.contains("var permissionRefused: Bool"),
                      "the recorder must expose whether macOS is REFUSING the mic, distinct from 'not asked yet'")
        XCTAssertTrue(delegate.contains("permissionRefused { self.promptMicPermission() }"),
                      "a refused grant must route to the actionable prompt, not to a transient flash")
        XCTAssertTrue(delegate.contains("Privacy_Microphone"),
                      "the prompt must open the Microphone pane — the only place the user can reverse a denial")
    }

    /// The Fn dead end: `fnTapPermissionsGranted()` reads ACCESSIBILITY only, so a user with
    /// Accessibility granted and Input Monitoring missing burned every silent retry and was never
    /// told which permission to grant.
    func testExhaustedFnTapRetriesSurfaceThePermissionAlert() throws {
        let delegate = try appDelegate()
        XCTAssertTrue(delegate.contains("guard attemptsLeft > 0 else { forceTapPermissionAlert(); return }"),
                      "when every silent retry has failed the tap is genuinely dead — the user must be told, not left with a dead Fn key")
        XCTAssertFalse(delegate.contains("guard attemptsLeft > 0, Settings.shared.useFnAsPrimary, !FnTap.shared.active else { return }"),
                      "the old form returned quietly on exhaustion, which is the silent dead end itself")
        XCTAssertTrue(delegate.contains("Privacy_ListenEvent"),
                      "the alert must name and open Input Monitoring, not only Accessibility")
    }

    /// Every branch that declines to start a capture has to say so. A trigger that starts nothing
    /// and prints nothing is indistinguishable from a broken microphone, which is precisely how
    /// this bug was reported.
    func testNoCapturePathDeclinesSilently() throws {
        let delegate = try appDelegate()
        for (guardClause, why) in [
            ("if todoCaptureRecording {", "a stuck to-do capture would swallow every dictation with no message"),
            ("if transformInFlight { flashStatusItemMessage(", "a Fn press during a transform must explain why nothing started"),
        ] {
            XCTAssertTrue(delegate.contains(guardClause), why)
        }
        XCTAssertFalse(delegate.contains("if todoCaptureRecording { resetOneShotFlags(); return }"),
                       "the silent one-line form is the regression: it returns with no recorder, no overlay and no message")
        XCTAssertFalse(delegate.contains("if transformInFlight { return }\n\n        // Double-tap"),
                       "the dictation path's transform guard must not return silently")
    }

    /// The delegate callbacks existed in the conformance list and nowhere else, so an encoder
    /// failure was invisible and could poison the PRE-ARMED recorder — which `prewarm()` then
    /// refuses to replace, because it only arms when `armed == nil`.
    func testEncoderFailuresDropThePreArmedRecorder() throws {
        let source = try audioRecorder()
        XCTAssertTrue(source.contains("func audioRecorderEncodeErrorDidOccur"),
                      "AVAudioRecorderDelegate was declared but its failure callbacks were never implemented")
        XCTAssertTrue(source.contains("func audioRecorderDidFinishRecording"))
        XCTAssertEqual(Regex.captures(#"if recorder === armed \{ (discardArmed\(\)) \}"#, in: source).count, 2,
                       "both failure callbacks must drop a poisoned armed recorder so prewarm() can build a healthy one")
    }

    // MARK: The silent input

    /// The dead end this group exists for, observed on a real machine: the system default input was
    /// a Bluetooth speaker that advertises a microphone and sends no audio, so Verba recorded a
    /// 28-byte file, threw `TranscribeError.empty` and flashed "Didn't catch that". Mic access was
    /// granted, the recorder was healthy, and the working built-in mic sat unselected. The app was
    /// working perfectly and looked broken, because nothing it said named the device or a next step.
    ///
    /// The recorder therefore has to REMEMBER whether any audio reached it, per capture: without
    /// that fact, "no words" and "no sound at all" are indistinguishable at the failure site.
    func testTheRecorderRemembersWhetherAnyAudioEverReachedIt() throws {
        let source = try audioRecorder()
        XCTAssertTrue(source.contains("private(set) var sawSignal = false"),
                      "the recorder must expose whether the capture ever saw signal, and only the recorder may set it")
        XCTAssertTrue(source.contains("private static let signalFloorDB: Float"),
                      "the floor that separates 'no samples at all' from 'a quiet room' has to be a named constant, not a literal buried in the sampler")
        XCTAssertEqual(Regex.captures(#"(self\.sawSignal = true)"#, in: source).count, 1,
                       "the latch is one-way and set in exactly one place: a second writer is a second answer")
        XCTAssertFalse(source.contains("\n    var sawSignal"),
                       "sawSignal must not be publicly settable — a caller that can write it can fake a silent capture")
        // The verdict is read from the meter that already exists, not from a second audio tap.
        XCTAssertTrue(Regex.captures(#"rec\.updateMeters\(\)\s*\n\s*guard rec\.averagePower\(forChannel: 0\) > (Self\.signalFloorDB)"#, in: source).count == 1,
                      "the sampler must reuse averagePower, the same reading level() already takes")
    }

    /// Reset polarity, and it is the one that can destroy a live dictation if it is wrong: `start()`
    /// refuses when a recording is already live or paused, and that refusal must leave the running
    /// capture's verdict alone. Resetting above the guard would clear the flag of the recording that
    /// is still going, so a genuine capture could report itself silent.
    func testTheSignalVerdictIsResetPerCaptureBelowTheLiveGuard() throws {
        let source = try audioRecorder()
        // The statement, at start()'s own indentation, not the property declaration above it.
        let reset = try XCTUnwrap(source.range(of: "\n        sawSignal = false"),
                                  "every start() must begin with a clean verdict")
        let guardClause = try XCTUnwrap(source.range(of: "guard !live.isRecording, !isPaused else"),
                                        "the live-recorder guard is where the refusal happens")
        XCTAssertTrue(guardClause.lowerBound < reset.lowerBound,
                      "the reset must sit BELOW the live-recorder guard, otherwise a refused start() wipes the running capture's verdict")
        XCTAssertTrue(source.contains("captureDeviceName = nil"),
                      "the device name belongs to one capture and must not survive into the next one")
    }

    /// Both start paths have to be watched. The fast path (a pre-armed recorder) is the one a normal
    /// dictation takes, so a watch wired only into the cold path would report "no signal" for every
    /// successful capture and blame a working microphone.
    func testBothStartPathsWatchTheInputLevel() throws {
        let source = try audioRecorder()
        XCTAssertFalse(source.contains("armed = nil; armedURL = nil\n                return true"),
                       "the pre-fix fast path returned without ever observing the input level")
        XCTAssertFalse(source.contains("currentURL = url\n            return true"),
                       "the pre-fix slow path returned without ever observing the input level")
        XCTAssertEqual(Regex.captures(#"(beginSignalWatch\(rec\))"#, in: source).count, 2,
                       "the fast path and the cold path must both start the watch")
        // Latency: the watch is armed AFTER record() has already returned true, so neither path waits on it.
        XCTAssertTrue(Regex.captures(#"if rec\.record\(\) \{[\s\S]{0,200}?(beginSignalWatch\(rec\))"#, in: source).count == 1,
                      "the fast path must call record() first and only then arm the watch")
    }

    /// `stop()` ends the sampling and NOTHING else: the whole point is that the caller reads the
    /// verdict after the capture has ended. Clearing it there would make the failure site blind
    /// again, which is the original bug with extra steps.
    func testStopEndsTheSamplingButKeepsTheVerdict() throws {
        let source = try audioRecorder()
        let body = try XCTUnwrap(Regex.captures(#"func stop\(\) -> URL\? \{([\s\S]*?)\n    \}"#, in: source).first,
                                 "stop() should be readable on its own")
        XCTAssertTrue(body.contains("endSignalWatch()"), "stop() must stop the meter sampler it started")
        XCTAssertFalse(body.contains("sawSignal = false"),
                       "stop() must NOT clear the verdict: the caller reads it after the capture ends")
        XCTAssertFalse(body.contains("captureDeviceName = nil"),
                       "the device name must survive stop(), which has already restored the previous default input")
    }

    /// Naming the device is what turns the message from a shrug into an instruction, and the name
    /// has to come from `MicDevices` — the one place that talks to CoreAudio. A second copy of that
    /// code in the delegate would be a second thing to keep correct.
    func testTheCaptureDeviceIsNamedThroughMicDevices() throws {
        let recorder = try audioRecorder()
        let devices = try micDevices()
        let delegate = try appDelegate()
        XCTAssertTrue(devices.contains("static func defaultInputName() -> String?"),
                      "MicDevices must be able to name the current default input, not only resolve its id and UID")
        XCTAssertTrue(devices.contains("return stringProp(id, kAudioObjectPropertyName)"),
                      "the name must be read off the device like defaultInputUID does, not by enumerating every input")
        XCTAssertTrue(recorder.contains("captureDeviceName = MicDevices.defaultInputName()"),
                      "the recorder must capture the device name while the capture is running, since stop() restores the previous default")
        XCTAssertFalse(delegate.contains("kAudioHardwarePropertyDefaultInputDevice"),
                       "the delegate must ask MicDevices, never re-derive the default input with its own CoreAudio call")
    }

    /// The failure site itself. `TranscribeError.empty` plus "no signal ever seen" is not the same
    /// event as `TranscribeError.empty` plus "we heard a room": the first one is a device the user
    /// must replace, the second one is silence they chose. The pre-fix source treated both as one
    /// two-second flash, which named neither the device nor a way out.
    func testASilentInputGetsANamedActionableAlertInsteadOfAFlash() throws {
        let delegate = try appDelegate()
        XCTAssertFalse(delegate.contains("if benign {\n            flashInfo(\"Didn't catch that\")"),
                       "the pre-fix shape is the dead end itself: every empty transcription got the same unactionable flash")
        XCTAssertEqual(Regex.captures(#"if case TranscribeError\.empty = error, !recorder\.sawSignal \{\s*\n\s*(promptSilentInput\(\))"#, in: delegate).count, 1,
                       "an empty transcription from a capture that saw NO signal must route to the actionable prompt")
        XCTAssertTrue(delegate.contains("No sound reached Verba from \\(named)"),
                      "the message must name the device that was actually recorded from")
        XCTAssertTrue(delegate.contains("recorder.captureDeviceName.map"),
                      "the name shown must be the recorder's captured device, not the current default (which stop() has already restored)")
    }

    /// Polarity, and the reason the flag exists at all: a capture that DID hear something and still
    /// transcribed to nothing is ordinary empty speech (an accidental key tap), and it must keep the
    /// quiet flash. Promoting that to a modal alert would nag every user who brushed the trigger.
    func testAnEmptyCaptureThatDidHearSomethingKeepsTheQuietFlash() throws {
        let delegate = try appDelegate()
        XCTAssertEqual(Regex.captures(#"promptSilentInput\(\)\s*\n\s*\} else \{\s*\n\s*(flashInfo\("Didn't catch that"\))"#, in: delegate).count, 1,
                       "the signal-was-seen branch must still flash 'Didn't catch that' rather than open an alert")
        XCTAssertFalse(delegate.contains("if benign {\n            promptSilentInput()"),
                       "a silent-input alert on EVERY benign failure would fire on too-short taps too")
    }

    /// An alert with no button that changes anything is the same dead end in a bigger window. The
    /// prompt must open the pane where the input can actually be swapped, and it must never print a
    /// raw Optional at the user when the device name cannot be read.
    func testTheSilentInputAlertOffersTheInputPaneAndNeverShowsAnEmptyName() throws {
        let delegate = try appDelegate()
        XCTAssertTrue(delegate.contains("com.apple.preference.sound?input"),
                      "the prompt must open Sound ▸ Input, the pane with a live input meter where the user can see the replacement work")
        XCTAssertTrue(delegate.contains("Open Sound Settings"),
                      "the fix has to be one button, not a sentence describing where to click")
        XCTAssertTrue(delegate.contains("?? \"your current microphone\""),
                      "an unreadable device name must degrade to a readable phrase, never to an empty pair of quotes")
        XCTAssertFalse(delegate.contains("private func promptSilentInput() {\n        flashInfo("),
                       "the prompt must not be a flash in disguise: a two-second banner is the dead end this fix replaces")
        XCTAssertEqual(Regex.captures(#"private func promptSilentInput\(\) \{[\s\S]*?(\.init\(title: "Later", role: \.cancel)"#, in: delegate).count, 1,
                       "the alert must be dismissible without doing anything, like every other Verba prompt")
    }
}

// MARK: - Capture diagnostics contract

/// Contract tests for the capture path's OBSERVABILITY and for the built-in-microphone recovery.
///
/// What bought this suite: a user reported dictation that worked, then did not, and a live failing
/// session 24 minutes long produced ONE line in the unified log. Twelve reviews of a byte-identical
/// trigger, engine and transcription path found no regression, because the app was not saying
/// enough for anyone to find one. An undiagnosable failure is a permanent failure, so the shape of
/// the diagnostics is pinned here exactly like the guards above.
///
/// Same technique and the same stated limits as `CaptureContractTests`: the sources are read AS
/// DATA, never imported, so this runs on Linux CI where the macOS app cannot even be built. These
/// prove the log lines and the recovery conditions are PRESENT and correctly bounded in the source.
/// They do NOT prove a single byte was ever written to the unified log. Only running the app on a
/// Mac does that. Every assertion below fails against the pre-fix sources.
final class CaptureDiagnosticsContractTests: XCTestCase {

    private func audioRecorder() throws -> String { try RepoFile.contents(of: "Sources/Verba/AudioRecorder.swift") }
    private func micDevices() throws -> String { try RepoFile.contents(of: "Sources/Verba/MicDevices.swift") }
    private func appDelegate() throws -> String { try RepoFile.contents(of: "Sources/Verba/AppDelegate.swift") }

    /// A capture that fails has to say WHICH device fed it, and both start paths have to say it. The
    /// pre-fix source returned from each path in silence, so a failing session could not even be
    /// attributed to a device, let alone to a cause.
    func testEveryStartLogsThePathTheDeviceAndWhetherRecordWasAccepted() throws {
        let source = try audioRecorder()
        XCTAssertFalse(source.contains("beginSignalWatch(rec)\n                return true"),
                       "the pre-fix fast path returned without logging anything at all")
        XCTAssertFalse(source.contains("beginSignalWatch(rec)\n            return true"),
                       "the pre-fix cold path returned without logging anything at all")
        XCTAssertTrue(source.contains("logCaptureStart(path: \"prearmed\", started: true)"),
                      "the prearmed fast path must be identifiable in the log: it is the path a normal dictation takes")
        XCTAssertTrue(source.contains("logCaptureStart(path: \"cold\", started: true)"),
                      "the cold path must be distinguishable from the fast one, since taking it at all is a fact worth seeing")
        XCTAssertTrue(source.contains("logCaptureStart(path: \"cold\", started: false)"),
                      "a record() that was REFUSED is the most important start of all and must not be the one that goes unlogged")
        for field in ["capture: start path=", "device=", "uid=", "chosenMicSwitch=", "record="] {
            XCTAssertTrue(source.contains(field),
                          "the start line must carry \(field): naming the device without its uid cannot tell two identically named inputs apart")
        }
    }

    /// Level, not decoration. The unified log keeps `.info` and `.debug` messages in MEMORY only, so
    /// a diagnostic logged there is gone by the time anyone asks the user for a log, which is
    /// exactly the failure being fixed. Default level persists to disk and survives to the report.
    func testCaptureDiagnosticsAreLoggedAtDefaultLevelSoTheySurviveToDisk() throws {
        let source = try audioRecorder()
        XCTAssertTrue(source.contains("VerbaLog.audio.log(\"capture: start"),
                      "the start line must be logged at default level so `log show` still has it after the fact")
        XCTAssertFalse(source.contains("VerbaLog.audio.info(\"capture:"),
                       "an .info capture diagnostic is memory-only: it would be missing from every log a user sends back")
        XCTAssertFalse(source.contains("VerbaLog.audio.debug(\"capture:"),
                       "same for .debug, and it is off by default on top of that")
    }

    /// THE number. An input that takes hundreds of milliseconds (or seconds) to deliver its first
    /// sample is a device waking up, which is what a Bluetooth input in A2DP mode does while it
    /// negotiates SCO/HFP. Without this measurement, "it works, then it does not" cannot be told
    /// apart from a code fault, which is how twelve reviews found nothing.
    func testTheFirstSignalLatencyIsMeasuredFromRecordAndLogged() throws {
        let source = try audioRecorder()
        XCTAssertFalse(source.contains("self.sawSignal = true\n            timer.invalidate()"),
                       "the pre-fix watcher latched the verdict and threw the timing away")
        XCTAssertTrue(source.contains("private(set) var firstSignalMs: Int?"),
                      "the latency must be readable after the capture, not only printed once")
        XCTAssertTrue(source.contains("captureStartedAt = Date()"),
                      "the clock has to start where record() was accepted, not where the file was created")
        XCTAssertEqual(Regex.captures(#"let ms = Int\(Date\(\)\.timeIntervalSince\(self\.captureStartedAt[\s\S]{0,60}?(\* 1000)\)"#, in: source).count, 1,
                       "the latency must be measured from captureStartedAt and reported in milliseconds")
        XCTAssertTrue(source.contains("capture: first signal after \\(ms"),
                      "the measurement is worthless if it is not on its own grep-able line")
    }

    /// The other half of the same diagnosis, and the reason the peak is tracked at all: on a capture
    /// that NEVER crosses the floor, the peak is the only number that separates a device sending
    /// literally nothing from a live device the user spoke too far from. The pre-fix watcher
    /// discarded every reading below the floor, so a silent capture reported no number whatsoever.
    func testThePeakLevelIsKeptEvenWhileItStaysUnderTheSignalFloor() throws {
        let source = try audioRecorder()
        XCTAssertFalse(source.contains("> Self.signalFloorDB else { return }"),
                       "the pre-fix guard dropped every sub-floor reading, which is precisely the reading a silent capture needs")
        XCTAssertTrue(source.contains("else { self.notePeak(rec); return }"),
                      "a reading under the floor must still update the peak before the sampler moves on")
        XCTAssertTrue(source.contains("private(set) var peakLevelDB: Float"),
                      "the peak belongs to the capture and must be readable after it, like sawSignal")
        XCTAssertTrue(source.contains("private static let meterFloorDB: Float = -160"),
                      "the reset value must be the meter's own floor, so an unstarted capture never reports a peak it did not measure")
    }

    /// The end of a capture is where the two facts a bug report needs come together: how long it ran
    /// and how much audio came out of it. A 28-byte file after 20 seconds of speaking is a complete
    /// diagnosis on its own, and the pre-fix source printed neither number.
    func testTheEndOfCaptureLineCarriesDurationSizeAndTheSignalVerdict() throws {
        let source = try audioRecorder()
        XCTAssertFalse(source.contains("let finished = currentURL\n        // Re-arm"),
                       "the pre-fix stop() went straight from the finished URL to the re-arm, recording nothing about the capture")
        XCTAssertTrue(source.contains("finishCapture(finished)"),
                      "stop() must hand the finished capture to the one place that reports it")
        for field in ["capture: stop device=", "seconds=", "bytes=", "sawSignal=", "firstSignalMs=", "peakDB="] {
            XCTAssertTrue(source.contains(field), "the stop line must carry \(field)")
        }
    }

    /// Privacy, and it is a hard line rather than a preference: these lines exist to be sent to us by
    /// a user. Device names and dB readings are hardware facts; a file path under the user's home and
    /// anything they dictated are not ours to publish. The file's SIZE answers the question without
    /// naming the file.
    func testTheCaptureDiagnosticsCarryNoPathAndNothingPersonal() throws {
        let source = try audioRecorder()
        let captureLines = source.split(separator: "\n").filter { $0.contains("VerbaLog.audio") && $0.contains("capture: ") }
        XCTAssertGreaterThanOrEqual(captureLines.count, 5,
                                    "one failing dictation has to produce several lines, not the single line that made this undiagnosable")
        for line in captureLines {
            XCTAssertFalse(line.contains(".path"), "a capture log line must never carry a filesystem path: \(line)")
            XCTAssertFalse(line.contains("currentURL"), "a capture log line must never carry the recording URL: \(line)")
            XCTAssertFalse(line.contains("text"), "a capture log line must never carry transcribed text: \(line)")
        }
        XCTAssertTrue(source.contains("resourceValues(forKeys: [.fileSizeKey])"),
                      "the size is read off the file, which is the one fact about it that may be logged")
    }

    /// A capture that saw nothing is an ERROR, not a note, and it has to name the device: "no sound
    /// reached Verba" is only actionable when the user can see WHICH input produced the silence.
    func testASilentCaptureIsLoggedAsAnErrorThatNamesTheDevice() throws {
        let source = try audioRecorder()
        XCTAssertEqual(Regex.captures(#"if !sawSignal \{\s*\n\s*(VerbaLog\.audio\.error\("capture: no signal from )"#, in: source).count, 1,
                       "a capture that saw zero signal must be logged at error level, immediately, and never as an ordinary note")
        XCTAssertTrue(source.contains("capture: no signal from \\(device"),
                      "the error must name the device it recorded from, not just report that nothing arrived")
        XCTAssertFalse(source.contains("VerbaLog.audio.log(\"capture: no signal"),
                       "logging the silent case at default level would bury it under the ordinary stop lines")
    }

    // MARK: The built-in microphone recovery

    /// Part 2, and the whole safety argument for it: three conditions, ALL required. Any one of them
    /// missing turns a recovery into Verba overruling a choice the user made.
    func testTheBuiltInRecoveryNeedsAllThreeConditions() throws {
        let recorder = try audioRecorder()
        let devices = try micDevices()
        XCTAssertEqual(Regex.captures(#"guard let silent = silentDefaultUID, (Settings\.shared\.micUID\.isEmpty) else \{ return nil \}"#, in: recorder).count, 1,
                       "condition 1 and 2: a remembered silent device AND no mic chosen by the user, in one guard so neither can be dropped alone")
        XCTAssertEqual(Regex.captures(#"guard MicDevices\.defaultInputUID\(\) == silent else \{ (silentDefaultUID = nil)"#, in: recorder).count, 1,
                       "condition 3: if the default input is no longer the device we blamed, the user already fixed it and we must stay out of the way")
        XCTAssertTrue(devices.contains("static let builtInInputUID = \"BuiltInMicrophoneDevice\""),
                      "the fallback target must be the stable CoreAudio UID, never a device name that changes with the system language")
        XCTAssertFalse(recorder.contains("if let rec = armed, chosen == nil {"),
                       "the pre-fix fast path would reuse a recorder bound to the device that just produced nothing")
        XCTAssertTrue(recorder.contains("if let rec = armed, chosen == nil, recovery == nil {"),
                      "a pending recovery is a device switch and must take the cold path, exactly like a chosen mic")
    }

    /// The memory is the dangerous half: remembered too eagerly, it moves a user's microphone for
    /// them after a stray key tap. It is written only below every guard, and any capture that hears
    /// something erases it.
    func testTheSilentDeviceMemoryIsBoundedAndClearedOnSuccess() throws {
        let source = try audioRecorder()
        let body = try XCTUnwrap(Regex.captures(#"private func noteSilentDefault\(after seconds: TimeInterval\) \{([\s\S]*?)\n    \}"#, in: source).first,
                                 "the memory rule should be readable as one function")
        XCTAssertTrue(body.contains("if sawSignal { silentDefaultUID = nil"),
                      "a capture that heard anything must clear the blame outright: the recovery lasts exactly as long as the problem")
        XCTAssertTrue(body.contains("guard Settings.shared.micUID.isEmpty else { return }"),
                      "a user who picked their own microphone must never be second-guessed, so nothing is remembered in that case")
        XCTAssertTrue(body.contains("seconds >= Self.minSecondsToBlameDevice"),
                      "a capture too short to have been measured must not be allowed to blame a healthy device")
        let guardEnd = try XCTUnwrap(body.range(of: "minSecondsToBlameDevice"))
        let write = try XCTUnwrap(body.range(of: "silentDefaultUID = uid"),
                                  "the blame has to be recorded somewhere")
        XCTAssertTrue(guardEnd.upperBound < write.lowerBound,
                      "the write must sit BELOW every guard, otherwise the bounds are decoration")
        XCTAssertTrue(source.contains("private static let minSecondsToBlameDevice: TimeInterval = 1.0"),
                      "the minimum must be a named constant, not a literal buried in the check")
    }

    /// "If the built-in mic cannot be resolved, change nothing and just log." A Mac with no built-in
    /// input exists, and moving that user's default somewhere arbitrary would be worse than the
    /// silence we are trying to fix.
    func testAnUnresolvableBuiltInMicrophoneChangesNothingAndOnlyLogs() throws {
        let recorder = try audioRecorder()
        let devices = try micDevices()
        XCTAssertEqual(Regex.captures(#"guard let builtIn = MicDevices\.builtInInput\(\) else \{[\s\S]{0,400}?(return nil)"#, in: recorder).count, 1,
                       "an unresolvable built-in mic must return nil (change nothing), never pick some other device")
        XCTAssertTrue(recorder.contains("no built-in microphone to fall back to"),
                      "changing nothing still has to be said out loud, or the recovery's absence is invisible")
        XCTAssertTrue(devices.contains("static func builtInInput() -> Device?"),
                      "resolving the built-in mic belongs in MicDevices, the one place that talks to CoreAudio")
        XCTAssertEqual(Regex.captures(#"private func applyBuiltInRecovery\(_ builtIn: AudioDeviceID\?\) \{\s*\n\s*(guard let builtIn else \{ return \})"#, in: recorder).count, 1,
                       "the switch must refuse to run on a nil device rather than reach CoreAudio with one")
    }

    /// A recovery is one capture long. It borrows the default input exactly like a chosen mic does,
    /// which means the previous device is read BEFORE the switch and restored by stop() after, or the
    /// user's whole system is left pointing at Verba's choice.
    func testTheRecoverySwitchIsRecordedSoStopRestoresIt() throws {
        let source = try audioRecorder()
        let body = try XCTUnwrap(Regex.captures(#"private func applyBuiltInRecovery\(_ builtIn: AudioDeviceID\?\) \{([\s\S]*?)\n    \}"#, in: source).first,
                                 "the recovery switch should be readable as one function")
        let read = try XCTUnwrap(body.range(of: "let current = MicDevices.defaultInputID()"),
                                 "the previous default has to be read")
        let set = try XCTUnwrap(body.range(of: "MicDevices.setDefaultInput(builtIn)"),
                                "the switch has to happen")
        XCTAssertTrue(read.upperBound < set.lowerBound,
                      "reading the previous default AFTER switching would record Verba's own choice as the thing to restore")
        XCTAssertTrue(body.contains("if restoreDefaultInput == nil { restoreDefaultInput = current }"),
                      "a chosen-mic switch already in place must not have its original device overwritten")
        XCTAssertTrue(body.contains("capture: recovery, recording from the built-in microphone because"),
                      "a recovery that changes which device the user records from must say so")
    }

    /// The delegate's half: the recorder's lines say what the microphone did, this one says what came
    /// of it. Without it the log shows a healthy-looking capture and never mentions that the user was
    /// shown nothing.
    func testTheDelegateLogsTheOutcomeOfACaptureThatProducedNothing() throws {
        let delegate = try appDelegate()
        XCTAssertFalse(delegate.contains("guard self.recorder.start() else { self.resetOneShotFlags(); self.flashError(\"Couldn't start recording\"); return }"),
                       "the pre-fix form failed a dictation start with a two-second flash and not one line in the log")
        XCTAssertTrue(delegate.contains("capture: dictation start refused by AudioRecorder.start()"),
                      "a dictation that never began must be visible in the log, not only on screen for two seconds")
        XCTAssertTrue(delegate.contains("capture: nothing transcribed sawSignal="),
                      "the empty-result branch must record the signal verdict that decided which message the user got")
    }
}

// MARK: - Transcription language contract

/// Contract tests for the language a transcription is pinned to.
///
/// The bug these exist for: `Settings` held the user's Primary language (`mainLanguage`), but every
/// call site derived the engine's language from the OPTIONAL "Spoken language" picker alone and
/// passed `nil` whenever it was empty. `nil` means auto-detect, and both on-device engines detect
/// per audio window — so a French dictation from a user whose Primary language is French could come
/// back partly, or entirely, in English. The user had already answered the question; the engine was
/// asked to guess it anyway.
///
/// Same technique and the same stated limits as the capture suite above: the production sources are
/// read AS DATA (`RepoFile`), never imported, because the app target is macOS-only and would not
/// build on Linux CI. These prove the resolution ORDER is what it claims to be and that no
/// production call site still bypasses it. They do NOT prove Whisper or Parakeet honour the code
/// they are handed — only a real dictation on a Mac does that. Every assertion has a negative twin:
/// the specific broken form must be ABSENT, so a checker that would pass on the pre-fix source is a
/// failing checker.
final class TranscriptionLanguageContractTests: XCTestCase {

    private func settings() throws -> String { try RepoFile.contents(of: "Sources/Verba/Settings.swift") }

    /// The body of `var transcriptionLanguage: String?`, so the assertions below read the resolver
    /// itself rather than any other mention of the same identifiers elsewhere in Settings.
    private func resolverBody() throws -> String {
        let source = try settings()
        let bodies = Regex.captures(#"var transcriptionLanguage: String\? \{([\s\S]*?)\n    \}"#, in: source)
        XCTAssertEqual(bodies.count, 1, "there must be exactly ONE transcription-language resolver — a second one is a second answer")
        return try XCTUnwrap(bodies.first)
    }

    // MARK: The resolver itself

    /// One helper, on Settings, returning an optional code. If it is not optional there is no way to
    /// express auto-detect; if it lives anywhere else the call sites will keep re-deriving it.
    func testSettingsExposesASingleOptionalResolver() throws {
        let source = try settings()
        XCTAssertEqual(Regex.captures(#"var (transcriptionLanguage): String\?"#, in: source).count, 1,
                       "Settings must expose exactly one `transcriptionLanguage: String?`")
    }

    /// Precedence, and it is the whole point of the helper: an explicit "Spoken language" is an
    /// explicit instruction and outranks the Primary language. The broken order would silently
    /// ignore the picker for anyone who also set a Primary language.
    func testExplicitSpokenLanguageIsReadAndReturnedFirst() throws {
        let body = try resolverBody()
        let spoken = try XCTUnwrap(body.range(of: "language.trimmingCharacters"),
                                   "the resolver must read the explicit Spoken language setting")
        let primary = try XCTUnwrap(body.range(of: "mainLanguage"),
                                    "the resolver must fall back to the Primary language")
        XCTAssertTrue(spoken.lowerBound < primary.lowerBound,
                      "the explicit Spoken language must be consulted BEFORE mainLanguage, otherwise the picker is outranked by the fallback")
        XCTAssertEqual(Regex.captures(#"if !spoken\.isEmpty \{ (return spoken) \}"#, in: body).count, 1,
                       "a non-empty Spoken language must return immediately — anything else lets the fallback overwrite an explicit choice")
    }

    /// The fix itself: an empty picker must fall through to the Primary language, mapped to ISO,
    /// instead of going straight to nil. `return nil` sitting on the empty-picker branch is exactly
    /// the pre-fix behaviour and must not reappear.
    func testPrimaryLanguageIsTheFallbackThroughTheISOMap() throws {
        let body = try resolverBody()
        XCTAssertTrue(body.contains("languageCode(forName:"),
                      "the Primary language is a display NAME, so it must go through the name→ISO map before reaching an engine")
        XCTAssertFalse(body.contains("guard !spoken.isEmpty else { return nil }"),
                       "returning nil on an empty picker is the regression: it discards a configured Primary language and re-enables per-chunk auto-detect")
    }

    /// Auto-detect must remain REACHABLE — this is not a fix that pins everyone to something. nil is
    /// the answer when neither setting is configured, and also when the Primary language is a name
    /// the ISO map does not carry (a Mac in a language Verba does not list).
    func testAutoDetectSurvivesWhenNeitherSettingIsConfigured() throws {
        let body = try resolverBody()
        XCTAssertEqual(Regex.captures(#"return (code\.isEmpty \? nil : code)"#, in: body).count, 1,
                       "the only nil must come from an unmapped/absent Primary language, so auto-detect stays reachable but is never the default for a configured user")
    }

    // MARK: Behaviour, against the map the app actually ships

    /// A model of the documented contract, driven by the REAL `languageNameToCode` table parsed out
    /// of Settings.swift. It cannot import the type (macOS-only target), so it re-states the rule —
    /// which is only worth anything because the tests above pin the production body to that same
    /// rule, and because the table is read rather than duplicated.
    private func resolve(spoken: String, primary: String, map: [String: String]) -> String? {
        let spoken = spoken.trimmingCharacters(in: .whitespaces)
        if !spoken.isEmpty { return spoken }
        let code = map[primary.trimmingCharacters(in: .whitespaces)] ?? ""
        return code.isEmpty ? nil : code
    }

    private func shippedLanguageMap() throws -> [String: String] {
        let source = try settings()
        let table = try XCTUnwrap(Regex.captures(#"let languageNameToCode: \[String: String\] = \[([\s\S]*?)\n\]"#, in: source).first,
                                  "the name→ISO table must stay parseable — the engines are handed its values")
        var map: [String: String] = [:]
        let regex = try NSRegularExpression(pattern: #""([A-Za-z ]+)": "([a-z]{2})""#)
        for match in regex.matches(in: table, range: NSRange(table.startIndex..., in: table)) {
            guard let name = Range(match.range(at: 1), in: table),
                  let code = Range(match.range(at: 2), in: table) else { continue }
            map[String(table[name])] = String(table[code])
        }
        XCTAssertGreaterThan(map.count, 10, "the parsed table is nearly empty — the parser broke, so every assertion below is vacuous")
        return map
    }

    /// The reported bug, stated as a test: French Primary language, no explicit picker, must reach
    /// every engine as "fr" rather than as nil.
    func testFrenchPrimaryLanguageResolvesToFR() throws {
        let map = try shippedLanguageMap()
        XCTAssertEqual(map["French"], "fr", "the shipped table must map French to the ISO code both engines expect")
        XCTAssertEqual(resolve(spoken: "", primary: "French", map: map), "fr",
                       "a French user with no explicit picker must be pinned to fr — passing nil here is what let the transcript drift to English")
        XCTAssertNotNil(resolve(spoken: "", primary: "French", map: map))
    }

    /// The precedence and the auto-detect escape hatch, end to end.
    func testResolutionOrderAndAutoDetectEndToEnd() throws {
        let map = try shippedLanguageMap()
        XCTAssertEqual(resolve(spoken: "en", primary: "French", map: map), "en",
                       "an explicit Spoken language must override the Primary language, not the other way round")
        XCTAssertEqual(resolve(spoken: "de", primary: "", map: map), "de",
                       "an explicit picker alone is still honoured")
        XCTAssertNil(resolve(spoken: "", primary: "", map: map),
                     "both empty is the real auto-detect case and must stay nil")
        XCTAssertNil(resolve(spoken: "", primary: "Klingon", map: map),
                     "a Primary language the ISO map does not carry must fall back to auto-detect, never to a bogus code")
    }

    // MARK: No call site bypasses it

    /// Every `.transcribe(fileURL:…)` in the app, found by scanning the sources rather than by a
    /// hand-written list, must take its `language:` from the resolver. A list would go stale the
    /// first time someone adds a seventh call site; the scan will not.
    func testNoProductionCallSiteBypassesTheResolver() throws {
        let directory = RepoFile.root.appendingPathComponent("Sources/Verba")
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path).filter { $0.hasSuffix(".swift") }.sorted()
        XCTAssertFalse(files.isEmpty, "no sources found — the scan below would pass vacuously")

        var callSites = 0
        for file in files {
            let source = try RepoFile.contents(of: "Sources/Verba/\(file)")
            for argument in Regex.captures(#"\.transcribe\(fileURL: [\s\S]{0,80}?language: ([^,\n]+),"#, in: source) {
                callSites += 1
                let argument = argument.trimmingCharacters(in: .whitespaces)
                if argument.contains("transcriptionLanguage") { continue }
                // A local binding is fine as long as the binding itself came from the resolver.
                let bound = Regex.captures(#"let \#(argument) = ([^\n]+)"#, in: source)
                XCTAssertTrue(bound.contains { $0.contains("transcriptionLanguage") },
                              "\(file) passes `language: \(argument)` — every transcription must be pinned through Settings.transcriptionLanguage, and `nil` or a re-derived picker read is the bug")
            }
        }
        XCTAssertGreaterThanOrEqual(callSites, 6,
                                    "the scanner found \(callSites) call sites; the known production paths are Pipeline, AppDelegate to-do capture, NotesView, FileTranscribeView, AdaptPanel and FeedbackView, so a lower count means the pattern stopped matching and this test is vacuous")
    }

    /// The two forms that WERE the bug, pinned as absent by name. The scan above would catch them,
    /// but naming them keeps the failure message pointed at the actual mistake.
    func testTheTwoBrokenFormsAreGoneFromEveryCallSite() throws {
        for file in ["Pipeline", "AppDelegate", "NotesView", "FileTranscribeView", "AdaptPanel", "FeedbackView"] {
            let source = try RepoFile.contents(of: "Sources/Verba/\(file).swift")
            XCTAssertFalse(source.contains("language: s.language.isEmpty ? nil : s.language"),
                           "\(file) still re-derives the language from the picker alone, ignoring the Primary language")
            XCTAssertFalse(source.contains("settings.language.isEmpty ? nil : settings.language"),
                           "\(file) still re-derives the language from the picker alone, ignoring the Primary language")
            XCTAssertFalse(source.contains(".transcribe(fileURL: url, language: nil"),
                           "\(file) still hard-codes auto-detect, which is what let a French dictation come back in English")
        }
    }

    /// The blast radius stays where it belongs: this change pins transcription INPUT only. Translate
    /// keeps its own output target and the reprompt directive keeps its own softer rule, so nothing
    /// here should have touched either.
    func testOutputLanguagePathsAreUntouched() throws {
        let source = try settings()
        XCTAssertTrue(source.contains("var languageDirective: String?"),
                      "the reprompt directive must survive — it governs OUTPUT language and is a different question from what the engine transcribes")
        let body = try resolverBody()
        XCTAssertFalse(body.contains("languageDirective"), "the transcription resolver must not reach into the output-language directive")
        XCTAssertFalse(body.contains("translate"), "Translate has its own target language and must not be consulted here")
    }
}

// MARK: - Stuck capture contract

/// Contract tests for the two ends of ONE failure: a capture that never stops.
///
/// What bought this suite, observed live on a real Mac: a dictation started at 14:27:29 was still
/// recording more than six minutes later, its .m4a still growing (444444 then 467788 bytes six
/// seconds apart) with Verba holding the descriptor, and no second trigger press ever came. The
/// default trigger is a TOGGLE, so a recording only ends on a second press; nothing in the audio
/// path capped a capture, so a press that never landed left the microphone open indefinitely. And
/// while it ran, the live-recorder guard in `start()` refused EVERY later dictation in EVERY mode,
/// which is exactly how it was reported: it does not work, does not work, then suddenly works
/// again. All the user ever saw was a two-second "Couldn't start recording", which named neither
/// the cause nor the cure.
///
/// Same technique and the same stated limits as `CaptureContractTests` above: the production
/// sources are read AS DATA (`RepoFile`), never imported, because the app target is macOS-only and
/// could not build on Linux CI. These prove the ceiling and the refusal reason are PRESENT, armed
/// on both start paths, cancelled per capture, and routed to a stop that PROCESSES the audio. They
/// do NOT prove a timer ever fired: only running the app on a Mac does that. Every assertion has a
/// negative twin naming the pre-fix shape, so a checker that would pass on the old source is a
/// failing checker.
final class StuckCaptureContractTests: XCTestCase {

    private func audioRecorder() throws -> String { try RepoFile.contents(of: "Sources/Verba/AudioRecorder.swift") }
    private func appDelegate() throws -> String { try RepoFile.contents(of: "Sources/Verba/AppDelegate.swift") }

    /// One function body, so an assertion reads the function itself rather than any other mention
    /// of the same identifiers elsewhere in the file.
    private func body(of signature: String, in source: String, _ what: String) throws -> String {
        let bodies = Regex.captures("\(signature) \\{([\\s\\S]*?)\\n    \\}", in: source)
        XCTAssertEqual(bodies.count, 1, "\(what) should be readable as exactly one function")
        return try XCTUnwrap(bodies.first)
    }

    // MARK: The ceiling

    /// The fact the whole failure rests on: nothing capped a capture. No maxRecord, no maxDuration,
    /// no autoStop, no record(forDuration:) existed anywhere in Sources/Verba, so a toggle whose
    /// second press never landed recorded until the disk or the user gave up.
    func testACaptureHasAHardCeiling() throws {
        let source = try audioRecorder()
        XCTAssertTrue(source.contains("static let maxCaptureSeconds: TimeInterval = 600"),
                      "a capture must have a named maximum duration, not an unbounded run")
        XCTAssertTrue(source.contains("private var ceilingTimer: Timer?"),
                      "the ceiling needs its own timer, separate from the signal watcher's")
        XCTAssertFalse(source.contains("private var signalTimer: Timer?\n\n    /// The encoder settings"),
                       "the pre-fix shape is the bug itself: the signal watcher was the ONLY per-capture timer, and nothing bounded the capture")
    }

    /// Both start paths have to be capped. The fast path (a pre-armed recorder) is the one a normal
    /// dictation takes, so a ceiling wired only into the cold path would leave every real dictation
    /// exactly as unbounded as before.
    func testTheCeilingIsArmedOnBothStartPaths() throws {
        let source = try audioRecorder()
        XCTAssertEqual(Regex.captures(#"\n\s+(armCaptureCeiling\(\))\n"#, in: source).count, 2,
                       "the pre-armed path and the cold path must both arm the ceiling")
        XCTAssertFalse(source.contains("                beginSignalWatch(rec)\n                logCaptureStart(path: \"prearmed\", started: true)"),
                       "the pre-fix fast path went straight from the signal watch to the log line with no ceiling armed")
        XCTAssertFalse(source.contains("            beginSignalWatch(rec)\n            logCaptureStart(path: \"cold\", started: true)"),
                       "the pre-fix cold path did the same")
        // Latency: the ceiling is armed AFTER record() has already returned true, exactly like the
        // signal watch, so neither path waits on a Timer being built.
        XCTAssertEqual(Regex.captures(#"if rec\.record\(\) \{[\s\S]{0,400}?(armCaptureCeiling\(\))"#, in: source).count, 1,
                       "the fast path must call record() first and only then arm the ceiling")
    }

    /// A ceiling that outlives its capture is worse than none: it would end the NEXT dictation early.
    /// It is cancelled by the same `stop()` that ends the sampler, cancelled again when a stale
    /// recorder is torn down, and re-armed from scratch per capture.
    func testTheCeilingIsCancelledInStopAndReArmedPerCapture() throws {
        let source = try audioRecorder()
        let stop = try body(of: #"func stop\(\) -> URL\?"#, in: source, "stop()")
        XCTAssertTrue(stop.contains("endCaptureCeiling()"),
                      "stop() must cancel the ceiling it armed, or it fires during the following capture")
        XCTAssertFalse(stop.contains("armCaptureCeiling()"),
                       "stop() must never arm one: a ceiling belongs to a running capture")
        XCTAssertFalse(source.contains("endSignalWatch()\n        recorder = nil"),
                       "the pre-fix stop() ended the sampler and nothing else, which is where a ceiling would have leaked")
        let arm = try body(of: #"private func armCaptureCeiling\(\)"#, in: source, "armCaptureCeiling()")
        XCTAssertTrue(arm.hasPrefix("\n        endCaptureCeiling()"),
                      "arming must cancel any previous ceiling FIRST, so two captures can never share one")
        XCTAssertFalse(source.contains("        endSignalWatch()\n\n        let chosen = chosenMicToApply()"),
                       "the pre-fix reset in start() cancelled the sampler alone; a torn-down stale recorder must not leave its ceiling running either")
    }

    /// The part that decides whether this fix is a fix or a new bug: hitting the ceiling must not
    /// throw the recording away. The recorder therefore hands the capture to its OWNER, which ends
    /// it through the ordinary stop path, and the recorder never deletes the buffer itself.
    func testTheCeilingProcessesTheAudioInsteadOfDiscardingIt() throws {
        let source = try audioRecorder()
        XCTAssertTrue(source.contains("var onCaptureCeiling: (() -> Void)?"),
                      "the recorder must be able to notify its owner, since only the owner can process a finished dictation")
        let fired = try body(of: #"private func captureCeilingReached\(\)"#, in: source, "captureCeilingReached()")
        XCTAssertTrue(fired.contains("owner()"),
                      "the ceiling must hand the capture to its owner rather than end it behind the owner's back")
        XCTAssertFalse(fired.contains("removeItem"),
                       "the ceiling must never delete the buffer: what it holds is the user's dictation")
        XCTAssertTrue(fired.contains("guard recorder != nil else { return }"),
                      "a ceiling that fires after the capture already ended must do nothing")
        XCTAssertTrue(fired.contains("capture: ceiling reached after"),
                      "the ceiling must be visible in the log, on the same `capture:` family as the rest of the path")
    }

    /// The delegate's half. The capture is ended through the SAME path the user's own second press
    /// takes — `stopAndProcess()` for a dictation, `stopTodoCapture()` for a voice to-do — so the
    /// audio is transcribed and delivered. `cancelRecording()` would have deleted it.
    func testTheDelegateEndsACeilingCaptureThroughTheNormalStopPath() throws {
        let delegate = try appDelegate()
        XCTAssertTrue(delegate.contains("recorder.onCaptureCeiling = { [weak self] in self?.endCaptureAtCeiling() }"),
                      "the ceiling must be wired at launch, or the recorder has no owner to hand the capture to")
        XCTAssertFalse(delegate.contains("overlay.model.onPauseToggle = { [weak self] in self?.togglePause() }\n        overlay.prepare()"),
                       "the pre-fix launch wiring set every other callback and none for a runaway capture")
        let ended = try body(of: #"private func endCaptureAtCeiling\(\)"#, in: delegate, "endCaptureAtCeiling()")
        XCTAssertTrue(ended.contains("stopAndProcess()"),
                      "a dictation must end at the ceiling exactly as a second trigger press ends it")
        XCTAssertTrue(ended.contains("stopTodoCapture()"),
                      "a voice to-do holds the same shared recorder and must end through its own normal stop")
        XCTAssertFalse(ended.contains("cancelRecording()"),
                       "the cancel path DELETES the buffer: ending at the ceiling must never take it")
        XCTAssertFalse(ended.contains("flashError("),
                       "flashError forces state = .idle and hides the overlay, which would tear down the pill of the dictation this just sent")
        XCTAssertTrue(ended.contains("Recording ended automatically after"),
                      "a recording the app ended by itself must say so, or it reads as another random failure")
    }

    // MARK: The refusal

    /// While a capture is stuck, every later `start()` returns false. The caller cannot explain that
    /// unless the recorder says WHICH refusal it was, so the reason is exposed and is not writable
    /// from outside: a caller that could write it could fake the way out it prints.
    func testTheRecorderSaysWhyAStartWasRefused() throws {
        let source = try audioRecorder()
        XCTAssertTrue(source.contains("private(set) var refusalReason: StartRefusal?"),
                      "the refusal reason must be exposed, and only the recorder may set it")
        for c in ["case alreadyLive", "case alreadyPaused", "case failed"] {
            XCTAssertTrue(source.contains(c), "the refusal reason must distinguish \(c)")
        }
        XCTAssertFalse(source.contains("\n    var refusalReason"),
                       "a publicly settable reason lets a caller fake the cause of a refusal")
        XCTAssertEqual(Regex.captures(#"guard !live\.isRecording, !isPaused else \{[\s\S]{0,500}?(refusalReason = isPaused \? \.alreadyPaused : \.alreadyLive)"#, in: source).count, 1,
                       "the live-recorder guard must record which of the two cases it refused on")
        XCTAssertFalse(source.contains("guard !live.isRecording, !isPaused else {\n                VerbaLog.audio.error(\"AudioRecorder.start() refused"),
                       "the pre-fix guard logged and returned false with nothing the caller could read")
        XCTAssertEqual(Regex.captures(#"(refusalReason = \.failed)"#, in: source).count, 2,
                       "both genuine-failure exits (record() refused, and the throwing build) must be marked as failures, not as a live capture")
        XCTAssertEqual(Regex.captures(#"\n        (refusalReason = nil)\n"#, in: source).count, 1,
                       "an accepted start must clear the previous reason, below the live guard like every other per-capture reset")
    }

    /// The message the user actually gets. "Couldn't start recording" is true and useless: the fix
    /// is one keypress away and it named neither the cause nor that keypress, so the report was a
    /// microphone that had simply stopped working.
    func testALiveCaptureRefusalTellsTheUserTheWayOut() throws {
        let delegate = try appDelegate()
        XCTAssertTrue(delegate.contains("A recording is already running. Press your trigger again to send it, or Esc to cancel."),
                      "the refusal must name what is happening AND how to end it")
        XCTAssertFalse(delegate.contains("self.resetOneShotFlags(); self.flashError(\"Couldn't start recording\"); return"),
                       "the pre-fix dictation refusal is the dead end itself: a two-second flash that explains nothing")
        XCTAssertFalse(delegate.contains("guard self.recorder.start() else { self.finishTodoCapture(error: \"Couldn't start recording.\"); return }"),
                       "the voice to-do trigger hits the same refusal and must not keep the unactionable message either")
        XCTAssertEqual(Regex.captures(#"case \.some\(\.alreadyLive\), \.some\(\.alreadyPaused\):\s*\n\s*(self\.flashError\(Self\.liveCaptureRefusalMessage, seconds: 4\))"#, in: delegate).count, 1,
                       "the actionable message must be reached from the already-live/paused reason, and stay long enough to read")
        XCTAssertEqual(Regex.captures(#"(static let liveCaptureRefusalMessage)"#, in: delegate).count, 1,
                       "the message must be stated once and shared by every trigger that can hit the refusal")
        // It stays a flash. A modal for a problem one keypress solves would be worse than the bug.
        XCTAssertFalse(delegate.contains("liveCaptureRefusalMessage)\n        alert.runModal"),
                       "the refusal must not become a modal: the fix is a keypress, not a dialog")
    }

    /// Polarity, and the reason the reason exists: a GENUINE failure (record() refused, the recorder
    /// could not be built) is not a live capture, and telling that user to press their trigger again
    /// would send them in a circle. It keeps the old message.
    func testAGenuineFailureKeepsTheOldMessage() throws {
        let delegate = try appDelegate()
        XCTAssertEqual(Regex.captures(#"default:\s*\n\s*(self\.flashError\("Couldn't start recording"\))"#, in: delegate).count, 1,
                       "a genuine audio-stack failure must keep the plain message, not the press-your-trigger one")
        XCTAssertEqual(Regex.captures(#"default:\s*\n\s*(self\.finishTodoCapture\(error: "Couldn't start recording\."\))"#, in: delegate).count, 1,
                       "same for the voice to-do trigger")
    }

    /// House style, and it is load-bearing here because both strings above are new user-facing copy:
    /// no em dash and no en dash in anything the user reads.
    func testTheNewUserFacingStringsCarryNoDashes() throws {
        let delegate = try appDelegate()
        for line in delegate.split(separator: "\n") where line.contains("A recording is already running")
            || line.contains("Recording ended automatically after") {
            XCTAssertFalse(line.contains("\u{2014}"), "em dash in a user-facing string: \(line)")
            XCTAssertFalse(line.contains("\u{2013}"), "en dash in a user-facing string: \(line)")
        }
    }
}
