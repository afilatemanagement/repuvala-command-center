GRANT SELECT, UPDATE ON public.reviews TO anon;
GRANT SELECT, UPDATE ON public.alerts TO anon;
GRANT SELECT, UPDATE ON public.connected_platforms TO anon;

CREATE POLICY "Prototype read reviews" ON public.reviews FOR SELECT TO anon USING (true);
CREATE POLICY "Prototype update reviews" ON public.reviews FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Prototype read alerts" ON public.alerts FOR SELECT TO anon USING (true);
CREATE POLICY "Prototype update alerts" ON public.alerts FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Prototype read platforms" ON public.connected_platforms FOR SELECT TO anon USING (true);
CREATE POLICY "Prototype update platforms" ON public.connected_platforms FOR UPDATE TO anon USING (true) WITH CHECK (true);