#!/bin/bash
#miner_log="/home/caslx/logs/seal-miner-2022-05-17-16-03.log"
miner_log="/home/caslx/logs/miner-2022-05-18-16-41.log"
file_path="/home/caslx/HIK/ceshi0411/NVR101/"
file_cache_path="/home/caslx/HIK/opsService/deal/cache/"
file_tar_path="/home/caslx/HIK/opsService/deal/tar/"
car_path="/home/caslx/HIK/opsService/deal/car/"
log_path="/home/caslx/HIK/opsService/deal/log"


import_log="$log_path/tmp/import.log"
commP_log="$log_path/tmp/commP.log"
deal_cid_log="$log_path/tmp/dealcid.log"
fail_log="$log_path/fail.log"
deal_log="$log_path/deal.log"
proposal_CID=`cat $deal_cid_log`
while true
do
echo -e `date +"%Y-%m-%d %H:%M:%S"` "    \033[34mINFO\033[0m    Waiting for proposal" 
while true
do
if [[  -s $deal_cid_log ]];then
    proposal_CID=`cat $deal_cid_log`
    echo -e `date +"%Y-%m-%d %H:%M:%S"` "    \033[34mINFO\033[0m    Received a new proposal application    proposal_CID: $proposal_CID"
    break
else
    sleep 10
fi
done

while true 
do
    proposal_CID=`cat $deal_cid_log`
    if [ `grep $proposal_CID $miner_log|tail -1|grep StorageDealWaitingForData|wc -l` -ne 0 ];then
        echo -e `date +"%Y-%m-%d %H:%M:%S"` "    \033[34mINFO\033[0m    Proposal status: waiting for data import"
        break
    else
        echo -e `date +"%Y-%m-%d %H:%M:%S"` "    \033[34mINFO\033[0m    Waiting for proposal status: waiting for data import......."
	sleep 10
    fi
done

echo -e `date +"%Y-%m-%d %H:%M:%S"` "    \033[34mINFO\033[0m    Start importing proposal data    " `grep $proposal_CID $deal_log|awk '{print $4}'`
lotus-miner storage-deals import-data $proposal_CID  `grep $proposal_CID $deal_log|awk '{print $4}'`
if [ $? = 0 ];then 
	echo -e `date +"%Y-%m-%d %H:%M:%S"` "    \033[34mINFO   Congratulations! Import succeeded!\033[0m "
    echo -en `date +"%Y-%m-%d %H:%M:%S"` "    \033[34mINFO\033[0m    "proposal_CID: $proposal_CID
	echo 
	>$deal_cid_log
else 
	echo -en "`date +"%Y-%m-%d %H:%M:%S"`    \033[31mERROR\033[0m    Import failed! proposal_CID: $proposal_CID 文件:" `grep $proposal_CID $deal_log|awk '{print $4}'`
	exit
fi
done
