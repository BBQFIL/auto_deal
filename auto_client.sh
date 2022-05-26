#!/bin/bash
file_path="/home/caslx/HIK/ceshi0411/NVR101/"
file_cache_path="/home/caslx/HIK/opsService/deal/cache/"
file_tar_path="/home/caslx/HIK/opsService/deal/tar/"
car_path="/home/caslx/HIK/opsService/deal/car/"
log_path="/home/caslx/HIK/opsService/deal/log"
file_name_path="$log_path/file_name"

import_log="$log_path/tmp/import.log"
commP_log="$log_path/tmp/commP.log"
deal_cid_log="$log_path/tmp/dealcid.log"
fail_log="$log_path/fail.log"
deal_log="$log_path/deal.log"



num=20 
term=1468800 
wallet="t1gaefbxfct24tfv4tck4lpbq3522sq7pb6odoiqq" 
MinerAddress=t036295 
echo -e "\n\n\n---------------------------------------------------------------------------------------"
echo -e "\033[33mNumber_files = $num\nClient_wallet = $wallet\nMinerAddress = $MinerAddress\033[0m"
echo -e "---------------------------------------------------------------------------------------\n"
while true
do
echo -n "Please confirm whether the configuration is correct (y/n):"
read -e  result
if [[ $result == "y" ]];then
	break
elif [[ $result == "n" ]];then
	echo " n ,end of script!"
	exit
else
	echo "Incorrect input,please input again...."
fi
done

echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    Start running the script"

while true
do
	tar_name=`date +%s`
	while true
	do
		if [[  -s $deal_cid_log ]];then
			echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    One proposal was not accepted. Wait 60 seconds to recheck ..........."
			sleep 60
		else 
			break
		fi
	done 
	echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    Check the number of files in the directory    directory=$file_path need=$num available=`ls $file_path|wc -l`"

	if [ `ls $file_path|wc -l` -ge $num ];then
		ls $file_path|head -$num >$file_name_path/$tar_name
		echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    Move the files to be packaged to the specified directory    info=$file_name_path/$tar_name"	

		for i in `ls $file_path|head -$num`;
		do
			mv $file_path$i $file_cache_path
		done
		
	else

		echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[31mERROR\033[0m    Insufficient number of files in directory! Exit script    need=$num available=`ls $file_path|wc -l`"
		exit

	fi
	cd $file_cache_path
	echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    Start packaging directories    directory=$file_cache_path"

	tar cfP $file_tar_path$tar_name.tar *
	if [ $? = 0 ];then 
		:
		rm -rf $file_cache_path*
	else
		echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[31mERROR\033[0m    Directory packaging failed, migrate all files! Exit script"
		for i in `ls $file_cache_path`;
		do
			mv $file_cache_path$i $file_path
		done
		exit
	fi

	echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    Start converting file format    file=$file_tar_path$tar_name.tar save=$car_path$tar_name.car"
	lotus client generate-car $file_tar_path$tar_name.tar $car_path$tar_name.car
	if [ $? = 0 ];then 
		:
	else 
		echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[31mERROR\033[0m    Failed to convert file format! Exit script"
		exit
	fi

	echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    Start importing files into lotus"
	lotus client import --car $car_path$tar_name.car > $import_log
	if [ $? = 0 ];then 
	    echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    Import complete" 
		echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    `cat $import_log|sed 's/Root/payload-CID:/'`"
	else 
		echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[31mERROR\033[0m    Import failed! Exit script"
		exit
	fi

	echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    Start commp calculation"
	lotus client commP $car_path$tar_name.car > $commP_log
	if [ $? = 0 ];then 
		echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    Commp calculation completed"
		echo -ne `date +"%Y-%m-%d %H:%M:%S"`"    \033[34mINFO\033[0m    "$car_path$tar_name.car `cat $commP_log|sed 's/CID/Piece-CID/'`
		echo 
	else 
		echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[31mERROR\033[0m    Commp calculation failed! Exit script"
		exit
	fi
	PiecesCID=`cat $commP_log |awk 'NR==1 {print $2}'`
	PayloadCID=`cat $import_log |awk '{print $NF}'`
	now=`lotus status |awk 'NR==1 {print $3}'`
	LatestTime=`expr $now + 20160` 

	Size=`awk 'NR==2 {print $3}' $commP_log`
	Type=`awk 'NR==2 {print $NF}' $commP_log`
	mm=`echo $Size|awk -F"." '{print $1}'`
	for (( i=1;i<=10;i++ ))
	do
	    let "n=2**$i"
	    if [ $mm -le $n ];then
	         PieceSize_=$n 
	        break
	    fi
	done
	if [[ $Type == "GiB" ]];then
	    let "PieceSize=$PieceSize_*254*1024*1024*1024/256"
	elif [[ $Type == "MiB" ]];then
	    let "PieceSize=$PieceSize_*254*1024*1024/256"
	elif [[ $Type == "KiB" ]];then
	    let "PieceSize=$PieceSize_*254*1024/256"
	else 
	    echo "Type is err"
	fi

	SubmitFun(){
		echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    Initiate transaction proposal"
		echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    lotus client deal --fast-retrieval=true --from=$wallet --manual-piece-cid=$PiecesCID --manual-piece-size=$PieceSize --manual-stateless-deal --verified-deal=false --start-epoch=$LatestTime $PayloadCID $MinerAddress 0 $term"
		lotus client deal --fast-retrieval=true --from=$wallet --manual-piece-cid=$PiecesCID --manual-piece-size=$PieceSize --manual-stateless-deal --verified-deal=false --start-epoch=$LatestTime $PayloadCID $MinerAddress 0 $term > $deal_cid_log
		if [ $? = 0 ];then 
			echo -ne `date +"%Y-%m-%d %H:%M:%S"` "   \033[34mINFO\033[0m    The proposal was successfully delivered!"    proposal_CID=`cat $deal_cid_log`
			echo 
			echo -ne "`date +"%Y-%m-%d %H:%M:%S"` Car_path:" $car_path$tar_name.car `cat $commP_log|sed 's/CID/Piece-CID/'|sed 's/Piece\ size/Piece-size/'` `cat $import_log|sed 's/Import/Import编号:/'|sed 's/Root/payload-CID:/'` "proposal_CID:" `cat $deal_cid_log` >> $deal_log
			echo >> $deal_log 
		else 
			echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[31mERROR\033[0m    Proposal submission failed! Exit script"
			echo -e "`date +"%Y-%m-%d %H:%M:%S"` Car_path: $car_path$tar_name.car info: `cat $deal_cid_log` command: lotus client deal --fast-retrieval=true --from=$wallet --manual-piece-cid=$PiecesCID --manual-piece-size=$PieceSize --manual-stateless-deal --verified-deal=false --start-epoch=$LatestTime $PayloadCID $MinerAddress 0 $term" >> $fail_log
			exit
		fi
	}

	SubmitFun

	echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    Waiting for the proposal to be adopted ..........."
		
	while true
	do
		if [[  -s $deal_cid_log ]];then
		    proposal_CID=`cat $deal_cid_log`
	   		sleep 15
		else
	    	echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO    Congratulations! The proposal was accepted successfully! \033[0m"
			rm -rf $car_path* $file_tar_path*
			echo -e "`date +"%Y-%m-%d %H:%M:%S"`    \033[34mINFO\033[0m    Wait 5 seconds before submitting the next proposal ..........."
			sleep 5
	    	break
		fi
	done
done
