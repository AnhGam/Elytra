-- Sprint 9: bucket riêng tư chứa bản sao lưu DB (gói Free không có sao lưu tự động).
-- KHÔNG public, KHÔNG có policy nào → app/anon không đọc được; chỉ service_role / Dashboard / Supabase CLI của chủ project.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('db-backups', 'db-backups', false, 52428800, ARRAY['application/gzip', 'application/x-gzip', 'application/octet-stream'])
ON CONFLICT (id) DO UPDATE SET public = false, file_size_limit = EXCLUDED.file_size_limit, allowed_mime_types = EXCLUDED.allowed_mime_types;
