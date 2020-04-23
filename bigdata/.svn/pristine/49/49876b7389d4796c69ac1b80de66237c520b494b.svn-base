#!/bin/sh
###############################################################################
##  Author        : sunxiaolong
##  Name          : export_fact_table.sh
##  Functions     : 增量导入生产数据库数据到hive表
##  description   : 需要传入的参数有：厂商编号、数据库名、表名
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
    echo "Sample: bash export_fact_table.sh [PROJECT] [DB_SCHEMA] [TAB_NAME] [DB_FLAG]"
}

set -x

if [ $# -lt 3 ];then
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
project_info=$(${MYSQL_EXEC} -Nse "SELECT DISTINCT PROJECT FROM ETL.SCHEMA_INFO WHERE PROJECT='${PROJECT}' AND IS_VALID = 'Y'")

if [[ -z ${project_info} ]];then
   echo "[-] This project name is not exists,please check table 'ETL.SCHEMA_INFO' value!"
   exit 2
fi

#获取DB参数信息,并且判断传入[DB_NAME]参数是否正确
db_info=(`${MYSQL_EXEC} -Nse "SELECT DB_HOST,DB_TYPE,DB_PORT,USERNAME,PASSWD FROM ETL.SCHEMA_INFO WHERE PROJECT='${PROJECT}' AND IS_VALID = 'Y'"`)

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


#判断是否全表还是单表增量导入,并且判断传入[TAB_NAME]参数是否正确
if [[ "$TAB_NAME" == "all" ]];then
   tab_list=$(${MYSQL_EXEC} -Nse "SELECT TABLE_NAME FROM ETL.TABLE_INFO WHERE PROJECT='${PROJECT}' AND SCHEMA_NAME='${DB_NAME}' AND IS_VALID='Y'")
else
   tab_list=$(${MYSQL_EXEC} -Nse "SELECT TABLE_NAME FROM ETL.TABLE_INFO WHERE PROJECT='${PROJECT}' AND SCHEMA_NAME='${DB_NAME}' AND TABLE_NAME='${TAB_NAME}' AND IS_VALID = 'Y'")
   
   if [[ -z ${tab_list} ]];then
       echo "[-] This table information is not exists,please check table 'ETL.TABLE_INFO' value!"
       exit 4
   fi
   
fi


#判断hive中是否存在库${PROJECT}_${DB_NAME}，不存在则创建 
hive -e "create database if not exists ${PROJECT}_${DB_NAME};"

#创建执行sqooo的日志目录
mkdir -p ${V_SHELL_LOGS}/sqoop

#获取本次更新到的PRI_KEY_COLUMN的max value
#get_key_sql="SELECT MAX(${PRI_KEY_COLUMN}) FROM ${DB_NAME}.${TAB_NAME}"
#max_key_value=$(bash $(dirname ${0})/db_executor.sh -t ${DB_TYPE} -h ${DB_HOST} -P ${DB_PORT} -n ${USERNAME} -p ${PASSWD} -q "${get_key_sql}")

#更新本次采集的截止PRI_KEY_COLUMN
#update_sql_last_value="UPDATE ETL.TABLE_INFO SET LAST_VALUE=${max_key_value} WHERE PROJECT='${PROJECT}' AND SCHEMA_NAME='${DB_NAME}' AND TABLE_NAME='${TAB_NAME}'"
#bash $(dirname ${0})/db_executor.sh -t mysql -h hadoop01 -P 3306 -n hadoop -p hadoop -q "${update_sql_last_value}"


#创建密码并且上传hdfs
echo -n ${PASSWD} > ${V_SHELL_TMP}/${PROJECT}_${DB_NAME}.pwd
hadoop fs -rm /user/hadoop/passwd/${PROJECT}_${DB_NAME}.pwd
hadoop fs -put ${V_SHELL_TMP}/${PROJECT}_${DB_NAME}.pwd  /user/hadoop/passwd/
rm -rf ${V_SHELL_TMP}/${PROJECT}_${DB_NAME}.pwd

for table in ${tab_list}
do 
    #拼接job name
    job_name=${PROJECT}_${DB_NAME}_${table}

    #判断${job_name}是否已经存在
    exist_job=$(sqoop job --list | grep ${PROJECT}_${DB_NAME}_${table} | awk '{print $NF}')
	
	#如果 ${job_name} 不存在，则创建job 
	if [[ -z ${exist_job} ]];then
#       sqoop job --exec  ${job_name}  > ${V_SHELL_LOGS}/sqoop/${PROJECT}_${DB_NAME}.${table}.log 2>&1

		PRI_KEY_COLUMN=$(${MYSQL_EXEC} -Nse "SELECT PRI_KEY_COLUMN FROM ETL.TABLE_INFO WHERE PROJECT='${PROJECT}' AND SCHEMA_NAME='${DB_NAME}' AND TABLE_NAME='${table}' AND IS_VALID = 'Y'")
		
        # 创建job任务
        sqoop job --create ${job_name} -- import \
        --connect ${JDBC_URL}  \
        --username ${USERNAME} \
        --password-file /user/hadoop/passwd/${PROJECT}_${DB_NAME}.pwd \
        --table ${table} \
        --null-string '\\N' \
        --null-non-string '\\N' \
        --fields-terminated-by '\001' \
        --hive-import \
        --hive-database ${PROJECT}_${DB_NAME} \
        --hive-table ${table} \
        --split-by ${PRI_KEY_COLUMN} \
        --incremental append \
        --check-column ${PRI_KEY_COLUMN} \
        --last-value 0  > ${V_SHELL_LOGS}/sqoop/${PROJECT}_${DB_NAME}.${table}.log.create 2>&1
		
		is_success && echo "${job_name}"
	fi
done



#trap捕获中断命令，如果接收到Ctrl+C中断命令，则关闭文件描述符1001的读写，并正常退出	
trap "exec 1001>&-;exec 1001<&-;exit 0" 2

#新建有名管道，用作控制并发量
mkfifo FIFO

#将文件描述符1001与FIFO进行绑定
exec 1001<>FIFO

#控制并发的数量10
for ((i=1; i<=10; i++))
do
    echo >&1001
done

#for循环执行每次并发的命令或者脚本
for TABLE in ${tab_list}
do 
    read -u 1001
    {   
	    #job开始执行时间
	    job_start=$(GET_CURTIME_STANDARD)
		
	    #获取job name
		JOB_NAME=${PROJECT}_${DB_NAME}_${TABLE}
		
        # 执行job任务
        sqoop job --exec  ${JOB_NAME} > ${V_SHELL_LOGS}/sqoop/${PROJECT}_${DB_NAME}.${TABLE}.log 2>&1	

        #获取执行状态
        status=$(echo `is_success` | awk '{print $2}' | awk -F ']' '{print $1}')
        echo "${TABLE} ${status}"
		
        #更新本次的主键值
        if [[ ${status} == "SUCCESSED" ]]; then
        
            min_value=$(cat ${V_SHELL_LOGS}/sqoop/${PROJECT}_${DB_NAME}.${TABLE}.log | grep "Lower bound value" | awk -F ":" '{print $NF}' | awk '{print $NF}')
            max_value=$(cat ${V_SHELL_LOGS}/sqoop/${PROJECT}_${DB_NAME}.${TABLE}.log | grep "Upper bound value" | awk -F ":" '{print $NF}' | awk '{print $NF}')
            
        	if [[ -n ${min_value} && -n ${max_value} ]]; then
        	
        	    update_pri_sql="UPDATE ETL.TABLE_INFO SET LAST_VALUE=${min_value},THIS_VALUE=${max_value} WHERE PROJECT='${PROJECT}' AND SCHEMA_NAME='${DB_NAME}' AND TABLE_NAME='${TABLE}'"
        		${MYSQL_EXEC} -Nse "${update_pri_sql}"
        		
            else 
        	    echo "The table ${TABLE} data unchanged from last-value"
            fi
        fi
        
        
        #获取错误原因
        if [[ ${status} == "FAILED" ]]; then
        
            error=$(cat ${V_SHELL_LOGS}/sqoop/${PROJECT}_${DB_NAME}.${TABLE}.log | grep -E "ERROR|error|failed|Caused by")
        	echo ${error}
        else 
            error=""
        fi
        
		#job执行结束时间
	    job_end=$(GET_CURTIME_STANDARD)
		
		#时长
		duration=$(DATETIME_DIF "${job_start}" "${job_end}")
		
        #把执行状态结果插入日志表 etl.collect_logs
        insert_log_sql="INSERT INTO etl.collect_logs (collect_type,state,project,db_name,table_name,db_user,sys_user,error,start_time,end_time,duration) VALUES ('incre','${status}','${PROJECT}','${DB_NAME}','${TABLE}','${USERNAME}','${USER}',\"${error}\",'${job_start}','${job_end}',${duration})"
        ${MYSQL_EXEC} -e "${insert_log_sql}"
		
		#删除自动生成的java文件(如果表名称是以数字0-9开头的，则生成的java文件前面加了"_")
        if [[ -f ${TABLE}.java ]];then
		    rm -rf ${TABLE}.java 
		else
            rm -rf _${TABLE}.java
		fi
		
		echo >&1001
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


