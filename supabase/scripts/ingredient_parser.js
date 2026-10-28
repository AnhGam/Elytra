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
  ['chuối', 'Chuối tiêu'], ['dừa nạo', 'Cùi dừa già'], ['cơm dừa', 'Cùi dừa già'], ['nước dừa tươi', 'Nước dừa non tươi'], ['nước dừa', 'Nước dừa non tươi'], ['nước cốt dừa', 'Nước cốt dừa'],
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
  ['su su', 'Su su'], ['rau răm', 'Rau răm'], // Nguồn bepxua là miền Nam: 'củ sắn' = củ đậu (jicama, 31 kcal), khoai mì mới là sắn của miền Bắc (158 kcal)
  ['sắn', 'Củ đậu'], ['củ sắn', 'Củ đậu'], ['củ đậu', 'Củ đậu'], ['khoai mì', 'Củ sắn'], ['đậu trắng', 'Đậu trắng hạt (Đậu Tây)'], ['nước cam', 'Nước cam tươi'],
  // 'bạc hà' trong canh chua là dọc mùng, không phải kẹo bạc hà
  ['bạc hà', 'Dọc mùng'], ['dọc mùng', 'Dọc mùng'], ['lá chanh', null], ['nước', null],
  ['thịt thăn bò', 'Thịt bò loại I'], ['bắp chuối', 'Hoa chuối'], ['hoa chuối', 'Hoa chuối'], ['lá dứa', null], ['gia vị', null], ['đậu bún', null],
  // đồ chay giả mặn: không lấy dinh dưỡng/dị ứng của nguyên liệu động vật.
  // Sườn/bò/cá chay thường làm từ protein đậu nành tách béo (TVP) -> tạm dùng 'Bột đậu tương đã loại béo' (có cả tag soy)
  ['sườn non chay', 'Bột đậu tương đã loại béo (đậu nành)'], ['sườn chay', 'Bột đậu tương đã loại béo (đậu nành)'],
  ['bò lát chay', 'Bột đậu tương đã loại béo (đậu nành)'], ['cá bống chay', 'Bột đậu tương đã loại béo (đậu nành)'],
  ['nước mắm chay', null],
  ['gói gia vị', null], ['mì trứng', 'Bột mì'], ['mì sợi', 'Bột mì'], ['mì gói', 'Bột mì'], ['mì', 'Bột mì'], ['nui', 'Bột mì'],
  // FCT không có bánh mì trơn; 'Bánh mì xíu mại' là món ăn (prepared_dishes), không phải nguyên liệu. Dị ứng gluten vẫn bắt qua từ khóa
  ['bánh mì', null]
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

// Phần thực sự ăn vào (%), so với khối lượng ghi trong công thức. FCT tính trên 100 g phần ăn được,
// nhưng công thức thường cân nguyên con/nguyên trái (gà 2 kg, sườn 1 kg, tôm 2 kg) -> trừ xương, vỏ theo edible_portion_pct.
// Đong bằng muỗng/chén/ml hoặc tên đã ghi rõ sơ chế (băm, phi lê, bóc vỏ...) thì coi là ăn hết.
const MEASURED_AFTER_PREP_UNITS = ['muỗng canh', 'muỗng cafe', 'muỗng cà phê', 'muỗng cà', 'muỗng', 'thìa', 'chén', 'bát', 'ml', 'lít', 'vá', 'gói', 'ống', 'túi'];
const ALREADY_EDIBLE_WORDS = ['phi lê', 'fillet', 'xay', 'bằm', 'băm', 'bào', 'nạo', 'xắt', 'thái', 'lát', 'sợi', 'bột',
  'bóc vỏ', 'lột vỏ', 'bỏ vỏ', 'bỏ xương', 'rút xương', 'lóc xương', 'nạc', 'thăn', 'ức', 'nõn', 'tim'];
function consumedPct(name, unit, ing) {
  if (!ing || !(Number(ing.edible_portion_pct) < 100)) return 100;
  const u = (unit || '').toLowerCase().trim();
  if (MEASURED_AFTER_PREP_UNITS.some((w) => u.startsWith(w))) return 100;
  const t = name.toLowerCase();
  // 'thịt' chỉ tính khi đứng đầu (thịt bò, thịt xay); 'cá biển thịt chắc' vẫn là cá nguyên con
  if (t.trim().startsWith('thịt') || ALREADY_EDIBLE_WORDS.some((w) => hasWord(t, w))) return 100;
  return Number(ing.edible_portion_pct);
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

// ===== Đọc số lượng =====
// Bản cũ chỉ hiểu số kiểu '1.5' và đơn vị 2 chữ: '1,5 kg' gà -> 30 g, '⅓ muỗng cafe' -> 30 g, 'muỗng cà phê' -> 30 g,
// '(1 con vừa ăn)' -> 2 g. Calo nhiều món lệch vài lần.
const FRACTIONS = { '½': 0.5, '⅓': 1 / 3, '⅔': 2 / 3, '¼': 0.25, '¾': 0.75, '⅕': 0.2, '⅛': 0.125 };
const NUM = '\\d+(?:[.,]\\d+)?(?:\\s*\\/\\s*\\d+)?';

// "1,5" -> 1.5 ; "1/2" -> 0.5 ; "1 ½" -> 1.5 ; "3-4" / "3 đến 4" -> 3.5 (lấy trung bình)
function parseNumber(text) {
  let t = text;
  for (const [ch, v] of Object.entries(FRACTIONS)) t = t.replace(new RegExp(`(\\d+)?\\s*${ch}`, 'g'), (m, whole) => String((whole ? Number(whole) : 0) + v));
  const range = t.match(new RegExp(`(${NUM})\\s*(?:-|–|~|đến|tới)\\s*(${NUM})`));
  const one = (s) => {
    s = s.replace(',', '.');
    const mixed = s.match(/^(\d+)\s+(\d+)\s*\/\s*(\d+)$/);
    if (mixed) return Number(mixed[1]) + Number(mixed[2]) / Number(mixed[3]);
    const frac = s.match(/^(\d+(?:\.\d+)?)\s*\/\s*(\d+)$/);
    return frac ? Number(frac[1]) / Number(frac[2]) : Number(s);
  };
  if (range) return { value: (one(range[1]) + one(range[2])) / 2, index: range.index, length: range[0].length };
  const m = t.match(new RegExp(`(\\d+\\s+\\d+\\s*\\/\\s*\\d+|${NUM})`));
  return m ? { value: one(m[1]), index: m.index, length: m[0].length, text: t } : null;
}

// [cụm, loại, hệ số]: g = gam; ml = mililit (nhân tỉ trọng nguyên liệu); count = đơn vị đếm (tra khối lượng chuẩn)
const UNITS = [
  ['muỗng cà phê', 'ml', 5], ['thìa cà phê', 'ml', 5], ['muỗng cafe', 'ml', 5], ['muỗng cà', 'ml', 5], ['tsp', 'ml', 5],
  ['muỗng canh', 'ml', 15], ['thìa canh', 'ml', 15], ['muỗng súp', 'ml', 15], ['tbsp', 'ml', 15], ['muỗng', 'ml', 15], ['thìa', 'ml', 5],
  ['kg', 'g', 1000], ['kí', 'g', 1000], ['ký', 'g', 1000], ['lạng', 'g', 100], ['gram', 'g', 1], ['gam', 'g', 1], ['gr', 'g', 1], ['g', 'g', 1],
  ['lít', 'ml', 1000], ['lit', 'ml', 1000], ['ml', 'ml', 1], ['l', 'ml', 1000], ['chén', 'ml', 200], ['bát', 'ml', 200], ['vá', 'ml', 100], ['ly', 'ml', 250],
  ['tép', 'count', 0], ['củ', 'count', 0], ['trái', 'count', 0], ['quả', 'count', 0], ['con', 'count', 0], ['cây', 'count', 0],
  ['nhánh', 'count', 0], ['miếng', 'count', 0], ['bó', 'count', 0], ['lát', 'count', 0], ['gói', 'count', 0], ['hộp', 'count', 0],
  ['lon', 'count', 0], ['cái', 'count', 0], ['sợi', 'count', 0], ['bắp', 'count', 0], ['tai', 'count', 0],
  // không ghi lượng cụ thể ('1 ít', 'chút'): chỉ là nêm/rắc thêm
  ['ít', 'small', 2], ['chút', 'small', 2], ['nhúm', 'small', 2], ['xíu', 'small', 2]
];

// Khối lượng chuẩn (g, khối lượng mua) cho đơn vị đếm. Ước tính thông dụng ở chợ VN.
const COUNT_WEIGHTS = [
  [['gà ta', 'gà tre', 'gà'], { con: 1500, cái: 300, default: 300 }],
  [['vịt'], { con: 2000, default: 500 }],
  [['cá'], { con: 500, default: 500 }],
  [['tôm'], { con: 25, default: 25 }], [['mực'], { con: 250, default: 250 }], [['cua', 'ghẹ'], { con: 200, default: 200 }],
  [['ốc'], { con: 15, default: 15 }],
  [['lòng đỏ'], { default: 17 }], [['lòng trắng'], { default: 33 }],
  [['trứng cút', 'trứng chim cút'], { default: 10 }], [['trứng vịt', 'hột vịt'], { default: 65 }], [['trứng', 'hột gà'], { default: 50 }],
  [['tỏi'], { tép: 4, củ: 40, default: 4 }], [['hành tím', 'hành khô'], { default: 15 }], [['hành tây'], { default: 150 }],
  [['hành lá', 'hành'], { default: 10 }], [['sả'], { default: 25 }], [['gừng', 'riềng', 'nghệ'], { lát: 2, default: 20 }],
  [['ớt'], { default: 5 }], [['chanh'], { default: 40 }], [['tắc', 'quất'], { default: 15 }], [['me'], { default: 15 }],
  [['cà chua'], { default: 100 }], [['cà tím'], { default: 200 }], [['cà rốt'], { default: 120 }], [['khoai tây'], { default: 150 }],
  [['khoai lang'], { default: 200 }], [['củ cải'], { default: 300 }], [['củ sen'], { default: 200 }], [['sắn'], { default: 300 }],
  [['đậu bắp'], { default: 15 }], [['bắp chuối'], { default: 400 }], [['bắp', 'ngô'], { default: 300 }], [['thơm', 'dứa', 'khóm'], { default: 1000 }],
  [['khổ qua', 'mướp đắng'], { default: 200 }], [['dưa leo', 'dưa chuột'], { default: 150 }], [['su su'], { default: 250 }],
  [['mướp'], { default: 300 }], [['bí'], { default: 1000 }],
  [['đậu hũ', 'đậu phụ', 'tàu hũ', 'tàu hủ'], { default: 100 }],
  [['ngò', 'rau mùi', 'húng', 'rau răm', 'thì là'], { default: 5 }], [['cần'], { default: 30 }],
  [['nấm hương', 'nấm đông cô'], { default: 15 }], [['mì gói', 'mì tôm', 'mì'], { default: 75 }], [['tiêu'], { default: 5 }],
];
const COUNT_UNIT_DEFAULT = { sợi: 0.5, bó: 300, lát: 5, gói: 50, hộp: 300, lon: 300, miếng: 50, tép: 4, cây: 15, nhánh: 15 };

// Tinh bột chính mà bài gốc không ghi lượng ("Bún tươi", "Hủ tiếu khô"): tính theo khẩu phần chuẩn của nam trưởng thành.
// Không có quy chuẩn chính thức; các trang y tế dùng 150 g bún/tô vừa (Long Châu, HelloBacsi), 190–200 g bún bò Huế/bún riêu
// (Bazaar), lẩu ~250 g/người (Bách hóa XANH). Chọn 200 g tươi (~80 g sợi khô). Đổi ở đây nếu nhóm có số chính thức.
const STAPLE_PER_SERVING_G = [['bún', 200], ['hủ tiếu', 200], ['bánh phở', 200], ['phở', 200]];
function staplePerServing(name) {
  const t = name.toLowerCase();
  const hit = STAPLE_PER_SERVING_G.find(([k]) => hasWord(t, k));
  return hit ? hit[1] : null;
}

function countWeight(name, unit) {
  const t = name.toLowerCase();
  // Cụm khớp dài nhất thắng: 'trứng gà' phải thắng 'gà'
  let best = null, bestLen = 0;
  for (const [keys, w] of COUNT_WEIGHTS) for (const k of keys) if (k.length > bestLen && hasWord(t, k)) { best = w; bestLen = k.length; }
  if (best) return best[unit] ?? best.default;
  return COUNT_UNIT_DEFAULT[unit] ?? 100;
}

// Khối lượng ghi rõ trong ngoặc thắng mọi suy luận: '1 vá (khoảng 150ml)', '(200g)'
function explicitAmount(text) {
  const m = text.match(new RegExp(`\\(\\s*(?:khoảng|tầm|chừng)?\\s*(${NUM})\\s*(kg|g|gr|gram|gam|ml|l|lít)\\s*\\)`, 'i'));
  if (!m) return null;
  const v = Number(m[1].replace(',', '.')), u = m[2].toLowerCase();
  return u === 'kg' ? { g: v * 1000 } : ['l', 'lít'].includes(u) ? { ml: v * 1000 } : u === 'ml' ? { ml: v } : { g: v };
}

function findUnit(text) {
  const t = text.toLowerCase();
  for (const [word, kind, factor] of UNITS) {
    const m = t.match(new RegExp(`^\\s*${word.replace(/\s+/g, '\\s+')}(?![\\p{L}])`, 'u'));
    if (m) return { word, kind, factor };
  }
  return null;
}

function decodeHtml(t) {
  return t.replace(/&#(\d+);/g, (m, n) => String.fromCharCode(Number(n))).replace(/&amp;/g, '&').replace(/&nbsp;/g, ' ');
}

function parseIngredientLine(raw) {
  const line = decodeHtml(raw).trim();
  let name, rest;
  if (line.includes(':')) {
    name = line.slice(0, line.indexOf(':')).trim();
    rest = line.slice(line.indexOf(':') + 1).trim();
  } else {
    // "500g thịt bò", "2 quả trứng gà", "Cá chim biển (1 con vừa ăn)", "Dầu ăn"
    const lead = line.match(new RegExp(`^((?:${NUM}|[½⅓⅔¼¾⅕⅛])\\s*(?:(?:-|–)\\s*${NUM}\\s*)?)(.*)$`));
    if (lead) {
      const afterNum = lead[2];
      const u = findUnit(afterNum);
      rest = lead[1] + (u ? afterNum.slice(0, afterNum.toLowerCase().indexOf(u.word) + u.word.length) : '');
      name = (u ? afterNum.slice(afterNum.toLowerCase().indexOf(u.word) + u.word.length) : afterNum).split(',')[0].trim();
    } else {
      name = line.split(',')[0].trim();
      const paren = line.match(/\(([^)]*\d[^)]*)\)/);
      rest = paren ? paren[1] : '';
    }
  }
  // Số lượng nằm trong ngoặc ở phần tên: "Cá chim biển (1 con vừa ăn)"
  if (!/\d|[½⅓⅔¼¾]/.test(rest)) {
    const paren = name.match(/\(([^)]*\d[^)]*)\)/);
    if (paren) rest = paren[1] + ' ' + rest;
  }
  const cleanName = name.replace(/\([^)]*\)?/g, '').trim() || name;

  const num = parseNumber(rest);
  const qty = num ? num.value : 1;
  const afterNum = num ? (num.text ?? rest).slice(num.index + num.length) : rest;
  const u = findUnit(afterNum);
  const unit = u ? u.word : num ? 'phần' : 'ít';

  const matchedIngredient = lookupIngredient(cleanName.toLowerCase().trim());
  const density = matchedIngredient ? Number(matchedIngredient.density_g_per_ml) || 1 : 1;

  let grams;
  const explicit = explicitAmount(line);
  if (explicit) grams = explicit.g ?? explicit.ml * density;
  else if (u && u.kind === 'g') grams = qty * u.factor;
  else if (u && u.kind === 'ml') grams = qty * u.factor * density;
  else if (u && u.kind === 'small') grams = u.factor;
  else if (u && u.kind === 'count') grams = qty * countWeight(cleanName, u.word);
  else if (num) grams = qty * countWeight(cleanName, 'default'); // "bắp chuối: 1", "Trứng gà: 2"
  else grams = 2; // không ghi lượng ("Dầu ăn", "Tiêu xay"): chỉ là nêm/rắc thêm

  return {
    raw_text: raw,
    ingredient_name_raw: cleanName || raw,
    amount: Math.round(qty * 100) / 100,
    unit,
    amount_g: Math.round(grams * 10) / 10,
    quantity_missing: !num && !explicit,
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
  condimentAllergenCodes,
  consumedPct,
  staplePerServing
};
