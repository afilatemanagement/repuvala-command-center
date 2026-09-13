CREATE TABLE public.connected_platforms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  platform text NOT NULL UNIQUE,
  display_name text NOT NULL,
  account_ref text,
  status text NOT NULL DEFAULT 'disconnected',
  last_synced_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  platform text NOT NULL,
  author text NOT NULL,
  rating int NOT NULL DEFAULT 5,
  sentiment text NOT NULL DEFAULT 'neutral',
  status text NOT NULL DEFAULT 'pending',
  priority text NOT NULL DEFAULT 'low',
  location_name text NOT NULL DEFAULT 'All locations',
  title text,
  body text NOT NULL,
  tags text[] NOT NULL DEFAULT '{}',
  unread boolean NOT NULL DEFAULT true,
  reply text,
  replied_at timestamptz,
  replied_by uuid,
  external_created_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind text NOT NULL,
  severity text NOT NULL DEFAULT 'medium',
  title text NOT NULL,
  detail text NOT NULL,
  location_name text NOT NULL DEFAULT 'All locations',
  review_id uuid REFERENCES public.reviews(id) ON DELETE SET NULL,
  resolved boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.connected_platforms TO authenticated;
GRANT ALL ON public.connected_platforms TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.reviews TO authenticated;
GRANT ALL ON public.reviews TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.alerts TO authenticated;
GRANT ALL ON public.alerts TO service_role;

ALTER TABLE public.connected_platforms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Signed-in users manage connected platforms" ON public.connected_platforms
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Signed-in users manage reviews" ON public.reviews
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Signed-in users manage alerts" ON public.alerts
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER AS $$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $$
LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER touch_connected_platforms BEFORE UPDATE ON public.connected_platforms
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER touch_reviews BEFORE UPDATE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

INSERT INTO public.connected_platforms (platform, display_name, account_ref, status, last_synced_at) VALUES
  ('google', 'Google Reviews', 'Aroma Ventures — Business Profile', 'connected', now() - interval '12 minutes'),
  ('facebook', 'Facebook', '@aromaventures', 'connected', now() - interval '40 minutes'),
  ('instagram', 'Instagram', '@aromaventures', 'connected', now() - interval '1 hour'),
  ('trustpilot', 'Trustpilot', 'aromaventures.com', 'connected', now() - interval '2 hours'),
  ('yelp', 'Yelp', 'Aroma Ventures', 'connected', now() - interval '3 hours'),
  ('youtube', 'YouTube', NULL, 'disconnected', NULL),
  ('tripadvisor', 'TripAdvisor', NULL, 'disconnected', NULL);

INSERT INTO public.reviews (platform, author, rating, sentiment, status, priority, location_name, title, body, tags, unread, reply, replied_at, external_created_at) VALUES
  ('google', 'Priya Sharma', 1, 'negative', 'pending', 'high', 'Singapore — Orchard', NULL, 'Waited 45 minutes for a table that we had booked in advance. Staff were apologetic but nobody followed up. Very disappointing for a special occasion.', ARRAY['Wait time','Booking'], true, NULL, NULL, now() - interval '12 minutes'),
  ('trustpilot', 'Daniel Okafor', 5, 'positive', 'pending', 'low', 'London — Soho', 'Outstanding service', 'The team went above and beyond. Quick, friendly, and the follow-up email with the invoice was a nice touch. Will recommend to colleagues.', ARRAY['Staff','Service'], true, NULL, NULL, now() - interval '38 minutes'),
  ('yelp', 'Meera Iyer', 2, 'negative', 'escalated', 'high', 'London — Soho', NULL, 'Billing error charged me twice. Support said they would fix it in 48 hours — it has been a week. Frustrated.', ARRAY['Billing','Support'], false, NULL, NULL, now() - interval '1 hour'),
  ('facebook', 'Lucas Moreau', 4, 'positive', 'replied', 'low', 'Dubai — Marina', NULL, 'Great atmosphere and lovely staff. Slightly pricey but worth it for the experience.', ARRAY['Ambience','Pricing'], false, 'Thank you Lucas! We are thrilled you enjoyed the experience — see you again soon.', now() - interval '2 hours', now() - interval '3 hours'),
  ('google', 'Aisha Khan', 3, 'neutral', 'pending', 'medium', 'Mumbai — Bandra', NULL, 'Product quality is good, but the app checkout kept failing. Had to call to complete my order.', ARRAY['App','Checkout'], true, NULL, NULL, now() - interval '5 hours'),
  ('instagram', '@travelwithsam', 5, 'positive', 'replied', 'low', 'Sydney — CBD', NULL, 'Obsessed with the new seasonal menu. The rooftop views are unbeatable.', ARRAY['Menu','Ambience'], false, 'Thanks Sam! Come back for the sunset session next week.', now() - interval '20 hours', now() - interval '1 day'),
  ('google', 'Unknown user 4821', 1, 'negative', 'flagged', 'high', 'New York — Midtown', NULL, 'Worst place ever. Do not go. (identical text posted from six accounts within twenty minutes)', ARRAY['Suspicious','Policy review'], false, NULL, NULL, now() - interval '1 day'),
  ('trustpilot', 'Hannah Weiss', 4, 'positive', 'pending', 'medium', 'New York — Midtown', 'Good, with one gap', 'Delivery was fast and packaging premium. The size guide was confusing though — I had to exchange once.', ARRAY['Delivery','Size guide'], false, NULL, NULL, now() - interval '2 days');

INSERT INTO public.alerts (kind, severity, title, detail, location_name, resolved, created_at) VALUES
  ('rating_drop', 'critical', 'Rating dropped 0.4★ in 7 days', 'Average rating fell from 4.5 to 4.1 following a cluster of wait-time complaints.', 'Singapore — Orchard', false, now() - interval '14 minutes'),
  ('negative_review', 'high', 'New 1★ review on Google', 'A one-star review was published and is still awaiting a response.', 'Singapore — Orchard', false, now() - interval '12 minutes'),
  ('suspicious_activity', 'high', 'Suspicious review burst detected', 'Six near-identical one-star reviews were posted within twenty minutes.', 'New York — Midtown', false, now() - interval '1 day'),
  ('unresolved', 'medium', 'Escalated review unanswered for 72h', 'A billing escalation has passed the response SLA.', 'London — Soho', false, now() - interval '2 hours'),
  ('volume_spike', 'info', 'Review volume up 34% this week', 'Higher than usual review volume following the seasonal campaign.', 'Mumbai — Bandra', true, now() - interval '3 days');