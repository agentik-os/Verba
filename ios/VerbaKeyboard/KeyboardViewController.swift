import UIKit

/// Verba keyboard: a row of modes + a mic button. Mic opens the Verba app to record
/// (keyboards can't use the microphone); on return, the app's result is inserted here.
final class KeyboardViewController: UIInputViewController {
    private var selectedMode = "Polish"

    override func viewDidLoad() {
        super.viewDidLoad()
        let modes = UIStackView()
        modes.axis = .horizontal; modes.distribution = .fillEqually; modes.spacing = 6
        modes.translatesAutoresizingMaskIntoConstraints = false
        for m in Verba.modes {
            let b = UIButton(type: .system)
            b.setTitle(m, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 13, weight: m == selectedMode ? .semibold : .regular)
            b.addAction(UIAction { [weak self] _ in self?.selectedMode = m }, for: .touchUpInside)
            modes.addArrangedSubview(b)
        }

        let mic = UIButton(type: .system)
        mic.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        mic.backgroundColor = .label; mic.tintColor = .systemBackground
        mic.layer.cornerRadius = 28
        mic.translatesAutoresizingMaskIntoConstraints = false
        mic.addAction(UIAction { [weak self] _ in self?.openAppToRecord() }, for: .touchUpInside)

        let nextKB = UIButton(type: .system)
        nextKB.setImage(UIImage(systemName: "globe"), for: .normal)
        nextKB.translatesAutoresizingMaskIntoConstraints = false
        nextKB.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)

        [modes, mic, nextKB].forEach { view.addSubview($0) }
        NSLayoutConstraint.activate([
            modes.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            modes.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            modes.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            mic.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mic.topAnchor.constraint(equalTo: modes.bottomAnchor, constant: 14),
            mic.widthAnchor.constraint(equalToConstant: 56), mic.heightAnchor.constraint(equalToConstant: 56),
            nextKB.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nextKB.centerYAnchor.constraint(equalTo: mic.centerYAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Insert any text the app produced while we were away.
        if let result = Verba.takePendingResult() { textDocumentProxy.insertText(result) }
    }

    private func openAppToRecord() {
        guard let url = URL(string: "verba://record?mode=\(selectedMode)") else { return }
        // Open the container app from the extension.
        var r: UIResponder? = self
        while let resp = r {
            if let app = resp as? UIApplication { app.open(url); break }
            r = resp.next
        }
    }
}
