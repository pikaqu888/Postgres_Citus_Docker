#!/bin/bash
containerName=$1 restoreTime=$2

sudo docker cp $containerName.Backup.tar.gz $containerName:.
sudo docker exec $containerName bash -c "tar -xzf $containerName.Backup.tar.gz"
sudo docker exec $containerName bash -c "chown -R postgres:postgres backup/"
sudo docker exec $containerName bash -c "rm $containerName.Backup.tar.gz"
sudo docker exec $containerName bash -c "rm -rf /var/lib/postgresql/data/*"
sudo docker exec $containerName bash -c "cp -r backup/$restoreTime/* /var/lib/postgresql/data/"
sudo docker exec $containerName bash -c "chown -R postgres:postgres /var/lib/postgresql/data/"
sleep 60
sudo docker restart $containerName

echo "Finish the Postgres Citus Restore process!"