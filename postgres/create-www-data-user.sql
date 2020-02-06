DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT                       -- SELECT list can stay empty for this
      FROM   pg_catalog.pg_roles
      WHERE  rolname = 'www-data') THEN

      CREATE ROLE "www-data" NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;
   END IF;
END
$do$;
