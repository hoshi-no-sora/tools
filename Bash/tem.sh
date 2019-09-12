#!/bin/bash
#
# For logging of vmstat
##################################################

#==========================#
#----- [ Initialize ] -----#
unset DEFAULT_EXENUM
#==========================#

#==========================#
#------ [ Settings ] ------#
DEFAULT_EXENUM=10
#==========================#

##################################################
set -e -o pipefail -o noclobber -o ignoreeof

# =========================================
# ====== [ definitiion of function ] ======
# =========================================

# [ definition of help message format ]
function printUsage() {
cat << EOF
=========================== [ USAGE ] ===========================
objective: logging of vmstat result
format   : vmstat.sh [PATH to logfile] [execution frequency]

--------------------
first  argument: logfile PATH
second argument: execution frequency (: processing repeat number)
                 (*** permit only natural number)
=========================== [ USAGE ] ===========================

EOF
}

# [ display help when no argument or '--help' ] 
#   (usage) ARGNUM=$#; helpInstruction [arg num] [first arg]
function helpInstruction() {
  local argnum=$1
  local arg1=$2
  # --- [ Help ] --- show USAGE
  if [ "${argnum}" -eq 0 ] \
  || [ "${argnum}" == 1 -a "${arg1}" = '--help' ]; then
  	printUsage; exit
  fi
}

#------------------------------------------

# [ check the number of argument ]
#   (usage) chkArgNum [ideal number] [argument number]
function chkArgNum() {
  local idealnum=$1  # In this time, idealnum is expected to be "2". 
  local argnum=$2
  unset CHKSTATUS
  # --- [ each argument number case ] ---
  case ${argnum} in
  "1")
      CHKSTATUS="firstargonly"
    ;;
  "${idealnum}")
      CHKSTATUS="completed"
    ;;
  *)
  	echo "$2 Arguments Now !" 
    echo -e "The number of Argument must be less than ${idealnum} ...\n"
  	exit
    ;;
  esac
}

# [ check first argument and confirmation of exsistence of file path ]
#   (usage) check_arg1 [file PATH]
function check_arg1() {
  local arg1=$1
  if [ ! -d $(dirname ${arg1}) ]; then echo "ERROR: No such directory"; exit; fi
  if [ ! -e ${arg1} ]; then
      echo -e "ERROR: No such file PATH"
      echo -e "first argument must be PATH format (strings)\n"; exit
  fi
}


# [ check second argument ]
#   (usage) check_arg2 [second argument]
function check_arg2() {
  if   [ "${CHKSTATUS}" = "firstargonly" ]; then
    echo "No second argument(execution frequency: processing repeat number)"
    CHK2=${DEFAULT_EXENUM}
  elif [ "${CHKSTATUS}" = "completed" ]; then
    local naturalnum="[0-9]*$" 
    # ===========================
    # [0-9]: 0~9の数字のいずれかの文字
    # *: 直前の文字列を0回以上の繰り返し
    # $: 文字列終了
    # ===========================
    if expr $1 : ${naturalnum} >& /dev/null; then   # check whether second arg is number or not (permit only number)
       echo "Info: second argument is Number"
    else
       echo "ERROR: second argument is Not number..."; exit 
    fi
  fi
}

#------------------------------------------

function set_EXENUM() {
  if [ "${CHKSTATUS}" = "firstargonly" ]; then
    echo "Set value 10 (default)"
    unset EXENUM
    EXENUM=${DEFAULT_EXENUM}
  elif [ "${CHKSTATUS}" = "completed" ]; then
  	echo $CHK2
  	EXENUM=${CHK2}
  else
  	echo "CANNNOT deal with such operation"; exit
  fi
}

# =========================================
# ====== [ definitiion of function ] ======
# =========================================

# =========================================
# ========= [ check of arguments] =========
# =========================================

unset ARGNUM CHK1 CHK2
ARGNUM=$#; CHK1=$1; CHK2=$2

# display help when no argument or '--help'
helpInstruction ${ARGNUM} ${CHK1}

# checking the numner of arguments
chkArgNum 2 ${ARGNUM}

# checkng FilePATH
check_arg1 ${CHK1}

# checking EXENUM
check_arg2 ${CHK2}

# definition of FilePATH
FilePATH=${CHK1}

# definition of EXENUM
set_EXENUM

# =========================================
# ========= [ check of arguments] =========
# =========================================

##################################################
LOG="tee -a ${FilePATH}"

#echo "EXENUM is $EXENUM"

if [ ! -f ${FilePATH} ]; then touch ${FilePATH}; fi
date | ${LOG}
vmstat | ${LOG}


unset ARGNUM CHK1 CHK2
unset EXENUM CHKSTATUS
exit


##################################################

