# QR Service Hub

1つのQRコードに複数のサービス（LINE・Instagram・予約ページ等）を紐づけるアプリ。
QRには固定短縮URL（`/u/{slug}`）だけを埋め込むため、サービスを編集してもQRの再生成は不要です。

## 構成

```
├── lib/                  Flutterアプリ（管理用・オーナー向け）
│   ├── main.dart         エントリポイント / 認証ゲート
│   ├── config.dart       ハブページのベースURL / SUZURIトークン
│   ├── models/           QrCodeInfo / HubService
│   ├── repos/            Firestoreリポジトリ
│   ├── services/         SUZURI APIクライアント
│   ├── screens/          ログイン / ホーム / QR詳細 / サービス編集 / グッズ作成
│   └── util/             QR画像生成 / slug生成 / URL検証
├── hub/index.html        ハブページ（QRの飛び先。Firebase Hostingへ配置）
├── firestore.rules       Firestoreセキュリティルール
└── firebase.json         Hosting / Firestoreのデプロイ設定
```

## 機能一覧

- メール/パスワードによるログイン・ログアウト（Firebase Auth）
- QRコードの作成・名前変更・削除
- サービス（URL）の追加・編集・並べ替え・表示/非表示（Firestoreリアルタイム同期）
- QR画像の書き出し（透過背景 / 白背景、1024px PNG）
- **SUZURI連携**: QRコードをグッズ（ステッカー・キーホルダー等450種以上）として作成・販売
  - QRサイズは30〜100%で調整（印刷面プレビュー付き）
  - 作成後に購入ページ（SUZURI上で決済・印刷・配送、ロイヤリティ100円）
- ハブページ（https://<project>.web.app）に広告スロット（Firestoreの `hubConfig/global` で切替）

## セットアップ

```powershell
flutter pub get
flutterfire configure          # lib/firebase_options.dart 生成
firebase deploy --only firestore:rules,hosting   # ルールとハブページ配備
```

Firebaseコンソールで Authentication の Email/Password を有効化し、
Firestoreを作成済みであること。

## ビルド・実行

```powershell
# SUZURI連携なし（グッズボタンは案内文言のみ）
flutter build apk --release --target-platform android-arm64

# SUZURI連携あり（トークンは https://suzuri.jp/developer で発行）
flutter build apk --release --target-platform android-arm64 `
  --dart-define=SUZURI_API_TOKEN=発行したトークン

# 実機テスト
flutter run -d <device-id> --dart-define=SUZURI_API_TOKEN=...
```

**注意**: SUZURIトークンはアプリに組み込まれます。一般配布APKに含める場合、
トークン漏洩時に第三者があなたのSUZURIアカウントで商品作成・編集を行える点に
留意してください（購入・決済はAPIから行えないため直接の金銭被害はありません）。
安全な公開配布にはFunctions経由（サーバ側でトークン管理）への移行を推奨します。

## 使い方

1. アプリで新規登録（メール + パスワード6文字以上）
2. ホームで「QRコードを作成」
3. QR詳細画面でサービスを追加（https のURLのみ可）
4. QR詳細画面のQRコードを印刷・共有。スキャンすると `https://<host>/u/<slug>` の
   ハブページが開き、アクティブなサービスが並ぶ
5. サービスの編集・並べ替えはいつでも可能。QRの再生成は不要
6. （任意）「グッズを作る」でSUZURIに商品を公開し、購入ページを共有して販売

## データ構成

```
qrCodes/{qrId}                        : ownerId / slug / title / createdAt
qrCodes/{qrId}/services/{serviceId}   : title / url / sortOrder / isActive
hubConfig/global                      : ハブページ広告設定（コンソール編集）
```

## セキュリティ設計の要点

- Firestoreルールはデフォルト拒否。QR/サービスの読み取りは誰でも可（ハブページのため）、
  書き込みは所有者のみ。URLは `https://` のみ許可
- slugは誤読みにくい文字種のランダム10文字（約60bit）
- ハブページは `innerHTML` を使わずDOM APIで描画（XSS対策）
- サービスURLはアプリ側・ルール側の両方で `https` スキーマを検証
