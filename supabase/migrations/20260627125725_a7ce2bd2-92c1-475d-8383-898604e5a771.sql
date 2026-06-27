CREATE TABLE public.script_keys (
  key TEXT PRIMARY KEY,
  token TEXT NOT NULL UNIQUE,
  tier TEXT NOT NULL DEFAULT 'normal',
  label TEXT,
  device_id TEXT,
  hwid TEXT,
  expires_at TIMESTAMPTZ,
  revoked BOOLEAN NOT NULL DEFAULT false,
  uses INTEGER NOT NULL DEFAULT 0,
  last_used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT ALL ON public.script_keys TO service_role;
ALTER TABLE public.script_keys ENABLE ROW LEVEL SECURITY;
CREATE INDEX script_keys_token_idx ON public.script_keys(token);
CREATE INDEX script_keys_device_idx ON public.script_keys(device_id) WHERE device_id IS NOT NULL;

-- Seed permanent owner keys
INSERT INTO public.script_keys (key, token, tier, label, expires_at) VALUES
  ('SEIGE-OWNER-ROTSHAD3-PERMA', 'owner-rotshad3', 'admin', 'rotshad3 (owner)', NULL)
ON CONFLICT (key) DO NOTHING;