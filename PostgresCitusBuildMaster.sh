#!/bin/bash
containerName=$1

docker exec $containerName bash -c "head -n -1 var/lib/postgresql/data/pg_hba.conf > var/lib/postgresql/data/temp.conf; mv var/lib/postgresql/data/temp.conf var/lib/postgresql/data/pg_hba.conf"
docker exec $containerName bash -c "echo -e \"host all all all trust\" >> var/lib/postgresql/data/pg_hba.conf"
docker restart $containerName
docker exec $containerName bash -c "psql -U postgres -c \"SELECT citus_add_node('xx.xxx.xxx.33', 5432);\""
docker exec $containerName bash -c "psql -U postgres -c \"SELECT citus_add_node('xx.xxx.xxx.32', 5432);\""
docker exec $containerName bash -c "psql -U postgres -c 'CREATE TABLE tb1(id int primary key, c1 int);'"
docker exec $containerName bash -c "psql -U postgres -c \"SELECT create_distributed_table('tb1','id');\""
docker exec $containerName bash -c "psql -U postgres -c 'INSERT INTO tb1 select id,random()*1000 from generate_series(1,100)id;'"

#done
echo "Finish the Postgres Citus build process!"
