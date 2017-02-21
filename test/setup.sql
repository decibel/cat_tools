-- Pulls in deps.sql
\i test/pgxntool/setup.sql

GRANT USAGE ON SCHEMA tap TO :use_role, :no_use_role;

CREATE FUNCTION pg_temp.exec(
  sql text
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE sql;
END
$$;

CREATE FUNCTION pg_temp.major()
RETURNS int LANGUAGE sql IMMUTABLE AS $$
SELECT current_setting('server_version_num')::int/100
$$;

-- vi: expandtab ts=2 sw=2
