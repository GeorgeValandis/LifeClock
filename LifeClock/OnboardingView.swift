import SwiftUI

struct OnboardingView: View {
    @Binding var birthDateTimestamp: Double
    @Binding var selectedUnitRaw: String
    @Binding var lifeExpectancyYears: Double

    let completeAction: () -> Void

    @State private var currentStep = 0
    @State private var showBirthDatePicker = false
    @State private var glowAnimate = false
    @State private var appeared = false
    @State private var iconPulse = false
    @State private var selectedFeature: String? = nil

    private let accentGreen = Color(red: 0.42, green: 0.98, blue: 0.76)
    private let accentOrange = Color(red: 1.0, green: 0.60, blue: 0.24)
    private let accentTeal = Color(red: 0.20, green: 0.88, blue: 0.90)
    private let totalSteps = 4

    private var birthDateBinding: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: birthDateTimestamp) },
            set: { birthDateTimestamp = min($0, Date()).timeIntervalSince1970 }
        )
    }

    private var selectedUnit: LifeUnit {
        LifeUnit(rawValue: selectedUnitRaw) ?? .days
    }

    private var elapsedSeconds: TimeInterval {
        max(0, Date().timeIntervalSince(birthDateBinding.wrappedValue))
    }

    private var remainingSeconds: TimeInterval {
        max(0, (lifeExpectancyYears * LifeUnit.years.seconds) - elapsedSeconds)
    }

    private var ageYearsText: String {
        let years = Int((elapsedSeconds / LifeUnit.years.seconds).rounded(.down))
        return "\(years) years old"
    }

    private var remainingSelectedUnitText: String {
        let value = Int((remainingSeconds / selectedUnit.seconds).rounded(.down))
        return "\(value.formatted(.number.grouping(.automatic))) \(selectedUnit.title.lowercased())"
    }

    private struct StepInfo {
        let icon: String
        let title: String
        let subtitle: String
        let accent: Color
    }

    private var steps: [StepInfo] {
        [
            StepInfo(
                icon: "hourglass.circle.fill", title: "Welcome", subtitle: "Your life, visualized",
                accent: accentTeal),
            StepInfo(
                icon: "birthday.cake.fill", title: "Birthday", subtitle: "When were you born?",
                accent: accentTeal),
            StepInfo(
                icon: "heart.circle.fill", title: "Expectancy",
                subtitle: "How long do you plan to live?", accent: accentOrange),
            StepInfo(
                icon: "timer.circle.fill", title: "Unit", subtitle: "How to count your time?",
                accent: accentGreen),
        ]
    }

    var body: some View {
        ZStack {
            backgroundLayer
            contentLayer
        }
        .interactiveDismissDisabled()
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                glowAnimate = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                iconPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.82)) {
                    appeared = true
                }
            }
        }
        .sheet(isPresented: $showBirthDatePicker) {
            birthDateSheet
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color(red: 0.02, green: 0.04, blue: 0.10)
                .ignoresSafeArea()

            Circle()
                .fill(steps[currentStep].accent.opacity(0.12))
                .frame(width: 300)
                .blur(radius: 80)
                .offset(x: glowAnimate ? -60 : 60, y: glowAnimate ? -200 : -160)

            Circle()
                .fill(accentOrange.opacity(0.08))
                .frame(width: 250)
                .blur(radius: 60)
                .offset(x: glowAnimate ? 80 : -20, y: glowAnimate ? 260 : 200)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: currentStep)
    }

    // MARK: - Content

    private var contentLayer: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)

            stepIcon
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -20)

            Spacer().frame(height: 20)

            titleBlock
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

            Spacer().frame(height: 32)

            stepContent
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Spacer()

            dotIndicator
                .padding(.bottom, 20)

            bottomButton
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: 8)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Step Icon

    private var stepIcon: some View {
        let step = steps[currentStep]
        return ZStack {
            Circle()
                .fill(step.accent.opacity(0.1))
                .frame(width: 100, height: 100)
                .scaleEffect(iconPulse ? 1.08 : 1.0)

            Circle()
                .fill(step.accent.opacity(0.06))
                .frame(width: 130, height: 130)
                .scaleEffect(iconPulse ? 1.12 : 1.0)

            Image(systemName: step.icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [step.accent, step.accent.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: step.accent.opacity(0.4), radius: 20, x: 0, y: 4)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
    }

    // MARK: - Title

    private var titleBlock: some View {
        let step = steps[currentStep]
        return VStack(spacing: 8) {
            Text(step.title)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(step.subtitle)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
        }
        .multilineTextAlignment(.center)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: currentStep)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0: welcomeContent
        case 1: birthDateContent
        case 2: expectancyContent
        case 3: unitContent
        default: EmptyView()
        }
    }

    // MARK: Step 0 – Welcome

    private var welcomeContent: some View {
        VStack(spacing: 14) {
            featureRow(
                id: "counter", icon: "clock.arrow.circlepath", title: "Live Counter",
                description: "Watch your remaining time tick in real-time", accent: accentTeal)
            featureRow(
                id: "grid", icon: "square.grid.3x3.fill", title: "Life Grid",
                description: "See your entire life as a beautiful mosaic", accent: accentGreen)
            featureRow(
                id: "widget", icon: "widget.small", title: "Widgets",
                description: "Glanceable stats right on your home screen", accent: accentOrange)
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)))
    }

    private func featureRow(
        id: String, icon: String, title: String, description: String, accent: Color
    )
        -> some View
    {
        let isSelected = selectedFeature == id
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedFeature = selectedFeature == id ? nil : id
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 44, height: 44)
                    .background(
                        accent.opacity(isSelected ? 0.25 : 0.12),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(description)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(isSelected ? 0.7 : 0.5))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(accent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.1) : .white.opacity(0.05))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? accent.opacity(0.4) : .white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 1)
            }
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(color: isSelected ? accent.opacity(0.25) : .clear, radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSelected)
    }

    // MARK: Step 1 – Birth Date

    private var birthDateContent: some View {
        VStack(spacing: 16) {
            Button {
                showBirthDatePicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accentTeal)

                    Text(birthDateBinding.wrappedValue.formatted(date: .long, time: .omitted))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(16)
                .background(
                    .white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentTeal.opacity(0.2), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accentTeal.opacity(0.7))
                Text("You are \(ageYearsText)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)))
    }

    // MARK: Step 2 – Life Expectancy

    private var expectancyContent: some View {
        VStack(spacing: 20) {
            Text("\(Int(lifeExpectancyYears))")
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .shadow(color: accentOrange.opacity(0.25), radius: 16, x: 0, y: 4)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: lifeExpectancyYears)

            Text("years")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .offset(y: -10)

            Slider(value: $lifeExpectancyYears, in: 50...120, step: 1)
                .tint(accentOrange)
                .padding(.horizontal, 8)

            HStack(spacing: 10) {
                ForEach([75, 80, 85, 90, 100], id: \.self) { years in
                    let isSelected = Int(lifeExpectancyYears) == years
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            lifeExpectancyYears = Double(years)
                        }
                    } label: {
                        Text("\(years)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? .black : .white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? accentOrange : .white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
                }
            }
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)))
    }

    // MARK: Step 3 – Default Unit

    private var unitContent: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(LifeUnit.allCases) { unit in
                    let isSelected = selectedUnit == unit
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedUnitRaw = unit.rawValue
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(unit.title)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(isSelected ? .black : .white)

                            if isSelected {
                                Text(remainingSelectedUnitText)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.black.opacity(0.6))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? accentGreen : .white.opacity(0.07))
                        )
                        .overlay {
                            if !isSelected {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            }
                        }
                        .shadow(
                            color: isSelected ? accentGreen.opacity(0.3) : .clear, radius: 8, x: 0,
                            y: 3)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
                }
            }
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)))
    }

    // MARK: - Dot Indicator

    private var dotIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index == currentStep ? steps[currentStep].accent : .white.opacity(0.2))
                    .frame(width: index == currentStep ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentStep)
            }
        }
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        currentStep -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(.white.opacity(0.1), in: Circle())
                        .overlay {
                            Circle().stroke(.white.opacity(0.12), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }

            Button {
                if currentStep == totalSteps - 1 {
                    completeAction()
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        currentStep += 1
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentStep == totalSteps - 1 ? "Start LifeClock" : "Continue")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Image(systemName: currentStep == totalSteps - 1 ? "checkmark" : "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [accentGreen, accentTeal],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .shadow(color: accentGreen.opacity(0.3), radius: 16, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: currentStep)
    }

    // MARK: - Birth Date Sheet

    private var birthDateSheet: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.06, blue: 0.14),
                    Color(red: 0.05, green: 0.10, blue: 0.20),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "birthday.cake.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(accentTeal)
                    Text("Pick your birthday")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                DatePicker(
                    "",
                    selection: birthDateBinding,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(accentTeal)
                .colorScheme(.dark)

                HStack {
                    Spacer()
                    Button("Done") {
                        showBirthDatePicker = false
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [accentGreen, accentTeal],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .padding(.top, 32)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
