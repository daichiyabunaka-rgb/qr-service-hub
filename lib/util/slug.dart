import 'dart:math';

/// 誤読みしにくい文字だけを使用する（0/O, 1/I/l を除外）。
const _slugChars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
final _random = Random.secure();

/// URL短縮用のランダム識別子を生成する。
/// 10文字で約60bitのエントロピーがあり、推測・総当たりに対して十分。
String generateSlug([int length = 10]) {
  return List.generate(
    length,
    (_) => _slugChars[_random.nextInt(_slugChars.length)],
  ).join();
}
