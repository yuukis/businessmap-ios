import SwiftUI

@main
struct BusinessMapApp: App {
    @State private var contactsModel = ContactsModel()

    var body: some Scene {
        WindowGroup {
            RootMapView()
                .environment(contactsModel)
        }
    }
}
