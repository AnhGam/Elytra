-- Sprint 8: app chỉ đọc lịch sử chat + xóa cả phiên của mình; Edge Function recommend-ai ghi chat bằng service_role sau khi xác thực user.

DROP POLICY IF EXISTS "Users can manage own chat sessions" ON public.chat_sessions;
DROP POLICY IF EXISTS "Users can manage own chat messages" ON public.chat_messages;

REVOKE ALL ON public.chat_sessions FROM anon;
REVOKE ALL ON public.chat_messages FROM anon;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public.chat_sessions FROM authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public.chat_messages FROM authenticated;
GRANT SELECT, DELETE ON public.chat_sessions TO authenticated;
GRANT SELECT ON public.chat_messages TO authenticated;

DROP POLICY IF EXISTS "Users read own chat sessions" ON public.chat_sessions;
CREATE POLICY "Users read own chat sessions" ON public.chat_sessions
    FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users delete own chat sessions" ON public.chat_sessions;
CREATE POLICY "Users delete own chat sessions" ON public.chat_sessions
    FOR DELETE TO authenticated USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users read own chat messages" ON public.chat_messages;
CREATE POLICY "Users read own chat messages" ON public.chat_messages
    FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);
