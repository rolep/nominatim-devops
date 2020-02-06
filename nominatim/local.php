<?php
// Paths
@define('CONST_Postgresql_Version', '11');
@define('CONST_Postgis_Version', '3.0');
// Website settings
@define('CONST_Replication_Url', 'http://download.geofabrik.de/europe/monaco-updates');
@define('CONST_Replication_MaxInterval', '86400');     // Process each update separately, osmosis cannot merge multiple updates
@define('CONST_Replication_Update_Interval', '86400');  // How often upstream publishes diffs
@define('CONST_Replication_Recheck_Interval', '900');   // How long to sleep if no update found yet
@define('CONST_Pyosmium_Binary', '/usr/local/bin/pyosmium-get-changes');
@define('CONST_Import_Style', CONST_BasePath.'/settings/import-'.(getenv('NOMINATIM_IMPORT_STYLE') ?: 'full').'.style');
@define('CONST_Website_BaseURL', getenv('NOMINATIM_WEB_BASE_URL') ?: '/');
@define('CONST_Database_DSN', getenv('NOMINATIM_DB_DSN') ?: 'pgsql:dbname=nominatim');
//@define('CONST_Database_DSN', 'pgsql:host=192.168.1.128;port=6432;user=nominatim;password=password1234;dbname=nominatim'); <driver>:host=<host>;port=<port>;user=<username>;password=<password>;dbname=<database>
