\set ECHO none

\i test/setup.sql

SELECT plan(
  0
  +1
);

SELECT hasnt_schema(
  '__cat_tools'
);

\i test/pgxntool/finish.sql

-- vi: expandtab ts=2 sw=2
