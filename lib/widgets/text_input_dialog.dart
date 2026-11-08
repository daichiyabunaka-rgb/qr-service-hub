import 'package:flutter/material.dart';

/// ラベル付きテキスト入力ダイアログ。
///
/// TextEditingControllerをこのウィジェット自身が管理することで、
/// 呼び出し側がルートの閉じアニメーション中にコントローラを破棄してしまう
/// 事故（framework assertion '_dependents.isEmpty' 等）を防ぐ。
/// 戻り値: 入力された文字列（トリム済み）。キャンセル時はnull。
class TextInputDialog extends StatefulWidget {
  const TextInputDialog({
    super.key,
    required this.title,
    this.initialValue = '',
    this.labelText,
    this.confirmLabel = 'OK',
  });

  final String title;
  final String initialValue;
  final String? labelText;
  final String confirmLabel;

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    // ルートが実際にツリーから外れるタイミングでフレームワークが呼ぶため、
    // 閉じアニメーション中の破棄にならない。
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.labelText,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
