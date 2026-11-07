import 'package:flutter/material.dart';

import '../models/models.dart';
import '../repos/qr_repository.dart';
import '../util/url_validator.dart';

/// サービスの追加／編集画面。
class ServiceEditScreen extends StatefulWidget {
  const ServiceEditScreen({
    super.key,
    required this.qrId,
    required this.repo,
    this.service,
  });

  final String qrId;
  final QrRepository repo;
  final HubService? service;

  @override
  State<ServiceEditScreen> createState() => _ServiceEditScreenState();
}

class _ServiceEditScreenState extends State<ServiceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController =
      TextEditingController(text: widget.service?.title ?? '');
  late final _urlController =
      TextEditingController(text: widget.service?.url ?? '');
  bool _loading = false;

  bool get _isEditing => widget.service != null;

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final title = _titleController.text.trim();
      final url = _urlController.text.trim();
      if (_isEditing) {
        await widget.repo.updateService(
          qrId: widget.qrId,
          serviceId: widget.service!.id,
          title: title,
          url: url,
        );
      } else {
        await widget.repo.addService(
          qrId: widget.qrId,
          title: title,
          url: url,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'サービスを編集' : 'サービスを追加'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'サービス名（例: LINE公式・Instagram）',
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  (value?.trim() ?? '').isEmpty ? 'サービス名を入力してください' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL（https://...）',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
                helperText: 'https で始まるURLのみ登録できます',
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _loading ? null : _save(),
              validator: validateServiceUrl,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
