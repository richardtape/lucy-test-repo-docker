-- allow replica user to be a replication client and receive all replication events for all db and tables
CREATE USER IF NOT EXISTS 'replica'@'%' IDENTIFIED BY 'replica_pass';
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';
