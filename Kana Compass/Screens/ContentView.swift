//
//  ContentView.swift
//  Kana Compass
//
//  Created by Akari Oh on 8/28/2026.
//

import SwiftUI

enum PracticeScreen: String, CaseIterable, Identifiable, Equatable {
    case compass
    case keyboardGrid
    case typing
    case timeAttack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compass: return "Compass Practice"
        case .keyboardGrid: return "Keyboard Grid"
        case .typing: return "Typing Practice"
        case .timeAttack: return "Time Attack"
        }
    }

    var icon: String {
        switch self {
        case .compass: return "safari"
        case .keyboardGrid: return "square.grid.3x3.fill"
        case .typing: return "text.bubble"
        case .timeAttack: return "stopwatch"
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @State private var selectedScreen: PracticeScreen = {
        if let stored = UserDefaults.standard.string(forKey: "selectedScreen"),
           let screen = PracticeScreen(rawValue: stored) {
            return screen
        }
        return .compass
    }()

    var body: some View {
        GeometryReader { geo in
            let scale = layoutScale(for: geo.size)

            ZStack(alignment: .top) {
                backgroundGradient

                VStack(spacing: 10 * scale) {
                    topBar

                    VStack(spacing: 10 * scale) {
                        switch selectedScreen {
                        case .typing:
                            TypingContentToggleView(viewModel: viewModel)
                            SecondaryMarksToggleView(viewModel: viewModel)
                        case .timeAttack:
                            TimeAttackDurationToggleView(viewModel: viewModel)
                        case .compass, .keyboardGrid:
                            RowSelectionView(viewModel: viewModel)
                        }
                        if selectedScreen != .timeAttack {
                            StageToggleView(viewModel: viewModel)
                        }
                    }
                    .padding(12 * scale)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.thinMaterial)
                    )
                    .padding(.horizontal, 20)

                    Spacer(minLength: 0)
                    screenContent(scale: scale)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: selectedScreen)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onChange(of: selectedScreen) {
            UserDefaults.standard.set(selectedScreen.rawValue, forKey: "selectedScreen")
        }
    }

    @ViewBuilder
    private func screenContent(scale: CGFloat) -> some View {
        switch selectedScreen {
        case .compass:
            KanaCompassView(viewModel: viewModel, scale: scale)
        case .keyboardGrid:
            KanaKeyboardGridView(viewModel: viewModel, scale: scale)
        case .typing:
            TypingPracticeView(viewModel: viewModel, scale: scale)
        case .timeAttack:
            TimeAttackView(viewModel: viewModel, scale: scale)
        }
    }

    private var topBar: some View {
        HStack {
            header
            Spacer()
            menuButton
        }
        .padding(.horizontal, 20)
    }

    private var menuButton: some View {
        Menu {
            ForEach(PracticeScreen.allCases) { screen in
                Button {
                    selectedScreen = screen
                } label: {
                    Label(screen.title, systemImage: screen.icon)
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(.thinMaterial))
        }
    }

    private func layoutScale(for size: CGSize) -> CGFloat {
        let widthScale = size.width / 390
        let heightScale = size.height / 720
        return min(1.05, max(0.68, min(widthScale, heightScale)))
    }

    private var header: some View {
        Text("Kana Compass")
            .font(.system(size: 28, weight: .heavy, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.top, 6)
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

#Preview {
    ContentView()
}
