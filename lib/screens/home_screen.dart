import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../models/models.dart';
import '../repos/qr_repository.dart';
import 'qr_detail_screen.dart';

/// ログイン後のホーム。所有するQRコード一覧を表示する。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = QrRepository();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _showCreateDialog() async {
    final titleController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QRコードを作成'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'QRコードの名前（例: 店舗名・商品名）',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('作成'),
          ),
        ],
      ),
    );
    final title = titleController.text.trim();
    titleController.dispose();
    if (created != true || title.isEmpty) return;
    final uid = _uid;
    if (uid == null) return;
    await _repo.createQrCode(ownerId: uid, title: title);
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) {
      // ログアウト直後のわずかな遷移期間。AuthGateがすぐに入れ替える。
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Service Hub'),
        actions: [
          IconButton(
            tooltip: 'ログアウト',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('QRコードを作成'),
      ),
      body: StreamBuilder<List<QrCodeInfo>>(
        stream: _repo.watchQrCodes(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('読み込みエラー:\n${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_2,
                    size: 72,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  const Text('QRコードがまだありません'),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: _showCreateDialog,
                    child: const Text('最初のQRコードを作成'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final qr = items[index];
              return ListTile(
                leading: const Icon(Icons.qr_code_2),
                title: Text(qr.title),
                subtitle: Text(
                  buildHubUrl(qr.slug),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        QrDetailScreen(qr: qr, repo: _repo),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
