/*
 * NOTE: All pg_temp objects must be dropped at the end of the script!
 * Otherwise the eventual DROP CASCADE of pg_temp when the session ends will
 * also drop the extension! Instead of risking problems, create our own
 * "temporary" schema instead.
 */
CREATE SCHEMA __cat_tools;
CREATE FUNCTION __cat_tools.exec(
  sql text
) RETURNS void LANGUAGE plpgsql AS $body$
BEGIN
  RAISE DEBUG 'sql = %', sql;
  EXECUTE sql;
END
$body$;
CREATE FUNCTION __cat_tools.create_function(
  function_name text
  , args text
  , options text
  , body text
  , grants text DEFAULT NULL
) RETURNS void LANGUAGE plpgsql AS $body$
DECLARE

  create_template CONSTANT text := $template$
CREATE OR REPLACE FUNCTION %s(
%s
) RETURNS %s AS
%L
$template$
  ;

  revoke_template CONSTANT text := $template$
REVOKE ALL ON FUNCTION %s(
%s
) FROM public;
$template$
  ;

  grant_template CONSTANT text := $template$
GRANT EXECUTE ON FUNCTION %s(
%s
) TO %s;
$template$
  ;

BEGIN
  PERFORM __cat_tools.exec( format(
      create_template
      , function_name
      , args
      , options
      , body
    ) )
  ;
  PERFORM __cat_tools.exec( format(
      revoke_template
      , function_name
      , args
    ) )
  ;

  IF grants IS NOT NULL THEN
    PERFORM __cat_tools.exec( format(
        grant_template
        , function_name
        , args
        , grants
      ) )
    ;
  END IF;
END
$body$;

/*
 * ACTUAL UPGRADE STARTS HERE!
 */
CREATE TYPE cat_tools.relation_kind AS ENUM(
  'table'
  , 'index'
  , 'sequence'
  , 'toast table'
  , 'view'
  , 'materialized view'
  , 'composite type'
  , 'foreign table'
);

CREATE TYPE cat_tools.relation_relkind AS ENUM(
  'r'
  , 'i'
  , 'S'
  , 't'
  , 'v'
  , 'c'
  , 'f'
  , 'm'
);


SELECT __cat_tools.create_function(
  'cat_tools.relation__kind'
  , 'relkind cat_tools.relation_relkind'
  , 'cat_tools.relation_kind LANGUAGE sql STRICT IMMUTABLE'
  , $body$
SELECT CASE relkind
  WHEN 'r' THEN 'table'
  WHEN 'i' THEN 'index'
  WHEN 'S' THEN 'sequence'
  WHEN 't' THEN 'toast table'
  WHEN 'v' THEN 'view'
  WHEN 'c' THEN 'materialized view'
  WHEN 'f' THEN 'composite type'
  WHEN 'm' THEN 'foreign table'
END::cat_tools.relation_kind
$body$
  , 'cat_tools__usage'
);

SELECT __cat_tools.create_function(
  'cat_tools.relation__relkind'
  , 'kind cat_tools.relation_kind'
  , 'cat_tools.relation_relkind LANGUAGE sql STRICT IMMUTABLE'
  , $body$
SELECT CASE kind
  WHEN 'table' THEN 'r'
  WHEN 'index' THEN 'i'
  WHEN 'sequence' THEN 'S'
  WHEN 'toast table' THEN 't'
  WHEN 'view' THEN 'v'
  WHEN 'materialized view' THEN 'c'
  WHEN 'composite type' THEN 'f'
  WHEN 'foreign table' THEN 'm'
END::cat_tools.relation_relkind
$body$
  , 'cat_tools__usage'
);


SELECT __cat_tools.create_function(
  'cat_tools.relation__relkind'
  , 'kind text'
  , 'cat_tools.relation_relkind LANGUAGE sql STRICT IMMUTABLE'
  , $body$SELECT cat_tools.relation__relkind(kind::cat_tools.relation_kind)$body$
  , 'cat_tools__usage'
);
SELECT __cat_tools.create_function(
  'cat_tools.relation__kind'
  , 'relkind text'
  , 'cat_tools.relation_kind LANGUAGE sql STRICT IMMUTABLE'
  , $body$SELECT cat_tools.relation__kind(relkind::cat_tools.relation_relkind)$body$
  , 'cat_tools__usage'
);

/*
 * END OF UPGRADE!
 */
DROP FUNCTION __cat_tools.exec(
  sql text
);
DROP FUNCTION __cat_tools.create_function(
  function_name text
  , args text
  , options text
  , body text
  , grants text
);
DROP SCHEMA __cat_tools;
