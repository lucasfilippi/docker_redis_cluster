#!/bin/sh

set -e

log_dir=/var/log/redis-cluster
lock_file=/data/cluster.lock

mkdir -p $log_dir

# Initialize configs
for p in 7000 7001 7002 7003 7004 7005
do
  conf_path=/redis-$p.conf
  data_dir=/data/redis-$p

  mkdir -p $data_dir
  cp /redis.conf $conf_path
  echo "
port $p
dir $data_dir" >> $conf_path

  echo "
[program:redis-$p]
command=redis-server $conf_path
autorestart=unexpected
stdout_logfile=$log_dir/$p.log" >> /supervisord.conf
done

# Start Redis servers
supervisord
sleep 3

IP=`ip add | grep global| awk '{print \$2}' | cut -d / -f 1`
# Create Redis cluster
if [ ! -f $lock_file ]; then
  touch $lock_file
  echo "yes" | /redis-trib.rb create --replicas 1 ${IP}:7000 ${IP}:7001 ${IP}:7002 ${IP}:7003 ${IP}:7004 ${IP}:7005
fi

tail -f $log_dir/*.log
