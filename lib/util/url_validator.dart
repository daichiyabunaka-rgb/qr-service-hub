/// サービスURLのバリデーション。
/// https のみを許可し、`javascript:` 等の危険なスキーマを拒否する。
String? validateServiceUrl(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) {
    return 'URLを入力してください';
  }
  final uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasScheme || uri.scheme != 'https' || uri.host.isEmpty) {
    return 'https:// で始まるURLを入力してください';
  }
  return null;
}
