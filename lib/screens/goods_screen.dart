import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/models.dart';
import '../services/suzuri_api.dart';
import '../util/qr_image.dart';

/// QRコードをSUZURIのグッズ（タトゥーシール・キーホルダー等）として
/// 作成・販売する画面。作成した商品の購入ページを開く。
class GoodsScreen extends StatefulWidget {
  const GoodsScreen({super.key, required this.qr});

  final QrCodeInfo qr;

  @override
  State<GoodsScreen> createState() => _GoodsScreenState();
}

class _GoodsScreenState extends State<GoodsScreen> {
  SuzuriApi? get _api => kSuzuriApiToken.isEmpty
      ? null
      : SuzuriApi(token: kSuzuriApiToken);

  List<SuzuriItem>? _items;
  String _search = '';
  SuzuriItem? _selectedItem;
  bool _transparent = false;
  double _scale = 0.7;
  bool _creating = false;
  String? _error;

  QrCodeInfo get _qr => widget.qr;

  @override
  void initState() {
    super.initState();
    if (_api == null) {
      _error = 'SUZURI APIトークンが設定されていません。'
          'https://suzuri.jp/developer でトークンを発行し、ビルド時に '
          '--dart-define=SUZURI_API_TOKEN=... を指定してください。';
    } else {
      _api!.fetchItems().then((items) {
        if (!mounted) return;
        setState(() => _items = items);
      }).catchError((Object e) {
        if (!mounted) return;
        setState(() =>
            _error = 'アイテム一覧の取得に失敗しました: $e');
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<SuzuriItem> get _filteredItems {
    final items = _items;
    if (items == null) return [];
    final q = _search.trim();
    if (q.isEmpty) return items;
    return items
        .where((i) => i.humanizeName.contains(q) || i.name.contains(q))
        .toList();
  }

  Future<void> _create() async {
    final api = _api;
    final item = _selectedItem;
    if (api == null || item == null || _creating) return;
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      // QR画像を生成し、データURI化してSUZURIへ渡す。
      final png = await generateQrPng(
        buildHubUrl(_qr.slug),
        transparent: _transparent,
        scale: _scale,
      );
      final dataUri =
          'data:image/png;base64,${base64Encode(png)}';
      final sampleUrl = await api.createQrProduct(
        textureDataUri: dataUri,
        title: '${_qr.title} QR',
        itemId: item.id,
        description: '${_qr.title}のQRコード / ${buildHubUrl(_qr.slug)}',
      );
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('グッズを作成しました'),
            content: Text(
              '「${item.humanizeName}」をSUZURIに公開しました。\n'
              '購入ページを開いて確認・共有できます。\n'
              'ロイヤリティは100円で作成しています。配置の微調整は'
              'SUZURIの商品ページから行えます。',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: sampleUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URLをコピーしました')),
                  );
                },
                child: const Text('URLをコピー'),
              ),
              FilledButton(
                onPressed: () => _openUrl(sampleUrl),
                child: const Text('購入ページを開く'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '作成に失敗しました: $e');
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SUZURIでグッズを作る')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('QR: ${_qr.title}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  RadioGroup<bool>(
                    groupValue: _transparent,
                    onChanged: (v) =>
                        setState(() => _transparent = v ?? false),
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          value: false,
                          title: const Text('白背景'),
                          subtitle: const Text('ほとんどのグッズで推奨（読み取り安定）'),
                          dense: true,
                        ),
                        RadioListTile<bool>(
                          value: true,
                          title: const Text('透過背景'),
                          subtitle: const Text('白い生地・ステッカー向け'),
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('QRのサイズ')),
                      Text('${(_scale * 100).round()}%',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  Slider(
                    value: _scale,
                    min: 0.3,
                    max: 1.0,
                    divisions: 14,
                    label: '${(_scale * 100).round()}%',
                    onChanged: (v) => setState(() => _scale = v),
                  ),
                  const Text(
                    'プレビュー（印刷面イメージ）',
                    style:TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Center(
                          child: SizedBox(
                            width: 220 * _scale,
                            height: 220 * _scale,
                            child: QrImageView(
                              data: buildHubUrl(_qr.slug),
                              gapless: true,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.black,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('商品の種類を選択',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: 'アイテムを検索（例: ステッカー・キーホルダー・Tシャツ）',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 8),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _error!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_items == null && _error == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_items != null) ..._buildItemList(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed:
                _creating || _selectedItem == null ? null : _create,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _creating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_selectedItem == null
                      ? 'アイテムを選択してください'
                      : '「${_selectedItem!.humanizeName}」で作成'),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItemList() {
    final items = _filteredItems;
    if (items.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('該当するアイテムがありません')),
        ),
      ];
    }
    return [
      RadioGroup<int>(
        groupValue: _selectedItem?.id,
        onChanged: (id) {
          if (id == null) return;
          setState(
            () => _selectedItem = items.firstWhere((i) => i.id == id),
          );
        },
        child: Column(
          children: items
              .map((item) => RadioListTile<int>(
                    value: item.id,
                    title: Text(item.humanizeName),
                    dense: true,
                  ))
              .toList(),
        ),
      ),
    ];
  }
}
