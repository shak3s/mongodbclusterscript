# Script to start a 4 shard 3 replica mongo cluster on a single node
# for development purposes


# Constants
DATADIRECTORY="datafolder"
SHARDCOUNT="a b c d" # use alpha a-z for your shard count
REPLICACOUNT=3

# Variables 
configdbparam=''
serviceportpart=10


# Clean up data and processes if they already exist 
if [ -d $DATADIRECTORY ]; then
  rm -rf $DATADIRECTORY
fi 
for pid in $(ps -ef | grep mongo | awk '{print $2}')
do 
  kill -9 $pid
done


# Create and move to working directory 
mkdir datafolder
cd datafolder


# Create db directories for config servers, start the config servers, 
# create the configdb parameter while starting servers up, strip the 
# trailing comma from the string. 
for i in $(seq 0 2)
do 
  mkdir cfg$i
  serviceport=2605$i
  mongod --configsvr --dbpath cfg$i --port $serviceport --fork --logpath log.cfg$i --logappend
  configdbparam=$configdbparam$(hostname):$serviceport,
done
configdbparam=$(echo $configdbparam | sed "s/.$//g")


# Create db directories for the different database servers
# and start the servers. 
for i in $SHARDCOUNT
do 
  for j in $(seq 1 $REPLICACOUNT)
  do
    let "j -= 1"
    mkdir $i$j
    serviceport=27$serviceportpart$j
    mongod --shardsvr --replSet $i --dbpath $i$j --logpath log.$i$j --port $serviceport --fork --logappend --smallfiles --oplogSize 50
  done
  let "serviceportpart += 10"
done


# Create the initial mongo shard listener on default port then 
# create the other mongo shard listeners on non-default ports 
mongos --configdb $configdbparam --fork --logappend --logpath log.mongos0
for i in $(seq 1 3)
do
  mongos --configdb $configdbparam --fork --logappend --logpath log.mongos$i --port 2606$i
done


# Output the running mongo processes and their startup commands 
echo
ps -Aef | grep mongo





