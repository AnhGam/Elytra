-- Sprint 9: hạn mức AI v2 — thêm trần chung cả app 600 lượt/giờ (chống lách bằng nhiều tài khoản).
-- Vượt trần chung: allowed = true nhưng ai_enabled = false (app vẫn trả lời bằng thứ tự SQL + câu mẫu), KHÔNG ghi lượt.
CREATE INDEX IF NOT EXISTS idx_ai_usage_time ON public.ai_usage(created_at);

CREATE OR REPLACE FUNCTION public.consume_ai_quota()
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_limit CONSTANT INT := 30;
    v_global_limit CONSTANT INT := 600;
    v_window CONSTANT INTERVAL := interval '1 hour';
    v_uid UUID := auth.uid();
    v_count INT;
    v_global INT;
    v_oldest TIMESTAMPTZ;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    PERFORM pg_advisory_xact_lock(hashtext('ai_quota:' || v_uid::text));

    DELETE FROM ai_usage WHERE user_id = v_uid AND created_at < now() - interval '1 day';

    SELECT count(*)::int INTO v_count FROM ai_usage WHERE user_id = v_uid AND created_at > now() - v_window;
    IF v_count >= v_limit THEN
        SELECT MIN(created_at) INTO v_oldest FROM ai_usage WHERE user_id = v_uid AND created_at > now() - v_window;
        RETURN jsonb_build_object('allowed', false, 'ai_enabled', false, 'remaining', 0,
            'retry_after_seconds', GREATEST(1, CEIL(EXTRACT(EPOCH FROM (v_oldest + v_window - now())))::INT));
    END IF;

    -- shortcut: đếm trần chung không khóa toàn cục, nhiều request cùng lúc có thể vượt 600 vài lượt; cần chính xác thì khóa chung
    SELECT count(*)::int INTO v_global FROM ai_usage WHERE created_at > now() - v_window;
    IF v_global >= v_global_limit THEN
        RETURN jsonb_build_object('allowed', true, 'ai_enabled', false, 'remaining', v_limit - v_count, 'retry_after_seconds', 0);
    END IF;

    INSERT INTO ai_usage (user_id) VALUES (v_uid);
    RETURN jsonb_build_object('allowed', true, 'ai_enabled', true, 'remaining', v_limit - v_count - 1, 'retry_after_seconds', 0);
END;
$$;
-- CREATE OR REPLACE giữ nguyên quyền cũ (chỉ authenticated gọi được)
