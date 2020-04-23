#!/bin/sh
###############################################################################
##  Author        : sunxiaolong
##  Name          : export_dim_table.sh
##  Functions     : 同步整库或者某个表到hive
##  description   : 需要传入的参数有：项目编号（名称）、数据库名、表名
##  Revisions or Comments
##  VER        DATE        AUTHOR           DESCRIPTION
##---------  ----------  ---------------  ------------------------------------ 
##  1.0      2019-07-18  sunxiaolong        1. CREATED THIS SHELL.   
###############################################################################


#刷新参数及引用公共function
. `dirname ${0}`/func_utils.sh
. `dirname ${0}`/parameter.sh

function USAGE(){
    echo "[ERROR] Please check the number of parameters passed in!"
    echo "How to use this shell script!"
    echo "Sample: bash export_dim_table.sh [PROJECT] [DB_SCHEMA] [TAB_NAME]"
}


if [ $# -ne 3 ];then
    USAGE
    exit 1;
fi

#开始时间
start_time=$(GET_CURTIME_STANDARD)

#接收传入参数
PROJECT=$1                #项目简称
DB_NAME=$2                #database名称
TAB_NAME=$3               #表名称

#判断[project]参数是否正确
project_info=$(mysql -h${ETL_HOST} -P${ETL_PORT} -u${ETL_USER} -p${ETL_PASSWD} -Nse "SELECT DISTINCT PROJECT FROM ETL.SCHEMA_INFO WHERE PROJECT='${PROJECT}' AND IS_VALID = 'Y'")

if [[ -z ${project_info} ]];then
   echo "[-] This project name is not exists,please check table 'ETL.SCHEMA_INFO' value!"
   exit 2
fi

#获取DB参数信息,并且判断传入[DB_NAME]参数是否正确
db_info=(`mysql -h${ETL_HOST} -P${ETL_PORT} -u${ETL_USER} -p${ETL_PASSWD} -Nse "SELECT DB_HOST,DB_TYPE,DB_PORT,USERNAME,PASSWD FROM ETL.SCHEMA_INFO WHERE PROJECT='${PROJECT}' AND IS_VALID = 'Y'"`)

if [[ -z ${db_info} ]];then
   echo "[-] This DB information is not exists,please check table 'ETL.SCHEMA_INFO' value!"
   exit 3
else
   DB_HOST=${db_info[0]}            #数据库地址IP
   DB_TYPE=${db_info[1]}            #数据库类型
   DB_PORT=${db_info[2]}            #端口号
   USERNAME=${db_info[3]}           #用户名
   PASSWD=${db_info[4]}             #密码
   
   #拼接jdbc_url 
   JDBC_URL=$(get_jdbc_url $DB_TYPE $DB_HOST $DB_PORT $DB_NAME)
fi


#判断是全库同步还是单表同步,并且判断传入[TAB_NAME]参数是否正确
if [[ "$TAB_NAME" == "all" ]];then
   tab_list=$(mysql -h${ETL_HOST} -P${ETL_PORT} -u${ETL_USER} -p${ETL_PASSWD} -Nse "SELECT TABLE_NAME FROM ETL.TABLE_INFO WHERE PROJECT='${PROJECT}' AND SCHEMA_NAME='${DB_NAME}' AND IS_VALID='Y'")
else
   tab_list=$(mysql -h${ETL_HOST} -P${ETL_PORT} -u${ETL_USER} -p${ETL_PASSWD} -Nse "SELECT TABLE_NAME FROM ETL.TABLE_INFO WHERE PROJECT='${PROJECT}' AND SCHEMA_NAME='${DB_NAME}' AND TABLE_NAME='${TAB_NAME}' AND IS_VALID = 'Y'")
   
   if [[ -z ${tab_list} ]];then
       echo "[-] This table information is not exists,please check table 'ETL.TABLE_INFO' value!"
       exit 4
   fi
   
fi


#判断hive中是否存在库${PROJECT}_${DB_NAME}，不存在则创建 
hive -e "create database if not exists ${PROJECT}_${DB_NAME};"

#创建执行sqooo的日志目录
mkdir -p ${V_SHELL_LOGS}/sqoop

#trap捕获中断命令，如果接收到Ctrl+C中断命令，则关闭文件描述符1000的读写，并正常退出	
trap "exec 1000>&-;exec 1000<&-;exit 0" 2

#新建有名管道，用作控制并发量
mkfifo FIFO

#将文件描述符1000与FIFO进行绑定
exec 1000<>FIFO

#控制并发的数量10
for ((i=1; i<=10; i++))
do
    echo >&1000
done


#for循环执行每次并发的命令或者脚本
for table in ${tab_list}
do 
    read -u 1000
    { 
	    #job开始执行时间
	    import_start=$(GET_CURTIME_STANDARD)
		
        # echo $table
		# hive -e "truncate table ${PROJECT}_${DB_NAME}.${table}"
	    set -x
    	sqoop import \
		--connect ${JDBC_URL} \
		--username ${USERNAME} \
		--password ${PASSWD} \
		--table ${table} \
		--null-string '\\N' \
		--null-non-string '\\N' \
		--hive-import \
		--hive-overwrite \
		--hive-database ${PROJECT}_${DB_NAME} \
		--hive-table ${table} > ${V_SHELL_LOGS}/sqoop/${PROJECT}_${DB_NAME}.${table}.log 2>&1
		
		#获取执行状态
		status=$(echo `is_success` | awk '{print $2}' | awk -F ']' '{print $1}')
		echo "${table} ${status}"
		set +x
		
		#获取错误原因
		if [[ ${status} == "FAILED" ]]; then
		
     	    error=$(cat ${V_SHELL_LOGS}/sqoop/${PROJECT}_${DB_NAME}.${table}.log | grep -E "ERROR|error|failed|Caused by")
			echo ${error}
		else 
		    error=""
		fi
		
		#job执行结束时间
	    import_end=$(GET_CURTIME_STANDARD)
		
		#时长
		duration=$(DATETIME_DIF "${import_start}" "${import_end}")
		
		#把执行状态插入日志表 etl.collect_logs
		insert_log_sql="INSERT INTO etl.collect_logs (collect_type,state,project,db_name,table_name,db_user,sys_user,error,start_time,end_time,duration) VALUES ('full','${status}','${PROJECT}','${DB_NAME}','${table}','${USERNAME}','${USER}',\"${error}\",'${import_start}','${import_end}',${duration})"
		mysql -h${ETL_HOST} -P${ETL_PORT} -u${ETL_USER} -p${ETL_PASSWD} -e "${insert_log_sql}"
		
		#删除自动生成的java文件(如果表名称是以数字0-9开头的，则生成的java文件前面加了"_")
		if [[ -f ${table}.java ]];then
		    rm -rf ${table}.java 
		else
            rm -rf _${table}.java
		fi
		
		echo >&1000
    } &
done

wait               #等待上次执行完毕

#删除管道符
rm -rf FIFO

#刷新impala元数据
impala-shell -q "INVALIDATE METADATA"

#结束时间
end_time=$(GET_CURTIME_STANDARD)

#用总时长
duration=$(DATETIME_DIF "${start_time}" "${end_time}")

echo "[+] Process is end, And total time is ${duration} seconds !"

