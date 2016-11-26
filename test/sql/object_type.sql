\set ECHO none

\i test/setup.sql

-- test_role is set in test/deps.sql

SET LOCAL ROLE :use_role;

SELECT plan(
  0
  + 4 -- no_use tests
  + 1 * (SELECT count(*)::int FROM cat_tools.enum_range_srf('cat_tools.object_type'))
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
      format( $$SELECT * FROM cat_tools.object__catalog(%L)$$, object_type )
      , format( $$SELECT * FROM cat_tools.object__catalog(%L)$$, object_type )
    )
  FROM cat_tools.enum_range_srf('cat_tools.object_type') r(object_type)
;

\i test/pgxntool/finish.sql

-- vi: expandtab ts=2 sw=2
