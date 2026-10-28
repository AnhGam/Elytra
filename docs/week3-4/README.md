# Tài liệu Kỹ thuật: Sprint 3 (Tuần 3 & 4)

Thư mục này chứa toàn bộ các tài liệu báo cáo kỹ thuật hoàn thành trong **Giai đoạn Sprint 3 (23/09/2026 - 07/10/2026)** theo Đề cương Đồ án 1.

---

## Danh mục Tài liệu

1. **[01_DATABASE_INITIALIZATION_AND_IMPORT.md](./01_DATABASE_INITIALIZATION_AND_IMPORT.md)**
   - Thiết kế lược đồ cơ sở dữ liệu (Database Schema) trên Supabase PostgreSQL (`ingredient_categories`, `allergens`, `ingredients`, `ingredient_allergens`, `profiles`, `user_allergens`).
   - Thiết lập chỉ mục (Indexes) và chính sách bảo mật cấp hàng (Row Level Security - RLS).
   - Quy trình trích xuất, làm sạch và chuẩn hóa toàn bộ 620 nguyên liệu thực phẩm từ Bảng thành phần thực phẩm Việt Nam 2017 (Bộ Y tế).
   - Kỹ thuật gán nhãn dị ứng chính xác và quy đổi khối lượng riêng (g/ml).
   - Kết quả đối soát số lượng bản ghi thực tế trong cơ sở dữ liệu.

2. **[02_EDGE_FUNCTION_NUTRITION_ENGINE.md](./02_EDGE_FUNCTION_NUTRITION_ENGINE.md)**
   - Cơ sở khoa học và công thức tính toán: Chỉ số BMI (chuẩn WHO Châu Á), BMR (Mifflin-St Jeor), TDEE (hệ số hoạt động PAL).
   - Cơ chế điều chỉnh Calo mục tiêu và sàn an toàn chuyển hóa (1200 kcal/nữ, 1500 kcal/nam).
   - Thuật toán phân bổ đa lượng (Protein theo g/kg thể trọng, Fat 25%, Carbs phần còn lại, Chất xơ và Nước).
   - Thiết kế và triển khai đồng thời ở 2 tầng:
     - Tầng Database: Stored Function `calculate_nutrition_targets` (PL/pgSQL).
     - Tầng Serverless: Supabase Edge Function `calculate-bmr-tdee` (Deno Runtime, TypeScript).
   - Đặc tả giao diện lập trình (API Specification) và kết quả kiểm thử tự động với 3 ca kiểm thử thực tế.

---

## Tệp mã nguồn và Cấu hình liên quan

- **Mã nguồn Edge Function:** [`Elytra/supabase/functions/calculate-bmr-tdee/index.ts`](file:///d:/Antigravity/DA1/Elytra/supabase/functions/calculate-bmr-tdee/index.ts)
- **Tệp di chuyển cơ sở dữ liệu:** [`Elytra/supabase/migrations/`](file:///d:/Antigravity/DA1/Elytra/supabase/migrations/)
- **Định nghĩa kiểu TypeScript:** [`Elytra/src/types/database.types.ts`](file:///d:/Antigravity/DA1/Elytra/src/types/database.types.ts)
- **Kịch bản kiểm thử tự động:** [`Elytra/tests/test_nutrition_engine.js`](file:///d:/Antigravity/DA1/Elytra/tests/test_nutrition_engine.js)
