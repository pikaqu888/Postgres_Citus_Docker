#!/bin/bash
containerName=$1 restoreTime=$2

sudo docker exec $containerName bash -c "mkdir backup"
sudo docker cp $containerName.Backup.tar.gz $containerName:/backup
sudo docker exec $containerName bash -c "tar -xzf backup/$containerName.Backup.tar.gz -C backup"
sudo docker exec $containerName bash -c "chown -R postgres:postgres backup/"
sudo docker exec $containerName bash -c "rm $containerName.Backup.tar.gz"
sudo docker exec $containerName bash -c "rm -rf /var/lib/postgresql/data/*"
sudo docker exec $containerName bash -c "cp -r backup/*/* /var/lib/postgresql/data/"
sudo docker exec $containerName bash -c "chown -R postgres:postgres /var/lib/postgresql/data/"
sudo docker exec $containerName bash -c "rm -rf backup"
sleep 60
sudo docker restart $containerName

echo "Finish the Postgres Restore process!"
