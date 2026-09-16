import SwiftUI

enum TimeAttackDuration: Int, CaseIterable, Identifiable, Hashable {
    case short = 30
    case medium = 60
    case long = 120

    var id: Int { rawValue }
    var seconds: TimeInterval { TimeInterval(rawValue) }
    var title: String { "\(rawValue)s" }
}

struct TimeAttackView: View {
    @ObservedObject var viewModel: PracticeViewModel
    var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 18 * scale) {
            statsRow
            countdown
            startStopButton

            // Time Attack is a scored minigame, not a lesson, so it always
            // runs in Practice mode — no glow hints, no Training toggle.
            TypingInteractionView(viewModel: viewModel, scale: scale, stage: .practice)
                .disabled(!viewModel.isTimeAttackRunning)
                .opacity(viewModel.isTimeAttackRunning ? 1.0 : 0.4)
        }
        .padding(.vertical, 22 * scale)
        .padding(.horizontal, 24 * scale)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
        )
        .padding(.horizontal, 20)
        .onDisappear {
            if viewModel.isTimeAttackRunning {
                viewModel.stopTimeAttack()
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 24 * scale) {
            statTile(label: "Best", value: "\(viewModel.timeAttackBestScore)")
            statTile(label: "Score", value: "\(viewModel.timeAttackScore)")
        }
    }

    private func statTile(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 28 * scale, weight: .bold, design: .rounded))
                .foregroundStyle(Color.accentColor)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var countdown: some View {
        Text(formattedTime)
            .font(.system(size: 40 * scale, weight: .heavy, design: .rounded))
            .foregroundStyle(isRunningLow ? Color.red : Color.primary)
            .monospacedDigit()
            .animation(.easeInOut(duration: 0.2), value: isRunningLow)
    }

    private var isRunningLow: Bool {
        viewModel.isTimeAttackRunning && viewModel.timeAttackRemaining <= 10
    }

    private var formattedTime: String {
        let total = Int(viewModel.timeAttackRemaining.rounded(.up))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var startStopButton: some View {
        Button {
            if viewModel.isTimeAttackRunning {
                viewModel.stopTimeAttack()
            } else {
                viewModel.startTimeAttack()
            }
        } label: {
            Text(viewModel.isTimeAttackRunning ? "Stop" : "Start")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12 * scale)
                .background(
                    Capsule().fill(viewModel.isTimeAttackRunning ? Color.red : Color.accentColor)
                )
        }
        .buttonStyle(.plain)
    }
}

struct TimeAttackDurationToggleView: View {
    @ObservedObject var viewModel: PracticeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Round Length")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            Picker("Duration", selection: Binding(
                get: { viewModel.timeAttackDuration },
                set: { viewModel.setTimeAttackDuration($0) }
            )) {
                ForEach(TimeAttackDuration.allCases) { duration in
                    Text(duration.title).tag(duration)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isTimeAttackRunning)
        }
    }
}
