import SwiftUI

struct OnboardingView: View {
    @Binding var birthDateTimestamp: Double
    @Binding var selectedUnitRaw: String
    @Binding var lifeExpectancyYears: Double

    let completeAction: () -> Void

    @State private var currentStep = 0
    @State private var showBirthDatePicker = false
    @State private var glowAnimate = false
    @State private var contentAppeared = false

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

    private var progressRatio: Double {
        Double(currentStep + 1) / Double(totalSteps)
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
        return "\(value.formatted(.number.grouping(.automatic))) \(selectedUnit.title.lowercased()) left"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.06, blue: 0.14),
                    Color(red: 0.04, green: 0.14, blue: 0.26),
                    Color(red: 0.12, green: 0.07, blue: 0.04),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ZStack {
                Circle()
                    .fill(accentTeal.opacity(0.18))
                    .frame(width: 270)
                    .blur(radius: 70)
                    .offset(x: glowAnimate ? -90 : -30, y: glowAnimate ? -320 : -200)
                Circle()
                    .fill(accentOrange.opacity(0.14))
                    .frame(width: 340)
                    .blur(radius: 75)
                    .offset(x: glowAnimate ? 120 : 40, y: glowAnimate ? 320 : 220)
            }
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                onboardingHeader
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 12)

                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    birthDateStep.tag(1)
                    lifeExpectancyStep.tag(2)
                    defaultUnitStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: currentStep)

                controls
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 16)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
        }
        .interactiveDismissDisabled()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                glowAnimate = true
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.84)) {
                contentAppeared = true
            }
        }
        .sheet(isPresented: $showBirthDatePicker) {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.08, blue: 0.16),
                        Color(red: 0.06, green: 0.12, blue: 0.22),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "birthday.cake.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(accentTeal)
                        Text("Birth date")
                            .font(.system(size: 24, weight: .black, design: .rounded))
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
                        .padding(.horizontal, 20)
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
                .padding(24)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var onboardingHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LIFECLOCK ONBOARDING")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.68))
                Spacer()
                Text("Step \(currentStep + 1) / \(totalSteps)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.16))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accentGreen, accentTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * progressRatio)
                }
            }
            .frame(height: 8)
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            if currentStep > 0 {
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                        currentStep -= 1
                    }
                } label: {
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.white.opacity(0.14))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.white.opacity(0.14), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }

            Button {
                if currentStep == totalSteps - 1 {
                    completeAction()
                } else {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                        currentStep += 1
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentStep == totalSteps - 1 ? "Enter LifeClock" : "Continue")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Image(systemName: currentStep == totalSteps - 1 ? "checkmark" : "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [accentGreen, accentTeal],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .shadow(color: accentGreen.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
    }

    private var welcomeStep: some View {
        onboardingStep(icon: "hourglass.circle.fill", title: "Welcome to LifeClock", accent: accentTeal) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Every second counts. Set up your timeline now and start with a clear visual of your lifetime.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.84))

                HStack(spacing: 10) {
                    previewPill(title: "Counter", value: "Live")
                    previewPill(title: "Grid", value: "Visual")
                    previewPill(title: "Widget", value: "Ready")
                }

                Text("Tap to continue")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                currentStep = min(totalSteps - 1, 1)
            }
        }
    }

    private var birthDateStep: some View {
        onboardingStep(icon: "birthday.cake.fill", title: "Pick your birth date", accent: accentTeal) {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    showBirthDatePicker = true
                } label: {
                    HStack {
                        Text(birthDateBinding.wrappedValue.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(accentTeal)
                        Spacer()
                        Image(systemName: "calendar")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.white.opacity(0.11))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)

                Text(ageYearsText)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
    }

    private var lifeExpectancyStep: some View {
        onboardingStep(icon: "heart.text.clipboard.fill", title: "Choose life expectancy", accent: accentOrange) {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(Int(lifeExpectancyYears)) years")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                Slider(value: $lifeExpectancyYears, in: 50...120, step: 1)
                    .tint(accentOrange)

                HStack(spacing: 8) {
                    quickExpectancyButton(80)
                    quickExpectancyButton(90)
                    quickExpectancyButton(100)
                }
            }
        }
    }

    private var defaultUnitStep: some View {
        onboardingStep(icon: "gauge.open.with.lines.needle.33percent.and.arrowtriangle", title: "Select default unit", accent: accentGreen) {
            VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(LifeUnit.allCases) { unit in
                            let isSelected = selectedUnit == unit
                            Button {
                                selectedUnitRaw = unit.rawValue
                            } label: {
                                Text(unit.title)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(isSelected ? .black : .white.opacity(0.9))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(isSelected ? accentGreen : .white.opacity(0.12))
                                    )
                                    .overlay {
                                        if !isSelected {
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(.white.opacity(0.15), lineWidth: 1)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Text("Preview: \(remainingSelectedUnitText)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
    }

    private func previewPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.1))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }

    private func quickExpectancyButton(_ years: Int) -> some View {
        Button {
            lifeExpectancyYears = Double(years)
        } label: {
            Text("\(years)y")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.12))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func onboardingStep<Content: View>(
        icon: String,
        title: String,
        accent: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accent)
                    .frame(width: 30, height: 30)
                    .background(
                        accent.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()
            }

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [accent.opacity(0.25), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .foregroundStyle(.white)
    }
}
