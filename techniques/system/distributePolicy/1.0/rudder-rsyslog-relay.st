#####################################################################################
# Copyright 2011 Normation SAS
#####################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, Version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################

# Rsyslog Rudder configuration

# Disable Repeated message reduction or reports may be lost
$RepeatedMsgReduction off

# Provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun &SYSLOGPORT&

# Provide udp for snare and compatibility with older syslog
$ModLoad imudp
$UDPServerRun &SYSLOGPORT&

# for Snare client
$EscapeControlCharactersOnReceive off

&if(STORE_ALL_CENTRALIZED_LOGS_IN_FILE)&
# Log everything
local6.* /var/log/rudder/reports/all.log
&endif&


# Direct to DB
$ActionQueueType Direct
$ActionQueueSaveOnShutdown on

# Filtering by content
# Process :
# We first forward the data to the root server, then we drop it to prevent
# it from reaching local storage in .log files.
# The report format is @@Policy@@State@@RuleId@@DirectiveId@@VersionId@@Component@@Key@@ExecutionTimeStamp##NodeId@#HumanReadableMessage
#

# 1 - Send every matching report to the root server
:msg, ereregex, "(R: )?@@[ a-zA-Z0-9_\-]+?@@[a-zA-Z0-9_\-]{1,64}?@@[a-zA-Z0-9\-]+@@[a-zA-Z0-9\-]+?@@[0-9]+?@@.*?@@.*?@@[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{1,2}:[0-9]{2}##[a-zA-Z0-9\-]+?@#.*" ${check_log_system.rsyslog_rule_prefix}${server_info.cfserved}:&SYSLOGPORT&

# 2 - Drop the remaining rudder logs to prevent local storage cluttering

## Syslog messages from "rudder"
:programname, contains, "rudder" ~
:programname, contains, "cf-agent" ~

## Syslog messages from "rudder" forwarded from AIX
:msg, ereregex, "from .*: rudder" ~
:msg, ereregex, "from .*: cf-agent" ~

