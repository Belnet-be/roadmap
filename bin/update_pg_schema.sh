#!/usr/bin/env bash
set -e

## Belnet specific script

# check if .env file exists
FILE=".env"
if [ -f "$FILE" ]; then
  echo "Found file: '${FILE}'. Will configure environment variables."
  set -o allexport; source .env; set +o allexport
else
  echo -e "Error: ${FILE} not found. Can not continue."
  exit 1
fi

# Make first copy of (backup) import file
if [ ! -f "$DB_IMPORT_FOLDER/original_$DB_IMPORT_FILE" ]; then
  cp "$DB_IMPORT_FOLDER/$DB_IMPORT_FILE" "$DB_IMPORT_FOLDER/original_$DB_IMPORT_FILE"
  echo "Created backup of import file: $DB_IMPORT_FOLDER/original_$DB_IMPORT_FILE"
else
  echo "(Updated) backup of import file already exists: $DB_IMPORT_FOLDER/original_$DB_IMPORT_FILE"
  echo "Restoring import file from backup: $DB_IMPORT_FOLDER/original_$DB_IMPORT_FILE"
  cp "$DB_IMPORT_FOLDER/original_$DB_IMPORT_FILE" "$DB_IMPORT_FOLDER/$DB_IMPORT_FILE"
fi
# Create temporary database
docker compose exec postgres createdb -U "$POSTGRES_USER" scratchdb
# Restore import file to temporary database
if [[ $DB_IMPORT_FILE =~ \.sql$ ]]; then
  echo "Importing SQL data from $DB_IMPORT_FOLDER/$DB_IMPORT_FILE to temporary database scratchdb"
  docker compose exec -T postgres psql -d scratchdb -U "$POSTGRES_USER" < "$DB_IMPORT_FOLDER/$DB_IMPORT_FILE"
  echo "Ready importing data from $DB_IMPORT_FOLDER/$DB_IMPORT_FILE to temporary database scratchdb"
elif [[ $DB_IMPORT_FILE =~ \.dump$ ]]; then
  echo "Importing dump data from $DB_IMPORT_FOLDER/$DB_IMPORT_FILE to temporary database scratchdb"
  docker compose exec -T postgres pg_restore -d scratchdb -U "$POSTGRES_USER" < "$DB_IMPORT_FOLDER/$DB_IMPORT_FILE"
  echo "Ready importing data from $DB_IMPORT_FOLDER/$DB_IMPORT_FILE to temporary database scratchdb"
else
  echo "Unsupported import file format: $DB_IMPORT_FILE. Supported formats are .sql and .dump."
  exit 1
fi
# Rename schema in temporary database and update ownership and privileges
docker compose exec -T postgres psql -d scratchdb -U "$POSTGRES_USER" <<-EOSQL
  ALTER SCHEMA $DB_ORIGINAL_SCHEMA RENAME TO $DB_USERNAME;
  \c scratchdb
  REASSIGN OWNED BY $DB_ORIGINAL_SCHEMA TO $DB_USERNAME;
  REVOKE ALL PRIVILEGES ON SCHEMA $DB_USERNAME FROM $DB_ORIGINAL_SCHEMA;
  REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA $DB_USERNAME FROM $DB_ORIGINAL_SCHEMA;
  REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA $DB_USERNAME FROM $DB_ORIGINAL_SCHEMA;
  ALTER DEFAULT PRIVILEGES IN SCHEMA $DB_USERNAME REVOKE ALL ON TABLES FROM $DB_ORIGINAL_SCHEMA;
  ALTER DEFAULT PRIVILEGES IN SCHEMA $DB_USERNAME REVOKE ALL ON SEQUENCES FROM $DB_ORIGINAL_SCHEMA;
EOSQL
# Dump renamed schema from temporary database; overwrite original import file
if [[ $DB_IMPORT_FILE =~ \.sql$ ]]; then
  echo "Exporting SQL data from temporary database scratchdb to $DB_IMPORT_FOLDER/$DB_IMPORT_FILE"
  docker compose exec postgres pg_dump -U "$POSTGRES_USER" -n "$DB_USERNAME" scratchdb > "$DB_IMPORT_FOLDER/$DB_IMPORT_FILE"
  echo "Ready exporting data from temporary database scratchdb to $DB_IMPORT_FOLDER/$DB_IMPORT_FILE"
elif [[ $DB_IMPORT_FILE =~ \.dump$ ]]; then
  echo "Exporting dump data from temporary database scratchdb to $DB_IMPORT_FOLDER/$DB_IMPORT_FILE"
  docker compose exec postgres pg_dump -Fc -b -U "$POSTGRES_USER" -n "$DB_USERNAME" scratchdb > "$DB_IMPORT_FOLDER/$DB_IMPORT_FILE"
  echo "Ready exporting data from temporary database scratchdb to $DB_IMPORT_FOLDER/$DB_IMPORT_FILE"
else
  echo "Unsupported import file format: $DB_IMPORT_FILE. Supported formats are .sql and .dump."
  exit 1
fi
# Drop temporary database
docker compose exec postgres dropdb -U "$POSTGRES_USER" scratchdb
