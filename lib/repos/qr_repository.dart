import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import '../util/slug.dart';

/// Firestoreへのアクセスを集約するリポジトリ。
/// Firestoreのコレクション構成:
///   qrCodes/{qrId}                       : QRコード本体（ownerId, slug, title, createdAt）
///   qrCodes/{qrId}/services/{serviceId}  : 紐づくサービス（title, url, sortOrder, isActive）
class QrRepository {
  QrRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _qrCodes =>
      _db.collection('qrCodes');

  CollectionReference<Map<String, dynamic>> _servicesOf(String qrId) =>
      _qrCodes.doc(qrId).collection('services');

  /// 指定ユーザーのQRコード一覧をリアルタイム監視する。
  Stream<List<QrCodeInfo>> watchQrCodes(String uid) {
    return _qrCodes
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final items = snap.docs
              .map((d) => QrCodeInfo.fromDoc(d.id, d.data()))
              .toList();
          // Firestoreの複合インデックスを避けるためクライアント側でソート。
          items.sort((a, b) =>
              (a.createdAt ?? DateTime(2000))
                  .compareTo(b.createdAt ?? DateTime(2000)));
          return items;
        });
  }

  /// QRコード配下のサービス一覧をリアルタイム監視する。
  Stream<List<HubService>> watchServices(String qrId) {
    return _servicesOf(qrId).snapshots().map((snap) {
      final items = snap.docs
          .map((d) => HubService.fromDoc(d.id, d.data()))
          .toList();
      items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return items;
    });
  }

  /// 新しいQRコードを作成し、ドキュメントIDを返す。
  Future<String> createQrCode({
    required String ownerId,
    required String title,
  }) async {
    final doc = await _qrCodes.add({
      'ownerId': ownerId,
      'slug': generateSlug(),
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> renameQrCode(String qrId, String title) =>
      _qrCodes.doc(qrId).update({'title': title});

  /// QRコードを削除する。配下のサービスもまとめて消す。
  Future<void> deleteQrCode(String qrId) async {
    final services = await _servicesOf(qrId).get();
    final batch = _db.batch();
    for (final doc in services.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_qrCodes.doc(qrId));
    await batch.commit();
  }

  Future<void> addService({
    required String qrId,
    required String title,
    required String url,
  }) async {
    // 既存の最大sortOrder+1で採番する（画面状態に依存させない）。
    final snap = await _servicesOf(qrId).get();
    var maxOrder = -1;
    for (final doc in snap.docs) {
      final order = (doc.data()['sortOrder'] as num?)?.toInt() ?? 0;
      if (order > maxOrder) maxOrder = order;
    }
    await _servicesOf(qrId).add({
      'title': title,
      'url': url,
      'sortOrder': maxOrder + 1,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateService({
    required String qrId,
    required String serviceId,
    required String title,
    required String url,
  }) {
    return _servicesOf(qrId).doc(serviceId).update({
      'title': title,
      'url': url,
    });
  }

  Future<void> setServiceActive({
    required String qrId,
    required String serviceId,
    required bool isActive,
  }) {
    return _servicesOf(qrId)
        .doc(serviceId)
        .update({'isActive': isActive});
  }

  Future<void> deleteService({
    required String qrId,
    required String serviceId,
  }) {
    return _servicesOf(qrId).doc(serviceId).delete();
  }

  /// ドラッグ&ドロップ後の並び順を書き戻す。
  Future<void> updateServicesOrder(
    String qrId,
    List<HubService> servicesInNewOrder,
  ) {
    final batch = _db.batch();
    for (var i = 0; i < servicesInNewOrder.length; i++) {
      batch.update(_servicesOf(qrId).doc(servicesInNewOrder[i].id), {
        'sortOrder': i,
      });
    }
    return batch.commit();
  }
}
