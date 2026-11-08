import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QRコードを、2048px四方のキャンバス中央に [scale] の比率で配置した
/// PNG画像として生成する。
/// SUZURIは画像を印刷領域にフィットさせて配置するため、
/// キャンバス内のQRの占有率がそのままグッズ上のQRサイズになる。
/// [transparent] がtrueなら背景透過、falseなら白背景。
Future<Uint8List> generateQrPng(
  String data, {
  required bool transparent,
  double scale = 1.0,
  int canvasSize = 2048,
}) async {
  scale = scale.clamp(0.2, 1.0);
  final innerSize = (canvasSize * scale).round();

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
    // 背景色を指定しない = 描画されない = 透過になる。
    // ignore: deprecated_member_use
    emptyColor: transparent ? null : Colors.white,
  );
  final innerBytes = await painter.toImageData(innerSize.toDouble());
  if (innerBytes == null) {
    throw Exception('QR画像の生成に失敗しました');
  }
  final codec = await ui.instantiateImageCodec(
    innerBytes.buffer.asUint8List(),
  );
  final frame = await codec.getNextFrame();
  final innerImage = frame.image;

  // キャンバスを用意し、QRを中央に配置する。
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  if (!transparent) {
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, canvasSize.toDouble(), canvasSize.toDouble()),
      ui.Paint()..color = const Color(0xFFFFFFFF),
    );
  }
  final offset = (canvasSize - innerSize) / 2;
  final dst = ui.Rect.fromLTWH(
    offset.toDouble(),
    offset.toDouble(),
    innerSize.toDouble(),
    innerSize.toDouble(),
  );
  canvas.drawImageRect(
    innerImage,
    ui.Rect.fromLTWH(
      0,
      0,
      innerImage.width.toDouble(),
      innerImage.height.toDouble(),
    ),
    dst,
    ui.Paint(),
  );

  final picture = recorder.endRecording();
  final composed = await picture.toImage(canvasSize, canvasSize);
  final composedBytes = await composed.toByteData(
    format: ui.ImageByteFormat.png,
  );
  if (composedBytes == null) {
    throw Exception('QR画像の合成に失敗しました');
  }
  return composedBytes.buffer.asUint8List();
}
