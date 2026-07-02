import Contacts
import ContactsUI
import SwiftUI

/// ContactsUI の連絡先カードを表示する。
/// 既存連絡先の閲覧と、住所を引き継いだ新規登録の両方に使う
/// (Android版の ACTION_VIEW / ACTION_INSERT インテント相当)。
struct ContactCardView: UIViewControllerRepresentable {

    enum Mode {
        case existing(contactId: String)
        case newContact(postalAddress: CNPostalAddress?)
    }

    let mode: Mode
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: { dismiss() })
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let store = CNContactStore()
        let controller: CNContactViewController

        switch mode {
        case .existing(let contactId):
            let keys = [CNContactViewController.descriptorForRequiredKeys()]
            if let contact = try? store.unifiedContact(withIdentifier: contactId, keysToFetch: keys) {
                controller = CNContactViewController(for: contact)
            } else {
                controller = CNContactViewController(forUnknownContact: CNContact())
            }
            controller.allowsEditing = false
            controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
                systemItem: .close,
                primaryAction: UIAction { [coordinator = context.coordinator] _ in
                    coordinator.dismiss()
                }
            )
        case .newContact(let postalAddress):
            let contact = CNMutableContact()
            if let postalAddress {
                contact.postalAddresses = [
                    CNLabeledValue(label: CNLabelWork, value: postalAddress)
                ]
            }
            controller = CNContactViewController(forNewContact: contact)
        }

        controller.contactStore = store
        controller.delegate = context.coordinator
        return UINavigationController(rootViewController: controller)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    final class Coordinator: NSObject, CNContactViewControllerDelegate {
        let dismiss: () -> Void

        init(dismiss: @escaping () -> Void) {
            self.dismiss = dismiss
        }

        func contactViewController(
            _ viewController: CNContactViewController,
            didCompleteWith contact: CNContact?
        ) {
            dismiss()
        }
    }
}
