import SwiftUI
import UIKit

private enum LifeUnit: String, CaseIterable, Identifiable {
    case years
    case months
    case weeks
    case days
    case hours
    case minutes
    case seconds

    var id: String { rawValue }

    var title: String {
        switch self {
        case .years: "Years"
        case .months: "Months"
        case .weeks: "Weeks"
        case .days: "Days"
        case .hours: "Hours"
        case .minutes: "Minutes"
        case .seconds: "Seconds"
        }
    }

    var shortTitle: String {
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

    func convert(from elapsed: TimeInterval) -> Double {
        elapsed / seconds
    }
}

private enum ClockTheme: String, CaseIterable, Identifiable {
    case aurora
    case solar
    case deepSea

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aurora: "Aurora"
        case .solar: "Solar Glow"
        case .deepSea: "Deep Sea"
        }
    }

    var background: [Color] {
        switch self {
        case .aurora:
            [
                Color(red: 0.03, green: 0.09, blue: 0.17),
                Color(red: 0.02, green: 0.25, blue: 0.24),
                Color(red: 0.20, green: 0.12, blue: 0.05)
            ]
        case .solar:
            [
                Color(red: 0.17, green: 0.07, blue: 0.03),
                Color(red: 0.33, green: 0.14, blue: 0.06),
                Color(red: 0.56, green: 0.27, blue: 0.08)
            ]
        case .deepSea:
            [
                Color(red: 0.01, green: 0.05, blue: 0.14),
                Color(red: 0.04, green: 0.15, blue: 0.30),
                Color(red: 0.01, green: 0.31, blue: 0.39)
            ]
        }
    }

    var topGlow: Color {
        switch self {
        case .aurora: Color(red: 1.0, green: 0.52, blue: 0.14)
        case .solar: Color(red: 1.0, green: 0.75, blue: 0.25)
        case .deepSea: Color(red: 0.08, green: 0.81, blue: 0.99)
        }
    }

    var bottomGlow: Color {
        switch self {
        case .aurora: Color(red: 0.16, green: 0.85, blue: 0.79)
        case .solar: Color(red: 0.96, green: 0.44, blue: 0.24)
        case .deepSea: Color(red: 0.19, green: 0.96, blue: 0.79)
        }
    }

    var ringColors: [Color] {
        switch self {
        case .aurora:
            [
                Color(red: 0.95, green: 0.94, blue: 0.64),
                Color(red: 1.0, green: 0.54, blue: 0.18),
                Color(red: 0.11, green: 0.87, blue: 0.84)
            ]
        case .solar:
            [
                Color(red: 1.0, green: 0.90, blue: 0.39),
                Color(red: 1.0, green: 0.63, blue: 0.21),
                Color(red: 1.0, green: 0.35, blue: 0.17)
            ]
        case .deepSea:
            [
                Color(red: 0.69, green: 0.95, blue: 1.0),
                Color(red: 0.26, green: 0.70, blue: 1.0),
                Color(red: 0.15, green: 0.95, blue: 0.81)
            ]
        }
    }

    var selectedChipForeground: Color {
        switch self {
        case .aurora: .black
        case .solar: .black
        case .deepSea: Color(red: 0.04, green: 0.10, blue: 0.20)
        }
    }

    var selectedChipBackground: Color {
        switch self {
        case .aurora: Color(red: 0.95, green: 0.98, blue: 0.95)
        case .solar: Color(red: 1.0, green: 0.94, blue: 0.80)
        case .deepSea: Color(red: 0.78, green: 0.95, blue: 1.0)
        }
    }
}

private enum TypographyPreset: String, CaseIterable, Identifiable {
    case modern
    case editorial
    case terminal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .modern: "Modern Rounded"
        case .editorial: "Editorial Serif"
        case .terminal: "Terminal Mono"
        }
    }

    var heroDesign: Font.Design {
        switch self {
        case .modern: .rounded
        case .editorial: .serif
        case .terminal: .monospaced
        }
    }

    var bodyDesign: Font.Design {
        switch self {
        case .modern: .rounded
        case .editorial: .default
        case .terminal: .monospaced
        }
    }
}

private enum AppIconChoice: String, CaseIterable, Identifiable {
    case primary
    case pulse
    case horizon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .primary: "Default"
        case .pulse: "Pulse"
        case .horizon: "Horizon"
        }
    }

    var iconName: String? {
        switch self {
        case .primary: nil
        case .pulse: "AppIconPulse"
        case .horizon: "AppIconHorizon"
        }
    }
}

struct ContentView: View {
    @AppStorage("birthDateTimestamp") private var birthDateTimestamp: Double = Date(timeIntervalSinceNow: -26 * 31_556_952).timeIntervalSince1970
    @AppStorage("selectedUnitRaw") private var selectedUnitRaw: String = LifeUnit.days.rawValue
    @AppStorage("lifeExpectancyYears") private var lifeExpectancyYears: Double = 90
    @AppStorage("clockThemeRaw") private var clockThemeRaw: String = ClockTheme.aurora.rawValue
    @AppStorage("typographyPresetRaw") private var typographyPresetRaw: String = TypographyPreset.modern.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("appIconChoiceRaw") private var appIconChoiceRaw: String = AppIconChoice.primary.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var showSettings = false
    @State private var showOnboarding = false
    @State private var animateBackground = false
    @State private var iconErrorMessage: String?
    @State private var unitSwapPulse = false
    @State private var showLifeGrid = false
    @Namespace private var unitChipSelectionAnimation

    private var selectedUnit: LifeUnit {
        LifeUnit(rawValue: selectedUnitRaw) ?? .days
    }

    private var selectedTheme: ClockTheme {
        ClockTheme(rawValue: clockThemeRaw) ?? .aurora
    }

    private var selectedTypography: TypographyPreset {
        TypographyPreset(rawValue: typographyPresetRaw) ?? .modern
    }

    private var birthDate: Date {
        Date(timeIntervalSince1970: birthDateTimestamp)
    }

    private var unitSwapTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(x: 12)),
            removal: .opacity.combined(with: .offset(x: -12))
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    mainContent(now: context.date)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                    animateBackground.toggle()
                }
                showOnboarding = !hasCompletedOnboarding
            }
            .sheet(isPresented: $showSettings) {
                settingsSheet
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(
                    birthDateTimestamp: $birthDateTimestamp,
                    selectedUnitRaw: $selectedUnitRaw,
                    lifeExpectancyYears: $lifeExpectancyYears,
                    completeAction: {
                        hasCompletedOnboarding = true
                        showOnboarding = false
                    }
                )
            }
            .alert("Icon Update Failed", isPresented: Binding(
                get: { iconErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        iconErrorMessage = nil
                    }
                }
            )) {
                Button("OK", role: .cancel) { iconErrorMessage = nil }
            } message: {
                Text(iconErrorMessage ?? "Unknown error")
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: selectedTheme.background,
            startPoint: animateBackground ? .topLeading : .bottomLeading,
            endPoint: animateBackground ? .bottomTrailing : .topTrailing
        )
        .overlay {
            ZStack {
                Circle()
                    .fill(selectedTheme.topGlow.opacity(0.32))
                    .frame(width: 290)
                    .blur(radius: 40)
                    .offset(x: animateBackground ? 120 : 8, y: animateBackground ? -260 : -140)

                Circle()
                    .fill(selectedTheme.bottomGlow.opacity(0.26))
                    .frame(width: 350)
                    .blur(radius: 50)
                    .offset(x: animateBackground ? -130 : -10, y: animateBackground ? 300 : 160)
            }
        }
        .ignoresSafeArea()
    }

    private func mainContent(now: Date) -> some View {
        let elapsed = max(0, now.timeIntervalSince(birthDate))
        let unitValue = selectedUnit.convert(from: elapsed)
        let progress = lifeProgress(elapsed: elapsed)
        let remaining = remainingLifeSeconds(elapsed: elapsed)

        return ScrollView {
            VStack(spacing: 22) {
                header
                if showLifeGrid {
                    lifeGridCard(elapsed: elapsed, remaining: remaining)
                    unitPicker
                } else {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 7) {
                                Text("LIFE CLOCK")
                                    .font(.system(size: 12, weight: .bold, design: selectedTypography.bodyDesign))
                                    .tracking(1.8)
                                    .foregroundStyle(.white.opacity(0.74))

                                ZStack(alignment: .leading) {
                                    Text(formattedValue(unitValue, unit: selectedUnit))
                                        .font(.system(size: 58, weight: .black, design: selectedTypography.heroDesign))
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                        .monospacedDigit()
                                        .foregroundStyle(.white)
                                        .contentTransition(.numericText())
                                        .id("life-clock-value-\(selectedUnitRaw)")
                                        .transition(unitSwapTransition)
                                }
                                .animation(.spring(response: 0.42, dampingFraction: 0.84), value: selectedUnitRaw)

                                ZStack(alignment: .leading) {
                                    Text(selectedUnit.title)
                                        .font(.system(size: 18, weight: .semibold, design: selectedTypography.bodyDesign))
                                        .foregroundStyle(.white.opacity(0.88))
                                        .id("life-clock-unit-\(selectedUnitRaw)")
                                        .transition(unitSwapTransition)
                                }
                                .animation(.spring(response: 0.42, dampingFraction: 0.84), value: selectedUnitRaw)
                            }

                            Spacer()

                            LifeProgressRing(progress: progress, colors: selectedTheme.ringColors)
                        }

                        Divider().overlay(.white.opacity(0.25))

                        HStack {
                            Label {
                                Text("Since \(birthDate.formatted(date: .abbreviated, time: .omitted))")
                            } icon: {
                                Image(systemName: "calendar")
                            }

                            Spacer()

                            Text(progress.formatted(.percent.precision(.fractionLength(0))))
                                .font(.system(size: 16, weight: .bold, design: selectedTypography.bodyDesign))
                        }
                        .font(.system(size: 14, weight: .medium, design: selectedTypography.bodyDesign))
                        .foregroundStyle(.white.opacity(0.86))
                    }
                    .padding(22)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    }
                    .scaleEffect(unitSwapPulse ? 0.985 : 1)
                    .opacity(unitSwapPulse ? 0.95 : 1)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: unitSwapPulse)

                    timeLeftHero(remaining: remaining)
                    unitPicker
                    milestoneGraphCard(progress: progress)

                    HStack(spacing: 14) {
                        statCard(
                            title: "Days lived",
                            value: Int(elapsed / LifeUnit.days.seconds).formatted(.number.grouping(.automatic)),
                            icon: "sun.max"
                        )

                        statCard(
                            title: "Years left (est.)",
                            value: Int((remaining / LifeUnit.years.seconds).rounded()).formatted(.number.grouping(.automatic)),
                            icon: "hourglass.bottomhalf.filled"
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Time")
                    .font(.system(size: 35, weight: .heavy, design: selectedTypography.heroDesign))
                    .foregroundStyle(.white)

                Text("Every second counts.")
                    .font(.system(size: 15, weight: .medium, design: selectedTypography.bodyDesign))
                    .foregroundStyle(.white.opacity(0.78))
            }

            Spacer()

            HStack(spacing: 10) {
                circleButton(systemName: showLifeGrid ? "chart.bar.doc.horizontal.fill" : "square.grid.3x3.fill") {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        showLifeGrid.toggle()
                    }
                }

                circleButton(systemName: "slider.horizontal.3") {
                    showSettings = true
                }
            }
        }
        .padding(.top, 8)
    }

    private func timeLeftHero(remaining: TimeInterval) -> some View {
        let selectedLeftValue = selectedUnit.convert(from: remaining)

        return VStack(alignment: .leading, spacing: 10) {
            Text("TIME LEFT (EST.)")
                .font(.system(size: 12, weight: .bold, design: selectedTypography.bodyDesign))
                .tracking(1.6)
                .foregroundStyle(.white.opacity(0.75))

            HStack(alignment: .firstTextBaseline) {
                ZStack(alignment: .leading) {
                    Text(formattedValue(selectedLeftValue, unit: selectedUnit))
                        .font(.system(size: 44, weight: .black, design: selectedTypography.heroDesign))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .id("time-left-value-\(selectedUnitRaw)")
                        .transition(unitSwapTransition)
                }
                .animation(.spring(response: 0.42, dampingFraction: 0.84), value: selectedUnitRaw)

                ZStack(alignment: .leading) {
                    Text(selectedUnit.title)
                        .font(.system(size: 18, weight: .semibold, design: selectedTypography.bodyDesign))
                        .foregroundStyle(.white.opacity(0.86))
                        .id("time-left-unit-\(selectedUnitRaw)")
                        .transition(unitSwapTransition)
                }
                .animation(.spring(response: 0.42, dampingFraction: 0.84), value: selectedUnitRaw)
            }
            .foregroundStyle(.white)

            ZStack(alignment: .leading) {
                Text("≈ \(formattedValue(selectedLeftValue, unit: selectedUnit)) \(selectedUnit.title) left")
                    .font(.system(size: 14, weight: .medium, design: selectedTypography.bodyDesign))
                    .foregroundStyle(.white.opacity(0.75))
                    .id("time-left-subtitle-\(selectedUnitRaw)")
                    .transition(unitSwapTransition)
            }
            .animation(.easeInOut(duration: 0.35), value: selectedUnitRaw)

            ZStack {
                timeLeftSparkline(remainingValue: selectedLeftValue, unit: selectedUnit)
                    .id("time-left-sparkline-\(selectedUnitRaw)")
                    .transition(unitSwapTransition)
            }
            .frame(height: 56)
            .padding(.top, 2)
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: selectedUnitRaw)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .scaleEffect(unitSwapPulse ? 0.985 : 1)
        .opacity(unitSwapPulse ? 0.95 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: unitSwapPulse)
    }

    private func timeLeftSparkline(remainingValue: Double, unit: LifeUnit) -> some View {
        GeometryReader { proxy in
            let exponent = graphCurveExponent(for: unit)
            let points = (0..<9).map { index -> CGPoint in
                let t = Double(index) / 8.0
                let value = max(0.02, 1.0 - pow(t, exponent))
                return CGPoint(
                    x: proxy.size.width * CGFloat(t),
                    y: proxy.size.height * CGFloat(1 - value)
                )
            }

            ZStack {
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: CGPoint(x: first.x, y: proxy.size.height))
                    path.addLine(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                    path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [selectedTheme.topGlow.opacity(0.35), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(
                    LinearGradient(colors: [selectedTheme.topGlow, selectedTheme.bottomGlow], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )

                if let last = points.last {
                    Circle()
                        .fill(selectedTheme.bottomGlow)
                        .frame(width: 8, height: 8)
                        .position(last)
                }
            }
            .overlay(alignment: .topLeading) {
                Text("Now")
                    .font(.system(size: 10, weight: .semibold, design: selectedTypography.bodyDesign))
                    .foregroundStyle(.white.opacity(0.62))
                    .offset(y: -2)
            }
            .overlay(alignment: .topTrailing) {
                Text("End")
                    .font(.system(size: 10, weight: .semibold, design: selectedTypography.bodyDesign))
                    .foregroundStyle(.white.opacity(0.62))
                    .offset(y: -2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
            .animation(.easeInOut(duration: 0.45), value: unit.rawValue)
        }
        .accessibilityLabel("Remaining life trend")
        .accessibilityValue("\(Int(remainingValue.rounded())) \(unit.title) left")
    }

    private func graphCurveExponent(for unit: LifeUnit) -> Double {
        switch unit {
        case .years: 1.2
        case .months: 1.1
        case .weeks: 1.0
        case .days: 0.92
        case .hours: 0.84
        case .minutes: 0.78
        case .seconds: 0.72
        }
    }

    private func lifeGridCard(elapsed: TimeInterval, remaining: TimeInterval) -> some View {
        let totalUnits = max((lifeExpectancyYears * LifeUnit.years.seconds) / selectedUnit.seconds, 1)
        let elapsedUnits = min(max(elapsed / selectedUnit.seconds, 0), totalUnits)
        let remainingUnits = max(0, totalUnits - elapsedUnits)
        let cellCount = 364
        let elapsedCells = min(cellCount, Int((elapsedUnits / totalUnits * Double(cellCount)).rounded(.down)))
        let unitsPerCell = max(1, Int((totalUnits / Double(cellCount)).rounded(.up)))
        let rows = Array(repeating: GridItem(.fixed(12), spacing: 5), count: 7)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIFE GRID")
                        .font(.system(size: 12, weight: .bold, design: selectedTypography.bodyDesign))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.76))

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(formattedValue(remainingUnits, unit: selectedUnit))
                            .font(.system(size: 44, weight: .black, design: selectedTypography.heroDesign))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())

                        Text("\(selectedUnit.title) left")
                            .font(.system(size: 17, weight: .semibold, design: selectedTypography.bodyDesign))
                            .foregroundStyle(.white.opacity(0.86))
                    }
                }
                Spacer()
            }

            Text("Each cell ≈ \(unitsPerCell.formatted(.number.grouping(.never))) \(selectedUnit.title.lowercased())")
                .font(.system(size: 12, weight: .medium, design: selectedTypography.bodyDesign))
                .foregroundStyle(.white.opacity(0.7))

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: rows, spacing: 5) {
                    ForEach(0..<cellCount, id: \.self) { index in
                        let isPast = index < elapsedCells
                        let isCurrent = index == elapsedCells && elapsedCells < cellCount
                        let futureIntensity = gridFutureIntensity(index: index, elapsedCells: elapsedCells, cellCount: cellCount)

                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(gridHeatColor(isPast: isPast, isCurrent: isCurrent, futureIntensity: futureIntensity))
                            .frame(width: 12, height: 12)
                            .overlay {
                                if isCurrent {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .stroke(.white.opacity(0.95), lineWidth: 1)
                                }
                            }
                    }
                }
                .padding(2)
            }

            HStack(spacing: 14) {
                Label("Past", systemImage: "square.fill")
                    .foregroundStyle(.white.opacity(0.6))
                Label("Current", systemImage: "location.fill")
                    .foregroundStyle(.white.opacity(0.9))
                Label("Future", systemImage: "sparkles")
                    .foregroundStyle(selectedTheme.topGlow.opacity(0.95))
            }
            .font(.system(size: 11, weight: .medium, design: selectedTypography.bodyDesign))
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
    }

    private func gridFutureIntensity(index: Int, elapsedCells: Int, cellCount: Int) -> Double {
        let futureRange = max(1, cellCount - elapsedCells)
        let distance = Double(max(0, index - elapsedCells)) / Double(futureRange)
        return max(0, 1 - distance)
    }

    private func gridHeatColor(isPast: Bool, isCurrent: Bool, futureIntensity: Double) -> Color {
        if isCurrent {
            return selectedTheme.topGlow.opacity(0.95)
        }
        if isPast {
            return selectedTheme.bottomGlow.opacity(0.92)
        }
        return selectedTheme.topGlow.opacity(0.18 + (0.36 * futureIntensity))
    }

    private func milestoneGraphCard(progress: Double) -> some View {
        let milestones = [0.25, 0.5, 0.75, 1.0]

        return VStack(alignment: .leading, spacing: 12) {
            Text("LIFETIME MILESTONES")
                .font(.system(size: 12, weight: .bold, design: selectedTypography.bodyDesign))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.76))

            HStack(spacing: 12) {
                ForEach(milestones, id: \.self) { milestone in
                    let fillProgress = min(progress / milestone, 1)

                    VStack(spacing: 8) {
                        Text("\(Int(milestone * 100))%")
                            .font(.system(size: 11, weight: .semibold, design: selectedTypography.bodyDesign))
                            .foregroundStyle(.white.opacity(0.78))

                        ZStack(alignment: .bottom) {
                            Capsule()
                                .fill(.white.opacity(0.16))
                                .frame(width: 18, height: 62)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [selectedTheme.topGlow, selectedTheme.bottomGlow],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 18, height: 62 * fillProgress)
                        }

                        Text(progress >= milestone ? "Reached" : "Upcoming")
                            .font(.system(size: 10, weight: .medium, design: selectedTypography.bodyDesign))
                            .foregroundStyle(progress >= milestone ? .white : .white.opacity(0.58))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
    }

    private var unitPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LifeUnit.allCases) { unit in
                    Button {
                        guard selectedUnitRaw != unit.rawValue else { return }
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.84)) {
                            selectedUnitRaw = unit.rawValue
                            unitSwapPulse = true
                        }
                        performSelectionHaptic()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                            withAnimation(.easeOut(duration: 0.28)) {
                                unitSwapPulse = false
                            }
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(unit.shortTitle)
                                .font(.system(size: 16, weight: .bold, design: selectedTypography.bodyDesign))
                            Text(unit.title)
                                .font(.system(size: 12, weight: .medium, design: selectedTypography.bodyDesign))
                        }
                        .foregroundStyle(unit == selectedUnit ? selectedTheme.selectedChipForeground : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background {
                            ZStack {
                                if unit == selectedUnit {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(selectedTheme.selectedChipBackground)
                                        .matchedGeometryEffect(id: "unit-chip-selection", in: unitChipSelectionAnimation)
                                } else {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.white.opacity(0.14))
                                }
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(.white.opacity(unit == selectedUnit ? 0.0 : 0.18), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .animation(.spring(response: 0.42, dampingFraction: 0.82), value: selectedUnitRaw)
        }
    }

    private var settingsSheet: some View {
        NavigationStack {
            ZStack {
                background
                settingsReadabilityLayer

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        settingsHeader(title: "Settings")
                        settingsSectionTitle("Life Profile")
                        VStack(spacing: 0) {
                            HStack {
                                Text("Birth date")
                                    .foregroundStyle(.white)
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { birthDate },
                                        set: { birthDateTimestamp = min($0, Date()).timeIntervalSince1970 }
                                    ),
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .tint(selectedTheme.bottomGlow)
                            }
                            .padding(16)

                            Divider().overlay(.white.opacity(0.18))

                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Life expectancy")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(Int(lifeExpectancyYears)) years")
                                        .foregroundStyle(.white.opacity(0.9))
                                }

                                Slider(value: $lifeExpectancyYears, in: 50...120, step: 1)
                                    .tint(selectedTheme.topGlow)
                            }
                            .padding(16)
                        }
                        .settingsCardStyle()

                        settingsSectionTitle("Appearance")
                        VStack(spacing: 0) {
                            settingsMenuRow(title: "Color theme", value: selectedTheme.title) {
                                ForEach(ClockTheme.allCases) { theme in
                                    Button(theme.title) {
                                        clockThemeRaw = theme.rawValue
                                        performSelectionHaptic()
                                    }
                                }
                            }

                            Divider().overlay(.white.opacity(0.28))

                            settingsMenuRow(title: "Typography", value: selectedTypography.title) {
                                ForEach(TypographyPreset.allCases) { style in
                                    Button(style.title) {
                                        typographyPresetRaw = style.rawValue
                                        performSelectionHaptic()
                                    }
                                }
                            }

                            Divider().overlay(.white.opacity(0.28))

                            settingsMenuRow(title: "App icon", value: AppIconChoice(rawValue: appIconChoiceRaw)?.title ?? AppIconChoice.primary.title) {
                                ForEach(AppIconChoice.allCases) { iconChoice in
                                    Button(iconChoice.title) {
                                        let oldValue = appIconChoiceRaw
                                        appIconChoiceRaw = iconChoice.rawValue
                                        applyAppIcon(from: oldValue, to: iconChoice.rawValue)
                                        performSelectionHaptic()
                                    }
                                }
                            }

                            Divider().overlay(.white.opacity(0.28))

                            Text("Tip: Add alternate icon assets named AppIconPulse and AppIconHorizon to fully enable icon switching.")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                        }
                        .settingsCardStyle()

                        settingsSectionTitle("Interactions")
                        Toggle(isOn: $hapticsEnabled) {
                            Text("Haptics")
                                .foregroundStyle(.white)
                        }
                        .tint(selectedTheme.bottomGlow)
                        .padding(16)
                        .settingsCardStyle()

                        settingsSectionTitle("App")
                        VStack(spacing: 0) {
                            Button {
                                hasCompletedOnboarding = false
                                showOnboarding = true
                                performSelectionHaptic()
                            } label: {
                                HStack {
                                    Text("Run onboarding again")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .padding(16)
                            }
                            .buttonStyle(.plain)

                            Divider().overlay(.white.opacity(0.28))

                            NavigationLink {
                                legalView
                            } label: {
                                HStack {
                                    Text("Legal & Policies")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .padding(16)
                            }
                        }
                        .settingsCardStyle()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .environment(\.colorScheme, .dark)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showSettings = false
                    }
                    .font(.system(size: 17, weight: .semibold, design: selectedTypography.bodyDesign))
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private var legalView: some View {
        ZStack {
            background
            settingsReadabilityLayer

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    settingsHeader(title: "Legal")
                    legalBlock(
                        title: "Legal Notice",
                        text: "Operator details, contact address, and responsible person information should be listed here."
                    )

                    legalBlock(
                        title: "Privacy",
                        text: "LifeClock stores your birth date, display settings, and preferences locally on your device. No cloud sync is enabled by default."
                    )

                    legalBlock(
                        title: "Terms of Use",
                        text: "All displayed values are estimations based on your inputs. LifeClock does not provide medical, legal, or financial advice."
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Policy Links")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                        Link("Terms & Conditions", destination: URL(string: "https://example.com/terms")!)
                        Link("Support", destination: URL(string: "mailto:support@example.com")!)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .settingsCardStyle()

                    Text("Last updated: February 24, 2026")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .environment(\.colorScheme, .dark)
    }

    private func circleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            performSelectionHaptic()
            action()
        }) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold, design: selectedTypography.bodyDesign))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .semibold, design: selectedTypography.bodyDesign))
                .foregroundStyle(.white.opacity(0.8))

            Text(value)
                .font(.system(size: 26, weight: .black, design: selectedTypography.heroDesign))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
    }

    private func legalBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(text)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .settingsCardStyle()
    }

    private func settingsSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .bold, design: selectedTypography.bodyDesign))
            .foregroundStyle(.white.opacity(0.95))
            .padding(.leading, 4)
    }

    private func settingsHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 48, weight: .heavy, design: selectedTypography.heroDesign))
            .foregroundStyle(.white)
            .padding(.top, 6)
            .padding(.leading, 4)
    }

    private func settingsMenuRow<Options: View>(title: String, value: String, @ViewBuilder options: () -> Options) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.white)
            Spacer()

            Menu {
                options()
            } label: {
                HStack(spacing: 6) {
                    Text(value)
                        .foregroundStyle(.white.opacity(0.95))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .padding(16)
    }

    private var settingsReadabilityLayer: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.22),
                Color.black.opacity(0.14),
                Color.black.opacity(0.2)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func formattedValue(_ value: Double, unit: LifeUnit) -> String {
        Int(value.rounded()).formatted(.number.grouping(.automatic))
    }

    private func lifeProgress(elapsed: TimeInterval) -> Double {
        let fullLife = max(lifeExpectancyYears * LifeUnit.years.seconds, 1)
        return min(max(elapsed / fullLife, 0), 1)
    }

    private func remainingLifeSeconds(elapsed: TimeInterval) -> TimeInterval {
        max(0, (lifeExpectancyYears * LifeUnit.years.seconds) - elapsed)
    }

    private func performSelectionHaptic() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func applyAppIcon(from oldValue: String, to newValue: String) {
        guard oldValue != newValue else { return }
        guard UIApplication.shared.supportsAlternateIcons else {
            iconErrorMessage = "This device does not support alternate app icons."
            appIconChoiceRaw = oldValue
            return
        }

        guard let newChoice = AppIconChoice(rawValue: newValue) else {
            iconErrorMessage = "Selected icon is invalid."
            appIconChoiceRaw = oldValue
            return
        }

        UIApplication.shared.setAlternateIconName(newChoice.iconName) { error in
            DispatchQueue.main.async {
                if let error {
                    iconErrorMessage = error.localizedDescription
                    appIconChoiceRaw = oldValue
                }
            }
        }
    }
}

private struct LifeProgressRing: View {
    let progress: Double
    let colors: [Color]

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.2), lineWidth: 10)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: colors, center: .center),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text(progress.formatted(.percent.precision(.fractionLength(0))))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(width: 88, height: 88)
    }
}

private extension View {
    func settingsCardStyle() -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
    }
}

private struct OnboardingView: View {
    @Binding var birthDateTimestamp: Double
    @Binding var selectedUnitRaw: String
    @Binding var lifeExpectancyYears: Double

    let completeAction: () -> Void

    private var birthDateBinding: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: birthDateTimestamp) },
            set: { birthDateTimestamp = min($0, Date()).timeIntervalSince1970 }
        )
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.09, blue: 0.17),
                    Color(red: 0.05, green: 0.17, blue: 0.29),
                    Color(red: 0.16, green: 0.09, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Welcome to LifeClock")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Set up your profile in less than a minute.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))

                    card {
                        DatePicker(
                            "Birth date",
                            selection: birthDateBinding,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .tint(.teal)
                    }

                    card {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Expected lifespan")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                Spacer()
                                Text("\(Int(lifeExpectancyYears)) years")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                            }
                            Slider(value: $lifeExpectancyYears, in: 50...120, step: 1)
                                .tint(.orange)
                        }
                    }

                    card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Default unit")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(LifeUnit.allCases) { unit in
                                        Button {
                                            selectedUnitRaw = unit.rawValue
                                        } label: {
                                            Text(unit.title)
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundStyle((LifeUnit(rawValue: selectedUnitRaw) ?? .days) == unit ? .black : .white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .fill((LifeUnit(rawValue: selectedUnitRaw) ?? .days) == unit ? Color.white : Color.white.opacity(0.16))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    Button(action: completeAction) {
                        Text("Start LifeClock")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.85, green: 0.99, blue: 0.95), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(24)
            }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
            .foregroundStyle(.white)
    }
}

#Preview {
    ContentView()
}
