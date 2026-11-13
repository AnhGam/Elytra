# Back-end: việc còn lại tới khi hoàn thiện

Theo đề cương (Sprint 7–9). Lập 12/11/2026. Cập nhật 12/11/2026: Sprint 3–6 xong (PR #7 đã merge); Sprint 7 back-end xong (xem `docs/week11-12/README.md`).
File này là **kế hoạch**, chưa phải tính năng đã có. Cái gì đã chạy thì xem `docs/api-contract.md`.

## Quyết định đã chốt (12/11/2026)

| Chủ đề | Quyết định |
| --- | --- |
| Giao diện admin | Trong app Flutter: tài khoản admin thấy thêm tab Admin |
| Đánh dấu admin | Bảng `admins` + hàm `is_admin()`; chỉ thêm admin qua Supabase Dashboard / migration |
| Kiểm tra quyền admin | Nghiêm ngặt: mọi thao tác admin kiểm `is_admin()` **trong DB** (RPC `SECURITY DEFINER` + RLS), app không ghi thẳng bảng admin, mọi thao tác admin ghi nhật ký, mỗi thao tác có test chứng minh user thường bị chặn, user không tự cấp quyền được |
| Sở thích ăn uống | Dùng `profiles.dietary_preference` trong gợi ý (vd chay → chỉ `mon_chay`) |
| Giới hạn gọi AI | `recommend-ai`: 30 lượt/giờ/user, vượt trả `429 RATE_LIMITED` |
| Kiểm duyệt món cộng đồng | Gemini Decision 1 chấm sẵn; admin duyệt 100% tới khi đo xong bộ ~100 món gắn nhãn (ngưỡng tự duyệt 0,9) |

## Sprint 7 (25/11 – 9/12): Cộng đồng + Admin — back-end ĐÃ XONG 12/11/2026

Đã chạy: xem `docs/week11-12/README.md` và `docs/api-contract.md` mục 6–7. Bảng dưới giữ lại để đối chiếu.

| # | Việc |
| --- | --- |
| 7.1 | Phân quyền admin: bảng `admins`, `is_admin()`, bảng nhật ký thao tác admin |
| 7.2 | Trạng thái công thức: `created_by`, `status` (`pending` / `approved` / `rejected`), `reject_reason`, `reviewed_by`, `reviewed_at`; giữ `is_verified` cho truy vấn cũ |
| 7.3 | User tạo công thức: chọn nguyên liệu + g/ml → tự tính dinh dưỡng + dị ứng → `pending`; xem/sửa/xóa món của mình khi còn `pending`; giới hạn số món/ngày |
| 7.4 | Ảnh món của user: thư mục riêng từng user, chỉ ảnh, giới hạn dung lượng |
| 7.5 | Admin duyệt món: hàng chờ, duyệt / từ chối kèm lý do; Gemini Decision 1 chấm sẵn |
| 7.6 | Admin quản lý nguyên liệu: thêm, sửa, vô hiệu hóa (nguyên liệu đã có công thức dùng thì không xóa) |
| 7.7 | Xem công thức cộng đồng: danh sách món đã duyệt kèm người đóng góp; món của mình thấy cả `pending` / `rejected` |
| 7.8 | Test dựng lại DB + E2E (user không tự duyệt, không sửa món người khác, không gọi được thao tác admin) + cập nhật `api-contract.md` |

## Sprint 8 (9/12 – 23/12): Kiểm thử + vá

| # | Việc |
| --- | --- |
| 8.1 | Unit test BMR/TDEE (`calculate_nutrition_targets`), tính dinh dưỡng, ràng buộc gợi ý |
| 8.2 | Test RLS toàn bộ: user A không đọc/ghi được dữ liệu của user B trên mọi bảng và RPC |
| 8.3 | Giới hạn gọi `recommend-ai` (30 lượt/giờ/user) |
| 8.4 | Siết quyền bảng chat: app chỉ đọc, server ghi bằng quyền riêng |
| 8.5 | Sở thích ăn uống (`dietary_preference`) trong gợi ý |
| 8.6 | Đo thời gian phản hồi chatbot và tải dữ liệu |
| 8.7 | Bộ ~100 món Việt gắn nhãn tay: đo Gemini Decision 1, chỉnh ngưỡng tự duyệt |
| 8.8 | Rà lại calo toàn bộ món |

## Sprint 9 (23/12 – kết thúc): Triển khai + báo cáo

- Chốt bản deploy, kiểm migration trên production, sao lưu DB.
- Hỗ trợ FE build APK.
- Báo cáo phần Backend, AI, Database, hệ thống gợi ý.

## Việc nợ

- ~~Duyệt + merge PR #7~~ (đã merge 12/11/2026).
- CI Flutter đỏ: Flutter stable mới đánh dấu `package:flutter/material.dart` là deprecated (phần FE).
