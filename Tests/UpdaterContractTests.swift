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
}
