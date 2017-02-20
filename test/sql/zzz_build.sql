\set ECHO none

\i test/pgxntool/psql.sql

BEGIN;
CREATE SCHEMA cat_tools;

\i sql/cat_tools.sql

\echo # TRANSACTION INTENTIONALLY LEFT OPEN!

-- vi: expandtab sw=2 ts=2
