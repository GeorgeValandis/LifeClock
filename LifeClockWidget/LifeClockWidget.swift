import AppIntents
import SwiftUI
import WidgetKit

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
        .seconds: "Seconds",
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
    let resolvedUnit: WidgetLifeUnit
}

struct LifeGridProvider: AppIntentTimelineProvider {
    private static let sharedDefaults = UserDefaults(suiteName: "group.com.GA.LifeClock")

    func placeholder(in context: Context) -> LifeGridEntry {
        LifeGridEntry(
            date: .now,
            configuration: LifeGridConfigurationIntent(),
            remainingUnits: 38,
            elapsedUnits: 37,
            totalUnits: 90,
            resolvedUnit: resolvedUnit(from: LifeGridConfigurationIntent())
        )
    }

    func snapshot(for configuration: LifeGridConfigurationIntent, in context: Context) async
        -> LifeGridEntry
    {
        makeEntry(configuration: configuration, now: .now)
    }

    func timeline(for configuration: LifeGridConfigurationIntent, in context: Context) async
        -> Timeline<LifeGridEntry>
    {
        let now = Date()
        let entry = makeEntry(configuration: configuration, now: now)

        let unit = resolvedUnit(from: configuration)
        let refreshMinutes: Int
        switch unit {
        case .seconds: refreshMinutes = 1
        case .minutes: refreshMinutes = 1
        case .hours: refreshMinutes = 5
        case .days, .weeks, .months, .years: refreshMinutes = 30
        }

        let next =
            Calendar.current.date(byAdding: .minute, value: refreshMinutes, to: now)
            ?? now.addingTimeInterval(Double(refreshMinutes) * 60)
        return Timeline(entries: [entry], policy: .after(next))
    }

    private func resolvedUnit(from configuration: LifeGridConfigurationIntent) -> WidgetLifeUnit {
        if let raw = Self.sharedDefaults?.string(forKey: "selectedUnitRaw"),
            let unit = WidgetLifeUnit(rawValue: raw)
        {
            return unit
        }
        return configuration.unit
    }

    private func makeEntry(configuration: LifeGridConfigurationIntent, now: Date) -> LifeGridEntry {
        let shared = Self.sharedDefaults

        let birthDate: Date
        if let ts = shared?.object(forKey: "birthDateTimestamp") as? Double {
            birthDate = min(Date(timeIntervalSince1970: ts), now)
        } else {
            birthDate = min(configuration.birthDate, now)
        }

        let lifeExpYears: Double
        if let le = shared?.object(forKey: "lifeExpectancyYears") as? Double, le > 0 {
            lifeExpYears = le
        } else {
            lifeExpYears = configuration.lifeExpectancyYears
        }

        let lifeSeconds = max(1, lifeExpYears * WidgetLifeUnit.years.seconds)
        let elapsed = max(0, now.timeIntervalSince(birthDate))
        let elapsedClamped = min(elapsed, lifeSeconds)

        let unit = resolvedUnit(from: configuration)
        let totalUnits = max(1, lifeSeconds / unit.seconds)
        let elapsedUnits = min(totalUnits, elapsedClamped / unit.seconds)
        let remainingUnits = max(0, Int((totalUnits - elapsedUnits).rounded()))

        return LifeGridEntry(
            date: now,
            configuration: configuration,
            remainingUnits: remainingUnits,
            elapsedUnits: elapsedUnits,
            totalUnits: totalUnits,
            resolvedUnit: unit
        )
    }
}

struct LifeGridWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LifeGridEntry

    private struct HomeLayout {
        let rows: Int
        let columns: Int
        let valueFontSize: CGFloat
        let horizontalPadding: CGFloat
        let verticalPadding: CGFloat
        let cardInset: CGFloat
        let cornerRadius: CGFloat
        let spacing: CGFloat
        let showScale: Bool
        let showLegend: Bool
    }

    private var homeLayout: HomeLayout {
        switch family {
        case .systemSmall:
            return HomeLayout(
                rows: 6,
                columns: 12,
                valueFontSize: 20,
                horizontalPadding: 9,
                verticalPadding: 8,
                cardInset: 4,
                cornerRadius: 15,
                spacing: 4,
                showScale: false,
                showLegend: false
            )
        case .systemMedium:
            return HomeLayout(
                rows: 8,
                columns: 23,
                valueFontSize: 34,
                horizontalPadding: 11,
                verticalPadding: 10,
                cardInset: 4,
                cornerRadius: 20,
                spacing: 5,
                showScale: false,
                showLegend: false
            )
        default:
            return HomeLayout(
                rows: 14,
                columns: 28,
                valueFontSize: 30,
                horizontalPadding: 18,
                verticalPadding: 18,
                cardInset: 10,
                cornerRadius: 24,
                spacing: 8,
                showScale: true,
                showLegend: true
            )
        }
    }

    private var rows: Int {
        homeLayout.rows
    }

    private var columns: Int {
        homeLayout.columns
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
        "\(entry.remainingUnits.formatted(.number.grouping(.never))) \(entry.resolvedUnit.rawValue.capitalized) left"
    }

    private var cellScaleText: String {
        let unit = singularUnitName(for: entry.resolvedUnit)
        return "Each cell = 1 \(unit) • rolling window"
    }

    private var shouldShowLegend: Bool {
        homeLayout.showLegend
    }

    private var valueFontSize: CGFloat {
        homeLayout.valueFontSize
    }

    private var horizontalPadding: CGFloat {
        homeLayout.horizontalPadding
    }

    private var verticalPadding: CGFloat {
        homeLayout.verticalPadding
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
        switch family {
        case .accessoryInline:
            inlineAccessoryView
        case .accessoryCircular:
            circularAccessoryView
        case .accessoryRectangular:
            rectangularAccessoryView
        default:
            homeWidgetView
        }
    }

    private var homeWidgetView: some View {
        let columnsDef = Array(
            repeating: GridItem(.flexible(minimum: 1, maximum: 10), spacing: 2), count: columns)

        return ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.08, blue: 0.16),
                    Color(red: 0.04, green: 0.14, blue: 0.22),
                    Color(red: 0.12, green: 0.08, blue: 0.04),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: homeLayout.cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: homeLayout.cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.15, green: 0.88, blue: 0.86).opacity(0.2),
                                    .white.opacity(0.06),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .padding(homeLayout.cardInset)

            VStack(alignment: .leading, spacing: homeLayout.spacing) {
                Text(titleText)
                    .font(
                        .system(
                            size: family == .systemSmall ? 9 : 12, weight: .bold, design: .rounded)
                    )
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.7))

                valueLine

                if homeLayout.showScale {
                    Text(cellScaleText)
                        .font(
                            .system(
                                size: family == .systemSmall ? 10 : 12, weight: .medium,
                                design: .rounded)
                        )
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                LazyVGrid(columns: columnsDef, spacing: 2) {
                    ForEach(0..<cellCount, id: \.self) { displayIndex in
                        let row = displayIndex / columns
                        let column = displayIndex % columns
                        let progressIndex = (column * rows) + row
                        let absoluteUnitIndex = windowStart + progressIndex
                        let isPast = absoluteUnitIndex < elapsedUnits
                        let isCurrent = progressIndex == currentIndexInWindow

                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .fill(
                                cellColor(
                                    isPast: isPast, isCurrent: isCurrent,
                                    futureIntensity: futureIntensity(index: progressIndex))
                            )
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                if isCurrent {
                                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                                        .stroke(.white.opacity(0.9), lineWidth: 1)
                                }
                            }
                    }
                }

                if shouldShowLegend {
                    HStack(spacing: 14) {
                        Label("Past", systemImage: "square.fill")
                            .foregroundStyle(Color(red: 0.15, green: 0.88, blue: 0.86).opacity(0.8))
                        Label("Now", systemImage: "location.fill")
                            .foregroundStyle(.white.opacity(0.9))
                        Label("Future", systemImage: "sparkles")
                            .foregroundStyle(Color(red: 1.0, green: 0.60, blue: 0.24).opacity(0.85))
                    }
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.06, blue: 0.12),
                    Color(red: 0.06, green: 0.10, blue: 0.18),
                    Color(red: 0.10, green: 0.06, blue: 0.04),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var valueLine: some View {
        ViewThatFits(in: .horizontal) {
            Text(valueLineText)
                .font(.system(size: valueFontSize, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(
                    color: Color(red: 0.15, green: 0.88, blue: 0.86).opacity(0.2), radius: 8, x: 0,
                    y: 2
                )
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .monospacedDigit()

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.remainingUnits.formatted(.number.grouping(.never)))
                    .font(.system(size: valueFontSize, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(
                        color: Color(red: 0.15, green: 0.88, blue: 0.86).opacity(0.2), radius: 8,
                        x: 0, y: 2
                    )
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .monospacedDigit()
                Text("\(entry.resolvedUnit.rawValue.capitalized) left")
                    .font(
                        .system(
                            size: max(10, valueFontSize * 0.5), weight: .semibold, design: .rounded)
                    )
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var inlineAccessoryView: some View {
        Text(
            "\(entry.remainingUnits.formatted(.number.grouping(.never))) \(entry.resolvedUnit.shortLabel) left"
        )
    }

    private var circularAccessoryView: some View {
        let ratio = min(max(entry.elapsedUnits / max(entry.totalUnits, 1), 0), 1)
        return ZStack {
            Circle()
                .stroke(.white.opacity(0.15), lineWidth: 3)
                .padding(6)
            Circle()
                .trim(from: 0, to: ratio)
                .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(6)
            VStack(spacing: 0) {
                Text("\(entry.remainingUnits)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.5)
                Text(entry.resolvedUnit.shortLabel)
                    .font(.system(size: 7, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var rectangularAccessoryView: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "hourglass")
                    .font(.system(size: 9, weight: .bold))
                Text("LIFE CLOCK")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.8)
            }
            .foregroundStyle(.secondary)
            Text(
                "\(entry.remainingUnits.formatted(.number.grouping(.never))) \(entry.resolvedUnit.rawValue.capitalized) left"
            )
            .font(.system(size: 14, weight: .black, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
    }
}

struct LifeGridWidget: Widget {
    let kind: String = "LifeGridWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind, intent: LifeGridConfigurationIntent.self, provider: LifeGridProvider()
        ) { entry in
            LifeGridWidgetView(entry: entry)
        }
        .configurationDisplayName("Life Grid")
        .description("Track your remaining lifetime as a grid.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular,
        ])
        .contentMarginsDisabled()
    }
}

@main
struct LifeClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        LifeGridWidget()
    }
}
