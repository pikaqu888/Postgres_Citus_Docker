# Postgres_Citus_Docker
## Create Citus Cluster and Backup
Citus is an open source extension that transforms Postgres into a distributed database. The docker image is based on the official PostgreSQL image. Here will use **citusdata/citus:10.1** which uses **PostgreSQL 13.4** as an example, and create a cluster with **one coordinator** node and **two worker nodes** in different machines:

(The benefit of using **Citus docker image** is that it already has the Citus extention and configuration in Postgre, you don't need to install it, configure the postgresql.conf(`shared_preload_libraries ='citus'`) or create extension(`CREATE EXTENSION citus;`))

![image](uploads/cef25c24c908208cae0755deb37ecc5f/image.png)

`docker run -d --name citus_master -p 5432:5432 -e POSTGRES_PASSWORD=mypass citusdata/citus:10.1` 

`docker run -d --name citus_slave_1 -p 5432:5432 -e POSTGRES_PASSWORD=mypass citusdata/citus:10.1` (10.100.100.33)

`docker run -d --name citus_slave_2 -p 5432:5432 -e POSTGRES_PASSWORD=mypass citusdata/citus:10.1` (10.100.100.32)

Enter to **every container** and do the following commands:

`docker exec citus_master bash -c "mkdir /wal_archive; chown postgres.postgres /wal_archive"` (to save the Write-Ahead Logging (WAL) files, for **backup**)

`docker exec citus_master bash -c "head -n -1 var/lib/postgresql/data/pg_hba.conf > var/lib/postgresql/data/temp.conf; mv var/lib/postgresql/data/temp.conf var/lib/postgresql/data/pg_hba.conf"`

`docker exec citus_master bash -c "echo -e \"host all all all trust\" >> var/lib/postgresql/data/pg_hba.conf"`

Enter to database (for **backup**):

`docker exec citus_master bash -c "psql -U postgres -c 'ALTER SYSTEM SET archive_mode = on;'"`

`docker exec citus_master bash -c "psql -U postgres -c \"ALTER SYSTEM SET archive_command = 'test ! -f /wal_archive/%f && cp %p /wal_archive/%f';\""`

`docker exec citus_master bash -c "psql -U postgres -c 'ALTER SYSTEM SET wal_level = replica;'"`

**must** restart docker with `docker restart container_name`

After the restart process, just go to the **coordinator node** to add the worker nodes, create tables and shard the data:

`docker exec citus_master bash -c "psql -U postgres -c \"SELECT citus_add_node('10.100.100.33', 5432);\""`

`docker exec citus_master bash -c "psql -U postgres -c \"SELECT citus_add_node('10.100.100.32', 5432);\""`

`docker exec citus_master bash -c "psql -U postgres -c 'CREATE TABLE tb1(id int primary key, c1 int);'"`

`docker exec citus_master bash -c "psql -U postgres -c \"SELECT create_distributed_table('tb1','id');\""` (this function will shard the data to the worker nodes, it informs Citus that the **tb1** table should be distributed on the **id** column. By default the number of replica is 1, you can change by `SET citus.shard_replication_factor = xx;` command; by default the distribute table will be 32, you can change by `SET citus.shard_count = xx;` command)

`docker exec citus_master bash -c "psql -U postgres -c 'INSERT INTO tb1 select id,random()*1000 from generate_series(1,100)id;'"`

In the coordinator node, you can see the following result:

![image](uploads/d87e8788a0a28e35bfe446d1192d4380/image.png)

In the worker nodes, you can see the following result:

![image](uploads/e47a756e7b1f2fcd461b2a9df4d4b11a/image.png)
![image](uploads/53140dcd408af9762976168664da668b/image.png)

In **every machine** do the following command for a cluster physical backup, using `pg_basebackup` (for backup):

`docker exec -it citus_master pg_basebackup -U postgres -Ft -z -Xs -P -D /backup`

`docker cp backup/ citus_master:.`

`docker cp wal_archive/ citus_master:.`

## Restore Citus Cluster
In **every machine** that has the physical backup, do the following commands:

`docker cp backup/ citus_master:.`

`docker cp wal_archive/ citus_master:.`

Enter to docker container:

`docker exec citus_master bash -c "tar xzf backup/base.tar.gz -C /var/lib/postgresql/data/"`

`docker exec citus_master bash -c "tar xzf backup/pg_wal.tar.gz -C /var/lib/postgresql/data/pg_wal"`

Enter to database:

`docker exec citus_master bash -c "psql -U postgres -c \"ALTER SYSTEM SET restore_command = 'cp /wal_archive/%f %p';\""`

wait like 5 second

And restart all the containers, ⚠you will need to wait some time depending on the data size you have after the restart process to see the data⚠
