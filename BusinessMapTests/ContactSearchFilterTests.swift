import XCTest
@testable import BusinessMap

final class ContactSearchFilterTests: XCTestCase {

    private func makeContact(
        name: String,
        phonetic: String? = nil,
        organization: String? = nil,
        address: String? = nil
    ) -> Contact {
        Contact(
            id: name,
            contactId: name,
            displayName: name,
            phoneticName: phonetic,
            organizationName: organization,
            postalAddress: address
        )
    }

    func testEmptyQueryReturnsAllContacts() {
        let contacts = [makeContact(name: "山田 太郎"), makeContact(name: "佐藤 花子")]
        XCTAssertEqual(ContactSearchFilter.filter(contacts, query: "").count, 2)
        XCTAssertEqual(ContactSearchFilter.filter(contacts, query: "   ").count, 2)
    }

    func testHiraganaQueryMatchesKatakanaPhonetic() {
        let contact = makeContact(name: "清水 優希", phonetic: "シミズ ユウキ")
        let result = ContactSearchFilter.filter([contact], query: "しみず")
        XCTAssertEqual(result.count, 1)
    }

    func testKatakanaQueryMatchesHiraganaPhonetic() {
        let contact = makeContact(name: "清水 優希", phonetic: "しみず ゆうき")
        let result = ContactSearchFilter.filter([contact], query: "シミズ")
        XCTAssertEqual(result.count, 1)
    }

    func testLatinQueryIsCaseInsensitive() {
        let contact = makeContact(name: "Apple Japan", organization: "Apple")
        XCTAssertEqual(ContactSearchFilter.filter([contact], query: "apple").count, 1)
        XCTAssertEqual(ContactSearchFilter.filter([contact], query: "APPLE").count, 1)
    }

    func testQueryMatchesAddress() {
        let contact = makeContact(name: "東京 太郎", address: "東京都千代田区丸の内1-9-1")
        XCTAssertEqual(ContactSearchFilter.filter([contact], query: "丸の内").count, 1)
    }

    func testQueryMatchesOrganization() {
        let contact = makeContact(name: "山田 太郎", organization: "株式会社サンプル")
        XCTAssertEqual(ContactSearchFilter.filter([contact], query: "さんぷる").count, 1)
    }

    func testNoMatchReturnsEmpty() {
        let contact = makeContact(name: "山田 太郎", phonetic: "ヤマダ タロウ")
        XCTAssertTrue(ContactSearchFilter.filter([contact], query: "さとう").isEmpty)
    }
}
