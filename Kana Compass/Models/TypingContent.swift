import Foundation

enum TypingContentType: String, CaseIterable, Identifiable, Hashable {
    case words
    case sentences

    var id: String { rawValue }

    var title: String {
        switch self {
        case .words: return "Words"
        case .sentences: return "Sentences"
        }
    }
}

// Every word and sentence below is built only from the plain (non-dakuten,
// non-youon) kana modeled in kanaRows, so every character can always be
// located on the keyboard grid.
let typingWords: [String] = [
    "あさ", "いえ", "うみ", "かさ", "くつ", "けさ", "さくら", "すし",
    "そら", "たこ", "とけい", "なつ", "にわ", "ぬの", "ねこ", "はな",
    "ひと", "ふね", "ほし", "まち", "むし", "もり", "やま", "ゆき",
    "よる", "るす", "れきし", "ろうか", "わたし",
    "あめ", "いろ", "うた", "えほん", "おかし", "かお", "きもの",
    "くも", "こおり", "しま", "すな", "せかい", "たいよう", "ちから",
    "つき", "てら", "とり", "なみ", "ぬま", "へや"
]

let typingSentences: [String] = [
    "そらはあおい",
    "はなはあかい",
    "ねこはいえにいる",
    "そとはさむい",
    "はるはあたたかい",
    "やまはたかい",
    "うみはひろい",
    "あさはさむい",
    "そらはたかい",
    "みちはせまい",
    "ふゆはさむい",
    "なつはあつい",
    "つきはきれい",
    "とりはそらにいる",
    "せかいはひろい",
    "ちからはたいせつ",
    "あめはつめたい"
]

// These add dakuten (がざだば…), handakuten (ぱぴぷ…), and small-kana
// (っゃゅょぁ…) forms on top of the plain set above, every one of them
// resolvable back to a base key + press count via kanaMarkCycles.
let typingWordsWithMarks: [String] = [
    "がっこう", "ばら", "かばん", "でんわ", "ぱん", "さんぽ",
    "きっぷ", "じかん", "ぞう", "しゃしん", "べんきょう", "ぎゅうにゅう",
    "めがね", "ぼうし", "くだもの", "たまご", "かぞく", "ぎんこう",
    "どうぶつ", "がくせい", "びょうき", "ぷりん", "しゅくだい", "べんとう"
]

let typingSentencesWithMarks: [String] = [
    "がっこうへいく",
    "でんわがある",
    "ばらはあかい",
    "きっぷをかう",
    "ぞうはおおきい",
    "じかんがない",
    "がっこうはたのしい",
    "どうぶつがすき",
    "かぞくとあそぶ",
    "おとなはいそがしい"
]
