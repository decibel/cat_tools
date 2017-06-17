-- IF NOT EXISTS will emit NOTICEs, which is annoying
SET client_min_messages = WARNING;

-- Add any test dependency statements here
-- Note: pgTap is loaded by setup.sql
--CREATE EXTENSION IF NOT EXISTS ...;

\i test/.build/active.sql

-- Used by several unit tests
\set no_use_role cat_tools_testing__no_use_role
\set use_role cat_tools_testing__use_role
CREATE ROLE :no_use_role;
CREATE ROLE :use_role;

GRANT cat_tools__usage TO :use_role;

