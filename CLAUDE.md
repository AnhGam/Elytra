# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Elytra: app Android (Flutter) gợi ý dinh dưỡng và món ăn. Mọi con số dinh dưỡng do rule-based engine và DB tính; AI (Gemini, gọi từ Edge Function) chỉ lo phần hội thoại.

## Bố cục repo

- `app/` – ứng dụng Flutter (mọi lệnh `flutter` chạy trong thư mục này).
- `supabase/` – back-end (migrations, Edge Functions). Back-end là **Supabase production**; nhánh này **KHÔNG sửa `supabase/`**.
- `docs/api-contract.md` – đặc tả request/response của Edge Functions.
- RPC `search_recipes`, cột `recipe_allergens.via_condiment` và `/meal-logs` đã chạy trên production nhưng migration/đặc tả chỉ có ở nhánh PR #4 (chưa merge, không merge vào đây): đọc bằng `git show origin/feat/meal-logs-sprint-5:<đường dẫn>` (vd `docs/api-contract.md` mục 4).
- `docs/design/sprint4/README.md` – thiết kế và quy ước màn hình Sprint 4 (Tìm kiếm món, Chi tiết món), kèm node Figma và ảnh trong `screens/`. Thiết kế triển khai đã duyệt: `docs/superpowers/specs/2026-10-28-recipe-search-detail-design.md`.

## Lệnh (chạy trong `app/`)

```powershell
flutter pub get
flutter analyze                                   # phải sạch trước khi commit
flutter test                                      # toàn bộ unit test
flutter test test/nutrition_calculator_test.dart  # một file
flutter test --plain-name "tên test"              # một test theo tên
flutter run --dart-define-from-file=env.json      # cần app/env.json (copy từ env.example.json)
```

`env.json` chứa `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `USE_MOCK_CALC`; đọc qua `String.fromEnvironment` trong `main.dart`. Không commit file này.

## Kiến trúc app

- `lib/main.dart` khởi tạo Supabase và export client toàn cục `supabase`; các repository dùng trực tiếp biến này.
- `lib/core/router.dart`: go_router với `redirect` tập trung. `AuthNotifier` nghe `onAuthStateChange` để redirect chạy lại khi đăng nhập/đăng xuất/khôi phục mật khẩu. `publicRoutes` / `guestOnlyRoutes` quyết định màn nào cần đăng nhập. `/result` nhận `BodyInfo` qua `state.extra`.
- Luồng onboarding: khai báo thể trạng khi chưa đăng nhập (`/onboarding` → `/result`) → giữ trong `pendingBodyInfo` (`core/pending_onboarding.dart`) → đăng ký/đăng nhập → `ProfileGate` (`/gate`) lưu hồ sơ qua `nutritionRepo` rồi vào `/home`. Bảng `profiles` có sẵn dòng do trigger tạo, nên "đã khai báo" = `target_calories != null`.
- `features/<tên>/`: mỗi tính năng gồm screen, repository (singleton cấp file, vd. `nutritionRepo`), logic thuần (vd. `nutrition_calculator.dart`, `body_info_rules.dart`) và `widgets/`. Unit test nhắm vào logic thuần.
- `NutritionCalculator` phải khớp công thức trong DB; RLS chỉ cho người dùng sửa dòng `profiles` của chính mình.

## Quy ước UI

- Màu: chỉ dùng `AppColors` trong `app/lib/core/theme.dart`, không hard-code mã màu. Theme dựng bằng `buildAppTheme()`.
- Font: Be Vietnam Pro (qua `google_fonts`, đã đặt trong theme).
- Số hiển thị kiểu Việt Nam, dùng `NumberFormat(..., 'vi')` của `intl`: `"38,5 g"`, `"1.968 kcal"` (phẩy thập phân, chấm phân cách nghìn).
- Chuỗi giao diện và comment code viết bằng tiếng Việt.

## Quy trình git

- `main` được bảo vệ; mọi thay đổi qua Pull Request, cần thành viên còn lại duyệt.
- Nhánh: `feat/...`, `fix/...`, `docs/...`, `chore/...`. Commit: `loại(phạm vi): mô tả`, vd. `feat(auth): login and register screens`.
