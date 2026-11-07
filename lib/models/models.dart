import 'package:cloud_firestore/cloud_firestore.dart';

/// QRコード1枚分の情報。
class QrCodeInfo {
  const QrCodeInfo({
    required this.id,
    required this.slug,
    required this.title,
    required this.ownerId,
    required this.createdAt,
  });

  final String id;
  final String slug;
  final String title;
  final String ownerId;
  final DateTime? createdAt;

  factory QrCodeInfo.fromDoc(String id, Map<String, dynamic> data) =>
      QrCodeInfo(
        id: id,
        slug: data['slug'] as String? ?? '',
        title: data['title'] as String? ?? '',
        ownerId: data['ownerId'] as String? ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      );
}

/// QRコード配下に紐づくサービス1件分の情報。
class HubService {
  const HubService({
    required this.id,
    required this.title,
    required this.url,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String title;
  final String url;
  final int sortOrder;
  final bool isActive;

  factory HubService.fromDoc(String id, Map<String, dynamic> data) =>
      HubService(
        id: id,
        title: data['title'] as String? ?? '',
        url: data['url'] as String? ?? '',
        sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
        isActive: data['isActive'] as bool? ?? true,
      );

  /// 表示用にURLからホスト名を取り出す。
  String get host => Uri.tryParse(url)?.host ?? url;
}
