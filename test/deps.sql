-- IF NOT EXISTS will emit NOTICEs, which is annoying
SET client_min_messages = WARNING;

-- Add any test dependency statements here
-- Note: pgTap is loaded by setup.sql
--CREATE EXTENSION IF NOT EXISTS ...;
/*
 * Now load our extension. We don't use IF NOT EXISTs here because we want an
 * error if the extension is already loaded (because we want to ensure we're
 * getting the very latest version).
 */
CREATE EXTENSION cat_tools;
/*
-- NOTE: To set this prior to 0.2.0 you need to hack the installed extension file to not create the cat_tools schema, or hack the current control file to not specify it!
CREATE EXTENSION cat_tools VERSION '0.2.0';
ALTER EXTENSION cat_tools UPDATE;
*/

-- Used by several unit tests
\set no_use_role cat_tools_testing__no_use_role
\set use_role cat_tools_testing__use_role
CREATE ROLE :no_use_role;
CREATE ROLE :use_role;

GRANT cat_tools__usage TO :use_role;

