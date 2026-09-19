import SwiftUI
import UIKit

// Configuration for the optional bottom-left dakuten/handakuten/small-kana
// key. Only Typing Practice passes this in; the standalone Keyboard Grid
// screen leaves it nil and gets the plain placeholder it always had.
struct MarkKeyState {
    var isEnabled: Bool
    var onPress: () -> Bool
}

// Just the interactive 3x4 flick-keyboard grid, with no card chrome of its
// own, so it can be embedded either in the standalone Keyboard Grid screen
// (wrapped in KanaKeyboardGridView below) or inside the Typing Practice
// screen alongside its progressive-reveal text.
struct KeyboardGridContent: View {
    @ObservedObject var viewModel: PracticeViewModel
    var scale: CGFloat = 1.0
    var stage: PracticeStage
    var targetRowKey: String
    var targetDirection: Direction
    var flicksSuspended: Bool = false
    var markKey: MarkKeyState? = nil
    var onResult: (String, Direction, Bool) -> Void = { _, _, _ in }

    private var keyWidth: CGFloat { 100 * scale }
    private var keyHeight: CGFloat { 54 * scale }
    private var gap: CGFloat { 8 * scale }
    private let tapThreshold: CGFloat = 20

    @State private var activeKey: String? = nil
    @State private var activeDragOffset: CGSize = .zero
    @State private var flashCorrect: Bool? = nil
    @State private var shakeTrigger: CGFloat = 0

    @State private var markKeyFlash: Bool? = nil
    @State private var markKeyShake: CGFloat = 0

    var body: some View {
        VStack(spacing: gap) {
            ForEach(0..<keyboardLayout.count, id: \.self) { rowIndex in
                HStack(spacing: gap) {
                    ForEach(0..<keyboardLayout[rowIndex].count, id: \.self) { colIndex in
                        key(for: keyboardLayout[rowIndex][colIndex], row: rowIndex, col: colIndex)
                    }
                }
            }
        }
        // Stopping Time Attack mid-drag never fires a key's own onEnded (the
        // finger is still down), so its drag/flash state would otherwise
        // stay frozen wherever it was. Force every key back to rest here.
        .onChange(of: viewModel.isTimeAttackRunning) {
            guard !viewModel.isTimeAttackRunning else { return }
            activeKey = nil
            activeDragOffset = .zero
            flashCorrect = nil
            shakeTrigger = 0
            markKeyFlash = nil
            markKeyShake = 0
        }
    }

    @ViewBuilder
    private func key(for rowKey: String?, row: Int, col: Int) -> some View {
        if let rowKey {
            let isActive = activeKey == rowKey
            keyLabel(rowKey: rowKey, isActive: isActive)
                .offset(isActive ? activeDragOffset : .zero)
                .modifier(ShakeEffect(animatableData: isActive ? shakeTrigger : 0))
                .gesture(dragGesture(for: rowKey))
        } else if row == 3, col == 0, let markKey {
            markKeyView(state: markKey)
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.tertiarySystemFill).opacity(0.4))
                .frame(width: keyWidth, height: keyHeight)
        }
    }

    private func markKeyView(state: MarkKeyState) -> some View {
        let isFlashing = markKeyFlash != nil
        let isGlowing = !isFlashing && state.isEnabled && stage == .training

        return Text("゛゜小")
            .font(.system(size: 18 * scale, weight: .semibold, design: .rounded))
            .frame(width: keyWidth, height: keyHeight)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(markKeyBackground(isFlashing: isFlashing, isGlowing: isGlowing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isGlowing ? Color.accentColor.opacity(0.9) : Color.accentColor.opacity(0.25),
                        lineWidth: isGlowing ? 2.5 : 1
                    )
            )
            .foregroundStyle(isFlashing ? .white : Color.accentColor)
            .shadow(
                color: isGlowing ? Color.accentColor.opacity(0.55) : .black.opacity(0.08),
                radius: isGlowing ? 10 : 5,
                y: isGlowing ? 0 : 2
            )
            .scaleEffect(isFlashing ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.25), value: isGlowing)
            .modifier(ShakeEffect(animatableData: markKeyShake))
            .gesture(markKeyGesture(state: state))
    }

    private func markKeyBackground(isFlashing: Bool, isGlowing: Bool) -> Color {
        if isFlashing, let markKeyFlash {
            return markKeyFlash ? Color.green : Color.red
        }
        return Color.accentColor.opacity(isGlowing ? 0.3 : 0.15)
    }

    private func markKeyGesture(state: MarkKeyState) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onEnded { _ in
                let isCorrect = state.onPress()

                withAnimation(.easeOut(duration: 0.25)) {
                    markKeyFlash = isCorrect
                }
                if !isCorrect {
                    withAnimation(.linear(duration: 0.4)) {
                        markKeyShake += 1
                    }
                }

                UINotificationFeedbackGenerator().notificationOccurred(isCorrect ? .success : .error)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    markKeyFlash = nil
                }
            }
    }

    private func keyLabel(rowKey: String, isActive: Bool) -> some View {
        let row = kanaRows[rowKey]
        let isFlashing = isActive && flashCorrect != nil
        let isGlowing = !isFlashing && stage == .training && rowKey == targetRowKey

        return Text(row?.center ?? "")
            .font(.system(size: 22 * scale, weight: .semibold, design: .rounded))
            .frame(width: keyWidth, height: keyHeight)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(keyBackground(isFlashing: isFlashing, isGlowing: isGlowing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isGlowing ? Color.accentColor.opacity(0.9) : Color.accentColor.opacity(0.25),
                        lineWidth: isGlowing ? 2.5 : 1
                    )
            )
            .foregroundStyle(isFlashing ? .white : Color.accentColor)
            .shadow(
                color: isGlowing ? Color.accentColor.opacity(0.55) : .black.opacity(0.08),
                radius: isGlowing ? 10 : 5,
                y: isGlowing ? 0 : 2
            )
            .scaleEffect(isFlashing ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 0.25), value: isGlowing)
    }

    private func keyBackground(isFlashing: Bool, isGlowing: Bool) -> Color {
        if isFlashing, let flashCorrect {
            return flashCorrect ? Color.green : Color.red
        }
        return Color.accentColor.opacity(isGlowing ? 0.3 : 0.15)
    }

    private func dragGesture(for rowKey: String) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                activeKey = rowKey
                activeDragOffset = value.translation
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

                let isCorrect = !flicksSuspended && rowKey == targetRowKey && direction == targetDirection

                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    activeDragOffset = .zero
                }

                withAnimation(.easeOut(duration: 0.25)) {
                    flashCorrect = isCorrect
                }

                if !isCorrect {
                    withAnimation(.linear(duration: 0.4)) {
                        shakeTrigger += 1
                    }
                }

                UINotificationFeedbackGenerator().notificationOccurred(isCorrect ? .success : .error)

                onResult(rowKey, direction, isCorrect)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    activeKey = nil
                    flashCorrect = nil
                }
            }
    }
}

struct KanaKeyboardGridView: View {
    @ObservedObject var viewModel: PracticeViewModel
    var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 18 * scale) {
            TargetHeaderView(viewModel: viewModel, scale: scale)
            KeyboardGridContent(
                viewModel: viewModel,
                scale: scale,
                stage: viewModel.stage,
                targetRowKey: viewModel.currentRowKey,
                targetDirection: viewModel.targetDirection,
                onResult: { rowKey, direction, _ in
                    viewModel.submitKeyboard(rowKey: rowKey, direction: direction)
                }
            )
            FeedbackBannerView(viewModel: viewModel)
        }
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
