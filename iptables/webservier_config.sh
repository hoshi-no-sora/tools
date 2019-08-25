#!/bin/bash
#############################
######## [ Setting ] ########
#############################
client='192.168.2.30'
webserver='192.168.2.11'
any='0.0.0.0/0'


#ssh_port=22
#http_port=80
#https_port=443
vncbegin=59001
vncend=59001
#############################
######## [ Setting ] ########
#############################
IPTCONF_PARENTDIR="/etc/sysconfig"
# SERVICE_COMMAND="rc-service"
SERVICE_COMMAND="service"


# setting for iptables_usage
PARENTDIR="${HOME}/Tools/iptables"
SUBDIR="${PARENTDIR}/sub"
#################################################
# function

function _initialize_() 
{
    iptables --flush # initialize tables
    iptables -X      # delete chains
    iptables -Z      # clear the packet counter nad byte counter
    iptables -P INPUT   ACCEPT
    iptables -P OUTPUT  ACCEPT
    iptables -P FORWARD ACCEPT
}

function _ipt_save_() {
  iptables -v --line-number --list
  #iptables -vn --line-number --list
  echo -e "\n"
  echo -n "Do you want to save these configuration?[yes/no]: "
  local answer
  read answer
  if [ "${answer}" = "yes" ]; then
    /sbin/iptables-save
  else
    echo -e "These configuration was NOT reflected... \n"
  fi
}

function _ssh_filtering_() {
  # ============= SSH connection fitering =============
  # 攻撃者のSSH接続パケットは60秒間破棄
  iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --rcheck --seconds 60 --name Attacker -j DROP
  
  iptables -N AttackerPolicy
  iptables -A AttackerPolicy -m recent --set --name Attacker  -j LOG --log-level warn --log-prefix '[Attack]:'
  iptables -A AttackerPolicy -j DROP
  
  # SSH filtering(60秒間以内に5回の接続 => Attacker)
  iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH
  iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --rcheck --seconds 60 --hitcount 5 --rttl --name SSH -j AttackerPolicy
  # ============= SSH connection fitering =============
}

function _vnc_accept_() {
  iptables -A INPUT -m state –state NEW -m tcp -p tcp –dport $1 -j ACCEPT
  iptables -A INPUT -m state –state NEW -m udp -p udp –dport $1 -j ACCEPT 
}

function _ipt_restart_() {
  "${SERVICE_COMMAND}" iptables restart
}

# function _finailize_()
# {
#     /etc/init.d/iptables save &&
#     /etc/init.d/iptables restart &&
#     return 0
# }
#################################################

source "${SUBDIR}/iptables_usage"
#_m_option_
#_default_setting_show_

if [ -z /etc/iptables.save.old ]; then
  cp -i "${IPTCONF_PARENTDIR}/iptables.save" "${IPTCONF_PARENTDIR}/iptables.save.old"
fi

#################################################
################### [ Begin ] ###################
#################################################
ipt=$(type -p iptables)

# %%%%%%%%%%%%%%%%%% ~ Step.1 ~ %%%%%%%%%%%%%%%%%%
# ========= Flush and Reset ========= #
#"$ipt" --flush
#"$ipt" -X
_initialize_
# ========= Flush and Reset ========= #

# ============= Policy ============= #
"$ipt" -P INPUT   DROP
"$ipt" -P OUTPUT  ACCEPT
"$ipt" -P FORWARD DROP
# ============= Policy ============= #


# %%%%%%%%%%%%%%%%%% ~ Step.2 ~ %%%%%%%%%%%%%%%%%%

# ================< icmp-type >================ 
# [number] => [meaning]               | [type] 
# ---------------------------------------------
#    0     => echo-reply              | Query
#    3     => Destination Unreachable | Error
#    8     => echo-request            | Query
#   11     => Time Exceeded           | Error
#   12     => Parameter Problem       | Error
# ================< icmp-type >================ 

# ============ logging ============ #
"$ipt" -N LOGGING
"$ipt" -A LOGGING -j LOG --log-level warning --log-prefix "DROP:" -m limit
"$ipt" -A LOGGING -j DROP
"$ipt" -A INPUT   -j LOGGING
"$ipt" -A OUTPUT  -j LOGGING
# ============ logging ============ #

# ===============================================
# ============== [ INPUT Chain ] ================
# ===============================================

# ============== TCP ============== #
"$ipt" -A INPUT  -p tcp ! --syn -m state --state NEW -j DROP

# ============ loopback ============ #
"$ipt" -A INPUT  -i lo -j ACCEPT

# ============= ICMP =============== #
# Error message signal
"$ipt" -A INPUT  -p icmp --icmp-type  3 -j ACCEPT
"$ipt" -A INPUT  -p icmp --icmp-type 11 -j ACCEPT
"$ipt" -A INPUT  -p icmp --icmp-type 12 -j ACCEPT
# ===========================
# [ client -> webserver ]
"$ipt" -A INPUT  -p icmp --icmp-type echo-request -s $client -d $webserver -j ACCEPT
# [ webserver -> client ]
"$ipt" -A INPUT  -p icmp --icmp-type echo-reply   -s $client -d $webserver -j ACCEPT

# ============== ssh =============== #
# ssh filtering (against SSH Brute Force Attack)
_ssh_filtering_
# [ client -> webserver ]
"$ipt" -A INPUT  -p tcp -m state --state NEW,ESTABLISHED,RELATED -s $client -d $webserver --dport 22 -j ACCEPT

# ========= http and https ========= #
# [ ANY -> webserver ]
"$ipt" -A INPUT  -p tcp -m state --state NEW,ESTABLISHED,RELATED -s $any    -d $webserver --dport 80 -j ACCEPT

# === ALL with ESTABLISHED,RELATED ==#
# ESTABLISHED,RELATED connection(ssh, http以外の通信が既に確立されたパケットに関しても許可)
# (syn flugが立ったパケットに関したは、NEWでないpacketのみ通過してきている)
"$ipt" -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# ============= VNC ===============
for portnum in $(seq ${vncbegin} ${vncend})
do
  _vnc_accept_ ${portnum}
done

# =========== TCP Reject =========== #
# 113 => Ident, authentication service/identification protocol, used by IRC servers to identify users
"$ipt" -A INPUT  -p tcp   --syn --dport 113 -j REJECT --reject-with tcp-reset

# ===============================================
# ============== [ INPUT Chain ] ================
# ===============================================
#
#
#
# ===============================================
# ============== [ OUTPUT Chain ] ===============
# ===============================================

# ============ loopback ============ #
"$ipt" -A OUTPUT -o lo -j ACCEPT

# ============= ICMP =============== #
# [ client -> webserver ]
"$ipt" -A OUTPUT -p icmp --icmp-type echo-reply   -s $webserver -d $client -j ACCEPT
# [ webserver -> client ]
"$ipt" -A OUTPUT -p icmp --icmp-type echo-request -s $webserver -d $client -j ACCEPT

# ============== ssh =============== #
# [ client -> webserver ]
"$ipt" -A OUTPUT -p tcp -s $webserver --sport 22 -d $client -j ACCEPT

# ========= http and https ========= #
# [ ANY -> webserver ]
"$ipt" -A OUTPUT -p tcp -s $webserver --sport 80 -d $any    -j ACCEPT

# ===============================================
# ============== [ OUTPUT Chain ] ===============
# ===============================================
#
#
#
# ===============================================
# ============== [ FORWARD Chain ] ==============
# ===============================================

# ===============================================
# ============== [ FORWARD Chain ] ==============
# ===============================================

##################################################
#################### [ End ] #####################
##################################################

# confirmation and save this configuration
_ipt_save_
# iptables service restart
_ipt_restart_

exit


