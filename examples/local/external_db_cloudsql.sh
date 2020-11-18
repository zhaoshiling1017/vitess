#!/bin/bash    
    
# Copyright 2019 The Vitess Authors.    
#     
# Licensed under the Apache License, Version 2.0 (the "License");    
# you may not use this file except in compliance with the License.    
# You may obtain a copy of the License at    
#     
#     http://www.apache.org/licenses/LICENSE-2.0    
#     
# Unless required by applicable law or agreed to in writing, software    
# distributed under the License is distributed on an "AS IS" BASIS,    
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    
# See the License for the specific language governing permissions and    
# limitations under the License.    
    
# this script brings up zookeeper and all the vitess components    
# required for a single shard deployment.    

uid=500    
printf -v tablet_dir 'vt_%010d' $uid    
echo calling mkdir ${VTDATAROOT}/${tablet_dir}    
mkdir -p ${VTDATAROOT}/${tablet_dir}    

source ./env.sh    
    
# start topo server    
if [ "${TOPO}" = "zk2" ]; then    
    CELL=zone1 ./scripts/zk-up.sh    
elif [ "${TOPO}" = "k8s" ]; then    
    CELL=zone1 ./scripts/k3s-up.sh    
else    
 CELL=zone1 ./scripts/etcd-up.sh    
fi    
    
# start vtctld    
CELL=zone1 ./scripts/vtctld-up.sh    
 
# scripts/vttablet-external-up.sh
echo running ./scripts/vttablet-external-cloudsql-up.sh
CELL=zone1 KEYSPACE=cloudsqltest1  SHARD=0    TABLET_UID=$uid ./scripts/vttablet-external-cloudsql-up.sh    

# reparent for the master
sleep 2    
vtctlclient -server localhost:15999 TabletExternallyReparented zone1-$uid

    
echo creating vschema
# create the vschema    
vtctlclient -server localhost:15999 ApplyVSchema -vschema_file vschema_commerce_initial.json cloudsqltest1    
    
echo starting vtgate
# start vtgate    
CELL=zone1 ./scripts/vtgate-up.sh    


