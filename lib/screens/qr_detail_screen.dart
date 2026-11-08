import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../config.dart';
import '../models/models.dart';
import '../repos/qr_repository.dart';
import '../widgets/text_input_dialog.dart';
import 'service_edit_screen.dart';

/// QRコード詳細画面。QRの表示と、配下サービスの管理（追加・編集・並べ替え・表示トグル・削除）を行う。
class QrDetailScreen extends StatefulWidget {
  const QrDetailScreen({super.key, required this.qr, required this.repo});

  final QrCodeInfo qr;
  final QrRepository repo;

  @override
  State<QrDetailScreen> createState() => _QrDetailScreenState();
}

class _QrDetailScreenState extends State<QrDetailScreen> {
  QrCodeInfo get _qr => widget.qr;
  QrRepository get _repo => widget.repo;
  String get _hubUrl => buildHubUrl(_qr.slug);

  Future<void> _rename() async {
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => TextInputDialog(
        title: '名前を変更',
        initialValue: _qr.title,
        confirmLabel: '保存',
      ),
    );
    if (newTitle == null || newTitle.isEmpty) return;
    await _repo.renameQrCode(_qr.id, newTitle);
  }

  Future<void> _deleteQr() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QRコードを削除'),
        content: Text('「${_qr.title}」を削除します。配下のサービスも削除されます。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.deleteQrCode(_qr.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: _hubUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URLをコピーしました')),
    );
  }

  Future<void> _shareUrl() async {
    await SharePlus.instance.share(
      ShareParams(text: _hubUrl, title: _qr.title),
    );
  }

  void _onReorder(List<HubService> services, int oldIndex, int newIndex) {
    // onReorderItem は newIndex が既に調整済みのため、そのまま操作する。
    final reordered = List<HubService>.from(services);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    _repo.updateServicesOrder(_qr.id, reordered);
  }

  Future<void> _deleteService(HubService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サービスを削除'),
        content: Text('「${service.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.deleteService(qrId: _qr.id, serviceId: service.id);
    }
  }

  void _openServiceMenu(HubService service) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('編集'),
              onTap: () {
                Navigator.of(context).pop();
                _openServiceEditor(service: service);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('削除'),
              onTap: () {
                Navigator.of(context).pop();
                _deleteService(service);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openServiceEditor({HubService? service}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServiceEditScreen(
          qrId: _qr.id,
          repo: _repo,
          service: service,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_qr.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _rename();
                case 'delete':
                  _deleteQr();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'rename',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('名前を変更'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('QRコードを削除'),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openServiceEditor(),
        icon: const Icon(Icons.add_link),
        label: const Text('サービスを追加'),
      ),
      body: StreamBuilder<List<HubService>>(
        stream: _repo.watchServices(_qr.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('読み込みエラー:\n${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final services = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _qrCard(),
              const SizedBox(height: 24),
              Text('サービス', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (services.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.link_off,
                          size: 40,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        const Text('まだサービスが登録されていません'),
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: () => _openServiceEditor(),
                          child: const Text('サービスを追加'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: services.length,
                  onReorderItem: (oldIndex, newIndex) =>
                      _onReorder(services, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _ServiceTile(
                      key: ValueKey(service.id),
                      index: index,
                      service: service,
                      onTap: () => _openServiceEditor(service: service),
                      onLongPress: () => _openServiceMenu(service),
                      onToggle: (value) => _repo.setServiceActive(
                        qrId: _qr.id,
                        serviceId: service.id,
                        isActive: value,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 88),
            ],
          );
        },
      ),
    );
  }

  Widget _qrCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: QrImageView(
                data: _hubUrl,
                size: 220,
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
            const SizedBox(height: 16),
            SelectableText(
              _hubUrl,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _copyUrl,
                  icon: const Icon(Icons.copy),
                  label: const Text('コピー'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _shareUrl,
                  icon: const Icon(Icons.share),
                  label: const Text('共有'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// サービス一覧の各行。ドラッグで並べ替え、スイッチで表示/非表示を切り替える。
class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    super.key,
    required this.index,
    required this.service,
    required this.onTap,
    required this.onLongPress,
    required this.onToggle,
  });

  final int index;
  final HubService service;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: super.key,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: ReorderableDelayedDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
        title: Text(
          service.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: service.isActive
              ? null
              : TextStyle(color: Theme.of(context).disabledColor),
        ),
        subtitle: Text(
          service.host,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: service.isActive
              ? null
              : TextStyle(color: Theme.of(context).disabledColor),
        ),
        trailing: Switch(
          value: service.isActive,
          onChanged: onToggle,
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
