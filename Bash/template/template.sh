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
# Not Set "LOGFILE" variable => ${HOME}/program.log
# 
#===============================================

#==============================================#
#=== [ Variable and Defalut Value Setting ] ===#
#==============================================#
LOGDIR=

#==============================================#
#=== [ Variable and Defalut Value Setting ] ===#
#==============================================#

######################################################

#===============================================
#========== [ Environmental Setting ] ==========
#===============================================
# set -e -o pipefail -o noclobber -o ignoreeof
set -e -E -o pipefail -o noclobber -o ignoreeof
export MYTOOLDIR="${HOME}/TOOLS/Bash"
source "${MYTOOLDIR}/share/error_func"
source "${MYTOOLDIR}/share/share_func"
source "${MYTOOLDIR}/share/debug_func"
source "${MYTOOLDIR}/share/coloring_func"
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

function () {
    
}

# function (){
# 
# }

#===============================================
#========= [ Definition of function ] =========#
#===============================================

######################################################
trap 'echo "ERROR: line no = $LINENO, exit status = $?" >&2; exit 1' ERR
# trap "cleanup ${file1} ${file2}" EXIT


# [ processing or display help ]
argument_check $(basename $0)   # inside share_func 


[ -z  ] || error ""
[ -d  ] || abort "no such directory"


exit
######################################################
#
#

