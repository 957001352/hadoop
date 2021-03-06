#!/bin/sh
###############################################################################
##  Author    : sunxiaolong
##  Name      : func_utils.sh
##  Functions : Define all common function
##  Purpose   : 
##  Revisions or Comments
##  VER        DATE        AUTHOR           DESCRIPTION
##---------  ----------  ---------------  ------------------------------------ 
##  1.0      2019-07-18  sunxiaolong        1. CREATED THIS SHELL.   
###############################################################################


#获取当前时间
function NOW(){
    echo $(date +"%Y/%m/%d %H:%M:%S")
}

#当前标准时间格式 [YYYY-MM-DD HH:MM:SS]
function GET_CURTIME_STANDARD(){
    echo "$(date +"%F %T")"
}

#获取时间戳
function GET_STAMP_TIME(){
    if [ $# -eq 0 ]; then
        echo "[ERROR] Please check the parameters passed in!"
        echo "Sample: GET_STAMP_TIME [YYYY-MM-DD HH:MM:SS] OR [YYYY-MM-DD] OR [YYYYMMDD HH:MM:SS] OR [YYYYMMDD]"
	else 
	    echo "$(date -d "$1" +%s)"
	fi
}

#获取当前时间戳
function GET_CURTIME_STAMP(){
    echo "$(date +%s)"
}

# 计算时间差 (单位：s)
function DIF_TIME(){
    START_TIME="${1}"
    END_TIME="${2}"
    DIF_SECOND=$(($(date +%s -d "${END_TIME}")-$(date +%s -d "${START_TIME}")))
    echo ${DIF_SECOND}
 #   echo $(date "+%H:%M:%S" -d @$((${DIF_SECOND}-28800)))
}

# 计算时间差 (单位：s)
function DATETIME_DIF(){
    START_STAMP=$(GET_STAMP_TIME "${1}")
    END_STAMP=$(GET_STAMP_TIME "${2}")
	DIF_SECOND=$(expr ${END_STAMP} - ${START_STAMP})
    echo ${DIF_SECOND}
}

# BEGIN & END
function BEGIN(){
    echo -e "[Begin: $(date +%F) $(date +%T)]"
}

function END(){
    echo -e "[End: $(date +%F) $(date +%T)]"
}

# Log
function LOGGER(){
    echo -e "\n$(date +%F) $(date +%T) [${1}]: ${2}"
}



# If date
function IF_DATE(){
    if [[ -n "${1}" && $(expr length ${1}) -eq 8 ]];then
        cal ${1:6:2} ${1:4:2} ${1:0:4} >> /dev/null 2>&1
        if [[ $? -eq 0 || ${1:4:2} -eq 13 ]];then
            echo 0
        else
            echo 1
        fi
    else
        echo 1
    fi
}

# UPPER LOWER
function UPPER(){
    echo "$(echo ${1} | tr [:lower:] [:upper:])"
}

function LOWER(){
    echo "$(echo ${1} | tr [:upper:] [:lower:])"
}

# Day
function GET_CURR_DATE(){
    echo "$(date -d "${1}" +%Y%m%d)"
}
function GET_PREV_DATE(){
    echo "$(date -d "-1 days ${1}" +%Y%m%d)"
}
function GET_NEXT_DATE(){
    echo "$(date -d "1 days ${1}" +%Y%m%d)"
}
function GET_DAYS(){
    echo "$(date -d "${2} days ${1}" +%Y%m%d)"
}
function GET_LAST_YEAR_DATE(){
    echo "$(date -d "-12 months ${1}" +%Y%m%d)"
}



#判断返回值是否成功，失败默认返回exit 1，参数指定return则返回return 1.
function is_success()
{
    if [ $? -eq 0 ]; then
        echo -e "\033[1;32m[COMMAND SUCCESSED] `date "+%F %T"` \033[0m"
    else
        echo -e "\033[1;31m[COMMAND FAILED] `date "+%F %T"` \033[0m"
#        if [[ $1 == "return" ]];then
#            return 1
#        else
#            exit 1
#        fi
    fi
}

#判断返回值是否成功，失败返回return 1.
function is_success_return()
{
    is_success return
}


#获取jdbc_url
function get_jdbc_url()
{
    if [ $# -ne 4 ];then
        echo "[ERROR] Please check the number of parameters passed in!"
		echo "Sample: bash get_jdbc_url [DB_TYPE] [DB_HOST] [DB_PORT] [DB_SCHEMA]"
        exit 1
    else
	    DB_HOST=$2
	    DB_PORT=$3
	    DB_SCHEMA=$4
	fi
	
    if [[ $1 == "mysql" ]];then
	    echo "jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_SCHEMA}?characterEncoding=utf-8"
	elif [[ $1 == "oracle" ]];then
	    echo "jdbc:oracle:thin:@//${DB_HOST}:${DB_PORT}/orcl"
	elif [[ $1 == "db2" ]];then
	    echo "jdbc:db2://${DB_HOST}:${DB_PORT}/${DB_SCHEMA}"
	elif [[ $1 == "sqlserver" ]];then
	    echo "jdbc:sqlserver://${DB_HOST}:${DB_PORT};${DB_SCHEMA}"
    else
	    echo "[-] please check if exists the $1 database !"
        exit 2
    fi
}



#删除所有sqoop job
function delete_job_sqoop()
{
	sqoop_list=$(sqoop job --list)
	
	for job in ${sqoop_list}
	do
	    sqoop job --delete ${job}
		echo "[+] The ${job} sqoop job is deleted !!! "
    done
}

#删除指定项目的sqoop job
function delete_job_sqoop_project()
{   
    if [[ -z ${1} ]];then
	    echo "[ERROR] Please check the project name of parameters passed in!"
		echo "Sample: delete_job_sqoop_project [project] !"
		exit 1
	fi
	
    project=${1}
	sqoop_list=$(sqoop job --list | grep ${project})
	
	for job in ${sqoop_list}
	do
        sqoop job --delete ${job}
        echo "[+] The ${job} sqoop job is deleted !!! "
    done
}

