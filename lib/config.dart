/// ハブページ（QRコードの飛び先）のベースURL。
/// 実行時に上書き可能:
///   flutter run --dart-define=HUB_BASE_URL=https://onetomanymyqrcode.web.app
const String kHubBaseUrl = String.fromEnvironment(
  'HUB_BASE_URL',
  defaultValue: 'https://onetomanymyqrcode.web.app',
);

/// QRコードに埋め込むURLを組み立てる。
/// QRにはこのURLだけを入れるため、サービスを編集してもQRの再生成は不要。
String buildHubUrl(String slug) => '$kHubBaseUrl/u/$slug';

/// SUZURI APIのアクセストークン。
/// ビルド時に渡す:
///   flutter run --dart-define=SUZURI_API_TOKEN=xxxxxxxx
/// https://suzuri.jp/developer でアプリケーションを作成して発行する。
const String kSuzuriApiToken = String.fromEnvironment(
  'SUZURI_API_TOKEN',
  defaultValue: '',
);
