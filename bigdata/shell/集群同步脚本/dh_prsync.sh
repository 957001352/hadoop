#!/bin/bash
#同步文件或者目录到其他机器上去，目前只支持全路径和当前路径，只能在hadoop01上执行
HOST_DIR=/home/hadoop/dev/parm

#判断是否为文件夹，保证此文件夹路径最后一个字符为/
if [ -d "$1" ];then
    str=$1
    ch="${str: -1}"
    if [ "x$ch" != "x/" ];then
        file_path=$1"/"
    else
        file_path=$1
    fi
else 
    file_path=$1
fi
#echo "${file_path}"

#判断是否为全路径，不是的话转为全路径
#找到上级路径
dirname_path=`dirname ${file_path}`
#echo "dirname_path: "$dirname_path
#根据上级路径判断是否是当前路径
if [ "." == "$dirname_path" ];then
    dirname_path=`pwd`
    full_file_path="$dirname_path/${file_path}"
#根据第一个字符判断是否为全路径，
elif [ "/" == "${file_path:0:1}" ];then
    #echo "this is full path"
    full_file_path=${file_path}
else
    echo "[-] This is not supported, only full path files and current path files are supported."
    exit 1
fi
echo "full_file_path : "$full_file_path

#如果目标路径为空，则和源路径一致
if [ -z "$2" ];then
    dist_full_file_path=$full_file_path
else
    dist_full_file_path=$2
fi

#实际测试不能自动创建多级远程目标文件夹，需手动创建
if [ -d "$dist_full_file_path" ];then
    #目录
    mkdir_path="mkdir -p $dist_full_file_path"
else
    #文件
    dirname_path=`dirname $dist_full_file_path`
    mkdir_path="mkdir -p $dirname_path"
fi

opts="--partial"
#hosts="${HOST_DIR}/"
if [ -z "$2" ];then
    opts="${opts} --delete -r"
    hosts="${HOST_DIR}/host_slaves.list"
    echo "full prsync ..."
else
    hosts="${HOST_DIR}/host_all.list"
    echo "half prsync ..."
fi

echo "pssh : '$mkdir_path'"
pssh -h $hosts -i $mkdir_path

if [ "$USER" == "root" ];then
    mkdir -p /var/log/pssh/prsync
    chmod -R 777 /var/log/pssh
fi

#进行同步
echo "prsync : '$full_file_path' '$dist_full_file_path'"
prsync -z -a -x "${opts}" -p 8 -e /var/log/pssh/prsync -h $hosts $full_file_path $dist_full_file_path


