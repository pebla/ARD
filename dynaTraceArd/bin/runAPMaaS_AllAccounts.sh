#! /bin/bash -x
_program=runAPMaaS_AllAccounts.sh

homeDir="${HOME}/dynaTrace"
configDir="${homeDir}/config"
binDir="${homeDir}/bin"

export homeDir configDir binDir

cd "${binDir}"

if [ "$#" -ne 1 ]
then
   cat << EOF

Run as: ${_program} [CONFIGURE MONITOR DASHBOARD]

When requested:
   - CONFIGURE, this shell script will download the latest APMaaS configuration for all Gomez Accounts
   - MONITOR, this shell script will dwnload the latest APMaaS performance test data for all tests for all Gomez Accounts
   - DASHBOARD, this shell script will update HTML dashboard http://localhost/index.html
 
Exiting...

EOF
   exit ${FALSE}
fi

task="${1}"
if [ "%${task}%" = "%DASHBOARD%" ] # For DASHBOARD, we have to do summary htmls and merge some files into one...
then
   . "ZAPMaaS_Functions.sh"
   mainUpdateDashboard
else   
   while read line
   do
      separator_II='|'
      login_compuware=`echo ${line} | cut -d"${separator_II}" -f1`

      "${binDir}/runAPMaaS.sh" "${task}" "${login_compuware}" &
   done < <(cat "${configDir}/Login/.passwd_compuware")

   wait
   # Above will run in parallel in background, so wait for it to complete
 
   if [ "%${task}%" = "%MONITOR%" ]
   then
      . "ZAPMaaS_Functions.sh"
	  debug "${_program}:Function HtmlTable_TestSummary requires one file for all tests. When run MONITOR, merge all log files into one at the end of the run."

 	  > "${APMaaS_CHECK_ABSOLUTE_NAME}"
      while read line
      do
         login_compuware=`echo ${line} | cut -d"${separator_II}" -f1`
	  
         _accountName=$(getAccountNameForLogin "${login_compuware}")
         CheckAbsoluteName=$(getAPMaaSCheckAbsoluteName "${_accountName}")

         cat "${CheckAbsoluteName}" | grep -v AccountName >> "${APMaaS_CHECK_ABSOLUTE_NAME}"
      done < <(cat "${configDir}/Login/.passwd_compuware")
   fi
fi

exit
