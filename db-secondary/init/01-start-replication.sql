--set credentials in replica server and starts replication threads 
CHANGE MASTER TO
  MASTER_HOST='db-primary',
  MASTER_USER='replica',
  MASTER_PASSWORD='replica_pass',
  MASTER_USE_GTID=slave_pos;

START SLAVE;

