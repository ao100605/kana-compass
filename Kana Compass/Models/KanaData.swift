import Foundation

enum Direction: CaseIterable {
    case center, up, down, left, right
}

struct KanaRow {
    let center: String
    let up: String?
    let down: String?
    let left: String?
    let right: String?

    func kana(for direction: Direction) -> String? {
        switch direction {
        case .center: return center
        case .up: return up
        case .down: return down
        case .left: return left
        case .right: return right
        }
    }

    var availableDirections: [Direction] {
        Direction.allCases.filter { kana(for: $0) != nil }
    }
}

let kanaRows: [String: KanaRow] = [
    "あ": KanaRow(center: "あ", up: "う", down: "お", left: "い", right: "え"),
    "か": KanaRow(center: "か", up: "く", down: "こ", left: "き", right: "け"),
    "さ": KanaRow(center: "さ", up: "す", down: "そ", left: "し", right: "せ"),
    "た": KanaRow(center: "た", up: "つ", down: "と", left: "ち", right: "て"),
    "な": KanaRow(center: "な", up: "ぬ", down: "の", left: "に", right: "ね"),
    "は": KanaRow(center: "は", up: "ふ", down: "ほ", left: "ひ", right: "へ"),
    "ま": KanaRow(center: "ま", up: "む", down: "も", left: "み", right: "め"),
    "や": KanaRow(center: "や", up: "ゆ", down: "よ", left: nil, right: nil),
    "ら": KanaRow(center: "ら", up: "る", down: "ろ", left: "り", right: "れ"),
    "わ": KanaRow(center: "わ", up: "ん", down: nil, left: "を", right: "ー")
]

// Standard 3-column x 4-row Japanese flick-keyboard layout. The two
// nil slots are the dakuten-toggle and punctuation keys on a real
// keyboard, which aren't kana rows, so they render as empty spacers.
let keyboardLayout: [[String?]] = [
    ["あ", "か", "さ"],
    ["た", "な", "は"],
    ["ま", "や", "ら"],
    [nil, "わ", nil]
]

// Finds which key and flick direction produces a given kana character,
// so a target character (e.g. from typing practice) can be mapped back
// onto the keyboard grid.
func locate(kana: Character) -> (rowKey: String, direction: Direction)? {
    let target = String(kana)
    for (key, row) in kanaRows {
        for direction in Direction.allCases where row.kana(for: direction) == target {
            return (key, direction)
        }
    }
    return nil
}

// The bottom-left key on a real Japanese flick keyboard cycles the most
// recently typed kana through its dakuten, handakuten, or small-kana form.
// Each cycle starts with the plain kana itself at index 0, so the number
// of presses needed to reach a given form is just that form's index.
let kanaMarkCycles: [String: [String]] = [
    "あ": ["あ", "ぁ"], "い": ["い", "ぃ"], "う": ["う", "ぅ"], "え": ["え", "ぇ"], "お": ["お", "ぉ"],
    "か": ["か", "が"], "き": ["き", "ぎ"], "く": ["く", "ぐ"], "け": ["け", "げ"], "こ": ["こ", "ご"],
    "さ": ["さ", "ざ"], "し": ["し", "じ"], "す": ["す", "ず"], "せ": ["せ", "ぜ"], "そ": ["そ", "ぞ"],
    "た": ["た", "だ"], "ち": ["ち", "ぢ"], "つ": ["つ", "っ", "づ"], "て": ["て", "で"], "と": ["と", "ど"],
    "は": ["は", "ば", "ぱ"], "ひ": ["ひ", "び", "ぴ"], "ふ": ["ふ", "ぶ", "ぷ"], "へ": ["へ", "べ", "ぺ"], "ほ": ["ほ", "ぼ", "ぽ"],
    "や": ["や", "ゃ"], "ゆ": ["ゆ", "ゅ"], "よ": ["よ", "ょ"],
    "わ": ["わ", "ゎ"]
]

// Given any kana (plain or a marked/small variant), finds the plain base
// kana it comes from and how many mark-key presses are needed to reach it.
func resolveMarkVariant(_ character: Character) -> (base: Character, pressesNeeded: Int) {
    let target = String(character)
    for cycle in kanaMarkCycles.values {
        if let index = cycle.firstIndex(of: target) {
            return (Character(cycle[0]), index)
        }
    }
    return (character, 0)
}
