-- Advisor: like_escape (thêm ở 20261028090000) quên cố định search_path.
ALTER FUNCTION public.like_escape(TEXT) SET search_path = public;
