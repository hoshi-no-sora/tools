#!/bin/bash
#
#===============================================
# [ Explanation ]
# 
# objective: ---
#           
# format: bash .sh [arg1] [arg2]
# arg1: [explaination of arg1]
#       "nothing" : display help
#       --help    : display help
#       --status  : display ps status
#
# arg2: [explaination of arg2]
# 
#
# [ ※※※ Caution ※※※ ]
# 
#
# [ Info ]
#
# Not Set "ERRLOGFILE" variable => ${HOME}/error.log
# 
#===============================================

#==============================================#
#=== [ Variable and Defalut Value Setting ] ===#
#==============================================#
LOGDIR="/job/infra/log"
LOGFILENAME="proc.log"
LOGFILE="${LOGDIR}/${LOGFILENAME}"
ERRLOGFILENAME="error.log"
ERRLOGFILE="${LOGDIR}/${ERRLOGFILENAME}"
#----------
interval_sec=10
tail_scriptname="sleep.sh"
INC_PROC_STATUSFILE="/tmp/inc_proc_status"
NOTINC_PROC_STATUSFILE="/tmp/notinc_proc_status"
BGPID_FILE="/tmp/proc_pid"
#==============================================#
#=== [ Variable and Defalut Value Setting ] ===#
#==============================================#

######################################################

#===============================================
#========== [ Environmental Setting ] ==========
#===============================================
set -e -o pipefail -o noclobber -o ignoreeof
export MYTOOLDIR="${HOME}/TOOLS/Bash"
source "${MYTOOLDIR}/share/error_func"
source "${MYTOOLDIR}/share/share_func"
source "${MYTOOLDIR}/share/debug_func"
source "${MYTOOLDIR}/share/coloring_setting"
#===============================================
#========== [ Environmental Setting ] ==========
#===============================================

#===============================================
#========= [ Definition of function ] =========#
#=============================================== 

# [ definition of help message format ]
function help() {
cat << EOF
=========================== [ USAGE ] ===========================
objective: "[purpose of script]"
format   : $(basename $0) [arg1] [arg2]
--------------------
arg1: "[arg1 explanation]"
arg2: "[arg2 explanation]"
=========================== [ USAGE ] ===========================
EOF
}

# [ Get Status Code ]
# -------------------------------------
# [USAGE] get_status_code ${PARENTPID}
# -------------------------------------
get_status_code() {

    # ---- [ tailed script ] ----
    local tailed_pid=$(ps -ef | pgrep ${tail_scriptname})
    if [ -z ${tailed_pid} ]; then
        tailed_status=1
    else
        tailed_status=0
    fi
    # ---------------------------
    
    #--- [ proc.sh  process ] ---
    PARENTPID=${1}
    \rm -f ${INC_PROC_STATUSFILE} ${NOTINC_PROC_STATUSFILE} 2> /dev/null
    
    # include proc.sh pid of this time
    ps aux --forest | grep "proc.sh" | grep -v grep > ${INC_PROC_STATUSFILE}
    # Not include proc.sh pid of this time
    awk -v id=${PARENTPID} '$2 != id { print $0 }' ${INC_PROC_STATUSFILE} \
     > ${NOTINC_PROC_STATUSFILE}
    
    if [ -s ${NOTINC_PROC_STATUSFILE} ]; then
        proc_status=0
    else
        proc_status=1
    fi
    # ---------------------------

}

function status_print() {

    local tailed_status_msg
    local proc_status_msg
    
    if [ ${tailed_status} -eq 0 ]; then
        tailed_status_msg="running"
    else
        tailed_status_msg="Notrunning"
    fi
    
    if [ ${proc_status} -eq 0 ]; then
        proc_status_msg="running"
        ps_pid_msg="(PSD:$(cat ${BGPID_FILE}))"
    else
        proc_status_msg="Not running"
        ps_pid_msg=
    fi


    echo "============================================="
    echo "[${tail_scriptname}]: ${tailed_status_msg}"
    echo "[proc.sh(background)]: ${proc_status_msg} ${ps_pid_msg}"
    echo "============================================="
    echo ""
}

# check of exsistence of proc.sh process
function ps_existence_check(){
    if [ -s ${NOTINC_PROC_STATUSFILE} ]; then
          echo -e "process(ps/$(basename $0)) is already exist\n"; exit
    fi
}

# [ Initialize ]
function Initialize() {
    [ -f ${LOGFILE} ] && error "LOGFILE already exist!!!" \
    && echo "Remove Logfile: ${LOGFILE}" \
    && confirmation "\rm ${LOGFILE}"
    touch ${LOGFILE}
}

# 
function proc_tail() {
    while : ; do
        ps -ef | grep "${tail_scriptname}" >> ${LOGFILE}
        sleep ${interval_sec}
    done
}

#===============================================
#========= [ Definition of function ] =========#
#===============================================

######################################################

# [ processing or display help ]
# argument_check $(basename $0)   # inside share_func 

PARENTPID=$$
export PARENTPID
#echo ${PARENTPID}
trap "last" {1,2,3,15}

case $1 in
"-start" )
          get_status_code ${PARENTPID}
          status_print
          ps_existence_check ${PARENTPID}   # proc.sh is already runninng?
          Initialize
          echo "Logging start ..."
          confirmation ":" 
          proc_tail &                       # watching sleep.sh used by proc.sh
          # unset PS_PID; PS_PID=$!
          \rm -f ${BGPID_FILE}; echo $! > ${BGPID_FILE}
          ;;

"-stop"  )
          get_status_code ${PARENTPID}
          status_print

          PS_PID=$(awk 'NR==1' ${BGPID_FILE})
          [ -z "${PS_PID}" ] && abort "No process for stopping"  # if PS_PID is empty

          echo "Process Kill: (PID:${PS_PID})"
          confirmation "kill ${PS_PID}"

          sed -i -e "s@${PS_PID}@@" ${BGPID_FILE}
          ;;

"-status")
          get_status_code ${PARENTPID}
          status_print
          ;;

"--help"|"")
          help; exit
          ;;

        *)
          echo -e "ERROR: cannot use option except for \"-start\", \"-stop\", \"-status\", \"--help\"\n"
          help
          exit 1
          ;;
esac


# [ -z  ] || error ""
# [ -d  ] || abort "no such directory"


exit
######################################################
#
#

