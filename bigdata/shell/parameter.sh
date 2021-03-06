#!/bin/sh
###############################################################################
##  Author    : sunxiaolong
##  Name      : parameter.sh
##  Functions : Initinal all variable and parameter
##  Purpose   : 
##  Revisions or Comments
##  VER        DATE        AUTHOR           DESCRIPTION
##---------  ----------  ---------------  ------------------------------------ 
##  1.0      2019-07-22  sunxiaolong        1. CREATED THIS SHELL.
###############################################################################


# etl database info
ETL_DB_TYPE=mysql
ETL_HOST=192.168.1.72
ETL_USER=hadoop
ETL_PASSWD=hadoop
ETL_PORT=3306

#mysql exec
MYSQL_EXEC="mysql -h${ETL_HOST} -P${ETL_PORT} -u${ETL_USER} -p${ETL_PASSWD}"

# shell dir path
V_HOME=/home/hadoop/dev
V_SHELL_HOME=${V_HOME}/shell
V_SHELL_PARM=${V_HOME}/parm
V_SHELL_PROC=${V_HOME}/proc
V_SHELL_SECU=${V_HOME}/secu
V_SHELL_LOGS=${V_HOME}/logs
V_SHELL_DATA=${V_HOME}/data
V_SHELL_DDL=${V_HOME}/ddl
V_SHELL_TEST=${V_HOME}/test
V_SHELL_TMP=${V_HOME}/tmp

# Script parameter
V_TIME_STAMP=$(date +%Y%m%d%H%M%S)
V_CURR_Y=$(date +%Y)
V_CURR_M=$(date +%m)
V_CURR_D=$(date +%d)

# Load data & parm file & same group
V_WAIT_TIME=10


# Execute shell
#V_REFRESH_P="${V_SHELL_HOME}/edw_parm_refresh.sh"
#V_RUN_PROCS="${V_SHELL_HOME}/edw_proc_launcher.sh"
#V_RUN_DB="${V_SHELL_HOME}/edw_db_executor.sh"
#V_RUN_HIVQL="${V_SHELL_HOME}/edw_hivql_executor.sh"
#V_EXPT_DATA="${V_SHELL_HOME}/edw_data_exporter.sh"
#V_IMPT_DATA="${V_SHELL_HOME}/edw_data_importer.sh"

# Export file delimiter
V_DELIMITER="\t"


# Create the folder if not exists
if [[ ! -d "${V_SHELL_PARM}" ]];then
    mkdir -p "${V_SHELL_PARM}"
fi

if [[ ! -d "${V_SHELL_PROC}" ]];then
    mkdir -p "${V_SHELL_PROC}"
fi

if [[ ! -d "${V_SHELL_DDL}" ]];then
    mkdir -p "${V_SHELL_DDL}"
fi

if [[ ! -d "${V_SHELL_SECU}" ]];then
    mkdir -p "${V_SHELL_SECU}"
fi

if [[ ! -d "${V_SHELL_LOGS}" ]];then
    mkdir -p "${V_SHELL_LOGS}"
fi

if [[ ! -d "${V_SHELL_TEST}" ]];then
    mkdir -p "${V_SHELL_TEST}"
fi

if [[ ! -d "${V_SHELL_TMP}" ]];then
    mkdir -p "${V_SHELL_TMP}"
fi
