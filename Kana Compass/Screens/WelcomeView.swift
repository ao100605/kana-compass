import SwiftUI
import UIKit

private struct WelcomeSlide: Identifiable {
    let id = UUID()
    let icon: String
    let eyebrow: String?
    let title: String
    let body: String
    let bullets: [(icon: String, title: String, subtitle: String)]?
    let showsKeyboardImage: Bool
    let showsCompassDiagram: Bool
}

private let welcomeSlides: [WelcomeSlide] = [
    WelcomeSlide(
        icon: "safari",
        eyebrow: nil,
        title: "Welcome to Kana Compass",
        body: "Learn to type Japanese FAST using the 12-key kana smartphone keyboard! \n\nUse flick gestures to type Japanese characters directly rather than spelling them out with a full QWERTY romaji keyboard.",
        bullets: nil,
        showsKeyboardImage: true,
        showsCompassDiagram: false
    ),
    WelcomeSlide(
        icon: "hand.draw",
        eyebrow: "How it works",
        title: "Flick to reveal kana",
        body: "Each row of kana lives on one tile. Tap the center (a-row), or flick left (i-row), up (u-row), right (e-row), or down (o-row) to find the kana you need.",
        bullets: nil,
        showsKeyboardImage: false,
        showsCompassDiagram: true
    ),
    WelcomeSlide(
        icon: "square.grid.2x2",
        eyebrow: "Four ways to practice",
        title: "Pick your mode",
        body: "Switch between modes anytime from the menu in the top corner.",
        bullets: [
            ("safari", "Compass Practice", "Flick gesture drills"),
            ("square.grid.3x3.fill", "Keyboard Grid", "Keyboard grid drills"),
            ("text.bubble", "Typing Practice", "Type full words or sentences"),
            ("stopwatch", "Time Attack", "Beat the clock")
        ],
        showsKeyboardImage: false,
        showsCompassDiagram: false
    ),
    WelcomeSlide(
        icon: "slider.horizontal.3",
        eyebrow: "Make it yours",
        title: "Customize your practice",
        body: "Choose the practice combination that best suits your learning style.",
        bullets: [
            ("safari", "Select Specific Rows", "Choose which rows to drill"),
            ("square.grid.3x3.fill", "Training vs Practice", "Switch between training (labels shown) and practice (blind) stages"),
            ("text.bubble", "Toggle Secondary Marks", "Toggle Dakuten, Handakuten, and Small Kana on or off")
        ],
        showsKeyboardImage: false,
        showsCompassDiagram: false
    )
]

struct WelcomeView: View {
    var onFinish: () -> Void

    @State private var currentSlide = 0

    private var isLastSlide: Bool { currentSlide == welcomeSlides.count - 1 }

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                skipBar

                TabView(selection: $currentSlide) {
                    ForEach(Array(welcomeSlides.enumerated()), id: \.element.id) { index, slide in
                        WelcomeSlideView(slide: slide)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: currentSlide)

                pageDots

                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if currentSlide > 0 {
                backButton
            }
            actionButton
        }
    }

    private var backButton: some View {
        Button {
            withAnimation {
                currentSlide -= 1
            }
        } label: {
            Text("Back")
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.thinMaterial)
                )
        }
        .buttonStyle(.plain)
    }

    private var skipBar: some View {
        HStack {
            Spacer()
            if !isLastSlide {
                Button("Skip") {
                    onFinish()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
        .frame(height: 24)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(welcomeSlides.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentSlide ? Color.accentColor : Color(.tertiarySystemFill))
                    .frame(width: index == currentSlide ? 20 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentSlide)
            }
        }
    }

    private var actionButton: some View {
        Button {
            if isLastSlide {
                onFinish()
            } else {
                withAnimation {
                    currentSlide += 1
                }
            }
        } label: {
            Text(isLastSlide ? "Get Started" : "Next")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.accentColor)
                )
        }
        .buttonStyle(.plain)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(.systemBackground), Color.accentColor.opacity(0.08)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

private struct WelcomeSlideView: View {
    let slide: WelcomeSlide

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                iconTile

                if let eyebrow = slide.eyebrow {
                    Text(eyebrow.uppercased())
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }

                Text(slide.title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)

                Text(slide.body)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if slide.showsKeyboardImage {
                    HStack {
                        Spacer()
                        Image("keyboardImage")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                        Spacer()
                    }
                    .padding(.top, 10)
                }

                if slide.showsCompassDiagram {
                    HStack {
                        Spacer()
                        CompassDiagramView()
                        Spacer()
                    }
                    .padding(.top, 30)
                }

                if let bullets = slide.bullets {
                    VStack(spacing: 10) {
                        ForEach(bullets, id: \.title) { bullet in
                            bulletRow(bullet)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var iconTile: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.accentColor.opacity(0.15))
            .frame(width: 56, height: 56)
            .overlay(
                Image(systemName: slide.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            )
    }

    private func bulletRow(_ bullet: (icon: String, title: String, subtitle: String)) -> some View {
        HStack(spacing: 12) {
            Image(systemName: bullet.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.accentColor.opacity(0.12)))

            VStack(alignment: .leading, spacing: 1) {
                Text(bullet.title)
                    .font(.body.weight(.semibold))
                Text(bullet.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

private struct CompassDiagramView: View {
    private let tapThreshold: CGFloat = 20

    @State private var dragOffset: CGSize = .zero
    @State private var flashDirection: Direction? = nil
    @State private var hintMessage: String = "Try flicking the center tile"

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 10) {
                arrowTile(.up, systemName: "u.square")
                HStack(spacing: 10) {
                    arrowTile(.left, systemName: "i.square")
                    centerTile
                    arrowTile(.right, systemName: "e.square")
                }
                arrowTile(.down, systemName: "o.square")
            }

            Text(hintMessage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .id(hintMessage)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: hintMessage)
        }
    }

    private func arrowTile(_ direction: Direction, systemName: String) -> some View {
        let isFlashing = flashDirection == direction

        return RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(isFlashing ? Color.accentColor : Color.accentColor.opacity(0.15))
            .frame(width: 64, height: 64)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(isFlashing ? .white : Color.accentColor)
            )
            .scaleEffect(isFlashing ? 1.08 : 1.0)
    }

    private var centerTile: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(.secondarySystemFill))
            .frame(width: 64, height: 64)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(flashDirection == .center ? Color.accentColor : Color.accentColor.opacity(0.35), lineWidth: flashDirection == .center ? 3 : 1.5)
            )
            .overlay(
                Image(systemName: "a.square")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            )
            .offset(dragOffset)
            .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                let direction: Direction

                if abs(dx) < tapThreshold && abs(dy) < tapThreshold {
                    direction = .center
                } else if abs(dx) > abs(dy) {
                    direction = dx > 0 ? .right : .left
                } else {
                    direction = dy > 0 ? .down : .up
                }

                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    dragOffset = .zero
                }

                withAnimation(.easeOut(duration: 0.25)) {
                    flashDirection = direction
                }

                UIImpactFeedbackGenerator(style: .light).impactOccurred()

                hintMessage = message(for: direction)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    flashDirection = nil
                }
            }
    }

    private func message(for direction: Direction) -> String {
        switch direction {
        case .center: return "That's a center tap (a-row)"
        case .left: return "That's a left flick (i-row)"
        case .up: return "That's an up flick (u-row)"
        case .right: return "That's a right flick (e-row)"
        case .down: return "That's a down flick (o-row)"
        }
    }
}

#Preview {
    WelcomeView(onFinish: {})
}
