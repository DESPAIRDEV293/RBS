CREATE TABLE public.spotify_drops (
  code TEXT PRIMARY KEY,
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  expires_in INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT ALL ON public.spotify_drops TO service_role;
ALTER TABLE public.spotify_drops ENABLE ROW LEVEL SECURITY;
-- No policies: only server-side admin client (service_role) accesses this table.