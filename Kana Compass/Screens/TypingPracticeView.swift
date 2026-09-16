import SwiftUI

struct TypingPracticeView: View {
    @ObservedObject var viewModel: PracticeViewModel
    var scale: CGFloat = 1.0

    var body: some View {
        TypingInteractionView(viewModel: viewModel, scale: scale, stage: viewModel.stage)
            .padding(.vertical, 22 * scale)
            .padding(.horizontal, 24 * scale)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
            )
            .padding(.horizontal, 20)
    }
}

// The ghost-text reveal, direction hint, and keyboard grid — the core
// typing-practice mechanic shared by the Typing Practice screen and the
// Time Attack screen, which just wraps this in its own scoring chrome.
struct TypingInteractionView: View {
    @ObservedObject var viewModel: PracticeViewModel
    var scale: CGFloat = 1.0
    var stage: PracticeStage

    var body: some View {
        let target = viewModel.currentTypingTarget ?? (rowKey: "あ", direction: .center)

        VStack(spacing: 18 * scale) {
            ghostText
            directionHint

            KeyboardGridContent(
                viewModel: viewModel,
                scale: scale,
                stage: stage,
                targetRowKey: target.rowKey,
                targetDirection: target.direction,
                flicksSuspended: viewModel.awaitingMarkKey,
                markKey: (viewModel.isTimeAttackRunning || viewModel.includeSecondaryMarks) ? MarkKeyState(
                    isEnabled: viewModel.awaitingMarkKey,
                    onPress: { viewModel.submitMarkKeyPress() }
                ) : nil,
                onResult: { _, _, isCorrect in
                    viewModel.submitTypingAttempt(isCorrect: isCorrect)
                }
            )
            .allowsHitTesting(!viewModel.isTypingComplete)
        }
    }

    private var ghostText: some View {
        HStack(spacing: 4 * scale) {
            ForEach(Array(viewModel.typingText.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.system(size: 34 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(colorForCharacter(at: index))
                    .scaleEffect(index < viewModel.typedCount ? 1.0 : 0.92)
            }

            if viewModel.isTypingComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28 * scale, weight: .bold))
                    .foregroundStyle(Color.green)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: viewModel.typedCount)
        .frame(minHeight: 48 * scale)
    }

    private func colorForCharacter(at index: Int) -> Color {
        guard index < viewModel.typedCount else { return Color.secondary.opacity(0.35) }
        return viewModel.isTypingComplete ? Color.green : Color.accentColor
    }

    private var directionHint: some View {
        let target = viewModel.currentTypingTarget
        let text: String
        let symbol: String

        if viewModel.awaitingMarkKey {
            text = "Now press the marks key"
            symbol = "asterisk.circle"
        } else {
            text = target.map { directionLabel(for: $0.direction) } ?? " "
            symbol = target.map { symbolName(for: $0.direction) } ?? "questionmark.circle"
        }

        return Label(text, systemImage: symbol)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .opacity(stage == .training && !viewModel.isTypingComplete ? 1 : 0)
    }

    private func directionLabel(for direction: Direction) -> String {
        switch direction {
        case .center: return "Tap the center"
        case .up: return "Flick upwards"
        case .down: return "Flick downwards"
        case .left: return "Flick leftwards"
        case .right: return "Flick rightwards"
        }
    }

    private func symbolName(for direction: Direction) -> String {
        switch direction {
        case .center: return "hand.tap.fill"
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        }
    }
}

struct TypingContentToggleView: View {
    @ObservedObject var viewModel: PracticeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Practice Content")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            Picker("Content", selection: Binding(
                get: { viewModel.typingContentType },
                set: { viewModel.selectTypingContent($0) }
            )) {
                ForEach(TypingContentType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

struct SecondaryMarksToggleView: View {
    @ObservedObject var viewModel: PracticeViewModel

    var body: some View {
        Toggle(isOn: Binding(
            get: { viewModel.includeSecondaryMarks },
            set: { viewModel.setIncludeSecondaryMarks($0) }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Secondary Marks")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Dakuten/Handakuten/Small Kana")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.8))
            }
        }
        .tint(Color.accentColor)
        .padding(.horizontal, 4)
    }
}
