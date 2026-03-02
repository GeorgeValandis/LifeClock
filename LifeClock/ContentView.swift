import StoreKit
import SwiftUI
import UIKit
import WidgetKit

enum LifeUnit: String, CaseIterable, Identifiable {
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

enum ClockTheme: String, CaseIterable, Identifiable {
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
                Color(red: 0.20, green: 0.12, blue: 0.05),
            ]
        case .solar:
            [
                Color(red: 0.17, green: 0.07, blue: 0.03),
                Color(red: 0.33, green: 0.14, blue: 0.06),
                Color(red: 0.56, green: 0.27, blue: 0.08),
            ]
        case .deepSea:
            [
                Color(red: 0.01, green: 0.05, blue: 0.14),
                Color(red: 0.04, green: 0.15, blue: 0.30),
                Color(red: 0.01, green: 0.31, blue: 0.39),
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
                Color(red: 0.11, green: 0.87, blue: 0.84),
            ]
        case .solar:
            [
                Color(red: 1.0, green: 0.90, blue: 0.39),
                Color(red: 1.0, green: 0.63, blue: 0.21),
                Color(red: 1.0, green: 0.35, blue: 0.17),
            ]
        case .deepSea:
            [
                Color(red: 0.69, green: 0.95, blue: 1.0),
                Color(red: 0.26, green: 0.70, blue: 1.0),
                Color(red: 0.15, green: 0.95, blue: 0.81),
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
    @AppStorage(SharedDefaults.keyBirthDate, store: SharedDefaults.store) private
        var birthDateTimestamp: Double = Date(
            timeIntervalSinceNow: -26 * 31_556_952
        ).timeIntervalSince1970
    @AppStorage(SharedDefaults.keySelectedUnit, store: SharedDefaults.store) private
        var selectedUnitRaw: String = LifeUnit.days.rawValue
    @AppStorage(SharedDefaults.keyLifeExpectancy, store: SharedDefaults.store) private
        var lifeExpectancyYears: Double = 90
    @AppStorage(SharedDefaults.keyClockTheme, store: SharedDefaults.store) private
        var clockThemeRaw: String = ClockTheme.aurora.rawValue
    @AppStorage("typographyPresetRaw") private var typographyPresetRaw: String = TypographyPreset
        .modern.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("appIconChoiceRaw") private var appIconChoiceRaw: String = AppIconChoice.primary
        .rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage(SharedDefaults.keyTrialStartTimestamp, store: SharedDefaults.store) private
        var trialStartTimestamp: Double = 0
    @AppStorage(SharedDefaults.keyLifetimeUnlocked, store: SharedDefaults.store) private
        var lifetimeUnlocked: Bool = false

    @State private var showSettings = false
    @State private var showOnboarding = false
    @State private var animateBackground = false
    @State private var iconErrorMessage: String?
    @State private var unitSwapPulse = false
    @State private var showLifeGrid = false
    @State private var cardsAppeared = false
    @State private var pendingOnboardingRestart = false
    @State private var showLifetimePaywallManually = false
    @State private var pendingManualPaywallPresentation = false
    @State private var lifetimeProduct: Product?
    @State private var isPurchasingLifetime = false
    @State private var isRestoringPurchases = false
    @State private var paywallMessage: String?
    @Namespace private var unitChipSelectionAnimation

    private let lifetimeProductID = "com.GA.LifeClock.lifetime"
    private let trialDuration: TimeInterval = 3 * 24 * 60 * 60

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Night Owl"
        }
    }

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

    private var trialStartDate: Date {
        Date(timeIntervalSince1970: trialStartTimestamp)
    }

    private var trialEndDate: Date {
        trialStartDate.addingTimeInterval(trialDuration)
    }

    private var trialRemaining: TimeInterval {
        max(0, trialEndDate.timeIntervalSinceNow)
    }

    private var isTrialExpired: Bool {
        trialStartTimestamp > 0 && trialRemaining <= 0
    }

    private var shouldShowLifetimePaywall: Bool {
        hasCompletedOnboarding && !showOnboarding && !lifetimeUnlocked && isTrialExpired
    }

    private var timelineRefreshInterval: TimeInterval {
        if showLifeGrid {
            // Grid cursor should advance exactly when one selected unit completes.
            return max(1, min(selectedUnit.seconds, 3600))
        }
        return 1
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

                TimelineView(.periodic(from: .now, by: timelineRefreshInterval)) { context in
                    mainContent(now: context.date)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                    animateBackground.toggle()
                }
                initializeTrialIfNeeded()
                showOnboarding = !hasCompletedOnboarding
                withAnimation(.spring(response: 0.7, dampingFraction: 0.82).delay(0.15)) {
                    cardsAppeared = true
                }
            }
            .task {
                await preloadLifetimeProduct()
                await refreshLifetimeEntitlement()
            }
            .sheet(isPresented: $showSettings) {
                settingsSheet
            }
            .onChange(of: showSettings) { _, isPresented in
                if !isPresented && pendingOnboardingRestart {
                    pendingOnboardingRestart = false
                    showOnboarding = true
                }

                if !isPresented && pendingManualPaywallPresentation {
                    pendingManualPaywallPresentation = false
                    showLifetimePaywallManually = true
                }
            }
            .onChange(of: selectedUnitRaw) { _, _ in
                WidgetCenter.shared.reloadAllTimelines()
            }
            .onChange(of: birthDateTimestamp) { _, _ in
                WidgetCenter.shared.reloadAllTimelines()
            }
            .onChange(of: lifeExpectancyYears) { _, _ in
                WidgetCenter.shared.reloadAllTimelines()
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(
                    birthDateTimestamp: $birthDateTimestamp,
                    selectedUnitRaw: $selectedUnitRaw,
                    lifeExpectancyYears: $lifeExpectancyYears,
                    clockThemeRaw: $clockThemeRaw,
                    completeAction: {
                        hasCompletedOnboarding = true
                        showOnboarding = false
                    }
                )
            }
            .fullScreenCover(
                isPresented: Binding(get: { shouldShowLifetimePaywall }, set: { _ in })
            ) {
                lifetimePaywallView(allowDismiss: false)
            }
            .fullScreenCover(isPresented: $showLifetimePaywallManually) {
                lifetimePaywallView(allowDismiss: true)
            }
            .alert(
                "Icon Update Failed",
                isPresented: Binding(
                    get: { iconErrorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            iconErrorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) { iconErrorMessage = nil }
            } message: {
                Text(iconErrorMessage ?? "Unknown error")
            }
            .alert(
                "Purchase Notice",
                isPresented: Binding(
                    get: { paywallMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            paywallMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) { paywallMessage = nil }
            } message: {
                Text(paywallMessage ?? "")
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

    private func lifetimePaywallView(allowDismiss: Bool) -> some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 0) {

                    // MARK: – Close button
                    if allowDismiss {
                        HStack {
                            Spacer()
                            Button {
                                showLifetimePaywallManually = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(width: 30, height: 30)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .overlay {
                                        Circle().stroke(.white.opacity(0.12), lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    } else {
                        Spacer().frame(height: 56)
                    }

                    // MARK: – Hero icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        selectedTheme.topGlow.opacity(0.35),
                                        selectedTheme.topGlow.opacity(0.08),
                                        .clear,
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [selectedTheme.topGlow, selectedTheme.bottomGlow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: selectedTheme.topGlow.opacity(0.5), radius: 20, x: 0, y: 8)
                    }
                    .padding(.top, 12)

                    // MARK: – Headline
                    Text("Unlock LifeClock")
                        .font(
                            .system(size: 32, weight: .heavy, design: selectedTypography.heroDesign)
                        )
                        .foregroundStyle(.white)
                        .padding(.top, 20)

                    Text("One purchase. Forever yours.")
                        .font(
                            .system(
                                size: 16, weight: .medium, design: selectedTypography.bodyDesign)
                        )
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 4)

                    // MARK: – Feature list
                    VStack(spacing: 0) {
                        paywallFeatureRow(
                            icon: "infinity",
                            title: "Unlimited Access",
                            subtitle: "Use every feature, forever"
                        )
                        paywallDivider
                        paywallFeatureRow(
                            icon: "square.grid.3x3.fill",
                            title: "Life Grid & Clock",
                            subtitle: "All visualization modes"
                        )
                        paywallDivider
                        paywallFeatureRow(
                            icon: "paintpalette.fill",
                            title: "Themes & Typography",
                            subtitle: "Personalize your experience"
                        )
                        paywallDivider
                        paywallFeatureRow(
                            icon: "widget.small",
                            title: "Home Screen Widgets",
                            subtitle: "Glanceable life progress"
                        )
                        paywallDivider
                        paywallFeatureRow(
                            icon: "bolt.shield.fill",
                            title: "No Subscription",
                            subtitle: "Pay once — no recurring fees"
                        )
                    }
                    .padding(.vertical, 6)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                    // MARK: – CTA button
                    Button {
                        Task { await purchaseLifetime() }
                    } label: {
                        HStack(spacing: 10) {
                            if isPurchasingLifetime {
                                ProgressView()
                                    .tint(.black)
                            }
                            Text(
                                lifetimeProduct.map { "Unlock Lifetime — \($0.displayPrice)" }
                                    ?? "Unlock Lifetime"
                            )
                            .font(
                                .system(
                                    size: 17, weight: .bold, design: selectedTypography.bodyDesign))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [selectedTheme.topGlow, selectedTheme.bottomGlow],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .shadow(color: selectedTheme.topGlow.opacity(0.4), radius: 16, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasingLifetime || isRestoringPurchases)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // MARK: – One-time badge
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(selectedTheme.bottomGlow)
                        Text("One-time purchase • No subscription")
                            .font(
                                .system(
                                    size: 12, weight: .medium, design: selectedTypography.bodyDesign
                                )
                            )
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.top, 10)

                    // MARK: – Restore
                    Button {
                        Task { await restorePurchases() }
                    } label: {
                        HStack(spacing: 6) {
                            if isRestoringPurchases {
                                ProgressView()
                                    .tint(.white.opacity(0.7))
                                    .scaleEffect(0.8)
                            }
                            Text("Restore Purchases")
                                .font(
                                    .system(
                                        size: 14, weight: .semibold,
                                        design: selectedTypography.bodyDesign))
                        }
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasingLifetime || isRestoringPurchases)
                    .padding(.top, 4)

                    Spacer().frame(height: 32)
                }
            }
            .scrollIndicators(.hidden)
        }
        .interactiveDismissDisabled(!allowDismiss)
        .task {
            await preloadLifetimeProduct()
            await refreshLifetimeEntitlement()
        }
    }

    private func paywallFeatureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(selectedTheme.topGlow)
                .frame(width: 36, height: 36)
                .background(
                    selectedTheme.topGlow.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(
                        .system(size: 15, weight: .semibold, design: selectedTypography.bodyDesign)
                    )
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: selectedTypography.bodyDesign))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(selectedTheme.bottomGlow.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var paywallDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, 66)
    }

    private func mainContent(now: Date) -> some View {
        let elapsed = max(0, now.timeIntervalSince(birthDate))
        let unitValue = selectedUnit.convert(from: elapsed)
        let progress = lifeProgress(elapsed: elapsed)
        let remaining = remainingLifeSeconds(elapsed: elapsed)

        return ScrollView {
            VStack(spacing: 24) {
                header
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 18)

                if showLifeGrid {
                    VStack(spacing: 24) {
                        lifeGridCard(elapsed: elapsed, remaining: remaining)
                        unitPicker
                    }
                    .transition(.asymmetric(insertion: .flipForward, removal: .flipBackward))
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 24)
                } else {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 7) {
                                Text("LIFE CLOCK")
                                    .font(
                                        .system(
                                            size: 12, weight: .bold,
                                            design: selectedTypography.bodyDesign)
                                    )
                                    .tracking(1.8)
                                    .foregroundStyle(.white.opacity(0.74))

                                ZStack(alignment: .leading) {
                                    Text(formattedValue(unitValue, unit: selectedUnit))
                                        .font(
                                            .system(
                                                size: lifeClockValueFontSize(for: selectedUnit),
                                                weight: .black,
                                                design: selectedTypography.heroDesign)
                                        )
                                        .minimumScaleFactor(0.22)
                                        .lineLimit(1)
                                        .allowsTightening(true)
                                        .layoutPriority(1)
                                        .monospacedDigit()
                                        .foregroundStyle(.white)
                                        .shadow(
                                            color: selectedTheme.topGlow.opacity(0.25), radius: 16,
                                            x: 0, y: 2
                                        )
                                        .contentTransition(.numericText())
                                        .id("life-clock-value-\(selectedUnitRaw)")
                                        .transition(unitSwapTransition)
                                }
                                .animation(
                                    .spring(response: 0.42, dampingFraction: 0.84),
                                    value: selectedUnitRaw)

                                ZStack(alignment: .leading) {
                                    Text(selectedUnit.title)
                                        .font(
                                            .system(
                                                size: 18, weight: .semibold,
                                                design: selectedTypography.bodyDesign)
                                        )
                                        .foregroundStyle(.white.opacity(0.88))
                                        .id("life-clock-unit-\(selectedUnitRaw)")
                                        .transition(unitSwapTransition)
                                }
                                .animation(
                                    .spring(response: 0.42, dampingFraction: 0.84),
                                    value: selectedUnitRaw)
                            }

                            Spacer()

                            LifeProgressRing(
                                progress: progress, colors: selectedTheme.ringColors,
                                glowColor: selectedTheme.topGlow)
                        }

                        LinearGradient(
                            colors: [
                                selectedTheme.topGlow.opacity(0.6),
                                selectedTheme.bottomGlow.opacity(0.6),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 1)
                        .padding(.horizontal, 4)

                        HStack {
                            Label {
                                Text(
                                    "Since \(birthDate.formatted(date: .abbreviated, time: .omitted))"
                                )
                            } icon: {
                                Image(systemName: "calendar")
                            }

                            Spacer()

                            Text(progress.formatted(.percent.precision(.fractionLength(1))))
                                .font(
                                    .system(
                                        size: 16, weight: .bold,
                                        design: selectedTypography.bodyDesign))
                        }
                        .font(
                            .system(
                                size: 14, weight: .medium, design: selectedTypography.bodyDesign)
                        )
                        .foregroundStyle(.white.opacity(0.86))
                    }
                    .padding(22)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 34, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        selectedTheme.topGlow.opacity(0.25), .white.opacity(0.1),
                                        selectedTheme.bottomGlow.opacity(0.2),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .scaleEffect(unitSwapPulse ? 0.985 : 1)
                    .opacity(unitSwapPulse ? 0.95 : 1)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: unitSwapPulse)
                    .transition(.asymmetric(insertion: .flipBackward, removal: .flipForward))
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 24)
                }

                if !showLifeGrid {
                    timeLeftHero(remaining: remaining)
                        .opacity(cardsAppeared ? 1 : 0)
                        .offset(y: cardsAppeared ? 0 : 32)

                    unitPicker
                        .opacity(cardsAppeared ? 1 : 0)

                    nextMilestoneCard(now: now, elapsed: elapsed)
                        .opacity(cardsAppeared ? 1 : 0)
                        .offset(y: cardsAppeared ? 0 : 36)

                    HStack(spacing: 14) {
                        statCard(
                            title: "Days lived",
                            value: groupedIntegerString(Int(elapsed / LifeUnit.days.seconds)),
                            icon: "sun.max",
                            accentColor: selectedTheme.topGlow
                        )

                        statCard(
                            title: "Years left (est.)",
                            value: groupedIntegerString(
                                Int((remaining / LifeUnit.years.seconds).rounded())),
                            icon: "hourglass.bottomhalf.filled",
                            accentColor: selectedTheme.bottomGlow
                        )
                    }
                    .opacity(cardsAppeared ? 1 : 0)
                    .offset(y: cardsAppeared ? 0 : 40)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .animation(.spring(response: 0.7, dampingFraction: 0.82), value: cardsAppeared)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(
                        .system(size: 14, weight: .semibold, design: selectedTypography.bodyDesign)
                    )
                    .foregroundStyle(selectedTheme.topGlow.opacity(0.9))
                    .tracking(1.2)

                Text("Your Time")
                    .font(.system(size: 35, weight: .heavy, design: selectedTypography.heroDesign))
                    .foregroundStyle(.white)
                    .shadow(color: selectedTheme.topGlow.opacity(0.3), radius: 12, x: 0, y: 4)

                Text("Every second counts.")
                    .font(.system(size: 15, weight: .medium, design: selectedTypography.bodyDesign))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            HStack(spacing: 10) {
                circleButton(
                    systemName: showLifeGrid
                        ? "chart.bar.doc.horizontal.fill" : "square.grid.3x3.fill"
                ) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
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

    private func alternateTimeLeftDescription(remaining: TimeInterval) -> String {
        let years = Int(remaining / LifeUnit.years.seconds)
        let months = Int(
            (remaining.truncatingRemainder(dividingBy: LifeUnit.years.seconds))
                / LifeUnit.months.seconds)
        if years > 0 {
            return "≈ \(years) years, \(months) months remaining"
        }
        let days = Int(remaining / LifeUnit.days.seconds)
        return "≈ \(groupedIntegerString(days)) days remaining"
    }

    private func timeLeftHero(remaining: TimeInterval) -> some View {
        let selectedLeftValue = selectedUnit.convert(from: remaining)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TIME LEFT (EST.)")
                    .font(.system(size: 12, weight: .bold, design: selectedTypography.bodyDesign))
                    .tracking(1.6)
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(selectedTheme.bottomGlow.opacity(0.7))
            }

            HStack(alignment: .firstTextBaseline) {
                ZStack(alignment: .leading) {
                    Text(formattedValue(selectedLeftValue, unit: selectedUnit))
                        .font(
                            .system(size: 44, weight: .black, design: selectedTypography.heroDesign)
                        )
                        .monospacedDigit()
                        .shadow(
                            color: selectedTheme.bottomGlow.opacity(0.2), radius: 12, x: 0, y: 2
                        )
                        .contentTransition(.numericText())
                        .id("time-left-value-\(selectedUnitRaw)")
                        .transition(unitSwapTransition)
                }
                .animation(.spring(response: 0.42, dampingFraction: 0.84), value: selectedUnitRaw)

                ZStack(alignment: .leading) {
                    Text(selectedUnit.title)
                        .font(
                            .system(
                                size: 18, weight: .semibold, design: selectedTypography.bodyDesign)
                        )
                        .foregroundStyle(.white.opacity(0.86))
                        .id("time-left-unit-\(selectedUnitRaw)")
                        .transition(unitSwapTransition)
                }
                .animation(.spring(response: 0.42, dampingFraction: 0.84), value: selectedUnitRaw)
            }
            .foregroundStyle(.white)

            ZStack(alignment: .leading) {
                Text(alternateTimeLeftDescription(remaining: remaining))
                    .font(.system(size: 14, weight: .medium, design: selectedTypography.bodyDesign))
                    .foregroundStyle(.white.opacity(0.6))
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
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [selectedTheme.bottomGlow.opacity(0.2), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
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
                    LinearGradient(
                        colors: [selectedTheme.topGlow, selectedTheme.bottomGlow],
                        startPoint: .leading, endPoint: .trailing),
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
                    .font(
                        .system(size: 10, weight: .semibold, design: selectedTypography.bodyDesign)
                    )
                    .foregroundStyle(.white.opacity(0.62))
                    .offset(y: -2)
            }
            .overlay(alignment: .topTrailing) {
                Text("End")
                    .font(
                        .system(size: 10, weight: .semibold, design: selectedTypography.bodyDesign)
                    )
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

    private func lifeClockValueFontSize(for unit: LifeUnit) -> CGFloat {
        switch unit {
        case .seconds: 50
        case .minutes: 54
        case .hours: 56
        default: 58
        }
    }

    private func lifeGridCard(elapsed: TimeInterval, remaining: TimeInterval) -> some View {
        let totalUnits = max(
            (lifeExpectancyYears * LifeUnit.years.seconds) / selectedUnit.seconds, 1)
        let elapsedUnitsRaw = min(max(elapsed / selectedUnit.seconds, 0), totalUnits)
        let elapsedUnits = Int(elapsedUnitsRaw.rounded(.down))
        let remainingUnits = max(0, Int((totalUnits - Double(elapsedUnits)).rounded()))
        let dimensions = gridDimensions(for: selectedUnit)
        let rows = dimensions.rows
        let columns = dimensions.columns
        let cellCount = rows * columns
        let unitsPerCell = 1
        let totalWholeUnits = max(1, Int(totalUnits.rounded(.down)))
        let maxStart = max(0, totalWholeUnits - cellCount)
        let currentIndexInWindow: Int
        let windowStart: Int
        if totalWholeUnits <= cellCount {
            windowStart = 0
            currentIndexInWindow = min(max(0, elapsedUnits), cellCount - 1)
        } else {
            // Move the current marker forward cell by cell, then advance to the next window chunk.
            let movingIndex = max(0, elapsedUnits % cellCount)
            currentIndexInWindow = min(movingIndex, cellCount - 1)
            let alignedWindowStart = elapsedUnits - currentIndexInWindow
            windowStart = min(max(0, alignedWindowStart), maxStart)
        }
        let gridColumns = Array(
            repeating: GridItem(.flexible(minimum: 1, maximum: 12), spacing: 2), count: columns)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIFE GRID")
                        .font(
                            .system(size: 12, weight: .bold, design: selectedTypography.bodyDesign)
                        )
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.76))

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(groupedIntegerString(remainingUnits))
                            .font(
                                .system(
                                    size: 44, weight: .black, design: selectedTypography.heroDesign)
                            )
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .lineLimit(1)
                            .minimumScaleFactor(0.42)

                        Text("\(selectedUnit.title) left")
                            .font(
                                .system(
                                    size: 17, weight: .semibold,
                                    design: selectedTypography.bodyDesign)
                            )
                            .foregroundStyle(.white.opacity(0.86))
                    }
                }
                Spacer()
            }

            Text("Each cell = 1 \(selectedUnit.title.lowercased().dropLast()) • rolling window")
                .font(.system(size: 12, weight: .medium, design: selectedTypography.bodyDesign))
                .foregroundStyle(.white.opacity(0.7))

            LazyVGrid(columns: gridColumns, spacing: 3) {
                ForEach(0..<cellCount, id: \.self) { displayIndex in
                    let row = displayIndex / columns
                    let column = displayIndex % columns
                    let progressIndex = (column * rows) + row
                    let absoluteUnitIndex = windowStart + progressIndex
                    let isPast = absoluteUnitIndex < elapsedUnits
                    let isCurrent = progressIndex == currentIndexInWindow
                    let futureIntensity = gridFutureIntensity(
                        index: progressIndex, elapsedCells: currentIndexInWindow,
                        cellCount: cellCount)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(
                            gridHeatColor(
                                isPast: isPast, isCurrent: isCurrent,
                                futureIntensity: futureIntensity)
                        )
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            if isCurrent {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .stroke(.white.opacity(0.95), lineWidth: 1)
                            }
                        }
                }
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
                .stroke(
                    LinearGradient(
                        colors: [
                            selectedTheme.topGlow.opacity(0.2), .white.opacity(0.08),
                            selectedTheme.bottomGlow.opacity(0.15),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    private func gridFutureIntensity(index: Int, elapsedCells: Int, cellCount: Int) -> Double {
        let futureRange = max(1, cellCount - elapsedCells)
        let distance = Double(max(0, index - elapsedCells)) / Double(futureRange)
        return max(0, 1 - distance)
    }

    private func gridDimensions(for unit: LifeUnit) -> (rows: Int, columns: Int) {
        switch unit {
        case .years: (10, 10)  // 100
        case .months: (18, 30)  // 540
        case .weeks: (20, 40)  // 800
        case .days: (24, 40)  // 960
        case .hours: (26, 42)  // 1092
        case .minutes: (28, 44)  // 1232
        case .seconds: (30, 46)  // 1380
        }
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

    private func nextMilestoneCard(now: Date, elapsed: TimeInterval) -> some View {
        let fullLife = max(lifeExpectancyYears * LifeUnit.years.seconds, 1)
        let progress = min(max(elapsed / fullLife, 0), 1)
        let milestones = [0.25, 0.5, 0.75, 1.0]
        let nextMilestone = milestones.first(where: { $0 > progress }) ?? 1.0
        let previousMilestone = milestones.last(where: { $0 < nextMilestone }) ?? 0.0
        let segmentProgress = min(
            max((progress - previousMilestone) / max(nextMilestone - previousMilestone, 0.0001), 0),
            1)

        let milestoneDate = birthDate.addingTimeInterval(fullLife * nextMilestone)
        let remainingToMilestone = max(0, milestoneDate.timeIntervalSince(now))
        let years = Int(remainingToMilestone / LifeUnit.years.seconds)
        let months = Int(
            (remainingToMilestone.truncatingRemainder(dividingBy: LifeUnit.years.seconds))
                / LifeUnit.months.seconds)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("NEXT MILESTONE")
                    .font(.system(size: 12, weight: .bold, design: selectedTypography.bodyDesign))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.76))
                Spacer()
                Image(systemName: "flag.checkered")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(selectedTheme.topGlow.opacity(0.8))
                    .frame(width: 26, height: 26)
                    .background(selectedTheme.topGlow.opacity(0.15), in: Circle())
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(Int(nextMilestone * 100))%")
                    .font(.system(size: 38, weight: .black, design: selectedTypography.heroDesign))
                    .foregroundStyle(.white)
                    .shadow(color: selectedTheme.topGlow.opacity(0.2), radius: 10, x: 0, y: 2)
                Text("of lifetime")
                    .font(
                        .system(size: 17, weight: .semibold, design: selectedTypography.bodyDesign)
                    )
                    .foregroundStyle(.white.opacity(0.7))
            }

            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 12))
                    .foregroundStyle(selectedTheme.bottomGlow.opacity(0.8))
                Text(
                    "≈ \(years)y \(months)m left • \(milestoneDate.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.system(size: 13, weight: .medium, design: selectedTypography.bodyDesign))
                .foregroundStyle(.white.opacity(0.65))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.1))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [selectedTheme.topGlow, selectedTheme.bottomGlow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: selectedTheme.topGlow.opacity(0.5), radius: 6, x: 0, y: 0)
                        .frame(width: max(8, proxy.size.width * segmentProgress))
                }
            }
            .frame(height: 10)

            HStack {
                Text("\(Int(previousMilestone * 100))%")
                    .font(
                        .system(size: 10, weight: .semibold, design: selectedTypography.bodyDesign)
                    )
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                Text("\(Int(nextMilestone * 100))%")
                    .font(
                        .system(size: 10, weight: .semibold, design: selectedTypography.bodyDesign)
                    )
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [selectedTheme.topGlow.opacity(0.18), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    private var unitPicker: some View {
        HStack(spacing: 8) {
            ForEach(LifeUnit.allCases) { unit in
                let isSelected = unit == selectedUnit
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
                    Text(unit.shortTitle)
                        .font(
                            .system(size: 15, weight: .bold, design: selectedTypography.bodyDesign)
                        )
                        .foregroundStyle(
                            isSelected ? selectedTheme.selectedChipForeground : .white.opacity(0.7)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(selectedTheme.selectedChipBackground)
                                    .matchedGeometryEffect(
                                        id: "unit-chip-selection",
                                        in: unitChipSelectionAnimation)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.08))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: selectedUnitRaw)
    }

    private var settingsSheet: some View {
        NavigationStack {
            ZStack {
                background
                settingsReadabilityLayer

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        settingsHeader(title: "Settings")

                        if !lifetimeUnlocked {
                            Button {
                                pendingManualPaywallPresentation = true
                                showSettings = false
                                performSelectionHaptic()
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedTheme.topGlow.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(selectedTheme.topGlow)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Go Premium")
                                            .font(
                                                .system(
                                                    size: 17,
                                                    weight: .bold,
                                                    design: selectedTypography.bodyDesign)
                                            )
                                            .foregroundStyle(.white)
                                        Text("Unlock Lifetime Access")
                                            .font(
                                                .system(
                                                    size: 13,
                                                    weight: .medium,
                                                    design: selectedTypography.bodyDesign)
                                            )
                                            .foregroundStyle(.white.opacity(0.7))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.65))
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(.white.opacity(0.08))
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    selectedTheme.topGlow.opacity(0.34),
                                                    .white.opacity(0.12),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        settingsSectionTitle("Life Profile", icon: "person.crop.circle")
                        VStack(spacing: 0) {
                            HStack {
                                Text("Birth date")
                                    .foregroundStyle(.white)
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { birthDate },
                                        set: {
                                            birthDateTimestamp =
                                                min($0, Date()).timeIntervalSince1970
                                        }
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

                        settingsSectionTitle("Appearance", icon: "paintbrush")
                        VStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Color theme")
                                    .foregroundStyle(.white)
                                HStack(spacing: 12) {
                                    ForEach(ClockTheme.allCases) { theme in
                                        Button {
                                            clockThemeRaw = theme.rawValue
                                            performSelectionHaptic()
                                        } label: {
                                            VStack(spacing: 6) {
                                                ZStack {
                                                    Circle()
                                                        .fill(
                                                            LinearGradient(
                                                                colors: theme.ringColors,
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        )
                                                        .frame(width: 40, height: 40)
                                                    if theme == selectedTheme {
                                                        Circle()
                                                            .stroke(.white, lineWidth: 2.5)
                                                            .frame(width: 46, height: 46)
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 14, weight: .bold))
                                                            .foregroundStyle(.white)
                                                    }
                                                }
                                                Text(theme.title)
                                                    .font(
                                                        .system(
                                                            size: 11,
                                                            weight: theme == selectedTheme
                                                                ? .bold : .medium)
                                                    )
                                                    .foregroundStyle(
                                                        .white.opacity(
                                                            theme == selectedTheme ? 1 : 0.6))
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(16)

                            Divider().overlay(.white.opacity(0.18))

                            settingsMenuRow(title: "Typography", value: selectedTypography.title) {
                                ForEach(TypographyPreset.allCases) { style in
                                    Button(style.title) {
                                        typographyPresetRaw = style.rawValue
                                        performSelectionHaptic()
                                    }
                                }
                            }

                            Divider().overlay(.white.opacity(0.18))

                            settingsMenuRow(
                                title: "App icon",
                                value: AppIconChoice(rawValue: appIconChoiceRaw)?.title
                                    ?? AppIconChoice.primary.title
                            ) {
                                ForEach(AppIconChoice.allCases) { iconChoice in
                                    Button(iconChoice.title) {
                                        let oldValue = appIconChoiceRaw
                                        appIconChoiceRaw = iconChoice.rawValue
                                        applyAppIcon(from: oldValue, to: iconChoice.rawValue)
                                        performSelectionHaptic()
                                    }
                                }
                            }
                        }
                        .settingsCardStyle()

                        settingsSectionTitle("Interactions", icon: "hand.tap")
                        Toggle(isOn: $hapticsEnabled) {
                            Text("Haptics")
                                .foregroundStyle(.white)
                        }
                        .tint(selectedTheme.bottomGlow)
                        .padding(16)
                        .settingsCardStyle()

                        settingsSectionTitle("App", icon: "info.circle")
                        VStack(spacing: 0) {
                            Button {
                                hasCompletedOnboarding = false
                                pendingOnboardingRestart = true
                                showSettings = false
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
                    .font(
                        .system(size: 17, weight: .semibold, design: selectedTypography.bodyDesign)
                    )
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
                        text:
                            "Operator details, contact address, and responsible person information should be listed here."
                    )

                    legalBlock(
                        title: "Privacy",
                        text:
                            "LifeClock stores your birth date, display settings, and preferences locally on your device. No cloud sync is enabled by default."
                    )

                    legalBlock(
                        title: "Terms of Use",
                        text:
                            "All displayed values are estimations based on your inputs. LifeClock does not provide medical, legal, or financial advice."
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Policy Links")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Link(
                            "Privacy Policy",
                            destination: URL(string: "https://example.com/privacy")!)
                        Link(
                            "Terms & Conditions",
                            destination: URL(string: "https://example.com/terms")!)
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
                .shadow(color: selectedTheme.topGlow.opacity(0.3), radius: 6, x: 0, y: 0)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.25), selectedTheme.topGlow.opacity(0.15),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
    }

    private func statCard(title: String, value: String, icon: String, accentColor: Color = .white)
        -> some View
    {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 28, height: 28)
                    .background(accentColor.opacity(0.18), in: Circle())

                Text(title)
                    .font(
                        .system(size: 12, weight: .semibold, design: selectedTypography.bodyDesign)
                    )
                    .foregroundStyle(.white.opacity(0.75))
            }

            Text(value)
                .font(.system(size: 28, weight: .black, design: selectedTypography.heroDesign))
                .foregroundStyle(.white)
                .shadow(color: accentColor.opacity(0.2), radius: 8, x: 0, y: 2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [accentColor.opacity(0.2), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
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

    private func settingsSectionTitle(_ title: String, icon: String? = nil) -> some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(selectedTheme.topGlow.opacity(0.8))
            }
            Text(title)
                .font(.system(size: 17, weight: .bold, design: selectedTypography.bodyDesign))
                .foregroundStyle(.white.opacity(0.95))
        }
        .padding(.leading, 4)
    }

    private func settingsHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 48, weight: .heavy, design: selectedTypography.heroDesign))
            .foregroundStyle(.white)
            .shadow(color: selectedTheme.topGlow.opacity(0.2), radius: 16, x: 0, y: 4)
            .padding(.top, 6)
            .padding(.leading, 4)
    }

    private func settingsMenuRow<Options: View>(
        title: String, value: String, @ViewBuilder options: () -> Options
    ) -> some View {
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
                Color.black.opacity(0.2),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func formattedValue(_ value: Double, unit: LifeUnit) -> String {
        groupedIntegerString(Int(value.rounded()))
    }

    private func groupedIntegerString(_ value: Int) -> String {
        Self.dotGroupingFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private static let dotGroupingFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

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

    private func initializeTrialIfNeeded() {
        guard trialStartTimestamp <= 0 else { return }
        trialStartTimestamp = Date().timeIntervalSince1970
    }

    private func preloadLifetimeProduct() async {
        guard lifetimeProduct == nil else { return }
        do {
            lifetimeProduct = try await Product.products(for: [lifetimeProductID]).first
        } catch {
            paywallMessage = "Could not load purchase data. Please try again."
        }
    }

    private func refreshLifetimeEntitlement() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == lifetimeProductID {
                lifetimeUnlocked = true
                await transaction.finish()
                return
            }
        }
    }

    private func purchaseLifetime() async {
        guard !isPurchasingLifetime else { return }
        guard let product = lifetimeProduct else {
            await preloadLifetimeProduct()
            if lifetimeProduct == nil {
                paywallMessage = "Lifetime product unavailable."
            }
            return
        }

        isPurchasingLifetime = true
        defer { isPurchasingLifetime = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    lifetimeUnlocked = true
                    await transaction.finish()
                case .unverified:
                    paywallMessage = "Purchase could not be verified."
                }
            case .userCancelled:
                break
            case .pending:
                paywallMessage = "Purchase is pending approval."
            @unknown default:
                paywallMessage = "Unknown purchase result."
            }
        } catch {
            paywallMessage = "Purchase failed. Please try again."
        }
    }

    private func restorePurchases() async {
        guard !isRestoringPurchases else { return }
        isRestoringPurchases = true
        defer { isRestoringPurchases = false }

        do {
            try await AppStore.sync()
            await refreshLifetimeEntitlement()
            if !lifetimeUnlocked {
                paywallMessage = "No lifetime purchase found for this Apple ID."
            }
        } catch {
            paywallMessage = "Restore failed. Please try again."
        }
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
    var glowColor: Color = .orange

    @State private var pulsing = false

    private var tipPosition: CGPoint {
        let angle = Angle.degrees(360 * progress - 90)
        let radius: CGFloat = 48
        return CGPoint(
            x: 48 + radius * cos(CGFloat(angle.radians)),
            y: 48 + radius * sin(CGFloat(angle.radians))
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 10)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: colors + [colors.first ?? .white], center: .center),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: glowColor.opacity(0.45), radius: 8, x: 0, y: 0)

            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
                .shadow(color: glowColor.opacity(0.8), radius: pulsing ? 8 : 4)
                .scaleEffect(pulsing ? 1.3 : 1.0)
                .position(tipPosition)

            VStack(spacing: 1) {
                Text(progress.formatted(.percent.precision(.fractionLength(0))))
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("lived")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(width: 96, height: 96)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulsing = true
            }
        }
    }
}

private struct FlipModifier: ViewModifier {
    let angle: Double
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
            .opacity(abs(angle) > 89 ? 0 : 1)
    }
}

extension AnyTransition {
    static var flipForward: AnyTransition {
        .modifier(
            active: FlipModifier(angle: -90),
            identity: FlipModifier(angle: 0)
        )
    }
    static var flipBackward: AnyTransition {
        .modifier(
            active: FlipModifier(angle: 90),
            identity: FlipModifier(angle: 0)
        )
    }
}

extension View {
    fileprivate func settingsCardStyle() -> some View {
        self
            .background(
                .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
    }
}

#Preview {
    ContentView()
}
