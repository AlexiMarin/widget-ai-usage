import AppIntents
import WidgetKit

/// Which AI provider a widget instance shows. One widget per provider keeps
/// rings from different services from mixing in the same row.
enum AIProvider: String, AppEnum {
    case claude
    case openai

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Proveedor"
    static let caseDisplayRepresentations: [AIProvider: DisplayRepresentation] = [
        .claude: "Claude",
        .openai: "OpenAI",
    ]

    func meters(in snapshot: UsageSnapshot) -> [UsageMeter] {
        switch self {
        case .claude: snapshot.claude
        case .openai: snapshot.openai
        }
    }
}

struct SelectProviderIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Proveedor"
    static let description = IntentDescription("Elige de qué servicio mostrar el uso.")

    @Parameter(title: "Proveedor", default: .claude)
    var provider: AIProvider
}
