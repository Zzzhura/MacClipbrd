import Foundation

enum Language: String, CaseIterable, Identifiable {
    case en
    case ru

    var id: String { rawValue }

    var label: String {
        switch self {
        case .en: return "EN"
        case .ru: return "RU"
        }
    }
}

final class Localization: ObservableObject {
    static let shared = Localization()

    private static let languageKey = "language"

    @Published var language: Language {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.languageKey) }
    }

    private init() {
        // English is the default: ignore the system locale and only honour a
        // choice the user made explicitly.
        language = UserDefaults.standard.string(forKey: Self.languageKey)
            .flatMap(Language.init(rawValue:)) ?? .en
    }

    private func t(_ en: String, _ ru: String) -> String {
        language == .en ? en : ru
    }

    var searchPlaceholder: String { t("Search…", "Поиск…") }
    var emptyHistory: String { t("History is empty", "История пуста") }
    var nothingFound: String { t("Nothing found", "Ничего не найдено") }
    var clear: String { t("Clear", "Очистить") }
    var image: String { t("Image", "Изображение") }

    func itemCount(_ count: Int) -> String {
        t(count == 1 ? "1 item" : "\(count) items", "\(count) элем.")
    }

    var accessibilityAlertTitle: String {
        t("Auto-paste is off", "Автовставка выключена")
    }

    var accessibilityAlertBody: String {
        t("To let MacClipbrd paste the selected entry for you, allow it in "
            + "System Settings → Privacy & Security → Accessibility.\n\n"
            + "If MacClipbrd is already in the list and the switch is on, turn it off and on "
            + "again: after an update macOS treats the app as new.",
          "Чтобы MacClipbrd вставлял выбранную запись сам, разрешите его в "
            + "Системных настройках → Конфиденциальность и безопасность → Универсальный доступ.\n\n"
            + "Если MacClipbrd уже есть в списке и переключатель включён — выключите и включите его "
            + "снова: после обновления macOS считает приложение новым.")
    }

    var pasteFallbackHint: String {
        t("The entry is on the clipboard — press ⌘V to paste it.\n\n",
          "Запись скопирована в буфер — нажмите ⌘V, чтобы вставить.\n\n")
    }

    var openSettings: String { t("Open Settings", "Открыть настройки") }
    var later: String { t("Later", "Позже") }
}
