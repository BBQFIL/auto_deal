#!/bin/bash
log_path="/home/caslx/HIK/opsService/deal/log"
file_name_path="$log_path/file_name"
deal_log="$log_path/deal.log"

input1=$1
input2=$2
Locate_file(){
locate=`grep $1 $file_name_path/*|awk -F"/" '{print $NF}'|sed 's/:/    /'  2>/dev/null`
if [ ! -n  "$locate" ];then
    echo -e "\033[31mError: file is not included in any deal.    Check input: \"$1\".\033[0m"
    exit
fi
echo -e "\033[34m$locate\033[0m"
}

Included_files(){
file=`grep $1 $deal_log |awk '{print $4}'|awk -F"/" '{print $NF}'|awk -F"." '{print $1}'`
if [ ! -n  "$file" ];then
    echo -e "\033[31mError: This deal was not found.    Check input: \"$1\".\033[0m"
    exit
fi

cat $file_name_path/$file|xargs -i echo -e "\033[34m{}\033[0m" 2>/dev/null  
}

Deal_info(){
grep $1 $deal_log 2>/dev/null 
    if [ $? = 0 ];then 
		:
	else
		echo -e "\033[31mError: deal information does not exist.    Check input: \"$1\".\033[0m"
	fi
}

Help(){
echo -e "\nUSAGE:\n    bash ./query.sh [command] [arguments]\n\nCOMMANDS:\n    deal    Query the information of deal\n    file    Find the deal that contains this file\n    tar     Query the files contained in this deal\n"
}


if [[ $input1 == "deal" ]];then
    Deal_info $input2
elif [[ $input1 == "file" ]];then
    Locate_file $input2
elif [[ $input1 == "tar"  ]];then
    Included_files $input2
elif [[ $input1 == "-h" ]];then
    Help $input2
else
    echo -e "\n\033[31mError: Input error, Check input: \"$input1\".\033[0m\n\n"
    Help 
fi
