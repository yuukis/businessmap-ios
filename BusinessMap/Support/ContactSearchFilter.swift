import Foundation

/// 連絡先一覧の検索。ひらがな/カタカナ、大文字/小文字、全角/半角の違いを吸収する
/// (Android版 StringJUtils.convertToKatakana によるカナ正規化に相当)。
enum ContactSearchFilter {

    static func normalize(_ text: String) -> String {
        let folded = text.folding(
            options: [.caseInsensitive, .widthInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "ja_JP")
        )
        return folded.applyingTransform(.hiraganaToKatakana, reverse: false) ?? folded
    }

    /// 名前・ふりがな・会社名・住所のいずれかに一致する連絡先を返す。
    static func filter(_ contacts: [Contact], query: String) -> [Contact] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return contacts }
        let needle = normalize(trimmed)
        return contacts.filter { contact in
            [contact.displayName, contact.phoneticName, contact.organizationName, contact.postalAddress]
                .compactMap { $0 }
                .contains { normalize($0).contains(needle) }
        }
    }
}
