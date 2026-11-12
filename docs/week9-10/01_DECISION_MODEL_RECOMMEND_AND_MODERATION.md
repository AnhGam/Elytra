# Mô hình quyết định kiểu Jev: chọn món + kiểm duyệt món upload

## Mô hình quyết định (kiểu Jev) là gì

Nhận **trạng thái** + **câu hỏi có kiểu**, trả **đáp án có kiểu kèm xác suất**, không sinh văn bản. Jev (TypeSafe) là model đầu tiên; nay nhiều hãng có model cùng kiểu.

| Primitive | Hỏi | Trả về |
| --- | --- | --- |
| Choice | Chọn 1 trong N | Lựa chọn + xác suất từng lựa chọn |
| Noul | Điều kiện có đúng không | Xác suất "có" |
| Score | Nằm đâu trên thang | Vị trí + xác suất từng mức |

Tách việc: **chọn** (quyết định, cần xác suất) giao cho mô hình quyết định; **giải thích** (viết chữ) giao cho Gemini chat; **an toàn** (dị ứng) giữ ở SQL vì phải đúng 100%.

## Chọn model (research 12/11/2026)

| Phương án | Kết luận |
| --- | --- |
| **Gemini Decision 1** (`gemini-decision-1`, Google, ra 11/11/2026) | **Dùng.** Có gói không tốn phí trong AI Studio, dùng chung `GEMINI_API_KEY`. Choice 2–255 lựa chọn, tối đa 1.000 câu hỏi/request |
| Jev (TypeSafe) qua OpenRouter | Không dùng: trả phí ($0,042/1M token), credit miễn phí $5 tạm dừng từ 27/9/2026 |
| Quyet-1.0-Small (328M, Apache-2.0) | **Dự phòng** khi Google siết gói miễn phí. Bản mở tốt nhất cho tiếng Việt: macro-F1 53,6 so với Jev 69,2 (preprint UIT, arXiv 2610.31422). Phải tự host trên VM; tối đa 10 lựa chọn |
| Laya, Von | Không dùng: gần mức đoán bừa trên bảng độc lập; Von chỉ tiếng Anh |
| Tự dựng (đọc logits LLM) | Không làm được trên host miễn phí: Groq không trả logprobs, Supabase Edge không chạy LLM |

Gói miễn phí: Google được dùng dữ liệu gửi lên để cải thiện sản phẩm → chỉ gửi dữ liệu cần cho quyết định (không gửi cân nặng, tuổi). Hạn mức gói miễn phí chưa công bố. Chưa ai đo model này với tiếng Việt → câu hỏi/tiêu chí viết bằng tiếng Anh.

## Gợi ý món (đã làm: `supabase/functions/recommend-ai`)

```
SQL recommend_dishes_for_user : lọc cứng dị ứng, món từ chối, gia vị; chấm điểm calo/protein → 10 ứng viên
Gemini Decision 1 (choice)    : state = mục tiêu, calo còn lại hôm nay, món đã ăn 3 ngày, món vừa từ chối, câu người dùng gõ
                                → xác suất từng món → xếp lại. Lỗi/timeout 3 s → giữ thứ tự SQL (decision_mode = "sql")
Gemini chat                   : chỉ viết lời giải thích cho món đã chọn. Lỗi → câu mẫu (fallback)
```

- Món chứa chất dị ứng không bao giờ tới được mô hình (đã lọc ở SQL).
- Xác suất mỗi lượt lưu ở `chat_messages.metadata.decision_probabilities`, món bị từ chối ở `chat_messages.rejected_recipe_ids`: dữ liệu để hiệu chỉnh và tự train sau này.
- Câu người dùng gõ tự do cũng do Gemini Decision 1 phân loại (choice: `recommend` / `how_to_cook` / `nutrition` / `out_of_scope`); `out_of_scope` chỉ khi chắc ≥ 0,7, lỗi thì coi như `recommend`.
- Test: `node supabase/scripts/test_recommend_ai_unit.mjs` (định dạng request, map xác suất, phân loại câu, fallback); E2E thật: `test_recommend_ai_e2e.mjs`.

## Kiểm duyệt món upload (chưa làm, chờ tính năng upload)

### Vì sao cần

Trước đây toàn bộ món do nhóm tự nhập/crawl rồi sửa tay. Khi mở cho người dùng upload, các lỗi đã gặp trong dataset sẽ lặp lại mà không ai kiểm:

| Lỗi đã gặp | Ví dụ |
| --- | --- |
| Calo vô lý do số khẩu phần sai | Chè đậu trắng 1.244 kcal/chén, Súp nui gà 1.050 kcal |
| Gia vị bị xếp thành món chính | Muối tôm khô, Tỏi ngâm giấm |
| Thiếu tag dị ứng | Món có mè nhưng không có `sesame` |
| Không phải món ăn / spam | (chưa gặp, sẽ gặp khi mở upload) |

### Luồng

```
Người dùng upload món
  → create_recipe_with_nutrition (service_role) → is_verified = false (mặc định, migration 20261106090000)
  → Gemini Decision 1: 1 request, nhiều câu hỏi
  → Áp ngưỡng
      ≥ 0,9 hợp lệ            → is_verified = true (tự duyệt)
      ≥ 0,9 "không phải món"  → từ chối
      còn lại                 → hàng chờ admin duyệt tay
```

Món chưa duyệt không lộ ra: policy SELECT, `search_recipes`, `recommend_dishes_for_user`, `log_meal` đều lọc `is_verified`.

### Câu hỏi kiểm duyệt

`input` = tên món, danh mục người dùng chọn, số khẩu phần, danh sách nguyên liệu + khối lượng, kcal/khẩu phần do engine tính (+ ảnh món nếu có).

| Khóa | Loại | Câu hỏi | Dùng để |
| --- | --- | --- | --- |
| `is_dish` | Noul | Đây có phải công thức món ăn thật không? | Chặn spam |
| `category` | Choice | Món thuộc danh mục nào? (gồm `gia_vi_an_kem`) | Bắt gia vị/đồ chấm xếp nhầm |
| `allergen_<code>` | Noul | Món có chứa <chất dị ứng> không? | Bắt tag dị ứng bộ từ khóa bỏ sót |
| `kcal_plausible` | Score | Kcal/khẩu phần hợp lý cho 1 người lớn ở mức nào? | Bắt lỗi số khẩu phần / khối lượng |

### Quy tắc an toàn

- **Dị ứng: mô hình chỉ được THÊM tag, không được GỠ.** Bộ từ khóa + `ingredient_allergens` vẫn là nguồn chính; lọc dị ứng khi gợi ý vẫn là lọc cứng bằng SQL.
- Mô hình không sửa số liệu dinh dưỡng; kcal vẫn do engine tính từ nguyên liệu. Mô hình chỉ báo "đáng ngờ" để chuyển admin.
- Mô hình lỗi / timeout → món ở lại hàng chờ admin (không tự duyệt).

### Ngưỡng

0,9 (đã chốt), nhưng **chỉ bật tự duyệt sau khi đo trên bộ ~100 món Việt gắn nhãn tay**: chọn ngưỡng sao cho không món sai nào được tự duyệt. Trước đó: mô hình chấm sẵn, **admin duyệt 100%**. Đổi model phải chọn lại ngưỡng (mỗi model cho xác suất khác nhau).

## Rủi ro

- Gemini Decision 1 mới ra 11/11/2026: API `v1beta` có thể đổi; hạn mức gói miễn phí chưa công bố.
- Chưa đo độ chính xác với món ăn tiếng Việt.
