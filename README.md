# Elytra

Ứng dụng Android gợi ý dinh dưỡng và món ăn cá nhân hóa bằng AI.
Đồ án 1 – Trường Đại học Công nghệ Thông tin – ĐHQG TP.HCM.

Elytra ước tính nhu cầu năng lượng hằng ngày (BMR, TDEE, macro) từ thể trạng và mục tiêu của người dùng, gợi ý món ăn phù hợp với lượng calo còn lại, và có chatbot giải thích gợi ý. Mọi con số dinh dưỡng do rule-based engine và cơ sở dữ liệu tính; AI chỉ đảm nhận phần hội thoại.

## Công nghệ

| Thành phần | Công nghệ |
| --- | --- |
| Ứng dụng di động | Flutter (Android) |
| Xác thực | Supabase Auth (email + mật khẩu) |
| Cơ sở dữ liệu | Supabase PostgreSQL, bảo vệ bằng Row Level Security |
| Lưu trữ ảnh | Supabase Storage |
| Xử lý phía server | Supabase Edge Functions (TypeScript / Deno) |
| AI chatbot | Gemini API (gọi từ Edge Function, không nằm trong app) |

## Cấu trúc thư mục

```textQ
elytra/
├─ app/            # Ứng dụng Flutter
│  ├─ lib/
│  │  ├─ main.dart
│  │  ├─ core/     # env, Supabase client, router, theme
│  │  └─ features/ # auth, onboarding, nutrition, ...
│  ├─ test/
│  └─ env.example.json
├─ supabase/       # Back-end: migrations, Edge Functions, config
├─ docs/           # api-contract.md, ảnh thiết kế
└─ README.md
```

## Yêu cầu

- Flutter SDK (kênh stable), kiểm tra bằng `flutter doctor`
- Android Studio (Android SDK, NDK, máy ảo) hoặc điện thoại Android bật Gỡ lỗi USB
- Git
- Node.js LTS (để chạy Supabase CLI qua `npx`)
- Quyền truy cập project Supabase của nhóm

## Cài đặt và chạy

1. Clone repo:

   ```powershell
   git clone https://github.com/AnhGam/Elytra.git elytra
   cd elytra
   ```

2. Tạo file cấu hình từ mẫu, rồi điền URL và khóa **publishable/anon** của project Supabase (Project Settings → Data API và API Keys):

   ```powershell
   Copy-Item app\env.example.json app\env.json
   ```

   `app/env.json` đã nằm trong `.gitignore`, không commit file này.

3. Tải thư viện:

   ```powershell
   cd app
   flutter pub get
   ```

4. Chạy app trên máy ảo hoặc điện thoại:

   ```powershell
   flutter run --dart-define-from-file=env.json
   ```

   Trong VS Code, chọn cấu hình **Elytra (app)** rồi bấm `F5` (cấu hình nằm trong `.vscode/launch.json`).

5. Chạy unit test:

   ```powershell
   flutter test
   ```

## Biến cấu hình (`app/env.json`)

| Biến | Ý nghĩa |
| --- | --- |
| `SUPABASE_URL` | Địa chỉ project Supabase, dạng `https://<project-ref>.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | Khóa publishable (hoặc anon) – an toàn để nằm trong app, dữ liệu được RLS bảo vệ |
| `USE_MOCK_CALC` | `"true"`: tính dinh dưỡng bằng bộ tính giả lập trong app; `"false"`: gọi Edge Function `calc-nutrition` |

Không bao giờ đưa khóa **secret / service_role** vào app hay vào repo.

## Back-end (Supabase CLI)

```powershell
npx supabase login
npx supabase link --project-ref <project-ref>
npx supabase db push                          # áp dụng migrations lên project
npx supabase functions deploy <tên-function>  # triển khai một Edge Function
npx supabase secrets set GEMINI_API_KEY=...   # lưu khóa bí mật cho Edge Function
```

Đặc tả request/response của các Edge Function: [`docs/api-contract.md`](docs/api-contract.md).

## Quy trình làm việc

- Nhánh `main` được bảo vệ, mọi thay đổi đi qua Pull Request và cần thành viên còn lại duyệt.
- Đặt tên nhánh theo loại việc: `feat/...`, `fix/...`, `docs/...`, `chore/...`.
- Commit theo dạng `loại(phạm vi): mô tả`, ví dụ `feat(auth): login and register screens`.

## Thành viên

| Họ tên | MSSV |
| --- | --- |
| Nguyễn Minh Anh | 24520107 |
| Nguyễn Đức Hoàng Thuận | 24521740 |

Giảng viên hướng dẫn: ThS. Võ Tuấn Kiệt.
