import Foundation
import Combine

enum PracticeStage {
    case training
    case practice
}

@MainActor
final class PracticeViewModel: ObservableObject {
    @Published var selectedRows: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(selectedRows), forKey: "selectedRows")
        }
    }
    @Published var stage: PracticeStage = .training
    @Published var currentRowKey: String = "あ"
    @Published var targetDirection: Direction = .center
    @Published var feedbackMessage: String = ""
    @Published var feedbackIsError: Bool = false

    @Published var typingContentType: TypingContentType = .words
    @Published var includeSecondaryMarks: Bool = false
    @Published var typingText: String = ""
    @Published var typedCount: Int = 0
    @Published var awaitingMarkKey: Bool = false
    @Published var markPressesRemaining: Int = 0

    @Published var timeAttackDuration: TimeAttackDuration = .medium
    @Published var isTimeAttackRunning: Bool = false
    @Published var timeAttackRemaining: TimeInterval = TimeAttackDuration.medium.seconds
    @Published var timeAttackScore: Int = 0
    @Published var timeAttackBestScores: [Int: Int] = [:]

    private var timeAttackTask: Task<Void, Never>?
    private var currentItemHadMistake = false

    let allRowKeys: [String] = Array(kanaRows.keys).sorted()

    init() {
        if let stored = UserDefaults.standard.array(forKey: "selectedRows") as? [String],
           !stored.isEmpty {
            selectedRows = Set(stored)
        } else {
            selectedRows = Set(kanaRows.keys)
        }
        if let storedTypingType = UserDefaults.standard.string(forKey: "typingContentType"),
           let type = TypingContentType(rawValue: storedTypingType) {
            typingContentType = type
        }
        includeSecondaryMarks = UserDefaults.standard.bool(forKey: "includeSecondaryMarks")
        if let storedDuration = UserDefaults.standard.object(forKey: "timeAttackDuration") as? Int,
           let duration = TimeAttackDuration(rawValue: storedDuration) {
            timeAttackDuration = duration
        }
        timeAttackRemaining = timeAttackDuration.seconds
        if let storedBest = UserDefaults.standard.dictionary(forKey: "timeAttackBestScores") as? [String: Int] {
            timeAttackBestScores = Dictionary(uniqueKeysWithValues: storedBest.compactMap { key, value in
                Int(key).map { ($0, value) }
            })
        }
        newQuestion()
        newTypingText()
    }

    var currentRow: KanaRow {
        kanaRows[currentRowKey] ?? kanaRows["あ"]!
    }

    var targetKana: String {
        currentRow.kana(for: targetDirection) ?? ""
    }

    func toggleRow(_ key: String) {
        if selectedRows.contains(key) {
            guard selectedRows.count > 1 else { return }
            selectedRows.remove(key)
        } else {
            selectedRows.insert(key)
        }
        newQuestion()
    }

    func newQuestion() {
        let pool = selectedRows.isEmpty ? Array(kanaRows.keys) : Array(selectedRows)
        currentRowKey = pool.randomElement() ?? "あ"
        targetDirection = currentRow.availableDirections.randomElement() ?? .center
        feedbackMessage = ""
    }

    func submit(direction: Direction) {
        evaluate(isCorrect: direction == targetDirection, got: currentRow.kana(for: direction))
    }

    func submitKeyboard(rowKey: String, direction: Direction) {
        let isCorrect = rowKey == currentRowKey && direction == targetDirection
        evaluate(isCorrect: isCorrect, got: kanaRows[rowKey]?.kana(for: direction))
    }

    private func evaluate(isCorrect: Bool, got: String?) {
        if isCorrect {
            feedbackMessage = "Correct!"
            feedbackIsError = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                self?.newQuestion()
            }
        } else if let got {
            feedbackMessage = "That was \(got) — try again"
            feedbackIsError = true
        } else {
            feedbackMessage = "No kana that way — try again"
            feedbackIsError = true
        }
    }

    var typingCharacters: [Character] {
        Array(typingText)
    }

    private var baseTypingTarget: (rowKey: String, direction: Direction, pressesNeeded: Int)? {
        guard !typingCharacters.isEmpty else { return nil }
        let index = min(typedCount, typingCharacters.count - 1)
        let (base, presses) = resolveMarkVariant(typingCharacters[index])
        guard let location = locate(kana: base) else { return nil }
        return (location.rowKey, location.direction, presses)
    }

    var currentTypingTarget: (rowKey: String, direction: Direction)? {
        guard let target = baseTypingTarget else { return nil }
        return (target.rowKey, target.direction)
    }

    var isTypingComplete: Bool {
        !typingCharacters.isEmpty && typedCount >= typingCharacters.count
    }

    func selectTypingContent(_ type: TypingContentType) {
        typingContentType = type
        UserDefaults.standard.set(type.rawValue, forKey: "typingContentType")
        newTypingText()
    }

    func setIncludeSecondaryMarks(_ value: Bool) {
        includeSecondaryMarks = value
        UserDefaults.standard.set(value, forKey: "includeSecondaryMarks")
        newTypingText()
    }

    func newTypingText() {
        let pool: [String]
        if isTimeAttackRunning {
            // Time Attack always draws from everything (words, sentences,
            // and marked forms) regardless of the regular typing screen's
            // own content/marks settings, for maximum variety and challenge.
            pool = typingWords + typingWordsWithMarks + typingSentences + typingSentencesWithMarks
        } else {
            let basePool = typingContentType == .words ? typingWords : typingSentences
            let markPool = typingContentType == .words ? typingWordsWithMarks : typingSentencesWithMarks
            // Bias heavily toward marked content while the toggle is on, so
            // turning it on actually surfaces dakuten/handakuten/small kana
            // often enough to practice, rather than just occasionally.
            pool = includeSecondaryMarks && Double.random(in: 0..<1) < 0.75 ? markPool : basePool
        }

        let choices = pool.filter { $0 != typingText }
        typingText = choices.randomElement() ?? pool.randomElement() ?? ""
        typedCount = 0
        awaitingMarkKey = false
        markPressesRemaining = 0
        currentItemHadMistake = false
    }

    // Called when the user flicks a grid key. isCorrect already accounts
    // for whether flicks are currently suspended (i.e. a mark-key press is
    // still owed from the previous character), so this only needs to react.
    func submitTypingAttempt(isCorrect: Bool) {
        guard isCorrect else {
            registerMistake()
            return
        }
        guard let target = baseTypingTarget else { return }
        if target.pressesNeeded == 0 {
            awardCharacterPoint()
            advanceTypedCharacter()
        } else {
            awaitingMarkKey = true
            markPressesRemaining = target.pressesNeeded
        }
    }

    // Called when the user taps the dakuten/handakuten/small-kana key.
    // Returns whether the press was expected, so the key can flash accordingly.
    func submitMarkKeyPress() -> Bool {
        guard awaitingMarkKey else {
            registerMistake()
            return false
        }
        markPressesRemaining -= 1
        if markPressesRemaining <= 0 {
            awaitingMarkKey = false
            awardCharacterPoint()
            advanceTypedCharacter()
        }
        return true
    }

    private func registerMistake() {
        currentItemHadMistake = true
        if isTimeAttackRunning {
            timeAttackScore -= 1
        }
    }

    private func awardCharacterPoint() {
        if isTimeAttackRunning {
            timeAttackScore += 1
        }
    }

    private func advanceTypedCharacter() {
        typedCount += 1
        if typedCount >= typingCharacters.count {
            if isTimeAttackRunning {
                if !currentItemHadMistake {
                    timeAttackScore += 3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                    self?.newTypingText()
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                    self?.newTypingText()
                }
            }
        }
    }

    var timeAttackBestScore: Int {
        timeAttackBestScores[timeAttackDuration.rawValue] ?? 0
    }

    func setTimeAttackDuration(_ duration: TimeAttackDuration) {
        guard !isTimeAttackRunning else { return }
        timeAttackDuration = duration
        UserDefaults.standard.set(duration.rawValue, forKey: "timeAttackDuration")
        timeAttackRemaining = duration.seconds
    }

    func startTimeAttack() {
        guard !isTimeAttackRunning else { return }
        isTimeAttackRunning = true
        timeAttackScore = 0
        timeAttackRemaining = timeAttackDuration.seconds
        newTypingText()

        timeAttackTask?.cancel()
        timeAttackTask = Task { [weak self] in
            while true {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard let self, !Task.isCancelled, self.isTimeAttackRunning else { return }
                self.timeAttackRemaining = max(0, self.timeAttackRemaining - 0.1)
                if self.timeAttackRemaining <= 0 {
                    self.endTimeAttack()
                    return
                }
            }
        }
    }

    func stopTimeAttack() {
        guard isTimeAttackRunning else { return }
        endTimeAttack()
    }

    private func endTimeAttack() {
        isTimeAttackRunning = false
        timeAttackTask?.cancel()
        timeAttackTask = nil
        awaitingMarkKey = false
        markPressesRemaining = 0

        if timeAttackScore > timeAttackBestScore {
            timeAttackBestScores[timeAttackDuration.rawValue] = timeAttackScore
            let stringKeyed = Dictionary(uniqueKeysWithValues: timeAttackBestScores.map { (String($0.key), $0.value) })
            UserDefaults.standard.set(stringKeyed, forKey: "timeAttackBestScores")
        }
    }
}
