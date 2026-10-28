// Kiểm normalizeDishName: bóc tên món khỏi tiêu đề bài viết. Chạy: node test_dish_name.js
const assert = require('assert/strict');
const { normalizeDishName } = require('./unified_recipe_parser');
const NAMES = require('../data/recipe_names.json');
const SOURCE_TITLES = require('../data/recipe_source_titles.json');

// Ngoại lệ có chủ đích: cần hiểu nghĩa, quy tắc không làm được -> dùng tên duyệt tay trong recipe_names.json
const KNOWN_EXCEPTIONS = {
  '-cong-thuc-sot-tron-hu-tieu-ga-dam-da-tron-la-ghien-lam-la-me': 'Sốt trộn hủ tiếu gà', // bài dạy cả món, không chỉ nước sốt
  'cach-lam-tom-kho-xe-deo-thom-va-cong-thuc-mam-me-me-ly-an-tom-nuong': 'Tôm khô xẻ và mắm me ăn tôm nướng', // 'ăn tôm nướng' là gợi ý dùng
  'cach-xao-mien-mem-toi-ngon-dam-bao-khong-dinh': 'Miến', // tiêu đề trong DB đã mất 'Cách xào' từ trước
};

let ruleOk = 0;
for (const [slug, title] of Object.entries(SOURCE_TITLES)) {
  const got = normalizeDishName(title);
  if (slug in KNOWN_EXCEPTIONS) {
    assert.equal(got, KNOWN_EXCEPTIONS[slug], 'ngoại lệ thay đổi: ' + slug);
    continue;
  }
  assert.equal(got, NAMES[slug], title);
  ruleOk++;
}
assert.equal(Object.keys(NAMES).length, Object.keys(SOURCE_TITLES).length);

// Tiêu đề chưa có trong dữ liệu
for (const [title, want] of [
  ['Cách Xào Miến Mềm Tơi Ngon, Đảm Bảo Không Dính', 'Miến xào'],
  ['Cách Nấu Phở Bò Hà Nội Chuẩn Vị Thơm Ngon', 'Phở bò Hà Nội'],
  ['Bí Quyết Làm Gà Kho Gừng Thơm Lừng', 'Gà kho gừng'],
  ['Hướng Dẫn Cách Làm Bánh Xèo Giòn Rụm Tại Nhà', 'Bánh xèo'],
  ['Cách Chiên Đậu Hũ Giòn Rụm', 'Đậu hũ chiên'],
  ['Thịt Kho Trứng Ngon Ngất Ngây – Món Ngon Ngày Tết', 'Thịt kho trứng'],
  ['Cá Chim Kho Thơm Đậm Đà', 'Cá chim kho thơm'], // 'thơm' = dứa, không phải lời khen
  ['sườn xào chua ngọt cực ngon', 'Sườn xào chua ngọt'], // vị sau động từ là tên món
  ['sườn non kho tiêu mềm ngon mặn ngọt hao cơm', 'Sườn non kho tiêu'], // vị đứng riêng là lời khen
]) assert.equal(normalizeDishName(title), want, title);

console.log(`dish name: all checks passed (quy tắc đúng ${ruleOk}/${Object.keys(NAMES).length}, ${Object.keys(KNOWN_EXCEPTIONS).length} ngoại lệ duyệt tay)`);
