#!/bin/sh
###############################################################################
##  Author        : sunxiaolong
##  Name          : db_executor.sh
##  Functions     : SQL执行器:目前仅支持mysql、db2
##                  (1) 传入一段sql返回查询结果
##					(2) 传入一个sql文件，执行sql文件
##					(3) 传入一段sql，导出查询结果到文件
##  description   : 需要出入的参数：(1)数据库类型 (2)地址 (3)端口 (4)用户名 (5)密码 (6)sql文件或sql语句
##  Purpose       : Construct the interface of mysql
##  Revisions or Comments
##  VER        DATE        AUTHOR           DESCRIPTION
##---------  ----------  ---------------  ------------------------------------ 
##  1.0      2019-07-19  sunxiaolong        1. UPDATE THIS SHELL.
###############################################################################

. `dirname ${0}`/func_utils.sh

function USAGE(){
    echo "[ERROR]How to use this shell script!"
    echo "db_executor.sh -t [DB_TYPE] -h [DB_HOST] -P [DB_PORT] -n [USERNAME] -p [PASSWD] -q \"[SQL_SCRIPT]\""
	echo "db_executor.sh -t [DB_TYPE] -h [DB_HOST] -P [DB_PORT] -n [USERNAME] -p [PASSWD] -x \"[SQL_SCRIPT]\""
	echo "db_executor.sh -t [DB_TYPE] -h [DB_HOST] -P [DB_PORT] -n [USERNAME] -p [PASSWD] -f /home/hadoop/sample.sql"
    echo "[sample]:bash db_executor.sh -t mysql -h hadoop01 -P 3306 -n hadoop -p hadoop -q \"SELECT NOW() FROM DUAL\""
}

# define basic parm
#V_DB_USER=$(base64 -di ${V_DB_USER})
#V_DB_PSWD=$(base64 -di ${V_DB_PSWD})

# run sql statement
function RUNSQL(){
  if [ "${V_DB_TYPE}"x == "mysql"x ]; then
    mysql -h${V_DB_HOST} -P${V_DB_PORT} -u${V_DB_USER} -p${V_DB_PSWD} -Nse "${1}"

    SQLCODE=$?
    if [[ ${SQLCODE} -ne 0 ]]; then
      LOGGER "ERROR" "SQL执行失败！"
      LOGGER "DEBUG" "SQL=${1}"
      exit ${SQLCODE}
    fi
  elif [ "${V_DB_TYPE}"x == "db2"x ]; then
    db2 connect to ${V_DB_HOST} user ${V_DB_USER} using ${V_DB_PSWD} >/dev/null
    SQLCODE=$?
    if [[ ${SQLCODE} -ne 0 ]]; then
      LOGGER "ERROR" "db2连接失败"
      LOGGER "DEBUG" "db2 connect to ${V_DB_HOST} user ${V_DB_USER} using ${V_DB_PSWD}"
      exit ${SQLCODE}
    fi
    RESULT=$(db2 -x "${1}") 
    SQLCODE=$?
    if [[ ${SQLCODE} -eq 1 || ${SQLCODE} -eq 2  ]]; then
      exit 0
    elif [[ ${SQLCODE} -eq 0 ]];then
      echo ${RESULT}
      exit ${SQLCODE}
    else
      LOGGER "ERROR" "SQL执行失败！"
      LOGGER "DEBUG" "SQL=${1}"
      exit ${SQLCODE}
    fi
  fi
}

# run a sql file
function RUNFILE(){
  if [ "${V_DB_TYPE}"x == "mysql"x ]; then
    mysql -h${V_DB_HOST} -P${V_DB_PORT} -u${V_DB_USER} -p${V_DB_PSWD} -vv < ${1}
    SQLCODE=$?
    if [[ ${SQLCODE} -ne 0 ]]; then
      LOGGER "ERROR" "SQL执行失败！"
      LOGGER "DEBUG" "SQL=${1}"
      exit ${SQLCODE}
    fi
  elif [ "${V_DB_TYPE}"x == "db2"x ]; then
    db2 connect to ${V_DB_HOST} user ${V_DB_USER} using ${V_DB_PSWD} >/dev/null
    SQLCODE=$?
    if [[ ${SQLCODE} -ne 0 ]]; then
      LOGGER "ERROR" "db2连接失败"
      LOGGER "DEBUG" "db2 connect to ${V_DB_HOST} user ${V_DB_USER} using ${V_DB_PSWD}"
      exit ${SQLCODE}
    fi
    db2 -xstf ${1}
    SQLCODE=$?
    if [[ ${SQLCODE} -ne 0 ]]; then
      LOGGER "ERROR" "SQL执行失败！"
      LOGGER "DEBUG" "SQL=${1}"
      exit ${SQLCODE}
    fi
  fi
}

# export data
function EXPDATA(){
  if [ "${V_DB_TYPE}"x == "mysql"x ]; then
    mysql -s -h${V_DB_HOST} -P${V_DB_PORT} -u${V_DB_USER} -p${V_DB_PSWD} -e "${V_EXP_DATA}" 
    SQLCODE=$?
    if [[ ${SQLCODE} -ne 0 ]]; then
      LOGGER "ERROR" "SQL执行失败！"
      LOGGER "DEBUG" "SQL=${1}"
      exit ${SQLCODE}
    fi
  elif [ "${V_DB_TYPE}"x == "db2"x ]; then
    db2 connect to ${V_DB_HOST} user ${V_DB_USER} using ${V_DB_PSWD} >/dev/null
    SQLCODE=$?
    if [[ ${SQLCODE} -ne 0 ]]; then
      LOGGER "ERROR" "db2连接失败"
      LOGGER "DEBUG" "db2 connect to ${V_DB_HOST} user ${V_DB_USER} using ${V_DB_PSWD}"
      exit ${SQLCODE}
    fi
    RESULT=$(db2 -x "${V_EXP_DATA}")
    SQLCODE=$?
    if [[ ${SQLCODE} -eq 1 || ${SQLCODE} -eq 2 ]]; then
      exit 0
    elif [[ ${SQLCODE} -eq 0 ]];then
      echo ${RESULT}
      exit ${SQLCODE}
    else
      LOGGER "ERROR" "SQL执行失败！"
      LOGGER "DEBUG" "SQL=${V_EXP_DATA}"
      exit ${SQLCODE}
    fi
  fi
}

# get the parameter
while getopts :n:p:h:P:q:x:f:t: args; do
    case ${args} in
        n)
            V_DB_USER=${OPTARG}
        ;;
        p)
            V_DB_PSWD=${OPTARG}
        ;;
        h)
            V_DB_HOST=${OPTARG}
        ;;
        P)
            V_DB_PORT=${OPTARG}
        ;;
        q)
            V_SQL_QUERY=${OPTARG}
        ;;
        x)
            V_EXP_DATA=${OPTARG}
        ;;
        f)
            V_SQL_FILE=${OPTARG}
        ;;
        t)
            V_DB_TYPE=${OPTARG}
        ;;
        ?)
            USAGE
        ;;
    esac
done


#echo "V_DB_USER:${V_DB_USER}"
#echo "V_DB_PSWD:${V_DB_PSWD}"
#echo "V_DB_HOST:${V_DB_HOST}"
#echo "V_DB_PORT:${V_DB_PORT}"
#echo "V_DB_TYPE:${V_DB_TYPE}"
#echo "V_SQL_QUERY:${V_SQL_QUERY}"



# ensure the basic variavle of connection is not null
if [[ -z ${V_DB_USER} || -z ${V_DB_PSWD} || -z ${V_DB_HOST} || -z ${V_DB_PORT} || -z ${V_DB_TYPE} ]];then
    USAGE
    exit 3
fi


# switch case
if [[ -f ${V_SQL_FILE} ]];then
    RUNFILE ${V_SQL_FILE}
elif [[ -n ${V_SQL_QUERY} ]];then
    RUNSQL "${V_SQL_QUERY}"
elif [[ -n ${V_EXP_DATA} ]];then
    EXPDATA
else
    USAGE
fi
