const fs = require('fs');
const path = require('path');

// 1. Load database catalogs
const catalogPath = path.join(__dirname, '../data/ingredients_catalog.json');
const allergensPath = path.join(__dirname, '../data/allergens.json');
const ingrAllergensPath = path.join(__dirname, '../data/ingredient_allergens.json');

const catalog = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));
const allergens = JSON.parse(fs.readFileSync(allergensPath, 'utf8'));
const ingrAllergens = JSON.parse(fs.readFileSync(ingrAllergensPath, 'utf8'));

// Build lookup maps
const ingredientByCode = new Map(catalog.map(i => [i.code, i]));
const ingredientById = new Map(catalog.map(i => [i.id, i]));
const allergensByIngrId = new Map();
for (const link of ingrAllergens) {
  if (!allergensByIngrId.has(link.ingredient_id)) {
    allergensByIngrId.set(link.ingredient_id, []);
  }
  allergensByIngrId.get(link.ingredient_id).push(link.allergen_id);
}

// 2. Từ điển đồng nghĩa: tên thường gặp trong công thức -> TÊN nguyên liệu trong bảng FCT (name_vi).
// Dùng tên thay vì mã: bản cũ dùng mã đoán tay, 116/285 mục trỏ sai (vd 'gà' -> Thịt cừu, 'lạc' -> Quả đại).
// null = cố ý không map (gia vị không đáng kể, hoặc FCT không có món tương đương).
// So khớp theo TỪ (không theo chuỗi con), cụm dài hơn được thử trước.
const RAW_SYNONYMS = [
  // Trứng
  ['lòng đỏ trứng gà', 'Lòng đỏ trứng gà'], ['lòng đỏ trứng vịt', 'Lòng đỏ trứng vịt'], ['lòng đỏ trứng', 'Lòng đỏ trứng gà'], ['lòng đỏ', 'Lòng đỏ trứng gà'],
  ['lòng trắng trứng gà', 'Lòng trắng trứng gà'], ['lòng trắng trứng', 'Lòng trắng trứng gà'], ['lòng trắng', 'Lòng trắng trứng gà'],
  ['trứng gà ta', 'Trứng gà ta'], ['trứng gà công nghiệp', 'Trứng gà công nghiệp'], ['trứng gà', 'Trứng gà ta'], ['hột gà', 'Trứng gà ta'],
  ['trứng vịt lộn', 'Trứng vịt lộn'], ['hột vịt lộn', 'Trứng vịt lộn'], ['trứng vịt', 'Trứng vịt'], ['hột vịt', 'Trứng vịt'],
  ['trứng cút', 'Trứng chim cút'], ['trứng chim cút', 'Trứng chim cút'], ['trứng', 'Trứng gà ta'],
  // Heo
  ['thịt ba rọi rút sườn', 'Thịt lợn nửa nạc, nửa mỡ'], ['thịt ba chỉ', 'Thịt lợn nửa nạc, nửa mỡ'], ['thịt ba rọi', 'Thịt lợn nửa nạc, nửa mỡ'],
  ['thịt lợn ba chỉ', 'Thịt lợn nửa nạc, nửa mỡ'], ['ba rọi heo', 'Thịt lợn nửa nạc, nửa mỡ'], ['ba chỉ heo', 'Thịt lợn nửa nạc, nửa mỡ'],
  ['ba rọi', 'Thịt lợn nửa nạc, nửa mỡ'], ['ba chỉ', 'Thịt lợn nửa nạc, nửa mỡ'],
  ['thịt nạc dăm', 'Thịt lợn, nạc vai'], ['thịt nạc vai', 'Thịt lợn, nạc vai'], ['nạc dăm', 'Thịt lợn, nạc vai'], ['nạc vai', 'Thịt lợn, nạc vai'],
  ['thịt nạc đùi', 'Thịt lợn, nạc mông'], ['thịt nạc thăn', 'Thịt lợn, nạc thăn'], ['thịt thăn heo', 'Thịt lợn, nạc thăn'], ['thịt thăn', 'Thịt lợn, nạc thăn'],
  ['sườn cốt lết', 'Thịt lợn, nạc vai'], ['sườn non', 'Sườn lợn'], ['sườn que', 'Sườn lợn'], ['sườn heo', 'Sườn lợn'], ['sườn lợn', 'Sườn lợn'], ['sườn cọng', 'Sườn lợn'], ['sườn', 'Sườn lợn'],
  ['thịt heo xay', 'Thịt lợn nạc'], ['thịt heo bằm', 'Thịt lợn nạc'], ['thịt lợn nạc', 'Thịt lợn nạc'], ['thịt nạc heo', 'Thịt lợn nạc'], ['thịt xay', 'Thịt lợn nạc'],
  ['thịt bằm', 'Thịt lợn nạc'], ['thịt nạc', 'Thịt lợn nạc'], ['thịt heo', 'Thịt lợn nạc'], ['thịt lợn', 'Thịt lợn nạc'],
  ['chân giò heo', 'Chân giò lợn'], ['chân giò', 'Chân giò lợn'], ['móng giò', 'Chân giò lợn'], ['da heo', 'Bì lợn'], ['bì heo', 'Bì lợn'],
  ['mỡ heo', 'Mỡ lợn muối'], ['mỡ lợn', 'Mỡ lợn muối'], ['tóp mỡ', 'Mỡ lợn muối'], ['tai heo', 'Tai lợn'], ['tai lợn', 'Tai lợn'],
  ['dạ dày heo', 'Dạ dày lợn'], ['bao tử heo', 'Dạ dày lợn'], ['gan heo', 'Gan lợn'], ['gan lợn', 'Gan lợn'], ['lòng non', 'Lòng lợn (ruột non)'],
  ['đuôi heo', 'Đuôi lợn'], ['đuôi lợn', 'Đuôi lợn'], ['huyết heo', 'Tiết lợn luộc'], ['tiết heo', 'Tiết lợn luộc'], ['tiết lợn', 'Tiết lợn luộc'],
  ['chả lụa', 'Giò lụa'], ['giò lụa', 'Giò lụa'], ['giò sống', 'Giò lụa'], ['lạp xưởng', 'Lạp xường'], ['lạp xường', 'Lạp xường'],
  // Bò, dê
  ['thịt bò phi lê', 'Thịt bò loại I'], ['thịt bò xay', 'Thịt bò loại I'], ['thịt bò bằm', 'Thịt bò loại I'], ['thịt bò nạc', 'Thịt bò loại I'], ['thịt bò', 'Thịt bò loại I'],
  ['thăn bò', 'Thịt bò loại I'], ['bò phi lê', 'Thịt bò loại I'], ['bắp bò', 'Thịt bò loại II'], ['gân bò', 'Thịt bò loại II'], ['nạm bò', 'Thịt bò loại II'],
  ['dẻ sườn bò', 'Thịt bò loại II'], ['đuôi bò', 'Đuôi bò'], ['bò', 'Thịt bò loại I'], ['bao tử dê', 'Dạ dày bò'], ['thịt dê', 'Thịt dê, nạc'],
  // Gà, vịt
  ['lòng gà', 'Lòng gà (cả bộ)'], ['mề gà', 'Mề gà'], ['gan gà', 'Gan gà'], ['cánh gà', 'Thịt gà công nghiệp, cánh'], ['nước luộc gà', null],
  ['thịt gà', 'Thịt gà ta'], ['gà ta', 'Thịt gà ta'], ['gà tre', 'Thịt gà ta'], ['ức gà', 'Thịt gà ta'], ['đùi gà', 'Thịt gà ta'], ['chân gà', 'Thịt gà ta'], ['gà', 'Thịt gà ta'],
  ['thịt vịt', 'Thịt vịt'], ['vịt', 'Thịt vịt'],
  // Hải sản, cá
  ['tôm sú tươi', 'Tôm biển'], ['tôm sú', 'Tôm biển'], ['tôm thẻ', 'Tôm biển'], ['tôm đồng', 'Tôm đồng'], ['tôm tươi', 'Tôm đồng'], ['tôm khô', 'Tôm khô'], ['tôm', 'Tôm đồng'], ['tép', 'Tôm đồng'],
  ['ruốc khô', 'Ruốc tôm'], ['ruốc', 'Ruốc tôm'],
  ['mực ống', 'Mực tươi'], ['mực lá', 'Mực tươi'], ['mực tươi', 'Mực tươi'], ['mực khô', 'Mực khô'], ['mực', 'Mực tươi'],
  ['cua đồng', 'Cua đồng'], ['thịt cua', 'Cua bể'], ['cua biển', 'Cua bể'], ['cua', 'Cua bể'], ['ghẹ', 'Cua ghẹ'],
  ['cá nục', 'Cá nục'], ['cá lóc', 'Cá quả'], ['cá quả', 'Cá quả'], ['cá diêu hồng', 'Cá rô phi'], ['cá điêu hồng', 'Cá rô phi'], ['cá rô phi', 'Cá rô phi'],
  ['cá basa', 'Cá basa, phi lê'], ['cá ba sa', 'Cá basa, phi lê'], ['cá hú', 'Cá basa, phi lê'], ['cá bông lau', 'Cá basa, phi lê'],
  ['cá thu', 'Cá thu'], ['cá trắm', 'Cá trắm cỏ'], ['cá chép', 'Cá chép'], ['cá trê', 'Cá trê'], ['cá chốt', 'Cá trê'], ['cá bống', 'Cá bống'],
  ['cá chim', 'Cá chim'], ['cá bớp', 'Cá nục'], ['cá kìm', 'Cá nục'], ['cá ngân', 'Cá nục'], ['cá biển', 'Cá nục'],
  ['lươn', 'Lươn'], ['nghêu', 'Ngao biển trắng'], ['ngao', 'Ngao biển trắng'], ['sò huyết', 'Sò'], ['sò', 'Sò'], ['hến', 'Hến'], ['ốc', 'Ốc bươu'],
  // Đậu nành
  ['đậu hũ non', 'Đậu phụ'], ['đậu hũ chiên', 'Đậu phụ nướng'], ['đậu hũ trắng', 'Đậu phụ'], ['đậu hũ', 'Đậu phụ'], ['đậu phụ', 'Đậu phụ'],
  ['tàu hũ ky', 'Đậu phụ chúc'], ['tàu hủ ky', 'Đậu phụ chúc'], ['tàu hũ', 'Đậu phụ'], ['tàu hủ', 'Đậu phụ'], ['váng đậu', 'Đậu phụ chúc'],
  // Rau, củ, nấm
  ['cà chua', 'Cà chua'], ['cà rốt', 'Cà rốt(củ đỏ, vàng)'], ['khoai tây', 'Khoai tây'], ['khoai lang', 'Khoai lang'], ['khoai môn', 'Khoai môn'], ['khoai sọ', 'Khoai sọ'],
  ['bí đỏ', 'Bí ngô'], ['bí xanh', 'Bí đao (bí xanh)'], ['bí đao', 'Bí đao (bí xanh)'], ['khổ qua', 'Mướp đắng'], ['mướp đắng', 'Mướp đắng'], ['mướp', 'Mướp'], ['bầu', 'Bầu'],
  ['rau muống', 'Rau muống'], ['rau ngót', 'Rau ngót'], ['rau mồng tơi', 'Rau mồng tơi'], ['mồng tơi', 'Rau mồng tơi'], ['rau dền', 'Rau giền cơm'],
  ['cải ngọt', 'Cải ngọt'], ['cải thìa', 'Cải thìa (cải trắng)'], ['cải bẹ xanh', 'Cải xanh'], ['cải xanh', 'Cải xanh'], ['cải thảo', 'Cải bắp'], ['bắp cải', 'Cải bắp'],
  ['giá đỗ', 'Giá đậu xanh'], ['giá', 'Giá đậu xanh'], ['dưa leo', 'Dưa chuột'], ['dưa chuột', 'Dưa chuột'], ['cà tím', 'Cà tím'],
  ['đậu cô ve', 'Đậu cô ve'], ['đậu que', 'Đậu cô ve'], ['đậu hà lan', 'Đậu Hà Lan'], ['đậu bắp', null],
  ['bông cải xanh', 'Súp lơ xanh'], ['súp lơ xanh', 'Súp lơ xanh'], ['súp lơ', 'Súp lơ trắng'], ['cần tây', 'Cần tây'], ['cần nước', 'Cần ta'],
  ['nấm rơm', 'Nấm rơm'], ['nấm đông cô khô', 'Nấm hương khô'], ['nấm hương khô', 'Nấm hương khô'], ['nấm đông cô', 'Nấm hương tươi'], ['nấm hương', 'Nấm hương tươi'],
  ['nấm mèo', 'Mộc nhĩ'], ['mộc nhĩ', 'Mộc nhĩ'], ['nấm kim châm', 'Nấm thường tươi'], ['nấm bào ngư', 'Nấm thường tươi'], ['nấm đùi gà', 'Nấm thường tươi'], ['nấm', 'Nấm thường tươi'],
  ['củ sen', 'Ngó sen'], ['ngó sen', 'Ngó sen'], ['hoa hẹ', 'Hẹ lá'], ['hẹ', 'Hẹ lá'],
  ['hành tây', 'Hành tây'], ['hành hoa', 'Hành lá (hành hoa)'], ['hành lá', 'Hành lá (hành hoa)'], ['hành tím', 'Hành củ tươi'], ['hành khô', 'Hành củ tươi'], ['hành củ', 'Hành củ tươi'],
  ['tỏi tây', 'Tỏi tây (cả lá)'], ['tỏi băm', 'Tỏi ta'], ['tỏi', 'Tỏi ta'], ['gừng tươi', 'Gừng tươi'], ['gừng', 'Gừng tươi'], ['riềng', 'Riềng'], ['nghệ bột', 'Nghệ khô, bột'],
  ['sả', null], ['thì là', null], ['ngò gai', 'Rau mùi'], ['ngò rí', 'Rau mùi'], ['rau mùi', 'Rau mùi'], ['rau ngổ', 'Rau ngổ'],
  ['ớt chuông', 'Ớt đỏ to'], ['ớt hiểm', 'Ớt đỏ to'], ['ớt sừng', 'Ớt đỏ to'], ['ớt đỏ', 'Ớt đỏ to'], ['ớt bột', 'ớt khô bột'], ['ớt', 'Ớt đỏ to'],
  // Trái cây
  ['nước cốt chanh', 'Chanh'], ['chanh', 'Chanh'], ['quất', 'Quất chín (cả vỏ)'], ['tắc', 'Quất chín (cả vỏ)'],
  ['dứa', 'Dứa ta'], ['thơm', 'Dứa ta'], ['khóm', 'Dứa ta'], ['nước cốt me', 'Quả me chua'], ['me chua', 'Quả me chua'], ['me chín', 'Quả me chua'], ['me', 'Quả me chua'],
  ['chuối', 'Chuối tiêu'], ['dừa nạo', 'Cùi dừa già'], ['cơm dừa', 'Cùi dừa già'], ['nước dừa tươi', 'Nước dừa non tươi'], ['nước dừa', 'Nước dừa non tươi'], ['nước cốt dừa', null],
  ['bắp ngọt', 'Ngô bắp tươi'], ['bắp non', 'Ngô bao tử'], ['bắp', 'Ngô bắp tươi'], ['ngô', 'Ngô bắp tươi'], ['măng chua', 'Măng chua'], ['măng tươi', 'Măng chua'], ['măng', 'Măng chua'],
  // Gia vị, dầu
  ['dầu đậu phộng', 'Dầu lạc'], ['dầu lạc', 'Dầu lạc'], ['dầu mè', 'Dầu mè'], ['dầu vừng', 'Dầu mè'],
  // dầu ăn ở VN thường là dầu tinh luyện pha trộn; map 'Dầu thảo mộc (Lạc, vừng...)' làm mọi món dính nhầm peanut + sesame
  ['dầu thực vật', 'Dầu cọ'], ['dầu ăn', 'Dầu cọ'], ['dầu điều', 'Dầu cọ'], ['dầu màu điều', 'Dầu cọ'], ['dầu hành phi', 'Dầu cọ'], ['dầu hào', 'Xì dầu'],
  ['nước mắm cốt', 'Nước mắm cá (loại đặc biệt)'], ['nước mắm cá', 'Nước mắm cá (loại đặc biệt)'], ['nước mắm loại i', 'Nước mắm loại I'], ['nước mắm', 'Nước mắm loại I'],
  ['mắm tôm đặc', 'Mắm tôm đặc'], ['mắm tôm', 'Mắm tôm đặc'], ['mắm tép', 'Mắm tép chua'], ['mắm cá', 'Mắm tép chua'],
  ['nước tương', 'Xì dầu'], ['xì dầu', 'Xì dầu'], ['tương ớt', 'Tương ớt'], ['tương cà', 'Cà chua'],
  ['đường thốt nốt', 'Đường kính'], ['đường phèn', 'Đường kính'], ['đường cát', 'Đường cát'], ['đường kính', 'Đường kính'], ['đường', 'Đường kính'],
  ['nước màu thốt nốt', 'Đường kính'], ['nước màu', 'Đường kính'], ['nước mía', null],
  ['muối ăn', 'Muối'], ['muối', 'Muối'], ['hạt nêm', 'Muối'], ['bột nêm', 'Muối'], ['bột ngọt', null], ['mì chính', null],
  ['hạt tiêu', 'Hạt tiêu'], ['tiêu xay', 'Hạt tiêu'], ['tiêu đen', 'Hạt tiêu'], ['tiêu', 'Hạt tiêu'],
  ['hạt mè', 'Vừng(đen, trắng)'], ['mè rang', 'Vừng(đen, trắng)'], ['mè', 'Vừng(đen, trắng)'], ['vừng', 'Vừng(đen, trắng)'],
  ['đậu phộng', 'Lạc hạt'], ['lạc', 'Lạc hạt'], ['hạt điều đỏ', null], ['hạt điều màu', null],
  ['bột chiên giòn', 'Bột mì'], ['bột mì', 'Bột mì'], ['bột bắp', 'Bột ngô vàng'], ['bột năng', 'Bột sắn'],
  // Tinh bột
  ['cơm nguội', 'Cơm tẻ (gạo tẻ máy nấu chín)'], ['cơm trắng', 'Cơm tẻ (gạo tẻ máy nấu chín)'], ['cơm', 'Cơm tẻ (gạo tẻ máy nấu chín)'],
  ['gạo tẻ', 'Gạo tẻ máy'], ['gạo nếp', 'Gạo nếp (loại thường)'], ['gạo', 'Gạo tẻ máy'],
  ['bún tươi', 'Bún'], ['bún', 'Bún'], ['bánh phở', 'Bánh phở'], ['phở', 'Bánh phở'], ['hủ tiếu', 'Bánh phở'], ['miến dong', 'Miến dong'], ['miến', 'Miến dong'],
  ['bia', 'Bia (cồn: 4,5 g)'], ['củ cải trắng', 'Củ cải trắng'], ['củ cải', 'Củ cải trắng'], ['nếp', 'Gạo nếp cái'], ['hạt sen', 'Hạt sen tươi'],
  ['su su', 'Su su'], ['rau răm', 'Rau răm'], ['sắn', 'Củ sắn'], ['đậu trắng', 'Đậu trắng hạt (Đậu Tây)'], ['nước cam', 'Nước cam tươi'],
  // 'bạc hà' trong canh chua là dọc mùng, không phải kẹo bạc hà
  ['bạc hà', 'Dọc mùng'], ['dọc mùng', 'Dọc mùng'], ['lá chanh', null], ['nước', null],
  ['thịt thăn bò', 'Thịt bò loại I'], ['bắp chuối', 'Hoa chuối'], ['hoa chuối', 'Hoa chuối'], ['lá dứa', null], ['gia vị', null], ['đậu bún', null],
  // đồ chay giả mặn: không lấy dinh dưỡng/dị ứng của nguyên liệu động vật
  ['nước mắm chay', null],
  ['gói gia vị', null], ['mì trứng', 'Bột mì'], ['mì sợi', 'Bột mì'], ['mì gói', 'Bột mì'], ['mì', 'Bột mì'], ['nui', 'Bột mì'], ['bánh mì', 'Bánh mì xíu mại']
];

const ingredientByName = new Map(catalog.map(i => [i.name_vi, i]));
const unknownNames = RAW_SYNONYMS.filter(([, n]) => n !== null && !ingredientByName.has(n));
if (unknownNames.length) throw new Error('Tên FCT không có trong catalog: ' + unknownNames.map(([s, n]) => s + ' -> ' + n).join(', '));

// Sort synonyms strictly by phrase length descending (longest, most specific first)
const SYNONYMS = RAW_SYNONYMS.sort((a, b) => b[0].length - a[0].length);

// Món chay ('cá bống chay', 'sườn non chay') không được map sang thịt/cá/trứng thật
const ANIMAL_CODE_PREFIXES = ['07', '08', '09'];

// Lưới an toàn dị ứng theo từ khóa: áp cho MỌI dòng, kể cả dòng không map được
const ALLERGEN_KEYWORDS = {
  seafood: ['tôm', 'tép', 'cua', 'ghẹ', 'mực', 'bạch tuộc', 'ốc', 'nghêu', 'ngao', 'sò', 'hến', 'ruốc', 'cá'],
  egg: ['trứng', 'hột gà', 'hột vịt'],
  dairy: ['sữa', 'phô mai', 'bơ lạt', 'kem tươi', 'whipping cream'],
  peanut: ['đậu phộng', 'lạc'],
  tree_nut: ['hạt điều', 'óc chó', 'hạnh nhân', 'hạt dẻ', 'macca', 'hồ đào'],
  // không dùng từ đơn 'tương': khớp nhầm 'tương tự', 'tương xí muội' (sốt mận)
  soy: ['đậu nành', 'đậu hũ', 'đậu phụ', 'tàu hũ', 'tàu hủ', 'váng đậu', 'nước tương', 'xì dầu', 'chao',
    'tương bần', 'tương hột', 'tương đen', 'tương đậu', 'tương nếp', 'tương ngô', 'hoisin', 'miso'],
  gluten: ['bột mì', 'bánh mì', 'mì', 'nui', 'bột chiên giòn', 'bánh quy', 'mì căn'],
  sesame: ['mè', 'vừng']
};
// Có từ này thì cả dòng không tính nhóm dị ứng đó (đồ chay giả mặn)
const ALLERGEN_VETO = { seafood: ['chay'], egg: ['chay'] };
// Cụm trông giống chất dị ứng nhưng không phải -> bỏ qua trước khi dò từ khóa
const ALLERGEN_IGNORE = {
  tree_nut: ['hạt điều đỏ', 'hạt điều màu', 'dầu điều', 'màu điều'],
  gluten: ['mì chính'],
  soy: ['tương ớt', 'tương cà']
};
// Gia vị chế biến từ chất dị ứng: VẪN gây dị ứng, nhưng không làm món thành "món hải sản".
// Tách riêng để recipe_allergens.via_condiment phân biệt 2 trường hợp.
const ALLERGEN_CONDIMENTS = {
  seafood: [/(nước\s+)?mắm(\s+\p{L}+)*/gu, /dầu\s+hào(\s+\p{L}+)*/gu]
};

// \b của JS không nhận chữ có dấu tiếng Việt -> tự kiểm ranh giới từ bằng \p{L}
function hasWord(text, phrase) {
  const esc = phrase.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp('(?<![\\p{L}\\p{N}])' + esc + '(?![\\p{L}\\p{N}])', 'u').test(text);
}

const strip = (text, phrases) =>
  phrases.reduce((acc, w) => (w instanceof RegExp ? acc.replace(w, ' ') : acc.split(w).join(' ')), text);

// Chất dị ứng là nguyên liệu chính (không tính phần nằm trong gia vị)
function keywordAllergenCodes(name) {
  const t = name.toLowerCase();
  return Object.keys(ALLERGEN_KEYWORDS).filter((code) => {
    if ((ALLERGEN_VETO[code] || []).some((w) => hasWord(t, w))) return false;
    const rest = strip(t, [...(ALLERGEN_IGNORE[code] || []), ...(ALLERGEN_CONDIMENTS[code] || [])]);
    return ALLERGEN_KEYWORDS[code].some((w) => hasWord(rest, w));
  });
}

// Chất dị ứng chỉ đến từ gia vị (nước mắm, mắm tôm/tép/cá, dầu hào); 'nước mắm chay' không tính
function condimentAllergenCodes(name) {
  const t = name.toLowerCase();
  return Object.keys(ALLERGEN_CONDIMENTS).filter((code) =>
    !(ALLERGEN_VETO[code] || []).some((w) => hasWord(t, w)) &&
    ALLERGEN_CONDIMENTS[code].some((re) => new RegExp(re.source, 'u').test(t)));
}

function lookupIngredient(name) {
  const t = name.toLowerCase().trim();
  return matchIngredient(t) || catalog.find(i => i.name_vi.toLowerCase() === t) || null;
}

function matchIngredient(name) {
  const t = name.toLowerCase().trim();
  for (const [synonym, fctName] of SYNONYMS) {
    if (!hasWord(t, synonym)) continue;
    if (fctName === null) return null;
    const ing = ingredientByName.get(fctName);
    if (hasWord(t, 'chay') && ANIMAL_CODE_PREFIXES.includes(ing.code.slice(0, 2))) return null;
    return ing;
  }
  return null;
}

function stripAccents(str) {
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .toLowerCase()
    .trim();
}

function parseIngredientLine(raw) {
  let line = raw.trim();
  let name = "";
  let qty = 1;
  let unit = "phần";
  let grams = 0;
  let notes = "";

  if (line.includes(':')) {
    const parts = line.split(':');
    name = parts[0].trim();
    const rest = parts.slice(1).join(':').trim();
    
    const parenGrams = rest.match(/\((\d+(?:\.\d+)?)\s*(?:g|gram|gam)\)/i);
    if (parenGrams) {
      grams = parseFloat(parenGrams[1]);
    }

    const qtyMatch = rest.match(/^(\d+(?:\/\d+|\.\d+)?)\s*([a-zA-Z\u00C0-\u1EF9]+(?:\s+[a-zA-Z\u00C0-\u1EF9]+)?)?/);
    if (qtyMatch) {
      let numStr = qtyMatch[1];
      if (numStr.includes('/')) {
        const [num, den] = numStr.split('/').map(Number);
        qty = num / den;
      } else {
        qty = parseFloat(numStr);
      }
      if (qtyMatch[2]) {
        unit = qtyMatch[2].toLowerCase().trim();
      }
    }
    notes = rest;
  } else {
    const numUnitRegex = /^(\d+(?:\/\d+|\.\d+)?)\s*(kg|kí|ký|g|gram|gam|ml|l|lít|muỗng canh|thìa canh|muỗng cà phê|thìa cà phê|muỗng súp|muỗng cafe|tbsp|tsp|chén|bát|tép|củ|trái|quả|cây|nhánh|miếng|bó|lát)\s+(.*)$/i;
    const match = line.match(numUnitRegex);
    if (match) {
      let numStr = match[1];
      if (numStr.includes('/')) {
        const [num, den] = numStr.split('/').map(Number);
        qty = num / den;
      } else {
        qty = parseFloat(numStr);
      }
      unit = match[2].trim().toLowerCase();
      name = match[3].split(',')[0].trim();
      notes = line;
    } else {
      const attachedMatch = line.match(/^(\d+(?:\.\d+)?)(kg|kí|ký|g|gram|gam|ml|l)\s+(.*)$/i);
      if (attachedMatch) {
        qty = parseFloat(attachedMatch[1]);
        unit = attachedMatch[2].trim().toLowerCase();
        name = attachedMatch[3].split(',')[0].trim();
        notes = line;
      } else {
        const numOnlyMatch = line.match(/^(\d+(?:\/\d+|\.\d+)?)\s+(.*)$/);
        if (numOnlyMatch) {
          qty = parseFloat(numOnlyMatch[1]);
          unit = "phần";
          name = numOnlyMatch[2].split(',')[0].trim();
          notes = line;
        } else {
          name = line.split(',')[0].trim();
          qty = 1;
          unit = "ít";
          notes = line;
        }
      }
    }
  }

  // Grams conversion
  if (grams === 0) {
    const u = unit.toLowerCase();
    const n = name.toLowerCase();

    if (u === 'g' || u === 'gram' || u === 'gam') {
      grams = qty;
    } else if (u === 'kg' || u === 'kí' || u === 'ký') {
      grams = qty * 1000;
    } else if (u === 'ml' || u === 'mililit') {
      grams = qty;
    } else if (u === 'l' || u === 'lít') {
      grams = qty * 1000;
    } else if (u.includes('muỗng canh') || u.includes('thìa canh') || u.includes('súp') || u.includes('tbsp')) {
      grams = qty * 15;
    } else if (u.includes('muỗng cà phê') || u.includes('thìa cà phê') || u.includes('tsp') || u.includes('cafe')) {
      grams = qty * 5;
    } else if (u.includes('chén') || u.includes('bát')) {
      grams = qty * 200;
    } else if (u.includes('tép')) {
      grams = qty * 5;
    } else if (u.includes('củ')) {
      if (n.includes('hành tím') || n.includes('hành khô')) grams = qty * 15;
      else if (n.includes('hành tây')) grams = qty * 120;
      else if (n.includes('gừng')) grams = qty * 20;
      else if (n.includes('cà rốt')) grams = qty * 100;
      else if (n.includes('khoai tây')) grams = qty * 150;
      else grams = qty * 50;
    } else if (u.includes('trái') || u.includes('quả')) {
      if (n.includes('trứng gà')) grams = qty * 50;
      else if (n.includes('trứng vịt')) grams = qty * 65;
      else if (n.includes('cà chua')) grams = qty * 75;
      else if (n.includes('ớt')) grams = qty * 5;
      else if (n.includes('chanh') || n.includes('tắc')) grams = qty * 30;
      else if (n.includes('khổ qua')) grams = qty * 150;
      else if (n.includes('dưa leo')) grams = qty * 100;
      else grams = qty * 60;
    } else if (u.includes('cây') || u.includes('nhánh')) {
      if (n.includes('sả')) grams = qty * 25;
      else if (n.includes('hành lá')) grams = qty * 15;
      else if (n.includes('cần')) grams = qty * 30;
      else grams = qty * 20;
    } else if (u.includes('miếng')) {
      if (n.includes('đậu hũ') || n.includes('đậu phụ')) grams = qty * 100;
      else grams = qty * 50;
    } else if (u.includes('bó')) {
      grams = qty * 300;
    } else if (u.includes('lát')) {
      grams = qty * 5;
    } else if (u.includes('ít') || u.includes('chút') || u.includes('nhúm')) {
      grams = 2;
    } else {
      grams = qty > 20 ? qty : qty * 30;
    }
  }

  // Lookup matching ingredient
  let matchedIngredient = null;
  const cleanNameLower = name.toLowerCase().trim();

  // 1. Từ điển đồng nghĩa (theo từ). 2. Trùng đúng tên FCT có dấu.
  // Bỏ so khớp mờ không dấu: 'ga' khớp cả 'gà', 'cà', 'gạ'... gây map sai loài.
  matchedIngredient = lookupIngredient(cleanNameLower);

  return {
    raw_text: raw,
    ingredient_name_raw: name || raw,
    amount: Math.round(qty * 100) / 100,
    unit: unit,
    amount_g: Math.round(grams * 10) / 10,
    matched_ingredient_id: matchedIngredient ? matchedIngredient.id : null,
    matched_ingredient_code: matchedIngredient ? matchedIngredient.code : null,
    matched_ingredient_name: matchedIngredient ? matchedIngredient.name_vi : null,
    calories_per_100g: matchedIngredient ? Number(matchedIngredient.calories_per_100g) : 0,
    protein_per_100g: matchedIngredient ? Number(matchedIngredient.protein_per_100g) : 0,
    fat_per_100g: matchedIngredient ? Number(matchedIngredient.fat_per_100g) : 0,
    carbs_per_100g: matchedIngredient ? Number(matchedIngredient.carbs_per_100g) : 0,
    fiber_per_100g: matchedIngredient ? Number(matchedIngredient.fiber_per_100g) : 0,
    sodium_mg_per_100g: matchedIngredient ? Number(matchedIngredient.sodium_mg) : 0
  };
}

module.exports = {
  parseIngredientLine,
  stripAccents,
  catalog,
  allergensByIngrId,
  lookupIngredient,
  keywordAllergenCodes,
  condimentAllergenCodes
};
