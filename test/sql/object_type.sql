\set ECHO none

\i test/setup.sql

-- test_role is set in test/deps.sql

SET LOCAL ROLE :use_role;
CREATE FUNCTION pg_temp.major()
RETURNS int LANGUAGE sql IMMUTABLE AS $$
SELECT current_setting('server_version_num')::int/100
$$;

CREATE FUNCTION pg_temp.extra_types()
RETURNS text[] LANGUAGE sql IMMUTABLE AS $$
SELECT '{}'::text[]
  || CASE WHEN pg_temp.major() < 905 THEN '{policy,transform}'::text[] END
  || CASE WHEN pg_temp.major() < 903 THEN '{event trigger}'::text[] END
$$;

CREATE TEMP VIEW obj_type AS
  SELECT object_type::text COLLATE "C", true AS is_real
    FROM cat_tools.enum_range_srf('cat_tools.object_type') r(object_type)
  UNION ALL -- INTENTIONALLY UNION ALL! We want dupes if something gets hosed
  SELECT u COLLATE "C", false
    FROM unnest(pg_temp.extra_types()) u
  ORDER BY 1 -- Intentionally done by ordinal
;

SELECT plan(
  0
  + 4 -- no_use tests
  + 2 * (SELECT count(*)::int FROM obj_type)
);

SET LOCAL ROLE :no_use_role;
SELECT throws_ok(
  format( 'SELECT NULL::%I', typename )
  , '42704' -- undefined_object; not exactly correct, but close enough
  , NULL
  , 'Permission denied trying to use types'
)
  FROM (VALUES
    ('cat_tools.constraint_type')
    , ('cat_tools.procedure_type')
    , ('cat_tools.object_type')
  ) v(typename)
;
SELECT throws_ok(
  format( 'SELECT cat_tools.object__catalog( NULL::%I )', argtype )
  , '42501' -- insufficient_privilege
  , NULL
  , 'Permission denied trying to run functions'
)
  FROM (VALUES
    ('text'::regtype)
  ) v(argtype)
;

SET LOCAL ROLE :use_role;

-- It doesn't seem worth it to hand-check all of these. Just make sure we get a valid relation for all of them
SELECT lives_ok(
      CASE WHEN is_real THEN format( $$SELECT * FROM cat_tools.object__catalog(%L)$$, object_type )
      ELSE 'SELECT 1'
      END
      , format( $$SELECT * FROM cat_tools.object__catalog(%L)$$, object_type )
    )
  FROM obj_type
;

SELECT lives_ok(
      CASE WHEN is_real THEN format( $$SELECT * FROM cat_tools.object__reg_type(%L)$$, object_type )
      ELSE 'SELECT 1'
      END
      , format( $$SELECT * FROM cat_tools.object__reg_type(%L)$$, object_type )
    )
  FROM obj_type
;

\i test/pgxntool/finish.sql

--select name,setting from pg_settings where name ~ '^lc_';

-- vi: expandtab ts=2 sw=2
