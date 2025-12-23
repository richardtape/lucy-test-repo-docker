#!/bin/bash
set -e

echo "Rendering replication SQL from template"

envsubst < /docker-entrypoint-initdb.d/02-replication-user-init.sql.template \
         > /docker-entrypoint-initdb.d/02-replication-user-init.sql
