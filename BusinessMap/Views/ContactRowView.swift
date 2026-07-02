import SwiftUI

/// 連絡先のサムネイル。写真がなければプレースホルダを表示する。
struct ContactAvatarView: View {
    let contact: Contact
    var size: CGFloat = 40

    var body: some View {
        if let data = contact.thumbnailData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle().fill(.gray.opacity(0.25))
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(.gray)
            }
            .frame(width: size, height: size)
        }
    }
}

/// 一覧・複数連絡先シートで使う共通の行。
struct ContactRowView: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: 12) {
            ContactAvatarView(contact: contact)
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)
                if let organization = contact.organizationName {
                    Text(organization)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let address = contact.postalAddress {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if contact.coordinate == nil {
                // 座標未解決(住所なし or ジオコーディング失敗)の連絡先
                Image(systemName: "mappin.slash")
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
    }
}
