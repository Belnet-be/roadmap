#!/usr/bin/env bash
set -e

# $POSTGRES_USER and $POSTGRES_DB are set in the Dockerfile, default `postgres` for user and database
# Setup initial database and user for the application, via superuser
if [ -z "$DB_NAME" ] || [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ]; then
  echo "Error: DB_NAME, DB_USERNAME, and DB_PASSWORD must be set in the environment."
  exit 1
fi

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE ROLE $DB_USERNAME WITH LOGIN CREATEDB PASSWORD '$DB_PASSWORD';
  CREATE DATABASE $DB_NAME OWNER $DB_USERNAME;
  ALTER DATABASE $DB_NAME SET search_path TO $DB_USERNAME;
  ALTER ROLE $DB_USERNAME SET search_path TO $DB_USERNAME;
  \c $DB_NAME $DB_USERNAME
  GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USERNAME;
EOSQL

# Only used when updating the schema of a dump file
# DB_ORIGINAL_SCHEMA must contain the original schema name (and related ownername) for the dump file
# DB_USERNAME must contain the new schema name and be different from the original schema name
# Or you get 'ERROR:  role "<schema_ownername>" does not exist'
if [ -n "$DB_ORIGINAL_SCHEMA" ] && [ "$DB_ORIGINAL_SCHEMA" != "$DB_USERNAME" ]; then

echo "Creating extra role to update schema: $DB_ORIGINAL_SCHEMA"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE ROLE $DB_ORIGINAL_SCHEMA WITH LOGIN CREATEDB PASSWORD '$DB_PASSWORD';
EOSQL

fi

# Check if importfile is available and import the data
# /data-import folder is mounted from the host machine, and should contain the import file
if [ -f /data-import/"$DB_IMPORT_FILE" ]; then
  if [[ $DB_IMPORT_FILE =~ \.sql$ ]]; then
    echo "Importing SQL data from /data-import/$DB_IMPORT_FILE"
    PGPASSWORD=$DB_SUPERUSER_PASSWORD psql -v ON_ERROR_STOP=1 -d "$DB_NAME" -U "$POSTGRES_USER" -f /data-import/"$DB_IMPORT_FILE"
    echo "Ready importing data from /data-import/$DB_IMPORT_FILE"
  elif [[ $DB_IMPORT_FILE =~ \.dump$ ]]; then
    echo "Importing dump data from /data-import/$DB_IMPORT_FILE"
    PGPASSWORD=$DB_SUPERUSER_PASSWORD pg_restore -d "$DB_NAME" -U "$POSTGRES_USER" /data-import/"$DB_IMPORT_FILE"
    echo "Ready importing data from /data-import/$DB_IMPORT_FILE"
  else
    echo "Unsupported import file format: $DB_IMPORT_FILE. Supported formats are .sql and .dump."
  fi
else
  echo "No data import file found at /data-import/$DB_IMPORT_FILE. Skipping data import."
fi

if [ -n "$DB2_NAME" ]; then

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE DATABASE $DB2_NAME OWNER $DB_USERNAME;
  ALTER DATABASE $DB2_NAME SET search_path TO $DB_USERNAME;
  \c $DB2_NAME $DB_USERNAME
  GRANT ALL PRIVILEGES ON DATABASE $DB2_NAME TO $DB_USERNAME;
EOSQL

fi
