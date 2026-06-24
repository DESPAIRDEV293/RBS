CREATE TABLE public.role_entries (
  key text NOT NULL PRIMARY KEY,
  role text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

GRANT SELECT ON public.role_entries TO anon, authenticated;
GRANT ALL ON public.role_entries TO service_role;

ALTER TABLE public.role_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read role entries"
ON public.role_entries
FOR SELECT
TO anon, authenticated
USING (true);

CREATE OR REPLACE FUNCTION public.role_entries_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER role_entries_set_updated_at
BEFORE UPDATE ON public.role_entries
FOR EACH ROW EXECUTE FUNCTION public.role_entries_set_updated_at();