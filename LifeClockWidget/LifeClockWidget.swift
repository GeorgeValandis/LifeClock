import WidgetKit
import SwiftUI
import AppIntents

enum WidgetLifeUnit: String, CaseIterable, AppEnum {
    case years
    case months
    case weeks
    case days
    case hours
    case minutes
    case seconds

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Unit"

    static var caseDisplayRepresentations: [WidgetLifeUnit: DisplayRepresentation] = [
        .years: "Years",
        .months: "Months",
        .weeks: "Weeks",
        .days: "Days",
        .hours: "Hours",
        .minutes: "Minutes",
        .seconds: "Seconds"
    ]

    var seconds: Double {
        switch self {
        case .years: 31_556_952
        case .months: 2_629_746
        case .weeks: 604_800
        case .days: 86_400
        case .hours: 3_600
        case .minutes: 60
        case .seconds: 1
        }
    }

    var shortLabel: String {
        switch self {
        case .years: "Y"
        case .months: "M"
        case .weeks: "W"
        case .days: "D"
        case .hours: "H"
        case .minutes: "Min"
        case .seconds: "Sec"
        }
    }
}

struct LifeGridConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Life Grid"
    static var description = IntentDescription("Show remaining life as a grid in your chosen unit.")

    @Parameter(title: "Unit", default: .years)
    var unit: WidgetLifeUnit

    @Parameter(title: "Birth Date", default: Date(timeIntervalSince1970: 592_444_800))
    var birthDate: Date

    @Parameter(title: "Life Expectancy (Years)", default: 90)
    var lifeExpectancyYears: Double
}

struct LifeGridEntry: TimelineEntry {
    let date: Date
    let configuration: LifeGridConfigurationIntent
    let remainingUnits: Int
    let elapsedUnits: Double
    let totalUnits: Double
}

struct LifeGridProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LifeGridEntry {
        LifeGridEntry(
            date: .now,
            configuration: LifeGridConfigurationIntent(),
            remainingUnits: 38,
            elapsedUnits: 37,
            totalUnits: 90
        )
    }

    func snapshot(for configuration: LifeGridConfigurationIntent, in context: Context) async -> LifeGridEntry {
        makeEntry(configuration: configuration, now: .now)
    }

    func timeline(for configuration: LifeGridConfigurationIntent, in context: Context) async -> Timeline<LifeGridEntry> {
        let now = Date()
        let entry = makeEntry(configuration: configuration, now: now)

        let refreshMinutes: Int
        switch configuration.unit {
        case .seconds: refreshMinutes = 1
        case .minutes: refreshMinutes = 1
        case .hours: refreshMinutes = 5
        case .days, .weeks, .months, .years: refreshMinutes = 30
        }

        let next = Calendar.current.date(byAdding: .minute, value: refreshMinutes, to: now) ?? now.addingTimeInterval(Double(refreshMinutes) * 60)
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func makeEntry(configuration: LifeGridConfigurationIntent, now: Date) -> LifeGridEntry {
        let birthDate = min(configuration.birthDate, now)
        let lifeSeconds = max(1, configuration.lifeExpectancyYears * WidgetLifeUnit.years.seconds)
        let elapsed = max(0, now.timeIntervalSince(birthDate))
        let elapsedClamped = min(elapsed, lifeSeconds)

        let unit = configuration.unit
        let totalUnits = max(1, lifeSeconds / unit.seconds)
        let elapsedUnits = min(totalUnits, elapsedClamped / unit.seconds)
        let remainingUnits = max(0, Int((totalUnits - elapsedUnits).rounded()))

        return LifeGridEntry(
            date: now,
            configuration: configuration,
            remainingUnits: remainingUnits,
            elapsedUnits: elapsedUnits,
            totalUnits: totalUnits
        )
    }
}

struct LifeGridWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LifeGridEntry

    private var rows: Int {
        switch family {
        case .systemSmall: 7
        case .systemMedium: 9
        default: 12
        }
    }

    private var columns: Int {
        switch family {
        case .systemSmall: 12
        case .systemMedium: 22
        default: 30
        }
    }

    private var cellCount: Int { rows * columns }

    private var elapsedCells: Int {
        let ratio = entry.elapsedUnits / max(entry.totalUnits, 1)
        return min(cellCount, Int((ratio * Double(cellCount)).rounded(.down)))
    }

    private var titleText: String {
        "LIFE GRID"
    }

    private var valueLineText: String {
        "\(entry.remainingUnits) \(entry.configuration.unit.rawValue.capitalized) left"
    }

    private var cellScaleText: String {
        let unitsPerCell = max(1, Int((entry.totalUnits / Double(cellCount)).rounded()))
        let unit = entry.configuration.unit.rawValue.capitalized
        return "Each cell ≈ \(unitsPerCell) \(unit.lowercased())"
    }

    var body: some View {
        let columnsDef = Array(repeating: GridItem(.flexible(minimum: 1, maximum: 10), spacing: 2), count: columns)

        VStack(alignment: .leading, spacing: 8) {
            Text(titleText)
                .font(.system(size: family == .systemSmall ? 11 : 12, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.78))

            Text(valueLineText)
                .font(.system(size: family == .systemSmall ? 24 : 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.55)
                .lineLimit(1)

            Text(cellScaleText)
                .font(.system(size: family == .systemSmall ? 11 : 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            LazyVGrid(columns: columnsDef, spacing: 2) {
                ForEach(0..<cellCount, id: \.self) { displayIndex in
                    let row = displayIndex / columns
                    let column = displayIndex % columns
                    let progressIndex = (column * rows) + row
                    let isPast = progressIndex < elapsedCells
                    let isCurrent = progressIndex == elapsedCells && elapsedCells < cellCount

                    RoundedRectangle(cornerRadius: 1.8, style: .continuous)
                        .fill(isPast ? Color.orange.opacity(0.9) : Color.orange.opacity(0.24))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            if isCurrent {
                                RoundedRectangle(cornerRadius: 1.8, style: .continuous)
                                    .stroke(Color.white.opacity(0.95), lineWidth: 0.8)
                            }
                        }
                }
            }

            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(red: 0.17, green: 0.07, blue: 0.03), Color(red: 0.56, green: 0.27, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct LifeGridWidget: Widget {
    let kind: String = "LifeGridWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: LifeGridConfigurationIntent.self, provider: LifeGridProvider()) { entry in
            LifeGridWidgetView(entry: entry)
        }
        .configurationDisplayName("Life Grid")
        .description("Track your remaining lifetime as a grid.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct LifeClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        LifeGridWidget()
    }
}
