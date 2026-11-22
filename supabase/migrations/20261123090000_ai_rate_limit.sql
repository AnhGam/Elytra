-- Sprint 8: giới hạn 30 lượt gọi AI (recommend-ai) mỗi giờ mỗi user, bảo vệ hạn mức Gemini miễn phí dùng chung.

CREATE TABLE IF NOT EXISTS public.ai_usage (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ai_usage_user_time ON public.ai_usage(user_id, created_at);
ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ai_usage FROM anon, authenticated;

-- Kiểm tra và tiêu thụ 1 lượt gọi AI trong cửa sổ trượt 1 giờ (tối đa 30 lượt/user).
CREATE OR REPLACE FUNCTION public.consume_ai_quota()
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_limit CONSTANT INT := 30;
    v_window CONSTANT INTERVAL := interval '1 hour';
    v_uid UUID := auth.uid();
    v_count INT;
    v_oldest TIMESTAMPTZ;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    PERFORM pg_advisory_xact_lock(hashtext('ai_quota:' || v_uid::text));

    DELETE FROM ai_usage WHERE user_id = v_uid AND created_at < now() - interval '1 day';

    SELECT count(*)::int INTO v_count
      FROM ai_usage
     WHERE user_id = v_uid AND created_at > now() - v_window;

    IF v_count >= v_limit THEN
        SELECT MIN(created_at) INTO v_oldest
          FROM ai_usage
         WHERE user_id = v_uid AND created_at > now() - v_window;
        RETURN jsonb_build_object(
            'allowed', false,
            'remaining', 0,
            'retry_after_seconds', GREATEST(1, CEIL(EXTRACT(EPOCH FROM (v_oldest + v_window - now())))::INT)
        );
    END IF;

    INSERT INTO ai_usage (user_id) VALUES (v_uid);
    RETURN jsonb_build_object(
        'allowed', true,
        'remaining', v_limit - v_count - 1,
        'retry_after_seconds', 0
    );
END;
$$;
REVOKE EXECUTE ON FUNCTION public.consume_ai_quota() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consume_ai_quota() TO authenticated;
