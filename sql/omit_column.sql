CREATE FUNCTION :s.omit_column(
  rel text
  , omit name[] DEFAULT array['oid']
) RETURNS text LANGUAGE sql IMMUTABLE AS $body$
SELECT array_to_string(array(
    SELECT attname
      FROM pg_attribute a
      WHERE attrelid = rel::regclass
        AND NOT attisdropped
        AND attnum >= 0
        AND attname != ANY( omit )
      ORDER BY attnum
    )
  , ', '
)
$body$;
