# Business Map for iOS (営業マップ)

[Business Map for Android](https://github.com/yuukis/businessmap) の iOS 版です。
Android 版から仕様・体験を読み取り、KMP やコード共有は使わず、Swift / SwiftUI と
Apple 標準 API のみで独立に実装しています。

住所が登録された連絡先を地図上にピン表示し、検索・経路案内・連絡先登録に
つなげる「営業先マップ」アプリです。

## 実装済み機能 (MVP)

- 連絡先アクセス許可の要求と、拒否時の案内 (設定アプリへの導線)
- Contacts framework による連絡先の読み込み (名前・ふりがな・会社名・住所・サムネイル)
- 住所を持つ連絡先の MapKit 地図へのピン表示 (同一座標は 1 ピンに集約し件数バッジ)
- CLGeocoder による住所→座標の直列ジオコーディング (進捗表示つき)
- ジオコーディング結果の SQLite キャッシュ (「該当なし」も記録し 14 日間は再問い合わせしない)
- 連絡先一覧シートと検索 (ひらがな/カタカナ・大小文字・全角半角を吸収)
- 連絡先グループによる絞り込み (「すべての連絡先」+ CNGroup)
- ピン選択時の連絡先概要シート (複数件は一覧から選択)
- ContactsUI による連絡先詳細カード表示
- Apple マップでの経路案内起動
- 地図の長押し → 逆ジオコーディング → 住所を引き継いだ連絡先新規登録
- 現在地表示 (Core Location / MapUserLocationButton)
- 最後に表示していた地図領域の保存・復元 (UserDefaults、初期値は東京駅)
- 文言のローカライズ分離 (String Catalog、日本語/英語)

## アーキテクチャ

過剰な抽象化は避け、責務ごとにレイヤを分けています。

```
BusinessMap/
├── App/            BusinessMapApp — エントリポイント
├── Models/         Contact / ContactGroup / MapPlace / DroppedPin
├── ViewModels/     ContactsModel — 連絡先・グループ・ジオコーディング進捗の状態
├── Views/          RootMapView ほか SwiftUI 画面と ContactsUI ブリッジ
├── Services/
│   ├── ContactRepository     Contacts framework の読み取り
│   ├── GeocodingService      CLGeocoder の直列ラッパー (actor)
│   ├── GeocodingCacheStore   住所→座標の SQLite キャッシュ
│   ├── MapStateStore         地図領域の UserDefaults 永続化
│   ├── ExternalNavigation    Apple マップ起動
│   └── LocationAuthorization 位置情報権限の要求
├── Support/        ContactSearchFilter — カナ正規化つき検索 (純粋関数)
└── Resources/      String Catalog / Assets
```

設計メモ:

- Android 版 `MainActivityViewModel` に相当する状態は `ContactsModel` に集約しました。
  検索文字列やシート・選択状態は各 View のローカル状態です。機能追加が少ない想定
  なので、ViewModel を画面ごとに分割するより見通しを優先しています。
- 検索ロジック (`ContactSearchFilter`) と永続化 (`GeocodingCacheStore` /
  `MapStateStore`) は View から切り離した純粋なコンポーネントで、ユニットテストの
  対象にしています。

## ビルド・実行手順

macOS + Xcode 15.4 以降 (iOS 17 SDK) が必要です。プロジェクトファイルは
[XcodeGen](https://github.com/yonaskolb/XcodeGen) (2.38 以降) で生成します。

```sh
brew install xcodegen
cd businessmap-ios
xcodegen generate
open BusinessMap.xcodeproj
```

1. Xcode で Signing の Team を自分のアカウントに設定 (シミュレータのみなら不要)
2. `BusinessMap` スキームを選択し、iOS 17 以降のシミュレータまたは実機で Run
3. 初回起動時に連絡先・位置情報の許可ダイアログが出ます

### 動作確認のポイント

- シミュレータの標準連絡先には住所つきのサンプル (Kate Bell など) が含まれて
  おり、許可するとジオコーディング後に地図へピンが立ちます
- 日本の住所で確認する場合は、連絡先アプリで住所つきの連絡先を追加してください
- ジオコーディングはネットワーク必須です。オフライン時はエラー表示後、
  次回の再読み込みで残りを再試行します
- 地図の長押しでピンが立ち、住所取得 → 「連絡先に登録」で住所が引き継がれます

### テスト

```sh
xcodebuild test \
  -project BusinessMap.xcodeproj \
  -scheme BusinessMap \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

ユニットテスト: 検索フィルタのカナ正規化 / 地図状態の保存・復元 /
ジオコーディングキャッシュ (成功・該当なし・期限切れ・再オープン)。

## Android 版との差分

| Android 版 | iOS 版 | 理由 |
| --- | --- | --- |
| Google Maps SDK | MapKit (SwiftUI `Map`) | Google 依存を排除する方針のため |
| InfoWindow + ボトムシート | シート (`presentationDetents`) | iOS の標準的な操作感を優先 |
| 経路 / ドライブナビの 2 アクション | 「経路」1 アクション | Apple マップでは経路表示→ナビ開始が一続きのため |
| Street View | 非対応 (Look Around は今後検討) | Look Around は対応地域が限られるため MVP から除外 |
| 連絡先メモ (Note) の表示 | 非対応 | iOS の Notes アクセスは Apple の追加エンタイトルメント審査が必要なため |
| ふりがな+Collator によるソート | 連絡先アプリのユーザー設定順 (`CNContactSortOrder.userDefault`) | OS 標準の並び順が日本語も適切に扱うため |
| 住所ハッシュキーの Room キャッシュ | 住所文字列キーの SQLite キャッシュ | ハッシュ衝突を避けるため。キャッシュ移行は行わない (別アプリのため不要) |
| 連絡先リストの直列化キャッシュ | なし | CNContact の読み取りは十分速く、座標キャッシュだけで起動が速いため |
| カメラの tilt / bearing 保存 | 中心座標とスパンのみ保存 | SwiftUI `Map` の region ベース API に合わせた簡略化 |
| Android Shortcuts (グループ直行) | 非対応 | MVP 対象外。将来 App Intents / App Shortcuts で検討 |
| グループのアカウント名表示 | グループ名のみ | CNGroup にアカウント表示の慣習がなく、MVP では簡略化 |

## 未実装・後回しにした機能

- Look Around (Street View 相当)
- 連絡先メモの表示 (エンタイトルメント取得後に検討)
- App Shortcuts / ウィジェット
- 連絡先の編集 (閲覧と新規登録のみ対応)
- グループ一覧でのアカウント名併記
- アプリアイコン (プレースホルダのまま)
- 「このアプリについて」/ ライセンス画面

## 次にやるべき改善案

1. **実機/シミュレータでの UI 磨き込み** — 長押しジェスチャと地図パンの共存、
   シート切り替えのアニメーションは実機での調整が必要
2. **iOS 18 の限定アクセス (`.limited`) 対応** — 現状は拒否扱い。許可された
   範囲の連絡先だけで動くようにする
3. **Look Around 追加** — `LookAroundPreview` は SwiftUI 標準で組み込みやすい
4. **ジオコーディングの再試行制御** — バックオフや、失敗住所の手動再試行 UI
5. **ピンのクラスタリング** — 連絡先が多い場合の視認性向上
   (`MKClusterAnnotation` 相当を SwiftUI で)
6. **UI テスト** — 権限許可フローと検索→フォーカスの E2E

## ライセンス

Android 版と同じく Apache License 2.0 を想定しています。
