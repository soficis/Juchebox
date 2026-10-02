import SwiftUI

struct OnboardingView: View {
    let accept: () -> Void

    @AppStorage(AppStorageKey.appLanguage) private var appLanguageRaw = AppLanguage.english.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .english
    }

    var body: some View {
        ZStack {
            // Socialist Realism Deep Crimson & Dark Red Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.18, green: 0.03, blue: 0.04),
                    Color(red: 0.05, green: 0.01, blue: 0.01)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Header Flag
                    DPRKFlagView()
                        .frame(height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppTheme.hairline, lineWidth: 1.5)
                        }
                        .padding(.top, 16)
                        .shadow(color: Color.black.opacity(0.6), radius: 10, x: 0, y: 5)


                    // Hero Section: Juchebox Vector Logo
                    VStack(spacing: 12) {
                        ZStack {
                            // Gold Record motif
                            Circle()
                                .stroke(AppTheme.secondaryText, lineWidth: 3)
                                .frame(width: 100, height: 100)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                                .overlay {
                                    // Vinyl Grooves
                                    Circle().stroke(AppTheme.secondaryText.opacity(0.3), lineWidth: 1).frame(width: 80, height: 80)
                                    Circle().stroke(AppTheme.secondaryText.opacity(0.3), lineWidth: 1).frame(width: 60, height: 60)
                                    Circle().stroke(AppTheme.secondaryText.opacity(0.3), lineWidth: 1).frame(width: 40, height: 40)
                                    Circle().fill(AppTheme.secondaryText).frame(width: 16, height: 16)
                                }
                            
                            // Red Star Overlay
                            StarShape()
                                .fill(AppTheme.accent)
                                .frame(width: 50, height: 50)
                                .overlay {
                                    StarShape()
                                        .stroke(AppTheme.warning, lineWidth: 2)
                                }
                                .shadow(color: AppTheme.accent.opacity(0.8), radius: 6, x: 0, y: 0)
                        }
                        .padding(.vertical, 8)

                        Text(t(.appName, language: appLanguage))
                            .font(.system(size: 38, weight: .black, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppTheme.secondaryText, AppTheme.warning, AppTheme.secondaryText],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.black, radius: 2, x: 2, y: 2)

                        Text(t(.subtitle, language: appLanguage))
                            .font(.system(.title3, design: .serif).weight(.bold))
                            .foregroundStyle(AppTheme.primaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Disclaimer Cards with socialist realism framing
                    VStack(spacing: 16) {
                        DisclaimerRow(
                            icon: "shield.fill",
                            title: t(.disclaimer1Title, language: appLanguage),
                            message: t(.disclaimer1Message, language: appLanguage),
                            lang: appLanguage
                        )

                        DisclaimerRow(
                            icon: "network",
                            title: t(.disclaimer2Title, language: appLanguage),
                            message: t(.disclaimer2Message, language: appLanguage),
                            lang: appLanguage
                        )

                        DisclaimerRow(
                            icon: "xmark.shield.fill",
                            title: t(.disclaimer3Title, language: appLanguage),
                            message: t(.disclaimer3Message, language: appLanguage),
                            lang: appLanguage
                        )

                        DisclaimerRow(
                            icon: "lock.fill",
                            title: t(.disclaimer4Title, language: appLanguage),
                            message: t(.disclaimer4Message, language: appLanguage),
                            lang: appLanguage
                        )
                    }

                    // Revolutionary Forward Button
                    Button(action: accept) {
                        HStack(spacing: 12) {
                            StarShape()
                                .fill(AppTheme.warning)
                                .frame(width: 18, height: 18)
                            
                            Text(t(.acceptButton, language: appLanguage))
                                .font(.system(.body, design: .serif).weight(.black))
                                .tracking(1.5)
                            
                            StarShape()
                                .fill(AppTheme.warning)
                                .frame(width: 18, height: 18)
                        }
                        .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .buttonStyle(.plain)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.accent, Color(red: 0.6, green: 0.08, blue: 0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppTheme.warning, lineWidth: 2)
                    }
                    .foregroundStyle(AppTheme.primaryText)
                    .shadow(color: AppTheme.accent.opacity(0.5), radius: 8, x: 0, y: 4)
                    .accessibilityIdentifier(AccessibilityID.onboardingAcceptButton)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: 600, alignment: .center)
            }
        }
    }
}

private struct DisclaimerRow: View {
    let icon: String
    let title: String
    let message: String
    let lang: AppLanguage

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.warning)
                .frame(width: 32, height: 32)
                .background(Circle().fill(AppTheme.accent.opacity(0.2)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.headline, design: .serif).weight(.bold))
                    .foregroundStyle(AppTheme.secondaryText)

                Text(message)
                    .font(.system(.body, design: .default))
                    .foregroundStyle(AppTheme.primaryText.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(AppTheme.surface.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 1.5)
        }
    }
}

struct DPRKFlagView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            let totalHeight: CGFloat = 36
            let blueH = h * (6 / totalHeight)
            let whiteH = h * (1 / totalHeight)
            let redH = h * (22 / totalHeight)
            
            ZStack(alignment: .leading) {
                // Background stripes
                VStack(spacing: 0) {
                    Color(red: 0.012, green: 0.282, blue: 0.612) // DPRK Blue
                        .frame(height: blueH)
                    Color.white
                        .frame(height: whiteH)
                    Color(red: 0.804, green: 0.125, blue: 0.153) // DPRK Red
                        .frame(height: redH)
                    Color.white
                        .frame(height: whiteH)
                    Color(red: 0.012, green: 0.282, blue: 0.612) // DPRK Blue
                        .frame(height: blueH)
                }
                
                // White circle + Red star
                let circleDiameter = h * (16 / totalHeight)
                let circleX = w * (24 / 72.0) - (circleDiameter / 2.0)
                
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: circleDiameter, height: circleDiameter)
                    
                    StarShape()
                        .fill(Color(red: 0.804, green: 0.125, blue: 0.153))
                        .frame(width: circleDiameter * 0.65, height: circleDiameter * 0.65)
                }
                .offset(x: circleX)
            }
        }
        .aspectRatio(2.0, contentMode: .fit)
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2.0
        let rc = r * 0.382 // inner radius proportion for perfect star
        
        for i in 0..<10 {
            let angle = CGFloat(i) * CGFloat.pi / 5.0 - CGFloat.pi / 2.0
            let radius = i % 2 == 0 ? r : rc
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}
