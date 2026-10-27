import 'package:elytra/features/recipes/recipe_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removeDiacritics bỏ dấu, đ→d, cả dạng NFD', () {
    expect(removeDiacritics('Phở Bò ĐẬU hũ'), 'pho bo dau hu');
    expect(removeDiacritics('Phở'), 'pho');
  });
  test('wordsOf thường hóa, giữ dấu, tách theo ký tự không phải chữ/số', () {
    expect(wordsOf('  Cá basa, KHO-tộ! '), ['cá', 'basa', 'kho', 'tộ']);
    expect(wordsOf(' , . '), isEmpty);
    expect(wordsOf('Phở Bò'), ['phở', 'bò']);
    expect(wordsOf('Phở Bò'), ['phở', 'bò']);
  });
  test('composeVietnamese: NFD và nửa tổ hợp → NFC', () {
    expect(composeVietnamese('Phở'), 'Phở');
    expect(composeVietnamese('ở'), 'ở');
    expect(composeVietnamese('Tiếng Việt'),
        'Tiếng Việt');
    expect(composeVietnamese('Tié̂ng'), 'Tiếng');
    expect(composeVietnamese('Ằ'), 'Ằ');
    expect(composeVietnamese('Phở bò'), 'Phở bò');
    expect(composeVietnamese('x́'), 'x́');
  });
  test('slugify', () {
    expect(slugify('  Phở  BÒ '), 'pho-bo');
    expect(slugify('Đậu hũ'), 'dau-hu');
    expect(slugify('--Cơm (chiên)--'), 'com-chien');
  });
  test('displayTitle chỉ cắt khoảng trắng và viết hoa chữ đầu', () {
    expect(displayTitle('  bò  xào Mông Cổ '), 'Bò xào Mông Cổ');
    expect(displayTitle('cơm chiên Dương Châu'), 'Cơm chiên Dương Châu');
    expect(displayTitle('ếch xào'), 'Ếch xào');
    expect(displayTitle('Cá Nục Kho'), 'Cá Nục Kho');
    expect(displayTitle('   '), '');
  });
  test('formatDuration', () {
    expect(formatDuration(40), '40 phút');
    expect(formatDuration(60), '1 giờ');
    expect(formatDuration(200), '3 giờ 20 phút');
    expect(formatDuration(0), '0 phút');
  });
}
