### APMaaS_param.sh - Begin ###
myName=APMaaS

#set -euo pipefail
set -u

separator='|'
separator_II='|'

# Source global variables and functions
#################################
# Do not touch below this line! #
#################################
TRUE=${TRUE:-0}
FALSE=${FALSE:-1}
DEBUG=${DEBUG:-${FALSE}}
DAY_IN_SECONDS=86400 # 24*60*60

homeDir="${HOME}/dynaTraceArd" # set in param_local.sh

configDir="${homeDir}/config"
tmpDir="${homeDir}/tmp"
binDir="${homeDir}/bin"
dataDir="${homeDir}/data"
htmlDir="${homeDir}/html"
logDir="${homeDir}/log"
reportDir="${homeDir}/report"

# Source local parameters
. "${binDir}"/ZAPMaaS_param_local.sh || { echo "Failed to source ZAPMaaS_param_local.sh, exiting..."; exit ${FALSE}; }


LOGIN_ACCOUNT_DIRECTORY="${configDir}/login/loginAccountName"
ACCOUNT_DIRECTORY="${configDir}/Account"
PLM_AGENTS="${configDir}/PLM/${myName}.plmAgents.cfg"

PASSWD_COMPUWARE="${configDir}/Login/.passwd_compuware"

# Proxy details - Begin #
PASSWD_PROXY="${configDir}/Login/.passwd_proxy"
PROXY_IP_PORT="${configDir}/Login/.proxy_ip_port"
domain=`cat "${PASSWD_PROXY}" | cut -d"${separator_II}" -f1`
login=`cat "${PASSWD_PROXY}" | cut -d"${separator_II}" -f2`
passwd=`cat "${PASSWD_PROXY}" | cut -d"${separator_II}" -f3`
proxy_ip=`cat "${PROXY_IP_PORT}" | cut -d"${separator_II}" -f1`
proxy_port=`cat "${PROXY_IP_PORT}" | cut -d"${separator_II}" -f2`
if [ "%${proxy_ip}%" = "%%" ]
then
   proxy=""
else
   proxy="-x ${proxy_ip}:${proxy_port} -U ${login}:${passwd}"
fi
export http_proxy="${proxy}"
export HTTP_PROXY="${proxy}"
# Proxy details - End #

ERROR_MAX_NUMBER_OF_CONCURRENT_SESSIONS_EXCEEDED=2 # This is the error number to indicate WebService is saturated and we need to wait
APMaaS_CHECK_ABSOLUTE_NAME="${dataDir}/APMaaSCheck.data" # Contains the last monitoring data for all accounts, tests and locations
BB_PLM="UTATX PRIVATEPEER" # Backbone and PrivateLastMile test types listed in $APMaaS_CHECK_ABSOLUTE_NAME

declare -A MATRIX # Stores one account details per row with following information (check $MATRIX_HEADER)
declare -a MATRIX_HEADER=('login' 'accountId' 'accountName' 'testsLocations' 'ok' 'failed' 'missingData' 'backBone' 'lastMile' 'privateLastMile');
MATRIX_ROWS=$(($(cat "${PASSWD_COMPUWARE}" | wc -l)-1)) # NUMBER_OF_CHILD_ACCOUNTS; -1 is because array starts from zero
MATRIX_COLS=$((${#MATRIX_HEADER[@]}-1)) # -1 is because array starts from zero

# Source functions
. "${binDir}"/ZAPMaaS_genericFunctions.sh || { echo "Failed to source genericFunctions.sh, exiting..."; exit ${FALSE}; }
. "${binDir}"/ZAPMaaS_dateFunctions.sh || { echo "Failed to source dateFunctions.sh, exiting..."; exit ${FALSE} ; }
dateTime="$(dt)"
. "${binDir}"/ZAPMaaS_htmlFunctions.sh || { echo "Failed to source htmlFunctions.sh, exiting..."; exit ${FALSE} ; }

# Calculate current daylight Time Offset from UTC taking into account summer time too, in seconds
TIMEZONE_OFFSET=$(dtGetTimeZoneOffset)

### Functions ###
init ()
{
local _func=${_program:-BASH}.init
if [ ${#} -ne 1 ]
then
      cat << EOF

Run as:
${_func} login

This function initiates directory structure for login.

EOF
   return ${FALSE}
fi

#
# Make sure all directories are there
#
mkdir -p "${configDir}"/Login
mkdir -p "${configDir}"/PLM/Email
mkdir -p "${configDir}"/Charts
mkdir -p "${LOGIN_ACCOUNT_DIRECTORY}"
mkdir -p "${tmpDir}"
mkdir -p "${dataDir}"
mkdir -p "${htmlDir}"
mkdir -p "${logDir}"
mkdir -p "${reportDir}"

local _login="$1"
getAccountIdNameFromLogin "${_login}" _accountId _accountName
   
mkdir -p "${ACCOUNT_DIRECTORY}"/"${_accountName}"/mid
MATRIX_init
}

getLoginFromAccountId ()
{
   local _accountId=${1:-accountId}
   awk -F"${separator_II}" '$2 == "'"${_accountId}"'" {print $1}' "${LOGIN_ACCOUNT_DIRECTORY}"/*.accountName.cfg | head -n1
}
getPasswordForLogin ()
{
   local _login=${1:-login}
   awk -F"${separator_II}" '$1 == "'"${_login}"'" {print $2}' "${PASSWD_COMPUWARE}" 
}
getAccountIdForLogin ()
{
   local _func=${_program:-BASH}.getAccountIdForLogin
   local _login=${1:-login}
   local _loginAccountFile=$(getLoginAccountAbsoluteName "${_login}")
   if [ -s "${_loginAccountFile}" ]
   then
      awk -F"${separator_II}" '$1 == "'"${_login}"'" {print $2; exit}' "${_loginAccountFile}" | head -n1 2>/dev/null
   else
      return ${FALSE}
   fi
}
getAccountNameForLogin ()
{
   local _func=${_program:-BASH}.getAccountNameForLogin
   local _login=${1:-login}
   local _loginAccountFile=$(getLoginAccountAbsoluteName "${_login}")
   if [ -s "${_loginAccountFile}" ]
   then
      awk -F"${separator_II}" '$1 == "'"${_login}"'" {print $3; exit}' "${_loginAccountFile}" | head -n1 2>/dev/null
   else
      return ${FALSE}
   fi
}

getAccountMidThresholdsAbsoluteName ()
{
   local _accountName=${1:-accountName}
   echo "${ACCOUNT_DIRECTORY}/${_accountName}/${_accountName}.mid.threshold.cfg"
}

getAPMaaSCheckAbsoluteName ()
{
   local _accountName=${1:-accountName}
   echo "${dataDir}/${_accountName}.APMaaSCheck.data"
}
getAPMaaSCheckAbsoluteNameTmp ()
{
   local _accountName=${1:-accountName}
   echo "${tmpDir}/"$(getTmpName "APMaaSCheck" "${_accountName}").tmp
}
getAPMaaSCheckSummaryAbsoluteName ()
{
   local _accountName=${1:-accountName}
   echo "${dataDir}/${_accountName}.APMaaSCheckSummary.data"
}

getHtmlTestStatusAbsoluteName ()
{
   local _accountName=${1:-accountName}
   echo "${htmlDir}/${_accountName}.testStatus.html"
}
getHtmlTestStatusAbsoluteNameTmp ()
{
   local _accountName=${1:-accountName}
   echo "${tmpDir}/"$(getTmpName "HTML_TEST_STATUS_" "${_accountName}").tmp
}

getLoginAccountAbsoluteName ()
{
   local _login=${1:-login}
   echo "${LOGIN_ACCOUNT_DIRECTORY}/${_login}.accountName.cfg"
}

getAPMaaSConfigAbsoluteName ()
{
   local _accountName=${1:-accountName}
   echo "${ACCOUNT_DIRECTORY}/${_accountName}/${_accountName}.cfg"
}
getAPMaaSConfigAbsoluteNameTmp ()
{
   local _accountName=${1:-accountName}
   echo "${tmpDir}/"$(getTmpName "APMaaSConfig" "${_accountName}").tmp
}
getAccountMonitors2AbsoluteName ()
{
   local _accountName=${1:-accountName}
   echo "${logDir}/${_accountName}.getAccountMonitors2.log"
}

getTmpName ()
{
   local _func=${1:-func}
   local _accountName=${2:-accountName}
   echo "${_accountName}.${_func}.${$}.$(dt)"
}
   
getMonitorSitesName ()
{
   local _mid=${1:-mid}
   echo "${_mid}.GetMonitorSites.cfg"
}
getMonitorSitesAbsoluteName ()
{
   local _accountName=${1:-accountName}
   local _mid=${2:-mid}
   echo "${ACCOUNT_DIRECTORY}/${_accountName}/mid/$(getMonitorSitesName ${_mid})"
}
getMonitorSitesAbsoluteNameTmp ()
{
   local _accountName=${1:-accountName}
   local _mid=${2:-mid}
   echo "${tmpDir}/"$(getTmpName "$(getMonitorSitesName ${_mid})" "${_accountName}").tmp
}

getAccountPopulationsAbsoluteName ()
{
   local _accountName=${1:-accountName}
   echo "${dataDir}/${_accountName}.getAccountPopulations.data"
}
getAccountPopulationsAbsoluteNameTmp ()
{
   local _accountName=${1:-accountName}
   echo "${tmpDir}/"$(getTmpName "getAccountPopulations" "${_accountName}").tmp
}

getLocationUsageAbsoluteName ()
{
   local _locationType=${1:-missingLocationType}
   echo "${dataDir}/locationUsage.${_locationType}.data" # Contains the test execution time consumed in minutes per location
}
getLocationUsageAbsoluteNameTmp ()
{
   local _locationType=${1:-missingLocationType}
   echo "${tmpDir}/locationUsage.${_locationType}.tmp"
}
getHtmlLocationUsageAbsoluteName ()
{
   local _locationType=${1:-missingLocationType}
   echo "${htmlDir}/locationUsage.${_locationType}.html"
}

getHtmlLocationTestAbsoluteName ()
{
   echo "${htmlDir}/location.TEST.html"
}
getReportAbsoluteName ()
{
   local _reportType=${1:-missingReportType}
   echo "${reportDir}/${_reportType}.txt"
}
### APMaaS_param.sh - The End ###
