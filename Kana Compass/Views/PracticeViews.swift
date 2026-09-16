import SwiftUI
import UIKit

struct TargetHeaderView: View {
    @ObservedObject var viewModel: PracticeViewModel
    var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 6 * scale) {
            Label(instructionLabel, systemImage: symbolName(for: viewModel.targetDirection))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .opacity(viewModel.targetKana.isEmpty ? 0 : 1)

            Text(viewModel.targetKana)
                .font(.system(size: 54 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(Color.accentColor)
                .frame(height: 64 * scale)
                .id(viewModel.targetKana)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.65), value: viewModel.targetKana)
        }
    }

    private var instructionLabel: String {
        guard viewModel.stage == .training else { return "Find" }
        switch viewModel.targetDirection {
        case .center: return "Tap the center for"
        case .up: return "Flick upwards for"
        case .down: return "Flick downwards for"
        case .left: return "Flick leftwards for"
        case .right: return "Flick rightwards for"
        }
    }

    private func symbolName(for direction: Direction) -> String {
        guard viewModel.stage == .training else { return "questionmark.circle" }
        switch direction {
        case .center: return "hand.tap.fill"
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        }
    }
}

struct FeedbackBannerView: View {
    @ObservedObject var viewModel: PracticeViewModel

    var body: some View {
        HStack(spacing: 6) {
            if !viewModel.feedbackMessage.isEmpty {
                Image(systemName: viewModel.feedbackIsError ? "xmark.circle.fill" : "checkmark.circle.fill")
                Text(viewModel.feedbackMessage)
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(viewModel.feedbackIsError ? Color.red : Color.green)
        .frame(height: 22)
        .id(viewModel.feedbackMessage)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.feedbackMessage)
    }
}

struct KanaCompassView: View {
    @ObservedObject var viewModel: PracticeViewModel
    var scale: CGFloat = 1.0

    private var tileSize: CGFloat { 60 * scale }
    private var centerSize: CGFloat { 112 * scale }
    private var radius: CGFloat { 116 * scale }
    private let tapThreshold: CGFloat = 20

    @State private var dragOffset: CGSize = .zero
    @State private var flashDirection: Direction? = nil
    @State private var shakeTrigger: CGFloat = 0
    @State private var successPulse: Bool = false

    var body: some View {
        VStack(spacing: 20 * scale) {
            TargetHeaderView(viewModel: viewModel, scale: scale)
            compass
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

    private var compass: some View {
        ZStack {
            tile(for: .up, offset: CGSize(width: 0, height: -radius))
            tile(for: .down, offset: CGSize(width: 0, height: radius))
            tile(for: .left, offset: CGSize(width: -radius, height: 0))
            tile(for: .right, offset: CGSize(width: radius, height: 0))

            Circle()
                .fill(Color(.secondarySystemFill))
                .frame(width: centerSize, height: centerSize)
                .overlay(
                    Circle()
                        .stroke(successPulse ? Color.green : Color.accentColor.opacity(0.35), lineWidth: successPulse ? 4 : 2)
                )
                .overlay(
                    Text(viewModel.currentRow.center)
                        .font(.system(size: 38 * scale, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                )
                .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
                .scaleEffect(successPulse ? 1.1 : 1.0)
                .offset(dragOffset)
                .modifier(ShakeEffect(animatableData: shakeTrigger))
                .gesture(dragGesture)
        }
        .frame(width: 270 * scale, height: 270 * scale)
    }

    @ViewBuilder
    private func tile(for direction: Direction, offset: CGSize) -> some View {
        if let kana = viewModel.currentRow.kana(for: direction) {
            let isFlashing = flashDirection == direction
            let isCorrectFlash = isFlashing && direction == viewModel.targetDirection

            Text(viewModel.stage == .training ? kana : "")
                .font(.system(size: 24 * scale, weight: .medium, design: .rounded))
                .frame(width: tileSize, height: tileSize)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(tileBackground(isFlashing: isFlashing, isCorrect: isCorrectFlash))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
                )
                .foregroundStyle(isFlashing ? .white : Color.accentColor)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                .scaleEffect(isFlashing ? 1.12 : 1.0)
                .offset(offset)
        }
    }

    private func tileBackground(isFlashing: Bool, isCorrect: Bool) -> Color {
        guard isFlashing else { return Color.accentColor.opacity(0.15) }
        return isCorrect ? Color.green : Color.red
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

                let isCorrect = direction == viewModel.targetDirection

                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    dragOffset = .zero
                }

                withAnimation(.easeOut(duration: 0.25)) {
                    flashDirection = direction
                }

                if isCorrect {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                        successPulse = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            successPulse = false
                        }
                    }
                } else {
                    withAnimation(.linear(duration: 0.4)) {
                        shakeTrigger += 1
                    }
                }

                UINotificationFeedbackGenerator().notificationOccurred(isCorrect ? .success : .error)

                viewModel.submit(direction: direction)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    flashDirection = nil
                }
            }
    }
}

struct ShakeEffect: GeometryEffect {
    var travelDistance: CGFloat = 12
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = travelDistance * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

struct RowSelectionView: View {
    @ObservedObject var viewModel: PracticeViewModel
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rows to Practice")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.allRowKeys, id: \.self) { key in
                    let isOn = viewModel.selectedRows.contains(key)
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.toggleRow(key)
                        }
                    } label: {
                        Text(key)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(isOn ? Color.accentColor : Color(.tertiarySystemFill))
                            )
                            .foregroundStyle(isOn ? .white : Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct StageToggleView: View {
    @ObservedObject var viewModel: PracticeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Practice Mode")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            Picker("Stage", selection: Binding(
                get: { viewModel.stage },
                set: { newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.stage = newValue
                    }
                }
            )) {
                Text("Training").tag(PracticeStage.training)
                Text("Practice").tag(PracticeStage.practice)
            }
            .pickerStyle(.segmented)
        }
    }
}
