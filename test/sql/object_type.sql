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

  -- Catalog search path
  + 1
  + 3 * 2
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

-- Verify catalog correctness
SELECT lives_ok(
  $$SET search_path = public,tap,pg_catalog$$ -- Note that we must explicitly set pg_catalog at the end of the path
  , 'Change search_path'
);

SELECT lives_ok(
  'CREATE TABLE pg_class()'
  , 'Create bogus pg_class table'
);
SELECT lives_ok(
  'CREATE TYPE regclass AS ENUM()'
  , 'Create bogus regclass type'
);
SELECT isnt(
  'pg_class'::pg_catalog.regclass
  , 'pg_catalog.pg_class'::pg_catalog.regclass
  , $$Simple 'pg_class'::pg_catalog.regclass should not return pg_catalog.pg_class$$
);
SELECT isnt(
  'regclass'::regtype
  , 'pg_catalog.regclass'::regtype
  , $$Simple 'regclass'::regtype should not return pg_catalog.regtype$$
);
SELECT is(
  cat_tools.object__catalog('table')
  , 'pg_catalog.pg_class'::pg_catalog.regclass
  , $$cat_tools.object__catalog('table') returns pg_catalog.pg_class$$
);
SELECT is(
  cat_tools.object__reg_type('table')
  , 'pg_catalog.regclass'::regtype
  , $$cat_tools.object__catalog('table') returns pg_catalog.pg_class$$
);

\i test/pgxntool/finish.sql

--select name,setting from pg_settings where name ~ '^lc_';

-- vi: expandtab ts=2 sw=2
