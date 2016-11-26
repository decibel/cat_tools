SET LOCAL client_min_messages = WARNING;

DO $$
BEGIN
  CREATE ROLE cat_tools__usage NOLOGIN;
EXCEPTION WHEN duplicate_object THEN
  NULL;
END
$$;

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

@generated@

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

@generated@

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

@generated@

CREATE SCHEMA cat_tools;
GRANT USAGE ON SCHEMA cat_tools TO cat_tools__usage;
CREATE SCHEMA _cat_tools;

CREATE OR REPLACE VIEW _cat_tools.pg_class_v AS
  SELECT c.oid AS reloid, c.*, n.nspname AS relschema
    FROM pg_class c
      LEFT JOIN pg_namespace n ON( n.oid = c.relnamespace )
;
REVOKE ALL ON _cat_tools.pg_class_v FROM public;

@generated@

CREATE TYPE cat_tools.constraint_type AS ENUM(
  'domain constraint', 'table constraint'
);
CREATE TYPE cat_tools.procedure_type AS ENUM(
  'aggregate', 'function'
);

CREATE TYPE cat_tools.relation_type AS ENUM(
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

@generated@

CREATE TYPE cat_tools.object_type AS ENUM(
  -- pg_class
  'table'
  , 'index'
  , 'sequence'
  , 'toast table'
  , 'view'
  , 'materialized view'
  , 'composite type'
  , 'foreign table'
  -- pg_constraint
  , 'domain constraint', 'table constraint'
  -- pg_proc
  , 'aggregate', 'function'
  -- This is taken from getObjectTypeDescription() in objectaddress.c in the Postgres source code
  , 'type'
  , 'cast'
  , 'collation'
  , 'conversion'
  , 'default value' -- pg_attrdef
  , 'language'
  , 'large object' -- pg_largeobject
  , 'operator'
  , 'operator class' -- pg_opclass
  , 'operator family' -- pg_opfamily
  , 'operator of access method' -- pg_amop
  , 'function of access method' -- pg_amproc
  , 'rule' -- pg_rewrite
  , 'trigger'
  , 'schema' -- pg_namespace
  , 'text search parser' -- pg_ts_parser
  , 'text search dictionary' -- pg_ts_dict
  , 'text search template' -- pg_ts_template
  , 'text search configuration' -- pg_ts_config
  , 'role' -- pg_authid
  , 'database'
  , 'tablespace'
  , 'foreign-data wrapper' -- pg_foreign_data_wrapper
  , 'server' -- pg_foreign_server
  , 'user mapping' -- pg_user_mapping
  , 'default acl' -- pg_default_acl
  , 'extension'
  , 'event trigger' -- pg_event_trigger
  , 'policy' -- SED: REQUIRES 9.5!
  , 'transform' -- SED: REQUIRES 9.5!
  , 'access method' -- pg_am
);

@generated@

SELECT __cat_tools.create_function(
  'cat_tools.object__catalog'
  , 'object_type cat_tools.object_type'
  , 'pg_catalog.regclass LANGUAGE sql STRICT IMMUTABLE'
  , $body$
SELECT CASE
  WHEN object_type = ANY( array[
  'table'
  , 'index'
  , 'sequence'
  , 'toast table'
  , 'view'
  , 'materialized view'
  , 'composite type'
  , 'foreign table'
    ]::cat_tools.object_type[] )
  THEN 'pg_class'
  WHEN object_type = ANY( '{domain constraint,table constraint}'::cat_tools.object_type[] )
    THEN 'pg_constraint'
  WHEN object_type = ANY( '{aggregate,function}'::cat_tools.object_type[] )
    THEN 'pg_proc'
  ELSE CASE object_type
    -- Unusual cases
    -- s/, \(.\{-}\) -- \(.*\)/  WHEN \1 THEN '\2'/
    WHEN 'default value' THEN 'pg_attrdef'
    WHEN 'large object' THEN 'pg_largeobject'
    WHEN 'operator class' THEN 'pg_opclass'
    WHEN 'operator family' THEN 'pg_opfamily'
    WHEN 'operator of access method' THEN 'pg_amop'
    WHEN 'function of access method' THEN 'pg_amproc'
    WHEN 'rule' THEN 'pg_rewrite'
    WHEN 'schema' THEN 'pg_namespace'
    WHEN 'text search parser' THEN 'pg_ts_parser'
    WHEN 'text search dictionary' THEN 'pg_ts_dict'
    WHEN 'text search template' THEN 'pg_ts_template'
    WHEN 'text search configuration' THEN 'pg_ts_config'
    WHEN 'role' THEN 'pg_authid'
    WHEN 'foreign-data wrapper' THEN 'pg_foreign_data_wrapper'
    WHEN 'server' THEN 'pg_foreign_server'
    WHEN 'user mapping' THEN 'pg_user_mapping'
    WHEN 'default acl' THEN 'pg_default_acl'
    WHEN 'event trigger' THEN 'pg_event_trigger'
    WHEN 'access method' THEN 'pg_am'
    ELSE 'pg_' || object_type::text
    END
  END::pg_catalog.regclass
$body$
  , 'cat_tools__usage'
);
SELECT __cat_tools.create_function(
  'cat_tools.object__catalog'
  , 'object_type text'
  , 'pg_catalog.regclass LANGUAGE sql STRICT IMMUTABLE'
  , $body$SELECT cat_tools.object__catalog(object_type::cat_tools.object_type)$body$
  , 'cat_tools__usage'
);

@generated@

CREATE TABLE _cat_tools.catalog_metadata(
  object_catalog    pg_catalog.regclass
    CONSTRAINT catalog_metadata__pk_object_catalog PRIMARY KEY
  , namespace_field name
  , reg_type        pg_catalog.regtype
  , simple_reg_type pg_catalog.regtype
);
-- Table is populated later, after enum_range_srf is created
SELECT __cat_tools.create_function(
  '_cat_tools.catalog_metadata__get'
  , 'object_catalog _cat_tools.catalog_metadata.object_catalog%TYPE'
  , '_cat_tools.catalog_metadata LANGUAGE plpgsql IMMUTABLE' -- Technically should be STABLE
  , $body$
DECLARE
  o _cat_tools.catalog_metadata;
BEGIN
  SELECT INTO STRICT o
      *
    FROM _cat_tools.catalog_metadata m
    WHERE m.object_catalog = catalog_metadata__get.object_catalog
  ;
  RETURN o;
END
$body$
  , 'cat_tools__usage'
);

@generated@

SELECT __cat_tools.create_function(
  'cat_tools.object__reg_type'
  , 'object_catalog pg_catalog.regclass'
  , 'pg_catalog.regtype LANGUAGE sql SECURITY DEFINER STRICT IMMUTABLE'
  , $body$
SELECT (_cat_tools.catalog_metadata__get(object_catalog)).reg_type
$body$
  , 'cat_tools__usage'
);
SELECT __cat_tools.create_function(
  'cat_tools.object__reg_type'
  , 'object_type cat_tools.object_type'
  , 'pg_catalog.regtype LANGUAGE sql STRICT IMMUTABLE'
  , $body$SELECT cat_tools.object__reg_type(cat_tools.object__catalog(object_type))$body$
  , 'cat_tools__usage'
);
SELECT __cat_tools.create_function(
  'cat_tools.object__reg_type'
  , 'object_type text'
  , 'pg_catalog.regtype LANGUAGE sql STRICT IMMUTABLE'
  , $body$SELECT cat_tools.object__reg_type(object_type::cat_tools.object_type)$body$
  , 'cat_tools__usage'
);

@generated@

SELECT __cat_tools.create_function(
  'cat_tools.relation__kind'
  , 'relkind cat_tools.relation_relkind'
  , 'cat_tools.relation_type LANGUAGE sql STRICT IMMUTABLE'
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
END::cat_tools.relation_type
$body$
  , 'cat_tools__usage'
);

SELECT __cat_tools.create_function(
  'cat_tools.relation__relkind'
  , 'kind cat_tools.relation_type'
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

@generated@

SELECT __cat_tools.create_function(
  'cat_tools.relation__relkind'
  , 'kind text'
  , 'cat_tools.relation_relkind LANGUAGE sql STRICT IMMUTABLE'
  , $body$SELECT cat_tools.relation__relkind(kind::cat_tools.relation_type)$body$
  , 'cat_tools__usage'
);
SELECT __cat_tools.create_function(
  'cat_tools.relation__kind'
  , 'relkind text'
  , 'cat_tools.relation_type LANGUAGE sql STRICT IMMUTABLE'
  , $body$SELECT cat_tools.relation__kind(relkind::cat_tools.relation_relkind)$body$
  , 'cat_tools__usage'
);

CREATE OR REPLACE VIEW cat_tools.pg_class_v AS
  SELECT *
    FROM _cat_tools.pg_class_v

    /*
     * Oddly, there's no security associated with schema or table visibility.
     * Be a bit paranoid though.
     */
    WHERE NOT pg_is_other_temp_schema(relnamespace)
      AND relkind IN( 'r', 'v', 'f' )
;
GRANT SELECT ON cat_tools.pg_class_v TO cat_tools__usage;

@generated@

CREATE OR REPLACE VIEW _cat_tools.pg_attribute_v AS
  SELECT a.*
      , c.*
      , t.oid AS typoid
      , t.*
    FROM pg_attribute a
      LEFT JOIN _cat_tools.pg_class_v c ON ( c.reloid = a.attrelid )
      LEFT JOIN pg_type t ON ( t.oid = a.atttypid )
;
REVOKE ALL ON _cat_tools.pg_attribute_v FROM public;

CREATE OR REPLACE VIEW _cat_tools.column AS
  SELECT *
    , pg_catalog.format_type(typoid, atttypmod) AS column_type
    , CASE typtype
        -- domain
        WHEN 'd' THEN pg_catalog.format_type(typbasetype, typtypmod)
        -- enum
        WHEN 'e' THEN 'text'
        ELSE pg_catalog.format_type(typoid, atttypmod)
      END AS base_type
    , pk.conkey AS pk_columns
    , ARRAY[attnum] <@ pk.conkey AS is_pk_member
    , (SELECT pg_catalog.pg_get_expr(d.adbin, d.adrelid)
          FROM pg_catalog.pg_attrdef d
          WHERE d.adrelid = a.attrelid
            AND d.adnum = a.attnum
            AND a.atthasdef
        ) AS column_default
    FROM _cat_tools.pg_attribute_v a
      LEFT JOIN pg_constraint pk
        ON ( reloid = pk.conrelid )
          AND pk.contype = 'p'
;
REVOKE ALL ON _cat_tools.column FROM public;

@generated@

CREATE OR REPLACE VIEW cat_tools.column AS
  SELECT *
    FROM _cat_tools.column
    -- SECURITY
    WHERE NOT pg_is_other_temp_schema(relnamespace)
      AND attnum > 0
      AND NOT attisdropped
      AND relkind IN( 'r', 'v', 'f' )
      AND (
        pg_has_role(SESSION_USER, relowner, 'USAGE'::text)
        OR has_column_privilege(SESSION_USER, reloid, attnum, 'SELECT, INSERT, UPDATE, REFERENCES'::text)
      )
    ORDER BY relschema, relname, attnum
;
GRANT SELECT ON cat_tools.column TO cat_tools__usage;

-- Borrowed from newsysviews: http://pgfoundry.org/projects/newsysviews/
SELECT __cat_tools.create_function(
  '_cat_tools._pg_sv_column_array'
  , 'OID, SMALLINT[]'
  , 'NAME[] LANGUAGE sql STABLE'
  , $$
    SELECT ARRAY(
        SELECT a.attname
          FROM pg_catalog.pg_attribute a
          JOIN generate_series(1, array_upper($2, 1)) s(i) ON a.attnum = $2[i]
         WHERE attrelid = $1
         ORDER BY i
    )
$$
);

@generated@

-- Borrowed from newsysviews: http://pgfoundry.org/projects/newsysviews/
SELECT __cat_tools.create_function(
  '_cat_tools._pg_sv_table_accessible'
  , 'OID, OID'
  , 'boolean LANGUAGE sql STABLE'
  , $$
    SELECT CASE WHEN has_schema_privilege($1, 'USAGE') THEN (
                  has_table_privilege($2, 'SELECT')
               OR has_table_privilege($2, 'INSERT')
               or has_table_privilege($2, 'UPDATE')
               OR has_table_privilege($2, 'DELETE')
               OR has_table_privilege($2, 'RULE')
               OR has_table_privilege($2, 'REFERENCES')
               OR has_table_privilege($2, 'TRIGGER')
           ) ELSE FALSE
    END;
$$
);

@generated@

-- Borrowed from newsysviews: http://pgfoundry.org/projects/newsysviews/
CREATE OR REPLACE VIEW cat_tools.pg_all_foreign_keys
AS
  SELECT n1.nspname                                   AS fk_schema_name,
         c1.relname                                   AS fk_table_name,
         k1.conname                                   AS fk_constraint_name,
         c1.oid                                       AS fk_table_oid,
         _cat_tools._pg_sv_column_array(k1.conrelid,k1.conkey)   AS fk_columns,
         n2.nspname                                   AS pk_schema_name,
         c2.relname                                   AS pk_table_name,
         k2.conname                                   AS pk_constraint_name,
         c2.oid                                       AS pk_table_oid,
         ci.relname                                   AS pk_index_name,
         _cat_tools._pg_sv_column_array(k1.confrelid,k1.confkey) AS pk_columns,
         CASE k1.confmatchtype WHEN 'f' THEN 'FULL'
                               WHEN 'p' THEN 'PARTIAL'
                               WHEN 'u' THEN 'NONE'
                               else null
         END AS match_type,
         CASE k1.confdeltype WHEN 'a' THEN 'NO ACTION'  -- @generated@
                             WHEN 'c' THEN 'CASCADE'
                             WHEN 'd' THEN 'SET DEFAULT'
                             WHEN 'n' THEN 'SET NULL'
                             WHEN 'r' THEN 'RESTRICT'
                             else null
         END AS on_delete,
         CASE k1.confupdtype WHEN 'a' THEN 'NO ACTION'
                             WHEN 'c' THEN 'CASCADE'
                             WHEN 'd' THEN 'SET DEFAULT'
                             WHEN 'n' THEN 'SET NULL'
                             WHEN 'r' THEN 'RESTRICT'
                             ELSE NULL
         END AS on_update,
         k1.condeferrable AS is_deferrable,             -- @generated@
         k1.condeferred   AS is_deferred
    FROM pg_catalog.pg_constraint k1
    JOIN pg_catalog.pg_namespace n1 ON (n1.oid = k1.connamespace)
    JOIN pg_catalog.pg_class c1     ON (c1.oid = k1.conrelid)
    JOIN pg_catalog.pg_class c2     ON (c2.oid = k1.confrelid)
    JOIN pg_catalog.pg_namespace n2 ON (n2.oid = c2.relnamespace)
    JOIN pg_catalog.pg_depend d     ON (
                 d.classid = 'pg_constraint'::regclass  -- @generated@
             AND d.objid = k1.oid
             AND d.objsubid = 0
             AND d.deptype = 'n'
             AND d.refclassid = 'pg_class'::regclass
             AND d.refobjsubid=0
         )
    JOIN pg_catalog.pg_class ci ON (ci.oid = d.refobjid AND ci.relkind = 'i')
    LEFT JOIN pg_depend d2      ON (
                 d2.classid = 'pg_class'::regclass      -- @generated@
             AND d2.objid = ci.oid
             AND d2.objsubid = 0
             AND d2.deptype = 'i'
             AND d2.refclassid = 'pg_constraint'::regclass
             AND d2.refobjsubid = 0
         )
    LEFT JOIN pg_catalog.pg_constraint k2 ON (          -- @generated@
                 k2.oid = d2.refobjid
             AND k2.contype IN ('p', 'u')
         )
   WHERE k1.conrelid != 0
     AND k1.confrelid != 0
     AND k1.contype = 'f'
     AND _cat_tools._pg_sv_table_accessible(n1.oid, c1.oid)
;
GRANT SELECT ON cat_tools.pg_all_foreign_keys TO cat_tools__usage;

@generated@

SELECT __cat_tools.create_function(
  'cat_tools.currval'
  , $$
  table_name text
  , column_name text
$$
  , $$bigint LANGUAGE plpgsql$$
  , $body$
DECLARE
  seq regclass;
BEGIN
  -- Note: the function will throw an error if table or column doesn't exist
  seq := pg_get_serial_sequence( table_name, column_name );

  IF seq IS NULL THEN
    RAISE EXCEPTION '"%" is not a serial column', column_name
      USING ERRCODE = 'wrong_object_type'
        -- TODO: SCHEMA and COLUMN
        , COLUMN = column_name
    ;
  END IF;

  RETURN currval(seq);
END
$body$
  , 'cat_tools__usage'
);

@generated@

SELECT __cat_tools.create_function(
  'cat_tools.enum_range'
  , 'enum regtype'
  , $$text[] LANGUAGE plpgsql STABLE$$
  , $body$
DECLARE
  ret text[];
BEGIN
  EXECUTE format('SELECT pg_catalog.enum_range( NULL::%s )', enum) INTO ret;
  RETURN ret;
END
$body$
  , 'cat_tools__usage'
);

@generated@

SELECT __cat_tools.create_function(
  'cat_tools.enum_range_srf'
  , 'enum regtype'
  , $$SETOF text LANGUAGE sql$$
  , $body$
SELECT * FROM unnest( cat_tools.enum_range($1) ) AS r(enum_label)
$body$
  , 'cat_tools__usage'
);

SELECT __cat_tools.create_function(
  'cat_tools.pg_class'
  , 'rel regclass'
  , $$cat_tools.pg_class_v LANGUAGE sql STABLE$$
  , $body$
SELECT * FROM cat_tools.pg_class_v WHERE reloid = $1
$body$
  , 'cat_tools__usage'
);

@generated@

SELECT __cat_tools.create_function(
  'cat_tools.name__check'
  , 'name_to_check text'
  , $$void LANGUAGE plpgsql$$
  , $body$
BEGIN
  IF name_to_check IS DISTINCT FROM name_to_check::name THEN
    RAISE '"%" becomes "%" when cast to name', name_to_check, name_to_check::name;
  END IF;
END
$body$
  , 'cat_tools__usage'
);

@generated@

SELECT __cat_tools.create_function(
  'cat_tools.function__arg_types'
  , $$arguments text$$
  , $$regtype[] LANGUAGE plpgsql$$
  , $body$
DECLARE
  input_arg_types regtype[];

  c_template CONSTANT text := $fmt$CREATE FUNCTION pg_temp.cat_tools__function__arg_types__temp_function(
    %s
  ) RETURNS %s LANGUAGE plpgsql AS 'BEGIN NULL; END'
  $fmt$;

  temp_proc regprocedure;
  sql text;
BEGIN
  sql := format(
    c_template
    , arguments
    , 'void'
  );
  --RAISE DEBUG 'Executing SQL %', sql;
  DECLARE
    v_type regtype;
  BEGIN
    EXECUTE sql;
  EXCEPTION WHEN invalid_function_definition THEN
    v_type := (regexp_matches( SQLERRM, 'function result type must be ([^ ]+) because of' ))[1];
    sql := format(
      c_template
      , arguments
      , v_type
    );
    EXECUTE sql;
  END;

  /*
   * Get new OID. *This must be done dynamically!* Otherwise we get stuck
   * with a CONST oid after first compilation. The regproc cast ensures there's
   * only one function with this name. The cast to regprocedure is for the sake
   * of the DROP down below.
   */
  EXECUTE $$SELECT 'pg_temp.cat_tools__function__arg_types__temp_function'::regproc::regprocedure$$ INTO temp_proc;
  SELECT INTO STRICT input_arg_types
      -- This is here to re-cast the array as 1-based instead of 0 based (better solutions welcome!)
      string_to_array(proargtypes::text,' ')::regtype[]
    FROM pg_proc
    WHERE oid = temp_proc
  ;
  -- NOTE: DROP may not accept all the argument options that CREATE does, so use temp_proc
  EXECUTE format(
    $fmt$DROP FUNCTION %s$fmt$
    , temp_proc
  );

  RETURN input_arg_types;
END
$body$
  , 'cat_tools__usage'
);

@generated@

SELECT __cat_tools.create_function(
  'cat_tools.function__arg_types_text'
  , $$arguments text$$
  , $$text LANGUAGE sql$$
  , $body$
SELECT array_to_string(cat_tools.function__arg_types($1), ', ')
$body$
  , 'cat_tools__usage'
);

@generated@

SELECT __cat_tools.create_function(
  'cat_tools.regprocedure'
  , $$
  function_name text
  , arguments text$$
  , $$regprocedure LANGUAGE sql$$
  , $body$
SELECT format(
  '%s(%s)'
  , $1
  , cat_tools.function__arg_types_text($2)
)::regprocedure
$body$
  , 'cat_tools__usage'
);

@generated@

SELECT __cat_tools.create_function(
  'cat_tools.trigger__parse'
  , $$
  trigger_oid oid
  , OUT timing text
  , OUT events text[]
  , OUT defer text
  , OUT row_statement text
  , OUT when_clause text
  , OUT function_arguments text
$$
  , $$record LANGUAGE plpgsql$$
  , $body$
DECLARE
  r_trigger pg_catalog.pg_trigger;
  v_triggerdef text;
  v_create_stanza text;
  v_on_clause text;
  v_execute_clause text;

  v_work text;
  v_array text[];
BEGIN
  -- Do this first to make sure trigger exists
  v_triggerdef := pg_catalog.pg_get_triggerdef(trigger_oid, true);
  SELECT * INTO STRICT r_trigger FROM pg_catalog.pg_trigger WHERE oid = trigger_oid;

  v_create_stanza := format(
    'CREATE %sTRIGGER %I '
    , CASE WHEN r_trigger.tgconstraint=0 THEN '' ELSE 'CONSTRAINT ' END
    , r_trigger.tgname
  );
  -- Strip CREATE [CONSTRAINT] TRIGGER ... off
  v_work := replace( v_triggerdef, v_create_stanza, '' );

  -- Get BEFORE | AFTER | INSTEAD OF
  timing := split_part( v_work, ' ', 1 );
  timing := timing || CASE timing WHEN 'INSTEAD' THEN ' OF' ELSE '' END;

  -- Strip off timing clause
  v_work := replace( v_work, timing || ' ', '' );

  -- Get array of events (INSERT, UPDATE [OF column, column], DELETE, TRUNCATE)
  v_on_clause := ' ON ' || r_trigger.tgrelid::regclass || ' ';
  v_array := regexp_split_to_array( v_work, v_on_clause );
  events := string_to_array( v_array[1], ' OR ' );
  -- Get everything after ON table_name
  v_work := v_array[2];
  RAISE DEBUG 'v_work "%"', v_work;

  -- Strip off FROM referenced_table if we have it
  IF r_trigger.tgconstrrelid<>0 THEN
    v_work := replace(
      v_work
      , 'FROM ' || r_trigger.tgconstrrelid::regclass || ' '
      , ''
    );
  END IF;
  RAISE DEBUG 'v_work "%"', v_work;

  -- Get function arguments
  v_execute_clause := ' EXECUTE PROCEDURE ' || r_trigger.tgfoid::regproc || E'\\(';
  v_array := regexp_split_to_array( v_work, v_execute_clause );
  function_arguments := rtrim( v_array[2], ')' ); -- Yank trailing )
  -- Get everything prior to EXECUTE PROCEDURE ...
  v_work := v_array[1];
  RAISE DEBUG 'v_work "%"', v_work;

  row_statement := (regexp_matches( v_work, 'FOR EACH (ROW|STATEMENT)' ))[1];

  -- Get [ NOT DEFERRABLE | [ DEFERRABLE ] { INITIALLY IMMEDIATE | INITIALLY DEFERRED } ]
  v_array := regexp_split_to_array( v_work, 'FOR EACH (ROW|STATEMENT)' );
  RAISE DEBUG 'v_work = "%", v_array = "%"', v_work, v_array;
  defer := rtrim(v_array[1]);

  IF r_trigger.tgqual IS NOT NULL THEN
    when_clause := rtrim(
      (regexp_split_to_array( v_array[2], E' WHEN \\(' ))[2]
      , ')'
    );
  END IF;

  RAISE DEBUG
$$v_create_stanza = "%"
  v_on_clause = "%"
  v_execute_clause = "%"$$
    , v_create_stanza
    , v_on_clause
    , v_execute_clause
  ;

  RETURN;
END
$body$
  , 'cat_tools__usage'
);

@generated@

SELECT __cat_tools.create_function(
  'cat_tools.trigger__get_oid__loose'
  , $$
  trigger_table regclass
  , trigger_name text
$$
  , $$oid LANGUAGE sql$$
  , $body$
  SELECT oid
    FROM pg_trigger
    WHERE tgrelid = $1 --trigger_table
      AND tgname = $2 --trigger_name
  ;
$body$
  , 'cat_tools__usage'
);

@generated@

SELECT __cat_tools.create_function(
  'cat_tools.trigger__get_oid'
  , $$
  trigger_table regclass
  , trigger_name text
$$
  , $$oid LANGUAGE plpgsql$$
  , $body$
DECLARE
  v_oid oid;
BEGIN
  -- Note that because __loose isn't an SRF it'll always return a value
  v_oid := cat_tools.trigger__get_oid__loose( trigger_table, trigger_name ) ;

  IF v_oid IS NULL THEN
    RAISE EXCEPTION 'trigger % on table % does not exist', trigger_name, trigger_table;
  END IF;

  RETURN v_oid;
END
$body$
  , 'cat_tools__usage'
);

@generated@

INSERT INTO _cat_tools.catalog_metadata(object_catalog, reg_type, namespace_field)
SELECT object__catalog
    , CASE object__catalog
      WHEN 'pg_catalog.pg_class'::regclass THEN 'pg_catalog.regclass'
      WHEN 'pg_catalog.pg_ts_config'::regclass THEN 'pg_catalog.regconfig'
      WHEN 'pg_catalog.pg_ts_dict'::regclass THEN 'pg_catalog.regdictionary'
      WHEN 'pg_catalog.pg_namespace'::regclass THEN 'pg_catalog.regnamespace' -- SED: REQUIRES 9.5!
      WHEN 'pg_catalog.pg_operator'::regclass THEN 'pg_catalog.regoperator'
      WHEN 'pg_catalog.pg_proc'::regclass THEN 'pg_catalog.regprocedure'
      WHEN 'pg_catalog.pg_authid'::regclass THEN 'pg_catalog.regrole' -- SED: REQUIRES 9.5!
      WHEN 'pg_catalog.pg_type'::regclass THEN 'pg_catalog.regtype'
    END::pg_catalog.regtype
    , n.attname
  FROM (
    SELECT DISTINCT cat_tools.object__catalog(object_type)
      FROM cat_tools.enum_range_srf('cat_tools.object_type') r(object_type)
    ) d
    LEFT JOIN cat_tools.column n
      ON n.attrelid = object__catalog
      AND n.attname ~ 'namespace$'
      AND atttypid = 'oid'::pg_catalog.regtype
;
UPDATE _cat_tools.catalog_metadata
  SET simple_reg_type = 'pg_catalog.regproc'
  WHERE object_catalog = 'pg_catalog.pg_proc'::regclass
;
UPDATE _cat_tools.catalog_metadata
  SET simple_reg_type = 'pg_catalog.regoper'
  WHERE object_catalog = 'pg_catalog.pg_operator'::regclass
;
-- Cluster to get rid of dead rows
CLUSTER _cat_tools.catalog_metadata USING catalog_metadata__pk_object_catalog;

@generated@

/*
 * Drop "temporary" objects
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

-- vi: expandtab ts=2 sw=2
