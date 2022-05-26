#!/bin/bash
#使用方法：(bash ./piece_size.sh 3.969 GiB) 
Size=$1
Type=$2
mm=`echo $Size|awk -F"." '{print $1}'`
for (( i=1;i<=10;i++ )) ; do  let "n=2**$i" ; if [ $mm -le $n ] ; then PieceSize_=$n ; break ; fi ; done
if [[ $Type == "GiB" ]];then let "PieceSize=$PieceSize_*254*1024*1024*1024/256" ; elif [[ $Type == "MiB" ]];then let "PieceSize=$PieceSize_*254*1024*1024/256" ; elif [[ $Type == "KiB" ]];then let "PieceSize=$PieceSize_*254*1024/256" ; else  echo "Type is err" ; fi
echo manual-piece-size=$PieceSize
