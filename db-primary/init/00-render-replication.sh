#!/bin/bash
set -e

echo "Rendering replication SQL from template"

# We use sed because envsubst is not available in the minimal MariaDB image
echo "DEBUG: Starting 00-render-replication.sh"
echo "DEBUG: REPL_USER=$REPL_USER"

# We use sed because envsubst is not available in the minimal MariaDB image
echo "Rendering replication SQL from template..."

sed -e "s|\${REPL_USER}|$REPL_USER|g" \
    -e "s|\${REPL_PASSWORD}|$REPL_PASSWORD|g" \
    /docker-entrypoint-initdb.d/02-replication-user-init.sql.template \
    > /docker-entrypoint-initdb.d/02-replication-user-init.sql || { echo "ERROR: sed failed"; exit 1; }

echo "DEBUG: Rendered 02-replication-user-init.sql successfully"

# Execute the generated SQL immediately against the temporary server
# The entrypoint script does not pick up new files created after the loop started.
# We access the server using the password from the env
mariadb -u root -p"$MARIADB_ROOT_PASSWORD" < /docker-entrypoint-initdb.d/02-replication-user-init.sql

echo "Executed 02-replication-user-init.sql"
