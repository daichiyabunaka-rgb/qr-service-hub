import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QRコードをPNG画像として生成する。
/// [transparent] がtrueなら背景透過、falseなら白背景。
Future<Uint8List> generateQrPng(
  String data, {
  required bool transparent,
  double size = 1024,
}) async {
  final painter = QrPainter(
    data: data,
    version: QrVersions.auto,
    gapless: true,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Colors.black,
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Colors.black,
    ),
    // 背景色を指定しない = 描画されない = 透過PNGになる。
    // ignore: deprecated_member_use
    emptyColor: transparent ? null : Colors.white,
  );
  final byteData = await painter.toImageData(size);
  if (byteData == null) {
    throw Exception('QR画像の生成に失敗しました');
  }
  return byteData.buffer.asUint8List();
}
