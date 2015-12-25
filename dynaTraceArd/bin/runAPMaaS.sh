#!/bin/bash -f
_program=runAPMaaS.sh

homeDir=${homeDir:-${HOME}/dynaTrace}
binDir=${binDir:-${homeDir}/bin}

. "${binDir}/ZAPMaaS_Functions.sh"

#DEBUG=$TRUE

if [ "$#" -ne 2 ]
then
   cat << EOF

Run as: ${_program} [CONFIGURE MONITOR REPORT] Gomezlogin

When requested:
   - CONFIGURE, this shell script will download the latest APMaaS configuration for the requested Gomez login. Result will be stored in: $(getAPMaaSConfigAbsoluteName yourAPMaaS_AccountName)
   - MONITOR, this shell script will download the latest APMaaS performance test data for the requested Gomez login
   - REPORT, reports on missing interactive graphs from APMaaS_HTML_CHART_CONFIG

Exiting...

EOF
   exit ${FALSE}
fi

task="${1}"
login_compuware="${2}"


case "${task}" in
   "CONFIGURE") 
      mainGetAPMaaSConfig "${login_compuware}";;

   "MONITOR") 
      mainAPMaaSCheck "${login_compuware}";;
      
   "REPORT") 
      listMissingPublicChart ;;

   *)
      info " ${_program}:Unknown task:${task}, exiting...";;
esac

exit
