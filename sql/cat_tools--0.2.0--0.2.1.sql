-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

/*
 * NOTE: All pg_temp objects must be dropped at the end of the script!
 * Otherwise the eventual DROP CASCADE of pg_temp when the session ends will
 * also drop the extension! Instead of risking problems, create our own
 * "temporary" schema instead.
 */
CREATE SCHEMA __cat_tools;

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

CREATE FUNCTION __cat_tools.exec(
  sql text
) RETURNS void LANGUAGE plpgsql AS $body$
BEGIN
  RAISE DEBUG 'sql = %', sql;
  EXECUTE sql;
END
$body$;

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

CREATE FUNCTION __cat_tools.create_function(
  function_name text
  , args text
  , options text
  , body text
  , grants text DEFAULT NULL
  , comment text DEFAULT NULL
) RETURNS void LANGUAGE plpgsql AS $body$
DECLARE
  c_simple_args CONSTANT text := cat_tools.function__arg_types_text(args);

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

  comment_template CONSTANT text := $template$
COMMENT ON FUNCTION %s(
%s
) IS %L;
$template$
  ;

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

BEGIN
  PERFORM __cat_tools.exec( format(
      create_template
      , function_name
      , args
      , options -- TODO: Force search_path if options ~* 'definer'
      , body
    ) )
  ;
  PERFORM __cat_tools.exec( format(
      revoke_template
      , function_name
      , c_simple_args
    ) )
  ;

  IF grants IS NOT NULL THEN
    PERFORM __cat_tools.exec( format(
        grant_template
        , function_name
        , c_simple_args
        , grants
      ) )
    ;
  END IF;

  IF comment IS NOT NULL THEN
    PERFORM __cat_tools.exec( format(
        comment_template
        , function_name
        , c_simple_args
        , comment
      ) )
    ;
  END IF;
END
$body$;

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

/*
 * UPGRADE STARTS HERE
 */
SELECT __cat_tools.create_function(
  'cat_tools.pg_attribute__get'
  , $$
  relation pg_catalog.regclass
  , column_name name
$$
  , $$pg_catalog.pg_attribute LANGUAGE plpgsql$$
  , $body$
DECLARE
  r pg_catalog.pg_attribute;
BEGIN
  SELECT INTO STRICT r
      *
    FROM pg_catalog.pg_attribute
    WHERE attrelid = relation
      AND attname = column_name
  ;
  RETURN r;
EXCEPTION WHEN no_data_found THEN
  RAISE 'column "%" of relation "%" does not exist', column_name, relation
    USING ERRCODE = 'undefined_column'
  ;
END
$body$
  , 'cat_tools__usage'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.function__arg_types'
  , $$arguments text$$
  , $$pg_catalog.regtype[] LANGUAGE plpgsql$$
  , $body$
DECLARE
  input_arg_types pg_catalog.regtype[];

  c_template CONSTANT text := $fmt$CREATE FUNCTION pg_temp.cat_tools__function__arg_types__temp_function(
    %s
  ) RETURNS %s LANGUAGE plpgsql AS 'BEGIN NULL; END'
  $fmt$;

  temp_proc pg_catalog.regprocedure;
  sql text;
BEGIN
  sql := format(
    c_template
    , arguments
    , 'void'
  );
  --RAISE DEBUG 'Executing SQL %', sql;
  DECLARE
    v_type pg_catalog.regtype;
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
  EXECUTE $$SELECT 'pg_temp.cat_tools__function__arg_types__temp_function'::pg_catalog.regproc::pg_catalog.regprocedure$$ INTO temp_proc;
  SELECT INTO STRICT input_arg_types
      -- This is here to re-cast the array as 1-based instead of 0 based (better solutions welcome!)
      string_to_array(proargtypes::text,' ')::pg_catalog.regtype[]
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
  , 'Returns argument types for a function argument body as an array. Unlike a
  normal regprocedure cast, this function accepts anything that is valid when
  defining a function.'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.function__arg_types_text'
  , $$arguments text$$
  , $$text LANGUAGE sql$$
  , $body$
SELECT array_to_string(cat_tools.function__arg_types($1), ', ')
$body$
  , 'cat_tools__usage'
  , 'Returns argument types for a function argument body as text. Unlike a
  normal regprocedure cast, this function accepts anything that is valid when
  defining a function.'

);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.regprocedure'
  , $$
  function_name text
  , arguments text$$
  , $$pg_catalog.regprocedure LANGUAGE sql$$
  , $body$
SELECT format(
  '%s(%s)'
  , $1
  , cat_tools.function__arg_types_text($2)
)::pg_catalog.regprocedure
$body$
  , 'cat_tools__usage'
  , 'Returns a regprocedure for a given function name and arguments. Unlike a
  normal regprocedure cast, arguments can contain anything that is valid when
  defining a function.'
);


-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

DO $$BEGIN
CREATE TYPE cat_tools.constraint_type AS ENUM(
  'domain constraint', 'table constraint'
);
EXCEPTION WHEN duplicate_object THEN NULL;
END$$;
COMMENT ON TYPE cat_tools.constraint_type IS $$Descriptive names for every type of Postgres object (table, operator, rule, etc)$$;

DO $$BEGIN
CREATE TYPE cat_tools.procedure_type AS ENUM(
  'aggregate', 'function'
);
EXCEPTION WHEN duplicate_object THEN NULL;
END$$;
COMMENT ON TYPE cat_tools.procedure_type IS $$Types of constraints (`domain constraint` or `table_constraint`)$$;

DO $$BEGIN
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
EXCEPTION WHEN duplicate_object THEN NULL;
END$$;
COMMENT ON TYPE cat_tools.relation_type IS $$Types of objects stored in `pg_class`$$;

/*
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
COMMENT ON TYPE cat_tools.relation_relkind IS $$Valid values for `pg_class.relkind`$$;
*/

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

DO $$BEGIN
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
  /*
   * NOTE! These are a bit weird because columns live in pg_attribute, but
   * address stuff recognizes columns as part of pg_class with a subobjid <> 0!
   */
  , 'table column'
  , 'index column'
  , 'sequence column'
  , 'toast table column'
  , 'view column'
  , 'materialized view column'
  , 'composite type column'
  , 'foreign table column'
  -- pg_constraint
  -- NOTE: a domain itself is considered to be a type
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
  , 'event trigger' -- pg_event_trigger -- SED: REQUIRES 9.3!
  , 'policy' -- SED: REQUIRES 9.5!
  , 'transform' -- SED: REQUIRES 9.5!
  , 'access method' -- pg_am
);
EXCEPTION WHEN duplicate_object THEN NULL;
END$$;

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.objects__shared'
  , ''
  , 'cat_tools.object_type[] LANGUAGE sql STRICT IMMUTABLE'
  , $body$
SELECT '{role,database,tablespace}'::cat_tools.object_type[]
$body$
  , 'cat_tools__usage'
  , 'Returns array of object types for shared objects.'
);
SELECT __cat_tools.create_function(
  'cat_tools.objects__shared_srf'
  , ''
  , 'SETOF cat_tools.object_type LANGUAGE sql STRICT IMMUTABLE'
  , $body$
SELECT * FROM pg_catalog.unnest(cat_tools.objects__shared())
$body$
  , 'cat_tools__usage'
  , 'Returns set of object types for shared objects.'
);
SELECT __cat_tools.create_function(
  'cat_tools.object__is_shared'
  , 'object_type cat_tools.object_type'
  , 'boolean LANGUAGE sql STRICT IMMUTABLE'
  , $body$
SELECT object_type = ANY(cat_tools.objects__shared())
$body$
  , 'cat_tools__usage'
  , 'Returns true if object_type is a shared object.'
);
SELECT __cat_tools.create_function(
  'cat_tools.object__is_shared'
  , 'object_type text'
  , 'boolean LANGUAGE sql STRICT IMMUTABLE'
  , $body$
SELECT cat_tools.object__is_shared(object_type::cat_tools.object_type)
$body$
  , 'cat_tools__usage'
  , 'Returns true if object_type is a shared object.'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.objects__address_unsupported'
  , ''
  , 'cat_tools.object_type[] LANGUAGE sql STRICT IMMUTABLE'
  , $body$
SELECT array[
  'toast table'::cat_tools.object_type, 'composite type'
  , 'index column' , 'sequence column', 'toast table column', 'view column'
  , 'materialized view column', 'composite type column'
]
$body$
  , 'cat_tools__usage'
  , 'Returns array of object types not supported by pg_get_object_address().'
);
SELECT __cat_tools.create_function(
  'cat_tools.objects__address_unsupported_srf'
  , ''
  , 'SETOF cat_tools.object_type LANGUAGE sql STRICT IMMUTABLE'
  , $body$
SELECT * FROM pg_catalog.unnest(cat_tools.objects__address_unsupported())
$body$
  , 'cat_tools__usage'
  , 'Returns set of object types not supported by pg_get_object_address().'
);
-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in
SELECT __cat_tools.create_function(
  'cat_tools.object__is_address_unsupported'
  , 'object_type cat_tools.object_type'
  , 'boolean LANGUAGE sql STRICT IMMUTABLE'
  , $body$
SELECT object_type = ANY(cat_tools.objects__address_unsupported())
$body$
  , 'cat_tools__usage'
  , 'Returns true if object type is not supported by pg_get_object_address().'
);
SELECT __cat_tools.create_function(
  'cat_tools.object__is_address_unsupported'
  , 'object_type text'
  , 'boolean LANGUAGE sql STRICT IMMUTABLE'
  , $body$
SELECT cat_tools.object__is_address_unsupported(object_type::cat_tools.object_type)
$body$
  , 'cat_tools__usage'
  , 'Returns true if object type is not supported by pg_get_object_address().'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.object__catalog'
  , 'object_type cat_tools.object_type'
  , 'pg_catalog.regclass LANGUAGE sql STRICT IMMUTABLE'
  , $body$
SELECT (
  'pg_catalog.'
  || CASE
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
    WHEN object_type::text LIKE '% column'
      THEN 'pg_attribute'
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
      WHEN 'event trigger' THEN 'pg_event_trigger' -- SED: REQUIRES 9.3!
      WHEN 'access method' THEN 'pg_am'
      ELSE 'pg_' || object_type::text
      END
    END
  )::pg_catalog.regclass
$body$
  , 'cat_tools__usage'
  , 'Returns catalog table that is used to store <object_type> objects'
);
-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in
SELECT __cat_tools.create_function(
  'cat_tools.object__catalog'
  , 'object_type text'
  , 'pg_catalog.regclass LANGUAGE sql STRICT IMMUTABLE'
  , $body$SELECT cat_tools.object__catalog(object_type::cat_tools.object_type)$body$
  , 'cat_tools__usage'
  , 'Returns catalog table that is used to store <object_type> objects'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.object__address_classid'
  , 'object_type cat_tools.object_type'
  , 'pg_catalog.regclass LANGUAGE sql STRICT IMMUTABLE'
  , $body$
SELECT CASE
  WHEN c = 'pg_catalog.pg_attribute'::regclass THEN 'pg_catalog.pg_class'::regclass
  ELSE c
  END
  FROM cat_tools.object__catalog(object_type::cat_tools.object_type) c
$body$
  , 'cat_tools__usage'
  , 'Returns the classid used by the pg_*_object*() functions for an object_type'
);
SELECT __cat_tools.create_function(
  'cat_tools.object__address_classid'
  , 'object_type text'
  , 'pg_catalog.regclass LANGUAGE sql STRICT IMMUTABLE'
  , $body$SELECT cat_tools.object__address_classid(object_type::cat_tools.object_type)$body$
  , 'cat_tools__usage'
  , 'Returns the classid used by the pg_*_object*() functions for an object_type'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

DO $$BEGIN
CREATE TABLE _cat_tools.catalog_metadata(
  object_catalog    pg_catalog.regclass
    CONSTRAINT catalog_metadata__pk_object_catalog PRIMARY KEY
  , namespace_field name
  , reg_type        pg_catalog.regtype
  , simple_reg_type pg_catalog.regtype
);
INSERT INTO _cat_tools.catalog_metadata(object_catalog, reg_type, namespace_field)
SELECT object__catalog
    , CASE object__catalog
      WHEN 'pg_catalog.pg_class'::pg_catalog.regclass THEN 'pg_catalog.regclass'
      WHEN 'pg_catalog.pg_ts_config'::pg_catalog.regclass THEN 'pg_catalog.regconfig'
      WHEN 'pg_catalog.pg_ts_dict'::pg_catalog.regclass THEN 'pg_catalog.regdictionary'
      WHEN 'pg_catalog.pg_namespace'::pg_catalog.regclass THEN 'pg_catalog.regnamespace' -- SED: REQUIRES 9.5!
      WHEN 'pg_catalog.pg_operator'::pg_catalog.regclass THEN 'pg_catalog.regoperator'
      WHEN 'pg_catalog.pg_proc'::pg_catalog.regclass THEN 'pg_catalog.regprocedure'
      WHEN 'pg_catalog.pg_authid'::pg_catalog.regclass THEN 'pg_catalog.regrole' -- SED: REQUIRES 9.5!
      WHEN 'pg_catalog.pg_type'::pg_catalog.regclass THEN 'pg_catalog.regtype'
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
  WHERE object_catalog = 'pg_catalog.pg_proc'::pg_catalog.regclass
;
UPDATE _cat_tools.catalog_metadata
  SET simple_reg_type = 'pg_catalog.regoper'
  WHERE object_catalog = 'pg_catalog.pg_operator'::pg_catalog.regclass
;
-- Cluster to get rid of dead rows
CLUSTER _cat_tools.catalog_metadata USING catalog_metadata__pk_object_catalog;
EXCEPTION WHEN duplicate_table THEN NULL;
END$$;
-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

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

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.object__reg_type'
  , 'object_catalog pg_catalog.regclass'
  , 'pg_catalog.regtype LANGUAGE sql SECURITY DEFINER STRICT IMMUTABLE'
  , $body$
SELECT (_cat_tools.catalog_metadata__get(object_catalog)).reg_type
$body$
  , 'cat_tools__usage'
  , 'Returns the object identifier type (ie: regclass) associated with a system catalog (ie: pg_class).'
);
SELECT __cat_tools.create_function(
  'cat_tools.object__reg_type'
  , 'object_type cat_tools.object_type'
  , 'pg_catalog.regtype LANGUAGE sql STRICT IMMUTABLE'
  , $body$SELECT cat_tools.object__reg_type(cat_tools.object__catalog(object_type))$body$
  , 'cat_tools__usage'
  , 'Returns the object identifier type (ie: regclass) associated with a system catalog (ie: pg_class).'
);
SELECT __cat_tools.create_function(
  'cat_tools.object__reg_type'
  , 'object_type text'
  , 'pg_catalog.regtype LANGUAGE sql STRICT IMMUTABLE'
  , $body$SELECT cat_tools.object__reg_type(object_type::cat_tools.object_type)$body$
  , 'cat_tools__usage'
  , 'Returns the object identifier type (ie: regclass) associated with a system catalog (ie: pg_class).'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.object__reg_type_catalog'
  , 'object_identifier_type regtype'
  , 'pg_catalog.regclass LANGUAGE plpgsql SECURITY DEFINER STRICT IMMUTABLE'
  , $body$
DECLARE
  cat pg_catalog.regclass;
BEGIN
  SELECT INTO STRICT cat
      object_catalog
    FROM _cat_tools.catalog_metadata m
    WHERE m.reg_type = object_identifier_type
      OR m.simple_reg_type = object_identifier_type
  ;
  RETURN cat;
EXCEPTION WHEN no_data_found THEN
  IF object_identifier_type::text LIKE 'reg%' THEN
    RAISE 'object identifier type % is not supported', object_identifier_type
      USING
        HINT = format( 'If %I is a valid object identifier type please open an issue at https://github.com/decibel/cat_tools/issues.', object_identifier_type )
        , ERRCODE = 'feature_not_supported'
    ;
  ELSE
    RAISE '% is not a object identifier type', object_identifier_type
      USING
        HINT = 'See https://www.postgresql.org/docs/current/static/datatype-oid.html'
        , ERRCODE = 'wrong_object_type'
    ;
  END IF;
END
$body$
  , 'cat_tools__usage'
  , 'Returns the system catalog that stores a particular object identifier type.'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

DROP FUNCTION cat_tools.relation__kind(cat_tools.relation_relkind);
DROP FUNCTION cat_tools.relation__kind(text);
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
  , 'Mapping from <pg_class.relkind> to a <cat_tools.relation_type>'
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
  , 'Mapping from <cat_tools.relation_type> to a <pg_class.relkind> value'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.relation__relkind'
  , 'kind text'
  , 'cat_tools.relation_relkind LANGUAGE sql STRICT IMMUTABLE'
  , $body$SELECT cat_tools.relation__relkind(kind::cat_tools.relation_type)$body$
  , 'cat_tools__usage'
  , 'Mapping from <cat_tools.relation_type> to a <pg_class.relkind> value'
);
SELECT __cat_tools.create_function(
  'cat_tools.relation__kind'
  , 'relkind text'
  , 'cat_tools.relation_type LANGUAGE sql STRICT IMMUTABLE'
  , $body$SELECT cat_tools.relation__kind(relkind::cat_tools.relation_relkind)$body$
  , 'cat_tools__usage'
  , 'Mapping from <cat_tools.relation_type> to a <pg_class.relkind> value'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

CREATE OR REPLACE VIEW _cat_tools.pg_depend_identity_v AS -- SED: REQUIRES 9.3!
  SELECT o.type AS object_type -- SED: REQUIRES 9.3!
      , o.schema AS object_schema -- SED: REQUIRES 9.3!
      , o.name AS object_name -- SED: REQUIRES 9.3!
      , o.identity AS object_identity -- SED: REQUIRES 9.3!
      , r.type AS reference_type -- SED: REQUIRES 9.3!
      , r.schema AS reference_schema -- SED: REQUIRES 9.3!
      , r.name AS reference_name -- SED: REQUIRES 9.3!
      , r.identity AS reference_identity -- SED: REQUIRES 9.3!
      , d.* -- SED: REQUIRES 9.3!
    FROM pg_catalog.pg_depend d -- SED: REQUIRES 9.3!
      , pg_catalog.pg_identify_object(classid, objid, objsubid) o -- SED: REQUIRES 9.3!
      , pg_catalog.pg_identify_object(refclassid, refobjid, refobjsubid) r -- SED: REQUIRES 9.3!
    WHERE classid <> 0 -- SED: REQUIRES 9.3!
  UNION ALL -- SED: REQUIRES 9.3!
  SELECT NULL, NULL, NULL, NULL -- SED: REQUIRES 9.3!
      , r.type AS reference_type -- SED: REQUIRES 9.3!
      , r.schema AS reference_schema -- SED: REQUIRES 9.3!
      , r.name AS reference_name -- SED: REQUIRES 9.3!
      , r.identity AS reference_identity -- SED: REQUIRES 9.3!
      , d.* -- SED: REQUIRES 9.3!
    FROM pg_catalog.pg_depend d -- SED: REQUIRES 9.3!
      , pg_catalog.pg_identify_object(refclassid, refobjid, refobjsubid) r -- SED: REQUIRES 9.3!
    WHERE classid = 0 -- SED: REQUIRES 9.3!
; -- SED: REQUIRES 9.3!

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in


CREATE OR REPLACE VIEW cat_tools.pg_extension_v AS
  SELECT e.oid, e.*

      , extnamespace::regnamespace AS extschema -- SED: REQUIRES 9.5!
-- Not used prior to 9.5:       , nspname AS extschema 

      , extconfig::pg_catalog.regclass[] AS ext_config_tables
    FROM pg_catalog.pg_extension e
      LEFT JOIN pg_catalog.pg_namespace n ON n.oid = e.extnamespace
;
GRANT SELECT ON cat_tools.pg_extension_v TO cat_tools__usage;

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

/*
 * EXTENSION FUNCTIONS
 */
SELECT __cat_tools.create_function(
  'cat_tools.pg_extension__get'
  , 'extension_name name'
  , $$cat_tools.pg_extension_v LANGUAGE plpgsql$$
  , $body$
DECLARE
  r cat_tools.pg_extension_v;
BEGIN
  SELECT INTO STRICT r
      *
    FROM cat_tools.pg_extension_v
    WHERE extname = extension_name
  ;
  RETURN r;
EXCEPTION WHEN no_data_found THEN
  RAISE 'extension "%" does not exist', extension_name
    USING ERRCODE = 'undefined_object'
  ;
END
$body$
  , 'cat_tools__usage'
);
SELECT __cat_tools.create_function(
  'cat_tools.extension__schemas'
  , 'extension_names name[]'
  , $$pg_catalog.regnamespace[] LANGUAGE sql$$ -- SED: REQUIRES 9.5!
-- Not used prior to 9.5:   , $$pg_catalog.name[] LANGUAGE sql$$ 
  , $body$
SELECT array(
  SELECT (cat_tools.pg_extension__get(en)).extschema
    FROM unnest(extension_names) en
)
$body$
  , 'cat_tools__usage'
);
SELECT __cat_tools.create_function(
  'cat_tools.extension__schemas_unique'
  , 'extension_names name[]'
  , $$pg_catalog.regnamespace[] LANGUAGE sql$$ -- SED: REQUIRES 9.5!
-- Not used prior to 9.5:   , $$pg_catalog.name[] LANGUAGE sql$$ 
  , $body$
SELECT array(
  SELECT DISTINCT (cat_tools.pg_extension__get(en)).extschema
    FROM unnest(extension_names) en
)
$body$
  , 'cat_tools__usage'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

-- Text versions
SELECT __cat_tools.create_function(
  'cat_tools.extension__schemas'
  , 'extension_names text'
  , $$pg_catalog.regnamespace[] LANGUAGE sql$$ -- SED: REQUIRES 9.5!
-- Not used prior to 9.5:   , $$pg_catalog.name[] LANGUAGE sql$$ 
  , $body$
SELECT cat_tools.extension__schemas(
  CASE WHEN extension_names LIKE '{%}' THEN extension_names
  ELSE '{' || extension_names || '}'
  END::name[]
)
$body$
  , 'cat_tools__usage'
);
SELECT __cat_tools.create_function(
  'cat_tools.extension__schemas_unique'
  , 'extension_names text'
  , $$pg_catalog.regnamespace[] LANGUAGE sql$$ -- SED: REQUIRES 9.5!
-- Not used prior to 9.5:   , $$pg_catalog.name[] LANGUAGE sql$$ 
  , $body$
SELECT cat_tools.extension__schemas_unique(
  CASE WHEN extension_names LIKE '{%}' THEN extension_names
  ELSE '{' || extension_names || '}'
  END::name[]
)
$body$
  , 'cat_tools__usage'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

/*
 * SEQUENCE FUNCTIONS
 */
SELECT __cat_tools.create_function(
  'cat_tools.get_serial_sequence'
  , $$
  table_name text
  , column_name text
$$
  , $$pg_catalog.regclass LANGUAGE plpgsql$$
  , $body$
DECLARE
  seq pg_catalog.regclass;
BEGIN
  -- Note: the function will throw an error if table or column doesn't exist
  seq := pg_get_serial_sequence( table_name, column_name );

  IF seq IS NULL THEN
    RAISE EXCEPTION '"%" is not a serial column', column_name
      USING ERRCODE = 'wrong_object_type'
        -- TODO: SCHEMA and COLUMN
        , COLUMN = column_name -- SED: REQUIRES 9.3!
    ;
  END IF;

  RETURN seq;
END
$body$
  , 'cat_tools__usage'
  , 'Return sequence that is associated with a column. Unlike the pg_get_serial_sequence, throw an exception if there is no sequence associated with the column.'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.sequence__last'
  , $$
  table_name text
  , column_name text
$$
  , $$bigint LANGUAGE sql$$
  , 'SELECT pg_catalog.currval(cat_tools.get_serial_sequence($1,$2))'
  , 'cat_tools__usage'
  , 'Return the last value assigned to a column with an associated sequence.'
);
SELECT __cat_tools.create_function(
  'cat_tools.currval'
  , $$
  table_name text
  , column_name text
$$
  , $$bigint LANGUAGE sql$$
  , 'SELECT cat_tools.sequence__last($1,$2)'
  , 'cat_tools__usage'
  , 'Return the last value assigned to a column with an associated sequence.'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.sequence__next'
  , $$
  table_name text
  , column_name text
$$
  , $$bigint LANGUAGE sql$$
  , 'SELECT pg_catalog.nextval(cat_tools.get_serial_sequence($1,$2))'
  , 'cat_tools__usage'
  , 'Return the next value to assign to a column with an associated sequence. THIS ADVANCES THE SEQUENCE.'
);
SELECT __cat_tools.create_function(
  'cat_tools.nextval'
  , $$
  table_name text
  , column_name text
$$
  , $$bigint LANGUAGE sql$$
  , 'SELECT cat_tools.sequence__next($1,$2)'
  , 'cat_tools__usage'
  , 'Return the next value to assign to a column with an associated sequence. THIS ADVANCES THE SEQUENCE.'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.setval'
  , $$
  table_name text
  , column_name text
  , new_value bigint
  , has_been_used boolean DEFAULT true
$$
  , $$bigint LANGUAGE sql$$
  , 'SELECT pg_catalog.setval(cat_tools.get_serial_sequence($1,$2), $3, $4)'
  , 'cat_tools__usage'
  , 'Changes the value for a sequence associated with a column. If has_been_used is true, the sequence will be set to new_value + 1. Returns new_value. See also sequence__set_last() and sequence__set_next().'
);
SELECT __cat_tools.create_function(
  'cat_tools.sequence__set_last'
  , $$
  table_name text
  , column_name text
  , last_value bigint
$$
  , $$bigint LANGUAGE sql$$
  , 'SELECT cat_tools.setval($1,$2,$3,true)'
  , 'cat_tools__usage'
  , 'Changes the value for a sequence associated with a column. last_value is the last value used, so sequence is set to last_value+1. See also sequence__set_next().'
);
SELECT __cat_tools.create_function(
  'cat_tools.sequence__set_next'
  , $$
  table_name text
  , column_name text
  , next_value bigint
$$
  , $$bigint LANGUAGE sql$$
  , 'SELECT cat_tools.setval($1,$2,$3,false)'
  , 'cat_tools__usage'
  , 'Changes the value for a sequence associated with a column. next_value is the next value the sequence will assign. See also sequence__last_value.'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

/*
 * Trigger functions
 */
DROP FUNCTION trigger__parse(oid);
SELECT __cat_tools.create_function(
  'cat_tools.trigger__get_oid__loose'
  , $$
  trigger_table pg_catalog.regclass
  , trigger_name text
$$
  , $$oid LANGUAGE sql$$
  , $body$
  SELECT oid
    FROM pg_trigger
    WHERE tgrelid = $1 --trigger_table
      AND tgname = CASE
        /*
         * tgname isn't quoted, so strip quotes, but only if the string both
         * starts and ends with quotes
         */
        WHEN $2 LIKE '"%"' THEN btrim($2, '"')
        ELSE $2
        END --trigger_name
  ;
$body$
  , 'cat_tools__usage'
  , 'Return the OID for a trigger. Returns NULL if trigger does not exist.'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.trigger__get_oid'
  , $$
  trigger_table pg_catalog.regclass
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
    RAISE EXCEPTION 'trigger % on table % does not exist', trigger_name, trigger_table
      USING errcode = 'undefined_object' -- 42704
    ;
  END IF;

  RETURN v_oid;
END
$body$
  , 'cat_tools__usage'
  , 'Return the OID for a trigger. Throws an undefined_object error if the trigger does not exist.'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.trigger__parse'
  , $$
  trigger_oid oid
  , OUT trigger_table regclass
  , OUT timing text
  , OUT events text[]
  , OUT defer text
  , OUT row_statement text
  , OUT when_clause text
  , OUT trigger_function regprocedure
  , OUT function_arguments text[]
$$
  , $$record STABLE LANGUAGE plpgsql$$
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
  /*
   * Do this first to make sure trigger exists.
   *
   * TODO: After we no longer support < 9.6, test v_triggerdef for NULL instead
   * using the extra block here.
   */
  BEGIN
    SELECT * INTO STRICT r_trigger FROM pg_catalog.pg_trigger WHERE oid = trigger_oid;
  EXCEPTION WHEN no_data_found THEN
    RAISE EXCEPTION 'trigger with OID % does not exist', trigger_oid
      USING errcode = 'undefined_object' -- 42704
    ;
  END;
  trigger_table := r_trigger.tgrelid;
  trigger_function := r_trigger.tgfoid;

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
  v_on_clause := ' ON ' || r_trigger.tgrelid::pg_catalog.regclass || ' ';
  v_array := regexp_split_to_array( v_work, v_on_clause );
  events := string_to_array( v_array[1], ' OR ' );
  -- Get everything after ON table_name
  v_work := v_array[2];
  RAISE DEBUG 'v_work "%"', v_work;

  -- Strip off FROM referenced_table if we have it
  IF r_trigger.tgconstrrelid<>0 THEN
    v_work := replace(
      v_work
      , 'FROM ' || r_trigger.tgconstrrelid::pg_catalog.regclass || ' '
      , ''
    );
  END IF;
  RAISE DEBUG 'v_work "%"', v_work;

  -- Get function arguments
  v_execute_clause := ' EXECUTE PROCEDURE ' || r_trigger.tgfoid::pg_catalog.regproc || E'\\(';
  v_array := regexp_split_to_array( v_work, v_execute_clause );
  EXECUTE format(
      'SELECT array[ %s ]'
      , rtrim( v_array[2], ')' ) -- Yank trailing )
    )
    INTO function_arguments
  ;
  RAISE DEBUG 'v_array[2] "%"', v_array[2];
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
  , 'Provide details about a trigger.'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.trigger__parse'
  , $$
  trigger_table pg_catalog.regclass
  , trigger_name text
  , OUT timing text
  , OUT events text[]
  , OUT defer text
  , OUT row_statement text
  , OUT when_clause text
  , OUT trigger_function regprocedure
  , OUT function_arguments text[]
$$
  , $$record STABLE LANGUAGE sql$$
  -- s/, OUT \(\w*\).*/  , \1/
  , $body$
SELECT
    timing
    , events
    , "defer"
    , row_statement
    , when_clause
    , trigger_function
    , function_arguments
  FROM cat_tools.trigger__parse(
    cat_tools.trigger__get_oid(trigger_table, trigger_name)
  )
$body$
  , 'cat_tools__usage'
  , 'Provide details about a trigger.'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in

SELECT __cat_tools.create_function(
  'cat_tools.trigger__args_as_text'
  , $$function_arguments text[]$$
  , $$text IMMUTABLE STRICT LANGUAGE sql$$
  , $body$
  SELECT format(
    $$'%s'$$
    , array_to_string(
      function_arguments
      , $$', '$$
    )
  )
$body$
  , 'cat_tools__usage'
  , 'Convert function_arguments as returned by trigger__parse() to text (for backwards compatibility).'
);

-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in



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
  , comment text
);
DROP SCHEMA __cat_tools;

-- vi: expandtab ts=2 sw=2
-- GENERATED FILE! DO NOT EDIT! See sql/cat_tools--0.2.0--0.2.1.sql.in
