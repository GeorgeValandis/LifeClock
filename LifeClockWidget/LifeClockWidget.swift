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
        case .systemMedium: 10
        default: 14
        }
    }

    private var columns: Int {
        switch family {
        case .systemSmall: 12
        case .systemMedium: 22
        default: 28
        }
    }

    private var cellCount: Int { rows * columns }

    private var elapsedUnits: Int {
        min(max(0, Int(entry.elapsedUnits.rounded(.down))), max(0, totalWholeUnits))
    }

    private var totalWholeUnits: Int {
        max(1, Int(entry.totalUnits.rounded(.down)))
    }

    private var windowStart: Int {
        if totalWholeUnits <= cellCount {
            return 0
        }
        let movingIndex = max(0, elapsedUnits % cellCount)
        let alignedWindowStart = elapsedUnits - movingIndex
        let maxStart = max(0, totalWholeUnits - cellCount)
        return min(max(0, alignedWindowStart), maxStart)
    }

    private var currentIndexInWindow: Int {
        if totalWholeUnits <= cellCount {
            return min(max(0, elapsedUnits), cellCount - 1)
        }
        return min(max(0, elapsedUnits % cellCount), cellCount - 1)
    }

    private var titleText: String {
        "LIFE GRID"
    }

    private var valueLineText: String {
        "\(entry.remainingUnits.formatted(.number.grouping(.never))) \(entry.configuration.unit.rawValue.capitalized) left"
    }

    private var cellScaleText: String {
        let unit = singularUnitName(for: entry.configuration.unit)
        return "Each cell = 1 \(unit) • rolling window"
    }

    private var shouldShowLegend: Bool {
        family == .systemLarge
    }

    private var valueFontSize: CGFloat {
        switch family {
        case .systemSmall: 16
        case .systemMedium: 24
        default: 30
        }
    }

    private var horizontalPadding: CGFloat {
        switch family {
        case .systemSmall: 12
        case .systemMedium: 14
        default: 18
        }
    }

    private var verticalPadding: CGFloat {
        switch family {
        case .systemSmall: 10
        case .systemMedium: 12
        default: 18
        }
    }

    private func singularUnitName(for unit: WidgetLifeUnit) -> String {
        switch unit {
        case .years: "year"
        case .months: "month"
        case .weeks: "week"
        case .days: "day"
        case .hours: "hour"
        case .minutes: "minute"
        case .seconds: "second"
        }
    }

    private func futureIntensity(index: Int) -> Double {
        let futureRange = max(1, cellCount - currentIndexInWindow)
        let distance = Double(max(0, index - currentIndexInWindow)) / Double(futureRange)
        return max(0, 1 - distance)
    }

    private func cellColor(isPast: Bool, isCurrent: Bool, futureIntensity: Double) -> Color {
        if isCurrent {
            return .white.opacity(0.95)
        }
        if isPast {
            return Color(red: 0.15, green: 0.88, blue: 0.86).opacity(0.9)
        }
        return Color(red: 1.0, green: 0.60, blue: 0.24).opacity(0.18 + (0.56 * futureIntensity))
    }

    var body: some View {
        let columnsDef = Array(repeating: GridItem(.flexible(minimum: 1, maximum: 10), spacing: 2), count: columns)

        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.20, blue: 0.27), Color(red: 0.22, green: 0.19, blue: 0.09)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: family == .systemSmall ? 18 : 24, style: .continuous)
                .fill(Color.white.opacity(0.24))
                .overlay {
                    RoundedRectangle(cornerRadius: family == .systemSmall ? 18 : 24, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
                .padding(family == .systemSmall ? 8 : 10)

            VStack(alignment: .leading, spacing: family == .systemSmall ? 5 : 8) {
                Text(titleText)
                    .font(.system(size: family == .systemSmall ? 10 : 12, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.78))

                Text(valueLineText)
                    .font(.system(size: valueFontSize, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.45)
                    .lineLimit(1)
                    .monospacedDigit()

                Text(cellScaleText)
                    .font(.system(size: family == .systemSmall ? 10 : 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                LazyVGrid(columns: columnsDef, spacing: 2) {
                    ForEach(0..<cellCount, id: \.self) { displayIndex in
                        let row = displayIndex / columns
                        let column = displayIndex % columns
                        let progressIndex = (column * rows) + row
                        let absoluteUnitIndex = windowStart + progressIndex
                        let isPast = absoluteUnitIndex < elapsedUnits
                        let isCurrent = progressIndex == currentIndexInWindow

                        Circle()
                            .fill(cellColor(isPast: isPast, isCurrent: isCurrent, futureIntensity: futureIntensity(index: progressIndex)))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                if isCurrent {
                                    Circle()
                                        .stroke(Color(red: 1.0, green: 0.52, blue: 0.20), lineWidth: 1.1)
                                }
                            }
                    }
                }

                if shouldShowLegend {
                    HStack(spacing: 12) {
                        Label("Past", systemImage: "square.fill")
                            .foregroundStyle(.white.opacity(0.65))
                        Label("Current", systemImage: "location.fill")
                            .foregroundStyle(.white.opacity(0.9))
                        Label("Future", systemImage: "sparkles")
                            .foregroundStyle(Color(red: 1.0, green: 0.60, blue: 0.24))
                    }
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
