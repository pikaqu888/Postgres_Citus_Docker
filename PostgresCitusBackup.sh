#!/bin/bash
containerName=$1

date=$(date +"%Y%m%d%H%M%S")
sudo docker exec $containerName bash -c "pg_basebackup -U postgres -Xs -P -D /backup/$date"
sudo docker exec $containerName bash -c "tar -czf $containerName.Backup.tar.gz -C /backup $date"
sudo docker cp $containerName:$containerName.Backup.tar.gz .
sudo docker exec $containerName bash -c "rm $containerName.Backup.tar.gz"

#done
echo "Finish the Postgres backup process!"
