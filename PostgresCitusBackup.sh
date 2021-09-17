#!/bin/bash
containerName=$1

sudo docker exec $containerName bash -c "pg_basebackup -U postgres -Xs -P -D /backup/'`date +\"%Y%m%d%H%M%S\"`'"
sudo docker exec $containerName bash -c "tar -czf $containerName.Backup.tar.gz backup/*"
sudo docker cp $containerName:$containerName.Backup.tar.gz .
sudo docker exec $containerName bash -c "rm $containerName.Backup.tar.gz"

#done
echo "Finish the Postgres Citus backup process!"