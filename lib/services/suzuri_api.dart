import 'dart:convert';

import 'package:http/http.dart' as http;

/// SUZURI API v1 のクライアント。
/// ドキュメント: https://suzuri.jp/developer/documentation/v1
class SuzuriApi {
  SuzuriApi({required this.token});

  final String token;
  static const _base = 'https://suzuri.jp/api/v1';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// SUZURIの商品カタログ（アイテム種別）を取得する。
  Future<List<SuzuriItem>> fetchItems() async {
    final res = await http.get(
      Uri.parse('$_base/items'),
      headers: _headers,
    );
    _throwIfFailed(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['items'] as List)
        .whereType<Map<String, dynamic>>()
        .map(SuzuriItem.fromJson)
        .toList();
    return items;
  }

  /// QRコード画像のデータURIから素材を作成し、指定アイテムの商品を公開する。
  /// 戻り値は購入ページのURL（sampleUrl）。
  Future<String> createQrProduct({
    required String textureDataUri,
    required String title,
    required int itemId,
    int price = 300,
    String? description,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/materials'),
      headers: _headers,
      body: jsonEncode({
        'texture': textureDataUri,
        'title': title,
        'price': price,
        'description': description,
        'products': [
          {
            'itemId': itemId,
            'published': true,
            'resizeMode': 'contain',
          },
        ],
      }),
    );
    _throwIfFailed(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final products = (data['products'] as List)
        .whereType<Map<String, dynamic>>()
        .toList();
    if (products.isEmpty) {
      throw SuzuriApiException('商品の作成に失敗しました');
    }
    final sampleUrl = products.first['sampleUrl'] as String?;
    if (sampleUrl == null || sampleUrl.isEmpty) {
      throw SuzuriApiException('購入ページURLの取得に失敗しました');
    }
    return sampleUrl;
  }

  void _throwIfFailed(http.Response res) {
    if (res.statusCode >= 400) {
      throw SuzuriApiException(
        'SUZURI APIエラー (${res.statusCode}): ${res.body.length > 300 ? res.body.substring(0, 300) : res.body}',
      );
    }
  }
}

/// SUZURIの商品種別（Tシャツ・ステッカー等）。
class SuzuriItem {
  const SuzuriItem({
    required this.id,
    required this.name,
    required this.humanizeName,
    required this.displayOrder,
  });

  final int id;
  final String name;
  final String humanizeName;
  final int displayOrder;

  factory SuzuriItem.fromJson(Map<String, dynamic> json) => SuzuriItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        humanizeName: json['humanizeName'] as String? ?? '',
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      );
}

class SuzuriApiException implements Exception {
  SuzuriApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
