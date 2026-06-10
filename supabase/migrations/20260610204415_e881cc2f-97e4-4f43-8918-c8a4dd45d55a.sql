CREATE TABLE public.tag_entries (
  key text PRIMARY KEY,
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT ON public.tag_entries TO anon, authenticated;
GRANT ALL ON public.tag_entries TO service_role;

ALTER TABLE public.tag_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read tag entries"
  ON public.tag_entries
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE OR REPLACE FUNCTION public.tag_entries_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER trg_tag_entries_updated_at
BEFORE UPDATE ON public.tag_entries
FOR EACH ROW EXECUTE FUNCTION public.tag_entries_set_updated_at();