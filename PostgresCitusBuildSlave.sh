#!/bin/bash
containerName=$1

docker exec $containerName bash -c "head -n -1 var/lib/postgresql/data/pg_hba.conf > var/lib/postgresql/data/temp.conf; mv var/lib/postgresql/data/temp.conf var/lib/postgresql/data/pg_hba.conf"
docker exec $containerName bash -c "echo -e \"host all all all trust\" >> var/lib/postgresql/data/pg_hba.conf"
docker restart $containerName

#done
echo "Finish the Postgres Citus build process!"