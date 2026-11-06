CREATE POLICY "Admins can send user announcements"
  ON public.notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());
