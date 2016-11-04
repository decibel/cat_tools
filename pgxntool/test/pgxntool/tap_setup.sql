\i test/pgxntool/psql.sql

SET client_min_messages = WARNING;
CREATE SCHEMA IF NOT EXISTS tap;
SET search_path = tap, public;
CREATE EXTENSION IF NOT EXISTS pgtap SCHEMA tap;
SET client_min_messages = NOTICE;
\pset format unaligned
\pset tuples_only true
\pset pager
