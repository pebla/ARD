### APMaaS_Functions:Begin ###
myName=APMaaS

#set -euo pipefail
set -u
. "${HOME}"/dynaTrace/bin/ZAPMaaS_param.sh || { echo "Failed to source APMaaS.param with global variables and functions, exiting..."; exit ${FALSE}; }

#############
# Functions #
#############
getAccountIdNameFromLogin ()
{
   local _func=${_program:-BASH}.getAccountIdNameFromLogin
   local _ret=${FALSE}

   if [ ${#} -ne 3 ]
   then
      cat << EOF

Run as:
${_func} login accountId accountName

This function populates accountId accountName with account information associated with login.

EOF
      return ${FALSE}
   fi

   local _login="${1}"
   local _passwd=$(getPasswordForLogin "${_login}")
   [ "%${_login}%" = "%%" ] || [ "%${_passwd}%" = "%%" ] && { info "${_func}:loginName:${_login}:passwd is blank, exiting..."; exit ${FALSE} ; }

   local _loginAccountFile=$(getLoginAccountAbsoluteName "${_login}")
   debug "${_func}:Recreate config file:${_loginAccountFile}, with login+account details, if older than ${REFRESH_CONFIG_FILES_OLDER_THEN_DAYS} days..."
   find "${LOGIN_ACCOUNT_DIRECTORY}" -maxdepth 1 -name "${_login}.accountName.cfg" -type f -mtime +${REFRESH_CONFIG_FILES_OLDER_THEN_DAYS} -exec cp /dev/null {} \;

   debug "${_func}:Getting Account Name and Id for loginName:${_login}..."
   [ "%${_login}%" = "%%" ] || [ "%${_passwd}%" = "%%" ] && { info "${_func}:loginName:${_login}:passwd is blank, exiting..."; exit ${FALSE} ; }

   _accountId=$(getAccountIdForLogin "${_login}") 
   _accountName=$(getAccountNameForLogin "${_login}") 

   if [ "%${_accountName}%" = "%%" ]
   then
      local _tmpName _curlLog _fileOutTmp WebServiceAPI
	 
      debug "${_func}:Not found accountId and accountName for the supplied loginName:${_login}, in file ${_loginAccountFile}. Will create an entry."
      _tmpName=$(getTmpName "${_func}" "${_login}") # We have no accountName details at this point, use _login instead
      _curlLog="${tmpDir}/${_tmpName}.curlLog"
      _fileOutTmp="${tmpDir}/${_tmpName}.tmp"

      WebServiceAPI="https://gpn.webservice.gomez.com/AccountManagementWS_20/AccountManagementWS.asmx/GetAccountConfigPackage?sUsername=${_login}&sPassword=${_passwd}"

      #<AccountInfo name="Bla" title="consultant" first="Pitt" last="Morr" username="PT.MR" address1="Enterprise House" address2="Add2" city="London" state="An" zip="000" email="e@e.com" phone="234" fax="" gmtoffset="60" timezone="(GMT +01:00) Amsterdam, Berlin, Madrid, Paris, Rome"/>
      #<MonitorSet>
      #<Monitor mid="22132279" desc="DeleteMe Agent" url="" class="TRANSACTION" status="ACTIVE" account="227" timeoutinsec="300" frequencyinms="300" docomponents="0" created="2/1/2015 9:32:49 AM" modified="2/1/2015 9:32:49 AM" isBrowser="true" isMobile="false"/>
      #</MonitorSet>
      #<SiteSet>
      #<Site sid="105" name="Newark, NJ - CenturyLink" status="ACTIVE" city="Newark" state="NJ" country="US" IP="63.236.80.118" backboneId="320" backbone="CenturyLink - IPv6 (C)" isURL="0" isEmpirix="0" isUTA="0"/>

      debug "${_func}:CURL-WebServiceAPI:$WebServiceAPI"
      curl ${proxy} -o "${_fileOutTmp}" "${WebServiceAPI}" 2>>"${_curlLog}"
      grep '\<eStatus>STATUS_SUCCESS</eStatus>' "${_fileOutTmp}" > /dev/null 2>&1
      if [ ${?} -eq ${TRUE} ]
      then
         _accountId=$(grep " account" "${_fileOutTmp}" | head -n 1 | sed 's/\"/\\"/g' | awk -F'=' '{print $7}' | awk -F'"' '{print $2}' | awk -F'\' '{print $1}')
         _accountName=$(grep "\<AccountInfo name" "${_fileOutTmp}"| sed 's/\"/\\"/g' | awk -F'=' '{print $2}' | awk -F'"' '{print $2}' | awk -F'\' '{print $1}')
         debug "${_func}:_accountId:${_accountId}:_accountName:${_accountName}"

         if [ -n "${_accountId}" ]
         then
            eval $2=\$_accountId
            if [ -n "${_accountName}" ]
            then
               eval $3=\$_accountName

               debug "${_func}:_login:${_login}:_accountId:${_accountId}:_accountName:${_accountName}."
               echo ${_login}${separator_II}${_accountId}${separator_II}${_accountName} > "${_loginAccountFile}"

               _ret=${TRUE}
            else
               info "${_func}:Failed to get accountName from the Webservice."
            fi
         else
            info "${_func}:Failed to get accountId data from the Webservice."
         fi
      else
         info "### ${_func} ###########################"
         [ -e "${_fileOutTmp}" ] && cat "${_fileOutTmp}"
         info "### ${_func} ###########################"
         info "${_func}:Failed to get Account data from the Webservice for login:${_login}."
      fi
      rm -f "${_curlLog}"
      [ ${DEBUG} -eq ${FALSE} ] && rm -f "${_fileOutTmp}"
   else
      debug "${_func}:Found accountId:${_accountId}, and accountName:${_accountName}, for the supplied loginName:${_login}, in file ${_loginAccountFile}."
      eval $2=\$_accountId
      eval $3=\$_accountName
      _ret=${TRUE}
   fi

   return ${_ret}
}

MATRIX_init ()
{
   local _func=${_program:-BASH}.MATRIX_init
   #
   # Generate global MATRIX with logins
   #
   # All declarations are in "param" file: MATRIX, MATRIX_HEADER, MATRIX_ROWS, MATRIX_COLS
   # Set MATRIX column 0 to accountLogin; 1 to the accountId; 2 to accountName...
   #
   MATRIX_getColForHeader "login" jLogin || { info "${_func}:Not found MATRIX header with title login, exiting..."; exit ${FALSE} ; }
   MATRIX_getColForHeader "accountId" jAccountId || { info "${_func}:Not found MATRIX header with title accountId, exiting..."; exit ${FALSE} ; }
   MATRIX_getColForHeader "accountName" jAccountName || { info "${_func}:Not found MATRIX header with title accountName, exiting..."; exit ${FALSE} ; }

   declare -a accounts=( `cat "${LOGIN_ACCOUNT_DIRECTORY}"/* | sort -t${separator} -k3,3 | awk -F${separator} '{print $1}'` ) # Sort accounts by name
   
   for ((i=0;i<=${MATRIX_ROWS};i++)) do
      if [ $((${#accounts[@]}-1)) -ne ${MATRIX_ROWS} ]
      then
         # We have not gone through getAccountIdNameFromLogin and have no accountName for login, get plain login and go unsorted. Next time around we will be able go sorted
         MATRIX[${i},${jLogin}]=`sed -n "$((${i}+1))p" < "${PASSWD_COMPUWARE}" |awk -F"${separator_II}" '{print $1}'`
      else
         MATRIX[${i},${jLogin}]=${accounts[${i}]}
      fi
      MATRIX[${i},${jAccountId}]="$(getAccountIdForLogin "${MATRIX[${i},${jLogin}]}")"
      MATRIX[${i},${jAccountName}]="$(getAccountNameForLogin "${MATRIX[${i},${jLogin}]}")"

      if [ "%${MATRIX[${i},${jAccountName}]}%" = "%%" ] # No info for this login, get it...
      then
         debug "${_func}:No info for login:${MATRIX[${i},${jLogin}]}:i:$i, get it..."
         getAccountIdNameFromLogin "${MATRIX[${i},${jLogin}]}" _accountId _accountName
         MATRIX[${i},${jAccountId}]="$(getAccountIdForLogin "${MATRIX[${i},${jLogin}]}")"
         MATRIX[${i},${jAccountName}]="$(getAccountNameForLogin "${MATRIX[${i},${jLogin}]}")"
      fi  
      
      for ((j=3;j<=${MATRIX_COLS};j++)) do
         MATRIX[${i},${j}]=0
      done
   done
}

getTotalUniqueTestsForAccount ()
{
   local _func=${_program:-BASH}.getTotalUniqueTestsForAccount
   local _ret=${FALSE}

   if [ ${#} -ne 1 ]
   then
		cat << EOF

Run as:
${_func} loginName

This function returns total unique tests for accountName

EOF
		return ${FALSE}
   fi

	local _loginName="${1}"
	local _accountName=$(getAccountNameForLogin "${_loginName}")
	local _morningCheckLog=$(getAPMaaSCheckAbsoluteName "${_accountName}")
	cat "${_morningCheckLog}" | grep -v 'AccountName' | awk -F"${separator}" '{print $5}' | sort -u | wc -l
}

MATRIX_print ()
{
   local f1="%$((${#MATRIX_ROWS}+1))s"
   local f2=" %15s"
   local _i _j

   printf "$f1" ''
   for ((_i=0;_i<=${MATRIX_COLS};_i++)) do
      printf "$f2" "${MATRIX_HEADER[${_i}]}"
   done
   echo

   for ((_i=0;_i<=${MATRIX_ROWS};_i++)) do
      printf "$f1" $_i
      for ((_j=0;_j<=${MATRIX_COLS};_j++)) do
         printf "$f2" "${MATRIX[${_i},${_j}]}"
      done
      echo
   done
}

MATRIX_getRowAccountId ()
{
   local _func=${_program:-BASH}.MATRIX_getRowAccountId
   local _ret=${FALSE}

   if [ ${#} -ne 2 ]
   then
      cat << EOF

Run as:
${_func} accountId rowId

This function finds accountId in MATRIX and returns its row number

EOF
      return ${FALSE}
   fi
   local _accountId="${1}"
   local _i=""
   eval $2=\$_i # Reset in case we do not find it

   debug "${_func}:Finding row with accountId:${_accountId}, in MATRIX..."
   MATRIX_getColForHeader accountId jAccountId

   for ((_i=0;_i<=${MATRIX_ROWS};_i++)) do
      if [ ${MATRIX[${_i},${jAccountId}]} -eq ${_accountId} ]
      then
         eval $2=\$_i
		 _ret=${TRUE}
         debug "${_func}:Found row:${_i}, with accountId:${_accountId}, in MATRIX."
         break
      fi
   done
   return ${_ret}
}

MATRIX_getColForHeader ()
{
   local _func=${_program:-BASH}.MATRIX_getColForHeader
   local _ret=${FALSE}

   if [ ${#} -ne 2 ]
   then
      cat << EOF

Run as:
${_func} MATRIXHeaderTitle columnId

This function finds accountId in MATRIX and returns its column number

EOF
      return ${FALSE}
   fi
   local _headerTitle="${1}"
   local _i=""
   eval $2=\$_i # Reset in case we do not find it
		 
   debug "${_func}:Finding column with headerTitle:${_headerTitle}, in MATRIX..."

   for ((_i=0;_i<=${MATRIX_COLS};_i++)) do
      if [ "%${MATRIX_HEADER[$_i]}%" = "%${_headerTitle}%" ]
      then
         eval $2=\$_i
		 _ret=${TRUE}
         debug "${_func}:Found col:${_i}, with header:${_headerTitle}, in MATRIX."
         break
      fi
   done
   return ${_ret}
}

getThresholds ()
{
   local _func=${_program:-BASH}.getThresholds
   if [ ${#} -ne 2 ]
   then
      cat << EOF

Run as:
${_func} accountName testID

This function returns warning and severe response time thresholds for supplied accountName and testID.

EOF
      return ${FALSE}
   fi
   local _accountName=${1}
   local _testID=${2}
   local _accountMidThresholdsAbsoluteName=$(getAccountMidThresholdsAbsoluteName "${_accountName}")
   
   local _warning=$(grep "^.*\.${WEBSERVICE_API_LOGIN_SUFIX}${separator_II}.*${separator_II}${_testID}${separator_II}.*${separator_II}.*${separator_II}.*$" "${_accountMidThresholdsAbsoluteName}"| head -n 1 | awk -F"${separator_II}" '{print $5}')
   local _severe=$(grep "^.*\.${WEBSERVICE_API_LOGIN_SUFIX}${separator_II}.*${separator_II}${_testID}${separator_II}.*${separator_II}.*${separator_II}.*$" "${_accountMidThresholdsAbsoluteName}"| head -n 1 | awk -F"${separator_II}" '{print $6}')

   _warning=${_warning:-0}
   _severe=${_severe:-0}
   debug "${_func}:Returning thresholds configured and registered at: "${_accountMidThresholdsAbsoluteName}", for testID:${_testID}:${_warning}:${_severe}."

   echo ${_warning}${separator_II}${_severe}
}

getConfig_Thresholds ()
{
   local _func=${_program:-BASH}.getConfig_Thresholds
   local _ret=${FALSE}

   if [ ${#} -ne 1 ]
   then
      cat << EOF

Run as:
${_func} login

This function updates alert configuration for the child account login into $(getAccountMidThresholdsAbsoluteName _accountName).

EOF
      return ${FALSE}
   fi

   local _login="${1}"
   local _passwd=$(getPasswordForLogin "${_login}")
   info "${_func}:Updating alert configuration for all tests for the child account login:${_login}"
   debug "${_func}:_login:${_login}. Make sure you executed init loginName before calling this function."
   [ "%${_login}%" = "%%" ] || [ "%${_passwd}%" = "%%" ] && { info "${_func}:loginName:${_login}:passwd is blank, exiting..."; exit ${FALSE} ; }

   local _accountId _accountName
   

   getAccountIdNameFromLogin "${_login}" _accountId _accountName
   [ ${?} -ne ${TRUE} ] && { info "${_func}:Failed to getAccountIdNameFromLogin for ${_login}, exiting..."; exit ${FALSE}; }
   
   local _tmpName=$(getTmpName "${_func}" "${_accountName}")
   local _curlLog="${tmpDir}/${_tmpName}.curlLog"
   local _fileOutTmp="${tmpDir}/${_tmpName}.tmp"

   local _fileOut=$(getAccountMidThresholdsAbsoluteName "${_accountName}")
   local _firstLine=${TRUE}
   local WebServiceAPI

   > "${_fileOut}"
   _mid=""
   _warning=""
   _severe=""
   
   for _BB_PLM in ${BB_PLM}
   do
      case "${_BB_PLM}" in
         "PRIVATEPEER") WebServiceAPI="https://gpn.webservice.gomez.com/AlertManagementService20/AlertManagementWS.asmx/GetLMCompleteAlertConfiguration?username="${_login}"&password="${_passwd}"&monitorType=ALL&statusType=${statusDesignator}" ;;
         "UTATX") WebServiceAPI="https://gpn.webservice.gomez.com/AlertManagementService20/AlertManagementWS.asmx/GetCompleteAlertConfiguration?username="${_login}"&password="${_passwd}"&monitorType=BROWSERTX&statusType=${statusDesignator}" ;;
         * ) info "${_func}:_BB_PLM:${_BB_PLM}:Parameter has unexpected value, exiting." ; exit ${FALSE};;
      esac
   
      debug "${_func}:CURL-WebServiceAPI:$WebServiceAPI"
      curl ${proxy} -o "${_fileOutTmp}" "${WebServiceAPI}" 2>>"${_curlLog}"
      grep '\<status>SUCCESS</status>' "${_fileOutTmp}" > /dev/null 2>&1
      if [ ${?} -eq ${TRUE} ]
      then
         while read _lineX
         do
            #<monitorAlertConfiguration id="202611" desc="MDM NA VSP Login" doSummary="true" doComponents="true" timeoutInSec="300" class="TRANSACTION" status="ACTIVE">

            echo "$_lineX" | grep '\<monitorAlertConfiguration id="' > /dev/null 2>&1
            if [ ${?} -eq ${TRUE} ]
            then
               if [ ${_firstLine} -eq ${FALSE} ] # If already printed, do not print again
               then
                  grep "${_mid}" "${_fileOut}" > /dev/null 2>&1 # Line with new mid, print the setup collected in the previous turn
                  if [ ${?} -ne ${TRUE} ]
                  then
                     debug "${_func}:${_login}${separator_II}${_class}${separator_II}${_mid}${separator_II}${_midDescription}${separator_II}${_warning}${separator_II}${_severe}"

                     echo "${_login}${separator_II}${_class}${separator_II}${_mid}${separator_II}${_midDescription}${separator_II}${_warning}${separator_II}${_severe}" >> "${_fileOut}"
                  fi
                  _warning='0'
                  _severe='0'
               fi
               _mid=$(awk -F'"' '$1 ~ "<monitorAlertConfiguration id=" {print $2}' <<< "${_lineX}") # Slice on ", if first column have "<monitorAlertConfiguration id=", print second column
			   _midDescription=$(awk -F'"' '$1 ~ "<monitorAlertConfiguration id=" {print $4}' <<< "${_lineX}") # Slice on ", if first column have "<monitorAlertConfiguration id=", print fourth column
			   _class=$(awk -F'"' '$1 ~ "<monitorAlertConfiguration id=" {print $12}' <<< "${_lineX}") # Slice on ", if first column have "<monitorAlertConfiguration id=", print twelfth column
               _firstLine=${FALSE}
            else
               echo "$_lineX" | grep 'persistenceIntervalInMin' > /dev/null 2>&1 # If Alert Reminder is set, columns will move +2...
               if [ ${?} -eq ${TRUE} ]
               then
                  #<StaticResponseTimeAlert alertId="5" isEnabled="true" isPersistent="true" persistenceIntervalInMin="60" warningThresholdInMS="10000" severeThresholdInMS="15000">
                  _warning=$(awk -F'"' '$9 ~ "warningThresholdInMS=" {print $10}' <<< "${_lineX}") # Slice on ", if first column have "warningThresholdInMS=", print column 10
                  _severe=$(awk -F'"' '$9 ~ "warningThresholdInMS=" {print $12}' <<< "${_lineX}") # Slice on ", if first column have "warningThresholdInMS=", print column 12
               else
                  #<StaticResponseTimeAlert alertId="5" isEnabled="true" isPersistent="false" warningThresholdInMS="15000" severeThresholdInMS="20000">
				  _warning=$(awk -F'"' '$7 ~ "warningThresholdInMS=" {print $8}' <<< "${_lineX}") # Slice on ", if first column have "warningThresholdInMS=", print column 8
                  _severe=$(awk -F'"' '$7 ~ "warningThresholdInMS=" {print $10}' <<< "${_lineX}") # Slice on ", if first column have "warningThresholdInMS=", print column 10
               fi
            fi
         done < <(egrep "\<monitorAlertConfiguration |warningThresholdInMS" "${_fileOutTmp}"| sed 's/\"/\\"/g')

         if [ "%${_mid}%" = "%%" ]
		 then
		    _midIsNOTSet_orIsEmpty_so_IGNORE=""
         else
            # If already printed, do not print again
            grep "${_mid}" "${_fileOut}" > /dev/null 2>&1
            if [ ${?} -ne ${TRUE} ]
            then
               debug "${_func}:${_login}${separator_II}${_class}${separator_II}${_mid}${separator_II}${_midDescription}${separator_II}${_warning}${separator_II}${_severe}"

                echo "${_login}${separator_II}${_class}${separator_II}${_mid}${separator_II}${_midDescription}${separator_II}${_warning}${separator_II}${_severe}" >> "${_fileOut}"
            fi
         fi

         _ret=${TRUE}
      else
         [ ${DEBUG} -eq ${TRUE} ] && info "### ${_func} ###########################"
         [ ${DEBUG} -eq ${TRUE} ] && cat "${_fileOutTmp}"
         [ ${DEBUG} -eq ${TRUE} ] && info "### ${_func} ###########################"
         [ ${DEBUG} -eq ${TRUE} ] && info "${_func}:Failed to get Alert Configuration from the Webservice for login:${_login}, ${_BB_PLM}."
      fi
      rm -f "${_curlLog}"
      [ ${DEBUG} -eq ${FALSE} ] && rm -f "${_fileOutTmp}"
   done

   return ${_ret}
}

getConfig_PlmAgents ()
{
   local _func=${_program:-BASH}.getConfig_PlmAgents
   local _ret=${FALSE}

   if [ ${#} -ne 1 ]
   then
      cat << EOF

Run as:
${_func} login 

This function populates file ${PLM_AGENTS} with PLMA Agent info: PLMAgentName PLMCountry PLMLastCheckIn PLMAgentComputer PLMAgentID

EOF
      return ${FALSE}
   fi

   local _login="${1}"
   local _passwd=$(getPasswordForLogin "${_login}")
   [ "%${_login}%" = "%%" ] || [ "%${_passwd}%" = "%%" ] && { info "${_func}:loginName:${_login}:passwd is blank, exiting..."; exit ${FALSE} ; }

   local _tmpName=$(getTmpName "${_func}")
   local _curlLog="${tmpDir}/${_tmpName}.curlLog"
   local _fileOutTmp="${tmpDir}/${_tmpName}.tmp"
   local _privatePeerTmp="${tmpDir}/${_tmpName}.GetAccountPrivatePeers"

   local _PLMAgentName _PLMCountry _PLMLastCheckIn _PLMAgentComputer _PLMAgentID

   debug "${_func}:Getting private peers account details for login:${_login}..."
   local WebServiceAPI="https://gpn.webservice.gomez.com/AccountManagementWS_20/AccountManagementWS.asmx/GetAccountPrivatePeers?sUsername=${_login}&sPassword=${_passwd}"
   debug "${_func}:CURL-WebServiceAPI:$WebServiceAPI"
   debug "${_func}:curl ${proxy} -o ${_fileOutTmp} ${WebServiceAPI}"
   curl ${proxy} -o "${_fileOutTmp}" "${WebServiceAPI}" 2>>"${_curlLog}"

   # <eStatus>STATUS_SUCCESS</eStatus>
   grep '\<eStatus>STATUS_SUCCESS</eStatus>' "${_fileOutTmp}" > /dev/null 2>&1
   if [ ${?} -eq ${TRUE} ]
   then
      grep "usr_id=\"${PRIVATE_PEER_NETWORK_ID}\"" "${_fileOutTmp}" | sed 's/\"/\\"/g' | while read _line
      do
#<PrivatePeer machine_id="4444234934" name="d02911" memory="3982" location="unset" usr_id="758873" lastused="11/18/2014 12:50:27 PM" zipcode="00000" network="" cpu="Intel(R) Core(TM) i3-3240 CPU @ 3.40GHz" OS="Windows 7" first_heartbeat_date="10/23/2014 9:39:00 AM" isp="Bla" last_heartbeat_date="11/33/2014 12:51:41 PM" ip="195.2.234.59" country="Nicaragua" region="Nicaragua" onlineTime="00:00:00" processingTime="00:00:00" user_def1="Deff" user_def2="Bamboo" user_def3=""/>

		_PLMAgentName=$(awk -F'"' '{print $40}' <<< "${_line}")
		_PLMCountry=$(awk -F'"' '{print $30}' <<< "${_line}")
		_PLMLastCheckIn=$(awk -F'"' '{print $26}' <<< "${_line}")
		_PLMAgentComputer=$(awk -F'"' '{print $4}' <<< "${_line}")
		_PLMAgentID=$(awk -F'"' '{print $2}' <<< "${_line}")

         debug "${_func}:_PLMAgentName:${_PLMAgentName}:_PLMCountry:${_PLMCountry}:_PLMLastCheckIn:${_PLMLastCheckIn}:_PLMAgentComputer:${_PLMAgentComputer}:_PLMAgentID:${_PLMAgentID}"
         debug "${_func}:${_line}"

         echo "${_PLMCountry}${separator}${_PLMAgentComputer}${separator}${_PLMAgentName}${separator}${_PLMAgentID}${separator}${_PLMLastCheckIn}" >> "${_privatePeerTmp}"
      done

      # No need for header in the file
      #echo "PLMCountry${separator}PLMAgentComputer${separator}PLMAgentName${separator}PLMAgentID${separator}PLMLastCheckIn${separator}" > "${PLM_AGENTS}"

      cat "${_privatePeerTmp}" | sort -t${separator} -k1 | egrep -v "${PLM_AGENTS_IGNORE}" > "${PLM_AGENTS}"
      rm -f "${_privatePeerTmp}"
   else
      info "### ${_func} ###########################"
      [ -e "${_fileOutTmp}" ] && cat "${_fileOutTmp}"
      info "### ${_func} ###########################"
      info "${_func}:Failed to get Private Peer data from the Webservice for login:${_login}."
   fi
   rm -f "${_curlLog}"
   [ ${DEBUG} -eq ${FALSE} ] && rm -f "${_fileOutTmp}"

   return ${_ret}
}

getConfig_Site ()
{
   local _func=${_program:-BASH}.getConfig_Site
   local _ret=${FALSE}

   if [ ${#} -ne 2 ]
   then
      cat << EOF

Run as:
${_func} login mid

This function lists sites assigned to specific account test into: $(getMonitorSitesAbsoluteName accountName mid).

EOF
      return ${FALSE}
   fi

   local _login="${1}"
   local _mid=${2}

   local _passwd=$(getPasswordForLogin "${_login}")
   [ "%${_login}%" = "%%" ] || [ "%${_passwd}%" = "%%" ] && { info "${_func}:loginName:${_login}:passwd is blank, exiting..."; exit ${FALSE} ; }

   local _accountId _accountName WebServiceAPI _siteIdSet _siteName

   debug "${_func}:Getting configured monitoring sites for loginName:${_login}:mid=${_mid}..."
  
   getAccountIdNameFromLogin "${_login}" _accountId _accountName
   [ ${?} -ne ${TRUE} ] && { info "${_func}:Failed to getAccountIdNameFromLogin for ${_login}, exiting..."; exit ${FALSE}; }

   local _tmpName=$(getTmpName "${_func}" "${_accountName}")
   local _curlLog="${tmpDir}/${_tmpName}.curlLog"
   local _fileOutTmp="${tmpDir}/${_tmpName}.tmp"

   local _monitorSitesName=$(getMonitorSitesName ${_mid})
   local _monitorSitesAbsoluteName=$(getMonitorSitesAbsoluteName "${_accountName}" ${_mid})

   debug "${_func}:Removing ${_monitorSitesAbsoluteName} file if older then ${REFRESH_CONFIG_FILES_OLDER_THEN_DAYS} day; will create the same file with new config if deleted..."
   debug "${_func}:find ${ACCOUNT_DIRECTORY}/${_accountName}/mid -maxdepth 1 -name ${_monitorSitesName} -type f -mtime +${REFRESH_CONFIG_FILES_OLDER_THEN_DAYS} -print"
   local _found=`find "${ACCOUNT_DIRECTORY}/${_accountName}/mid" -maxdepth 1 -name "${_monitorSitesName}" -type f -mtime +${REFRESH_CONFIG_FILES_OLDER_THEN_DAYS} -print`
   debug "${_func}:${_found} = ${_monitorSitesAbsoluteName}"
   if [ "${_found}" = "${_monitorSitesAbsoluteName}" ]
   then
      debug "${_func}:Removing ${_monitorSitesAbsoluteName}..."
      rm -f "${_monitorSitesAbsoluteName}"
   fi

   debug "${_func}:If ${_monitorSitesAbsoluteName} file exists and is not empty, return and use the same file - it is fresh enough."
   [ -s "${_monitorSitesAbsoluteName}" ] && return ${TRUE} ;

   debug "${_func}:Creating ${_monitorSitesAbsoluteName} file..."

   > "${_monitorSitesAbsoluteName}"

   debug "${_func}:Getting monitoring sites for the accountName:${_accountName}:mid=${_mid}..."
   WebServiceAPI="https://gpn.webservice.gomez.com/AccountManagementWS_20/AccountManagementWS.asmx/GetMonitorSites?sUsername=${_login}&sPassword=${_passwd}&iMonitorId=${_mid}"
   debug "${_func}:CURL-WebServiceAPI:$WebServiceAPI"
   curl ${proxy} -o "${_fileOutTmp}" "${WebServiceAPI}" 2>>"${_curlLog}"
   grep '\<eStatus>STATUS_SUCCESS</eStatus>' "${_fileOutTmp}" > /dev/null 2>&1
   if [ ${?} -eq ${TRUE} ]
   then
      grep "\<Site " "${_fileOutTmp}" | sed 's/\"/\\"/g' | while read _line
      do
         _siteIdSet=$(awk -F'=' '{print $2}' <<< "${_line}" | awk -F'"' '{print $2}')
         _siteName=$(awk -F'=' '{print $3}' <<< "${_line}" | awk -F'"' '{print $2}')
         echo "${_siteIdSet}"${separator_II}"${_siteName}" >> "${_monitorSitesAbsoluteName}"
      done
      _ret=${TRUE}
   else
      info "### ${_func} ###########################"
      cat "${_fileOutTmp}"
      info "### ${_func} ###########################"
      info "${_func}:Failed to get test sites from the Webservice for login:${_login}."
   fi
   rm -f "${_curlLog}"
   [ ${DEBUG} -eq ${FALSE} ] && rm -f "${_fileOutTmp}"

   return ${_ret}
}

openDataFeed3 ()
{
   local _func=${_program:-BASH}.openDataFeed3
   local _ret=${FALSE}

   if [ ${#} -ne 5 ]
   then
      cat << EOF

Run as:
${_func} login mid siteId monitorType tokenId

This function opens data feed 3 for extracton from APMaaS datawarehouse via WebService API, and it returns tokenId.

EOF
      return ${FALSE}
   fi

   local _login="${1}"
   local _mid=${2}
   local _siteId=${3}
   local _monitorType="${4}"

   local _passwd=$(getPasswordForLogin "${_login}")
   [ "%${_login}%" = "%%" ] || [ "%${_passwd}%" = "%%" ] && { info "${_func}:loginName:${_login}:passwd is blank, exiting..."; exit ${FALSE} ; }

   debug "${_func}:Getting the latest performance data for the loginName:${_login}:mid=${_mid}:siteId:${_siteId}:monitorType:${_monitorType}..."

   getAccountIdNameFromLogin "${_login}" _accountId _accountName
   [ ${?} -ne ${TRUE} ] && { info "${_func}:Failed to getAccountIdNameFromLogin for ${_login}, exiting..."; exit ${FALSE}; }

   local _tmpName=$(getTmpName "${_func}" "${_accountName}")
   local _curlLog="${tmpDir}/${_tmpName}.curlLog"
   local _fileOutTmp="${tmpDir}/${_tmpName}.tmp"

   touch "${_fileOutTmp}"

   local _dataDesignator='ALL'
   local _dataDesignator='SUMMARY'
   local _lastN=1
   local _startTime='2014-07-23%2000:00:00'
   local _endTime='2014-07-24%2008:00:00'
   local _orderDesignator='TIME'
   local _timeDesignator='TESTTIME_RELATIVE'

   local WebServiceAPI="https://gpn.webservice.gomez.com/DataExportService60/GPNDataExportService.asmx/OpenDataFeed3?sUsername=${_login}&sPassword=${_passwd}&iMonitorIDSet=${_mid}&iSiteIdSet=${_siteId}&sMonitorClassDesignator=${_monitorType}&sDataDesignator=${_dataDesignator}&sLastN=${_lastN}&sStartTime=${_startTime}&sEndTime=${_endTime}&sOrderDesignator=${_orderDesignator}&sTimeDesignator=${_timeDesignator}"

   debug "${_func}:CURL-WebServiceAPI:$WebServiceAPI"
   curl ${proxy} -o "${_fileOutTmp}" "$WebServiceAPI" 2>>"${_curlLog}"

   grep '\<eStatus>STATUS_SUCCESS</eStatus>' "${_fileOutTmp}" > /dev/null 2>&1
   if [ ${?} -eq ${TRUE} ]
   then
      _tokenId=$(grep "<SessionToken>" "${_fileOutTmp}" |cut -d\> -f2|cut -d\< -f1)
      if [ "%${_tokenId}%" != "%%" ]
      then
         eval $5=\$_tokenId
         info " ${_func}:Data stream token:${_tokenId}"
         _ret=${TRUE}
      else
         info "${_func}:+++ Failed to get tokenId +++"
      fi
   else
      debug "### ${_func} ###########################"
      [ ${DEBUG} = ${TRUE} ] && cat "${_fileOutTmp}"
      debug "### ${_func} ###########################"
      debug "${_func}:Failed to get data feed from the Webservice for login:${_login}"
	  
      grep 'Max number of concurrent sessions exceeded' "${_fileOutTmp}" > /dev/null 2>&1
      if [ ${?} -eq ${TRUE} ]
      then
         _ret=${ERROR_MAX_NUMBER_OF_CONCURRENT_SESSIONS_EXCEEDED}
         debug "${_func}:Max number of concurrent sessions exceeded. Going to sleep 5s..."
		 sleep 5
      fi
   fi
   rm -f "${_curlLog}"
   [ ${DEBUG} -eq ${FALSE} ] && rm -f "${_fileOutTmp}"

   return ${_ret}
}

getResponseData ()
{
   local _func=${_program:-BASH}.getResponseData
   local _ret=${FALSE}

   if [ ${#} -ne 6 ]
   then
      cat << EOF

Run as:
${_func} tokenId monitorType testStatus tTime rTime sName

This function extracts data from APMaaS datawarehouse via WebService API, and it populates last four calling parameters

EOF
      return ${FALSE}
   fi

   local _tokenId="${1}"
   local _monitorType="${2}"

   # Default status to FALSE and -1
   _testStatus=${FALSE}
   eval "$3=-1"
   eval "$4=-1";
   eval "$5=-1";
   eval "$6=-1";
		 
   local _tmpName=$(getTmpName "${_func}" "${_tokenId}")
   local _curlLog="${tmpDir}/${_tmpName}.curlLog"
   local _fileOutTmp="${tmpDir}/${_tmpName}.tmp"

   touch "${_fileOutTmp}"

   local WebServiceAPI="https://gpn.webservice.gomez.com/DataExportService60/GPNDataExportService.asmx/GetResponseData?sSessionToken=${_tokenId}"
   debug "${_func}:CURL-WebServiceAPI:$WebServiceAPI"
   curl ${proxy} -o "${_fileOutTmp}" "$WebServiceAPI" 2>>"${_curlLog}"
   grep '\<eStatus>STATUS_SUCCESS</eStatus>' "${_fileOutTmp}" > /dev/null 2>&1
   if [ ${?} -eq ${TRUE} ]
   then
      # Retrieved test data?
      grep "\<TXTEST " "${_fileOutTmp}" > /dev/null 2>&1
      if [ ${?} -eq ${TRUE} ]
      then
         # GetResponseData should retrieve only one record, but for any case use head to force only 1
         _line=`grep "\<TXTEST " "${_fileOutTmp}" | head -n 1`
         
         case "${_monitorType}" in
         "UTATX")
            _tTime=`echo "${_line}" | awk -F'=' '{print $4}' | awk -F'"' '{print $2}'` ;
            _sName=`echo "${_line}" | awk -F'=' '{print $5}' | awk -F'"' '{print $2}'` ;
            _rTime=`echo "${_line}" | awk -F'=' '{print $6}' | awk -F'"' '{print $2}'` ;
            _totalFailed=`echo "${_line}" | awk -F'=' '{print $9}' | awk -F'"' '{print $2}'` ;;
         "LASTMILE"|"PRIVATEPEER")
            _tTime=`echo "${_line}" | awk -F'=' '{print $5}' | awk -F'"' '{print $2}'` ;
            _sName=`echo "${_line}" | awk -F'=' '{print $6}' | awk -F'"' '{print $2}'` ;
            _rTime=`echo "${_line}" | awk -F'=' '{print $8}' | awk -F'"' '{print $2}'` ;
            _totalFailed=`echo "${_line}" | awk -F'=' '{print $11}' | awk -F'"' '{print $2}'` ;;
         *)
            info "${_func}:CRITICAL ALERT:Do not know how to process monitorType:${_monitorType}. THIS HAS TO BE PROGRAMMED!" ;;
         esac

         if [ -z "${_tTime}" ]; then _tTime=0; fi
         if [ -z "${_rTime}" ]; then _rTime=0; fi
         if [ -z "${_sName}" ]; then _sName="Unknown"; fi
         if [ -z "${_totalFailed}" ]; then _totalFailed=-1; fi

         eval "$4=\$_tTime";
         eval "$5=\$_rTime";
         eval "$6=\$_sName";

         case "${_totalFailed}" in
            "0")  # Test executed OK
                  _testStatus=${TRUE};
                  _ret=${TRUE};;

            *)    # Test executed but partly failed
                  _testStatus=2;;
         esac

         debug "${_func}:_testStatus:${_testStatus}:_tTime:${_tTime}:_rTime:${_rTime}:_sName:${_sName}:_totalFailed:${_totalFailed}."
      else
         debug "${_func}:No data found for this request!"
         _testStatus=3
      fi
   else
      debug "${_func}:Failed, eStatus is not STATUS_SUCCESS."
      _testStatus=4
      info "### ${_func} ###########################"
      cat "${_fileOutTmp}"
      info "### ${_func} ###########################"
      info "${_func}:Failed to get data feed from the Webservice for login:${_login}."
   fi
   rm -f "${_curlLog}"
   [ ${DEBUG} -eq ${FALSE} ] && rm -f "${_fileOutTmp}"

   # _ret = TRUE/FALSE
   # _testStatus = 0 - TRUE Test executed OK; 1 - FALSE Cannot retreive data from Compuware; 2 - Retreived data but test FAILED; 3 - Returned no data; 4 - Retreived eStatus is not STATUS_SUCCESS
   eval "$3=\$_testStatus"
   return ${_ret}
}

closeDataFeed ()
{
   local _func=${_program:-BASH}.closeDataFeed
   local _ret=${FALSE}

   if [ ${#} -ne 1 ]
   then
      cat << EOF

Run as:
${_func} tokenId

This function closes already opened data feed.

EOF
      return ${FALSE}
   fi

   local _tokenId="${1}"

   local _tmpName=$(getTmpName "${_func}" "${_tokenId}")
   local _curlLog="${tmpDir}/${_tmpName}.curlLog"
   local _fileOutTmp="${tmpDir}/${_tmpName}.tmp"

   touch "${_fileOutTmp}"

   local WebServiceAPI="https://gpn.webservice.gomez.com/DataExportService60/GPNDataExportService.asmx/CloseDataFeed?sSessionToken=${_tokenId}"
   debug "${_func}:CURL-WebServiceAPI:$WebServiceAPI"
   curl ${proxy} -o "${_fileOutTmp}" "$WebServiceAPI" 2>>"${_curlLog}"

   grep '\<eStatus>STATUS_SUCCESS</eStatus>' "${_fileOutTmp}" > /dev/null 2>&1
   if [ ${?} -eq ${TRUE} ]
   then
      _ret=${TRUE}
   else
      info "### ${_func} ###########################"
      cat "${_fileOutTmp}"
      info "### ${_func} ###########################"
      info "${_func}:Failed to close data feed from the Webservice for tokenId:${_tokenId}."
   fi
   rm -f "${_curlLog}"
   [ ${DEBUG} -eq ${FALSE} ] && rm -f "${_fileOutTmp}"

   return ${_ret}
}

getAccountPopulationsData ()
{
   local _func=${_program:-BASH}.getAccountPopulationsData
   local _ret=${FALSE}

   if [ ${#} -ne 1 ]
   then
      cat << EOF

Run as:
${_func} login 

This function appends Zurch populations to $(getAccountPopulationsAbsoluteName accountName) in format "accountId:accountName:populationId:populationName"

EOF
      return ${FALSE}
   fi

   local _login="${1}"
   local _passwd=$(getPasswordForLogin "${_login}")
   [ "%${_login}%" = "%%" ] || [ "%${_passwd}%" = "%%" ] && { info "${_func}:loginName:${_login}:passwd is blank, exiting..."; exit ${FALSE} ; }
   info "${_func}:Updating populations for the child account login:${_login}"
 
   getAccountIdNameFromLogin "${_login}" _accountId _accountName
   [ ${?} -ne ${TRUE} ] && { info "${_func}:Failed to getAccountIdNameFromLogin for ${_login}, exiting..."; exit ${FALSE}; }
   debug " ${_func}:login:${_login}:accountId:${_accountId}:accountName:${_accountName}:..."

   local _AccountPopulations=$(getAccountPopulationsAbsoluteName "${_accountName}")
   local _AccountPopulationsTmp=$(getAccountPopulationsAbsoluteNameTmp "${_accountName}")

   local _tmpName=$(getTmpName "${_func}" "${_accountName}")
   local _curlLog="${tmpDir}/${_tmpName}.curlLog"
   local _fileOutTmp="${tmpDir}/${_tmpName}.tmp"

   > "${_AccountPopulationsTmp}"

   local _monitorType='LM'
   local _firstLine=${TRUE}

   local WebServiceAPI="https://gpn.webservice.gomez.com/AccountManagementWS_20/AccountManagementWS.asmx/GetAccountPopulations?sUsername=${_login}&sPassword=${_passwd}&getDefinitions=true&populationType=ALL"
   debug "${_func}:CURL-WebServiceAPI:$WebServiceAPI"
   curl ${proxy} -o "${_fileOutTmp}" "${WebServiceAPI}" 2>>"${_curlLog}"
	
   grep '\<eStatus>STATUS_SUCCESS</eStatus>' "${_fileOutTmp}" > /dev/null 2>&1
   if [ ${?} -eq ${TRUE} ]
   then
      while read _lineX
      do
         #<Population id="88" name="Europe - Dial Up" type="PUBLIC">
         #<PopulationDefinition populationDefinitionId="112590" keyword="NetworkId" value="ALL" isIncluded="true" />

         echo "${_lineX}" | grep '\<Population id="' > /dev/null 2>&1
         if [ ${?} -eq ${TRUE} ]
         then
            if [ ${_firstLine} -eq ${FALSE} ]
            then
               echo "${_accountId}${separator_II}${_accountName}${separator_II}${_monitorType}${separator_II}${_populationId}${separator_II}${_populationName}${separator_II}${_populationDefinitionId}${separator_II}${_networkId}" >> "${_AccountPopulationsTmp}"
			   debug "${_func}:${_accountId}:${_accountName}:${_monitorType}:${_populationId}:${_populationName}:${_populationDefinitionId}:${_networkId}"
               _populationDefinitionId='0'
               _networkId='0'
            fi
            _populationId=$(grep '\<Population id="' <<< "${_lineX}" | cut -d'"' -f2,4 | cut -d'"' -f1)
            _populationName=$(grep '\<Population id="' <<< "${_lineX}" | cut -d'"' -f2,4 | cut -d'"' -f2)
            _firstLine=${FALSE}
            _monitorType='LM'
         else
            _populationDefinitionId=$(grep 'keyword="NetworkId"' <<< "${_lineX}" | cut -d'"' -f2,6 | cut -d'"' -f1)
            _networkId=$(grep 'keyword="NetworkId"' <<< "${_lineX}" | cut -d'"' -f2,6 | cut -d'"' -f2)
            _monitorType='PLM'

            echo ${_populationName} | egrep " - .* - " > /dev/null 2>&1
            if [ ${?} -eq ${TRUE} ]
            then
               _monitorType='MBL'
            fi

            echo "${_lineX}" | egrep 'keyword="NetworkId" value="ALL"' > /dev/null 2>&1
            if [ ${?} -eq ${TRUE} ]
            then
               _monitorType='LM'
            fi
         fi
      done < <(egrep '\<Population id="|keyword="NetworkId"' "${_fileOutTmp}")
      echo "${_accountId}${separator_II}${_accountName}${separator_II}${_monitorType}${separator_II}${_populationId}${separator_II}${_populationName}${separator_II}${_populationDefinitionId}${separator_II}${_networkId}" >> "${_AccountPopulationsTmp}"
      debug "${_func}:${_accountId}:${_accountName}:${_monitorType}:${_populationId}:${_populationName}:${_populationDefinitionId}:${_networkId}"
	  
      mv "${_AccountPopulationsTmp}" "${_AccountPopulations}"
      _ret=${TRUE}
   else
      info '#### ${_func} ##########################'
      cat "${_fileOutTmp}"
      info '#### ${_func} ##########################'
      info "${_func}:Failed to get population data from the Webservice for login:${_login}."
   fi
   rm -f "${_curlLog}"
   [ ${DEBUG} -eq ${FALSE} ] && rm -f "${_fileOutTmp}"

   return ${_ret}
}

getMonitorData ()
{
   local _func=${_program:-BASH}.getMonitorData
   local _ret=${FALSE}

   if [ ${#} -ne 1 ]
   then
      cat << EOF

Run as:
${_func} login 

This function lists all active tests created for the accountName into "$(getAccountMonitors2AbsoluteName _accountName)"

EOF
      return ${FALSE}
   fi

   local _login="${1}"
   local _passwd=$(getPasswordForLogin "${_login}")
   [ "%${_login}%" = "%%" ] || [ "%${_passwd}%" = "%%" ] && { info "${_func}:loginName:${_login}:passwd is blank, exiting..."; exit ${FALSE} ; }
   info "${_func}:Updating test configuration for the child account login:${_login}"

   local _accountId _accountName
   
   debug "${_func}:Getting tests for for loginName:${_login}..."

   getAccountIdNameFromLogin "${_login}" _accountId _accountName
   [ ${?} -ne ${TRUE} ] && { info "${_func}:Failed to getAccountIdNameFromLogin for ${_login}, exiting..."; exit ${FALSE}; }
   info " ${_func}:GetAccountMonitors2 for accountId:${_accountId}:accountName:${_accountName}:..."

   local _tmpName=$(getTmpName "${_func}" "${_accountName}")
   local _curlLog="${tmpDir}/${_tmpName}.curlLog"
   local _fileOutTmp="${tmpDir}/${_tmpName}.tmp"

   local _fileOut=$(getAccountMonitors2AbsoluteName "${_accountName}")
   > "${_fileOut}"

   debug "${_func}:Getting tests for the accountName:${_accountName}:..."
   
   local WebServiceAPI="https://gpn.webservice.gomez.com/AccountManagementWS_20/AccountManagementWS.asmx/GetAccountMonitors2?sUsername=${_login}&sPassword=${_passwd}&sMonitorSetDesignator=ALL&sstatusdesignator=${statusDesignator}"
   debug "${_func}:CURL-WebServiceAPI:$WebServiceAPI"
   curl ${proxy} -o "${_fileOutTmp}" "${WebServiceAPI}" 2>>"${_curlLog}"
   grep '\<eStatus>STATUS_SUCCESS</eStatus>' "${_fileOutTmp}" > /dev/null 2>&1
   if [ ${?} -eq ${TRUE} ]
   then
      cat "${_fileOutTmp}" | while read _line
      do
         echo "${_line}" | grep "\<Monitor " > /dev/null 2>&1
         [ ${?} -eq ${TRUE} ] && echo ${_line} >> "${_fileOut}"

         echo "${_line}" | grep "\<BatchGroupMonitorIds>" > /dev/null 2>&1
         [ ${?} -eq ${TRUE} ] && echo ${_line} >> "${_fileOut}"

         echo "${_line}" | grep "\<Id>" > /dev/null 2>&1
         [ ${?} -eq ${TRUE} ] && echo ${_line} >> "${_fileOut}"
      done
      _ret=${TRUE}
   else
      info "### ${_func} ###########################"
      cat "${_fileOutTmp}"
      info "### ${_func} ###########################"
      info "${_func}:Failed to get test data from the Webservice for login:${_login}."
   fi
   rm -f "${_curlLog}"
   [ ${DEBUG} -eq ${FALSE} ] && rm -f "${_fileOutTmp}"

   return ${_ret}
}

getData ()
{
   local _func=${_program:-BASH}.getData
   local _testStatus=${FALSE}

   if [ ${#} -ne 8 ]
   then
      cat << EOF

Run as:
${_func} login mid siteId monitorType testStatus tTime rTime sName

This function returns test performance data into variables: testStatus tTime rTime sName.

EOF
      return ${FALSE}
   fi

   local _login="${1}"
   local _mid=${2}
   local _siteId=${3}
   local _monitorType="${4}"

   local _passwd=$(getPasswordForLogin "${_login}")
   [ "%${_login}%" = "%%" ] || [ "%${_passwd}%" = "%%" ] && { info "${_func}:loginName:${_login}:passwd is blank, exiting..."; exit ${FALSE} ; }

   # Default status to FALSE
   eval "$5=\$FALSE"

   debug "${_func}:Getting performance data for loginName:${_login}:mid:${_mid}:siteId:${_siteId}:monitorType:${_monitorType}..."

   openDataFeed3 "${_login}" ${_mid} ${_siteId} "${_monitorType}" _tokenId
   if [ ${?} -eq ${FALSE} ]
   then # openDataFeed3
      debug "${_func}:mid:${_mid}:monitorType:${_monitorType}, is not executed from siteId:${_siteId}, try next site..."
      debug "${_func}:Note, openDataFeed3 failed to provide tokenId, there is nothing to close!"
   else # openDataFeed3 for LM/PM
      getResponseData "${_tokenId}" "${_monitorType}" _testStatus _tTime _rTime _sName
      # If getResponseData failed, close the feed!, so do not bother checking for the return status. If failed will try the next site anyway.

      debug "${_func}:testStatus:${_testStatus}:tTime:${_tTime}:rTime:${_rTime}:sName:${_sName}"
      # _testStatus = 0 - TRUE Test executed OK; 1 - FALSE Cannot retreive data from Compuware; 2 - Retreived data but test FAILED; 3 - Returned no data; 4 - Retreived eStatus is not STATUS_SUCCESS

      # Inject values to the calling function
      eval "$5=\$_testStatus"
      eval "$6=\$_tTime"
      eval "$7=\$_rTime"
      eval "$8=\$_sName"

      case "${_testStatus}" in
         "${TRUE}") 
            foo="";;

         "${FALSE}") 
            info " ${_func}:openDataFeed3 failed to retreive data from Compuware.";;

         "2") 
            info " ${_func}:openDataFeed3 test executed but partly failed.";;

         "3") 
            info " ${_func}:openDataFeed3 no data for the mid and siteId combination.";;

         "4") 
            info " ${_func}:openDataFeed3 eStatus is not STATUS_SUCCESS.";;

         *)
            _testStatus=5;
            info " ${_func}:openDataFeed3 FAILED - CHECK _testStatus returned unexpected value.";;
      esac

      closeDataFeed "${_tokenId}"
      [ ${?} -ne ${TRUE} ] && { info "  ${_func}:Failed to closeDataFeed, exiting..."; exit ${FALSE}; }
   fi

   return ${_testStatus}
}

checkSiteConfigured ()
{
   local _func=${_program:-BASH}.checkSiteConfigured
   local _ret=${FALSE}

   if [ ${#} -ne 4 ]
   then
      cat << EOF

Run as:
${_func} login mid siteId monitorType

This function returns TRUE/FALSE if the siteId is configured for the mid.

EOF
      return ${FALSE}
   fi

   local _login="${1}"
   local _mid=${2}
   local _siteId=${3}
   local _monitorType="${4}"

   local _passwd=$(getPasswordForLogin "${_login}")
   [ "%${_login}%" = "%%" ] || [ "%${_passwd}%" = "%%" ] && { info "${_func}:loginName:${_login}:passwd is blank, exiting..."; exit ${FALSE} ; }

   local _retOpenDataFeed3

   debug "${_func}"
   debug "${_func}:Checking if site is configured for loginName:${_login}:mid:${_mid}:siteId:${_siteId}:monitorType:${_monitorType}..."

   openDataFeed3 "${_login}" ${_mid} ${_siteId} "${_monitorType}" _tokenId
   _retOpenDataFeed3=${?}
   debug  "${_func}:_retOpenDataFeed3:${_retOpenDataFeed3}:ERROR_MAX_NUMBER_OF_CONCURRENT_SESSIONS_EXCEEDED:${ERROR_MAX_NUMBER_OF_CONCURRENT_SESSIONS_EXCEEDED}:"
   if [ ${_retOpenDataFeed3} -eq ${ERROR_MAX_NUMBER_OF_CONCURRENT_SESSIONS_EXCEEDED} ]
   then # openDataFeed3
      debug "${_func}:Sleeping 15s and will retry openDataFeed3..."
      sleep ${WAIT_ON_ERROR_MAX_NUMBER_OF_CONCURRENT_SESSIONS_EXCEEDED}
       openDataFeed3 "${_login}" ${_mid} ${_siteId} "${_monitorType}" _tokenId
      _retOpenDataFeed3=${?}
	fi  

   if [ ${_retOpenDataFeed3} -ne ${TRUE} ]
   then # openDataFeed3
      if [ ${_retOpenDataFeed3} -eq ${ERROR_MAX_NUMBER_OF_CONCURRENT_SESSIONS_EXCEEDED} ]
      then
         info "${_func}:mid:${_mid}:monitorType:${_monitorType}:siteId:${_siteId}: Maximum Number of Concurrent Sessions Exceeded."
      else
         debug "${_func}:mid:${_mid}:monitorType:${_monitorType}, is not executed from siteId:${_siteId}."
      fi
   else # openDataFeed3 for LM/PM
       getResponseData "${_tokenId}" "${_monitorType}" _testStatus _tTime _rTime _sName
#Following is for debugging only:
# _testStatus=0
# _tTime='2015-04-21 11:50:59'
# _rTime=12
# _sName="Foo"

      # If getResponseData failed, close the feed!, so do not bother checking for the return status. If failed will try the next site anyway.

      debug "${_func}:testStatus:${_testStatus}:tTime:${_tTime}:rTime:${_rTime}:sName:${_sName}"
      # _testStatus = 0 - TRUE Test executed OK; 1 - FALSE Cannot retrieve data from Compuware; 2 - Retrieved data but test FAILED; 3 - Returned no data; 4 - Retrieved eStatus is not STATUS_SUCCESS

      if [ ${_testStatus} -eq 0 ] || [ ${_testStatus} -eq 2 ]
      then
            # If the last test from the Site was executed more than 3 days ago, do not include assume Site is not in APMaaS Portal configuration. WebService API for PLM tests is not complete and we are poking here...
            
			# rTime is in UTC
			# Our offset is: ${TIMEZONE_OFFSET}, add that to rTime to get it in our time zone. That way we will be able to compare and calculate the distance.
			#local _dt=$(date -d "${_dt} +${TIMEZONE_OFFSET} seconds")
			#debug "${_func}:nowEpoch:${_nowEpoch} with local time zone offset adjusted"
#			local distance=$(dtInSec_FromNowTillUTCDateTime "${_tTime}" 'dmy')
			local distance=$(dtInSec_FromNowTillUTCDateTime "${_tTime}" 'ymd')
			debug "${_func}:Original rTime:${_tTime}:distance from NOW:${distance}, seconds."
			
            if [ ${distance} -lt ${DISTANCE_TEST_EXECUTED_FROM_SITE_TO_IGNORE} ]
            then
               _ret=${TRUE}
            else
				debug "${_func}:Ignoring the Site:${_sName}, as the last test was not executed within ${DISTANCE_TEST_EXECUTED_FROM_SITE_TO_IGNORE} seconds."
               _ret=${FALSE}
            fi

      else
            _ret=${FALSE}
      fi

      debug "${_func}:mid:${_mid}:monitorType:${_monitorType}, executed from siteId:${_siteId}:${_ret}."
      closeDataFeed "${_tokenId}"
   fi

   return ${_ret}
}

getLocationUsage ()
{
   local _func=${_program:-BASH}.locationUsage
   local _locationUsageAbsoluteName _locationUsageAbsoluteNameTmp

   for _BB_PLM in ${BB_PLM}
   do
      unset _values
      declare -A _values
      _locationUsageAbsoluteName="$(getLocationUsageAbsoluteName "${_BB_PLM}")"
      _locationUsageAbsoluteNameTmp="$(getLocationUsageAbsoluteNameTmp "${_BB_PLM}")"

      # while IFS='|' read key
      # do
        # _sort[${_i}]="${key}"
        # _i=$((_i+1))
      # done < <(cat "A${APMaaS_CHECK_ABSOLUTE_NAME}${APMaaS_CHECK_ABSOLUTE_NAME}" | grep "${_BB_PLM}" | awk -F"${separator}" '{print $6}' | sort -t'|' -u -k1,1)

      while IFS="${separator}" read key value
      do
         _values["$key"]=$(( $value + ${_values[$key]:-0} ))
      done < <(cat "${APMaaS_CHECK_ABSOLUTE_NAME}" | grep "${_BB_PLM}" | awk -F"${separator}" -v _separator="${separator}" '{print $6 _separator $8}' | sort -t"${separator}" -k1,1)

      # while IFS="${separator}" read key value
      # do
      # echo "$key" + 
        # _values[$key]=$(( $value + ${_values[$key]:-0} ))
        # echo $value + $key
      # done < <(cat "${APMaaS_CHECK_ABSOLUTE_NAME}" | grep "${_BB_PLM}" | awk -F"${separator}" -v _separator="${separator}" '{print $6 _separator $8}' | sort -t"${separator}" -k1,1)

      # _arrayNoElements=${_i}
      # for ((_i=0;_i<${_arrayNoElements};_i++)) do
         # key="${_sort[${_i}]}"
         # _values[${key}]=$(awk -v values=${_values[${key}]} -v ms2sec=1000 'BEGIN {printf "%.2f \n", ( ( values / ms2sec ) / 60 ) }')
         # printf "%s %s\n" "${key}"${separator}"${_values[${key}]}" >> "${_locationUsageAbsoluteName}"
      # done

      > "${_locationUsageAbsoluteNameTmp}"
      for key in "${!_values[@]}"; do
         _values["${key}"]=$(awk -v values=${_values["${key}"]} -v ms2sec=1000 'BEGIN {printf "%.2f \n", ( ( values / ms2sec ) / 60 ) }')
         echo "${key}${separator}${_values["${key}"]}" >> "${_locationUsageAbsoluteNameTmp}"
      done
      
      cat "${_locationUsageAbsoluteNameTmp}" | sort -t"${separator}" -r -n -k2,2 > "${_locationUsageAbsoluteName}"
      rm -f "${_locationUsageAbsoluteNameTmp}"
   done
}

mainAPMaaSCheck ()
{
   local _func=${_program:-BASH}.mainAPMaaSCheck
   local _ret=${FALSE}

   if [ ${#} -ne 1 ]
   then
      cat << EOF

Run as:
${_func} loginName

This function populates log file with the latest performance data from APMaaS.

EOF
      return ${FALSE}
   fi

   local _login="${1}"
   
   info "${_func}:Downloading the latest Dynatrace APMaaS performance test data for all tests configured for login ${_login}. Time is in UTC."

   local i=0
   
   local accountId=$(getAccountIdForLogin "${_login}")
   local accountName=$(getAccountNameForLogin "${_login}")

   local _passwd=$(getPasswordForLogin "${_login}")
   [ "%${_login}%" = "%%" ] || [ "%${_passwd}%" = "%%" ] && { info "${_func}:loginName:${_login}:passwd is blank, exiting..."; exit ${FALSE} ; }

   init "${_login}"
   MATRIX_getRowAccountId "${accountId}" iAccount
	   
   MATRIX_getColForHeader "testsLocations" jtestsLocations || { info "${_func}:Not found MATRIX header with title testsLocations, exiting..."; exit ${FALSE} ; }
   MATRIX_getColForHeader "ok" jok || { info "${_func}:Not found MATRIX header with title ok, exiting..."; exit ${FALSE} ; }
   MATRIX_getColForHeader "failed" jfailed || { info "${_func}:Not found MATRIX header with title failed, exiting..."; exit ${FALSE} ; }
   MATRIX_getColForHeader "backBone" jBackBone || { info "${_func}:Not found MATRIX header with title backBone, exiting..."; exit ${FALSE} ; }
   MATRIX_getColForHeader "lastMile" jLastMile || { info "${_func}:Not found MATRIX header with title lastMile, exiting..."; exit ${FALSE} ; }
   MATRIX_getColForHeader "privateLastMile" jPrivateLastMile || { info "${_func}:Not found MATRIX header with title privateLastMile, exiting..."; exit ${FALSE} ; }

   local morningCheckLog="$(getAPMaaSCheckAbsoluteName "${accountName}")"
   local morningCheckLogTmp="$(getAPMaaSCheckAbsoluteNameTmp "${accountName}")"
   echo "AccountId${separator}AccountName${separator}monitorType${separator}statusDesignator${separator}testDesc${separator}nodeName${separator}testTimeExecution${separator}testPerformanceTime${separator}APMaaS_Result${separator}testID${separator}locationID" > "${morningCheckLogTmp}"
   
   info "${_func}:Updating monitoring test data for the child account login:${_login}"

   while read lineX
   do
	   i=$((i+1))
	   
	   _accountIdTmp=$(awk -F"${separator_II}" '{print $1}' <<< "${lineX}")
	   if [ ${_accountIdTmp} -eq ${accountId} ] # Get Test data only for the requested login/accountId
	   then
		  # accountName=$(awk -F"${separator_II}" '{print $2}' <<< "${lineX}") # We already have accountName
	      monitorType=$(awk -F"${separator_II}" '{print $3}' <<< "${lineX}")
	      mid=$(awk -F"${separator_II}" '{print $4}' <<< "${lineX}")
	      desc=$(awk -F"${separator_II}" '{print $5}' <<< "${lineX}")
	      siteId=$(awk -F"${separator_II}" '{print $6}' <<< "${lineX}")
	      siteName=$(awk -F"${separator_II}" '{print $7}' <<< "${lineX}")
	      warningThreshold=$(awk -F"${separator_II}" '{print $8}' <<< "${lineX}")
	      severeThreshold=$(awk -F"${separator_II}" '{print $9}' <<< "${lineX}")

	      MATRIX[${iAccount},${jtestsLocations}]=$((${MATRIX[${iAccount},${jtestsLocations}]}+1))

		   case "${monitorType}" in
			  "UTATX") MATRIX[${iAccount},${jBackBone}]=$((${MATRIX[${iAccount},${jBackBone}]}+1));;
			  "LM_MONITOR"|"LASTMILE") MATRIX[${iAccount},${jLastMile}]=$((${MATRIX[${iAccount},${jLastMile}]}+1));;
			  "PRIVATEPEER") MATRIX[${iAccount},${jPrivateLastMile}]=$((${MATRIX[${iAccount},${jPrivateLastMile}]}+1));;
			  *) info "${_func}:CRITICAL ALERT:Failed to understand monitorType:${monitorType}, exiting..."; exit ${FALSE};;
		   esac

		   info " ${_func}:Processing Test:accountId:${accountId}:accountName:${accountName}:statusDesignator:${statusDesignator}:mid:${mid}:monitorType:${monitorType}:desc:${desc}:siteId:${siteId}:siteName:${siteName}"

		   getData "${_login}" ${mid} ${siteId} "${monitorType}" testStatus tTime rTime sName

		   debug "${_func}:testStatus:${testStatus}:tTime:${tTime}:rTime:${rTime}:sName:${sName}"

		   if [ ${testStatus} -eq ${TRUE} ]
		   then
			  CMPLTD='OK'
			  MATRIX[${iAccount},${jok}]=$((${MATRIX[${iAccount},${jok}]}+1))
		   else
			  CMPLTD='KO'
			  MATRIX[${iAccount},${jfailed}]=$((${MATRIX[${iAccount},${jfailed}]}+1))
		   fi
		##########
		   echo "${accountId}${separator}${accountName}${separator}${monitorType}${separator}${statusDesignator}${separator}${desc}${separator}${siteName}${separator}${tTime}${separator}${rTime}${separator}${CMPLTD}${separator}${mid}${separator}${siteId}" >> "${morningCheckLogTmp}"
		##########
		   debug "${_func}:${CMPLTD}:${tTime}:${rTime}:${desc}:${sName}"

		   # [ ${DEBUG} = ${TRUE} ] && read -p "Press any key to continue..."
		fi
	done < <(cat "$( getAPMaaSConfigAbsoluteName "${accountName}")")
	mv "${morningCheckLogTmp}" "${morningCheckLog}"

   debug "${_func}:Recording test summary for the account:${accountName}..."
   local _summary=""
   local _headerSummary=""
   for ((j=1;j<=${MATRIX_COLS};j++)) do
      _headerSummary="${_headerSummary}""${MATRIX_HEADER[${j}]}""${separator}"
      _summary="${_summary}""${MATRIX[${iAccount},${j}]}""${separator}"
   done	
   echo "${_headerSummary}"timeStamp > "$(getAPMaaSCheckSummaryAbsoluteName "${accountName}")"
   echo "${_summary}"$(dt 4) >> "$(getAPMaaSCheckSummaryAbsoluteName "${accountName}")"
   
   info "${_func}:Creating HTML Test Summary for the child account login:${_login}"
   htmlTable_AccountsStatus "${_login}"
}

mainGetAPMaaSConfig ()
{
   local _func=${_program:-BASH}.mainGetAPMaaSConfig
   if [ "$#" -ne 1 ]
   then
      cat << EOF

Run as: ${_func} Gomezlogin 

This script generates configuration file for all tests for the requested Gomez Login, and stores results into: $(getAPMaaSConfigAbsoluteName accountName)
Exiting...

EOF
      return ${FALSE}
   fi

   local _login="${1}"

   local accountId accountName
   init "${_login}"

   debug "${_func}:Getting Test Configuration for loginName:${_login}..."

   getAccountIdNameFromLogin "${_login}" accountId accountName
   [ ${?} -ne ${TRUE} ] && { info "${_func}:Failed to getAccountIdNameFromLogin for ${_login}, exiting..."; exit ${FALSE}; }
   info "${_func}:Getting configuration for all tests for accountId:${_accountId}:accountName:${_accountName}:..."

   local _passwd=$(getPasswordForLogin "${_login}")
   [ "%${_login}%" = "%%" ] || [ "%${_passwd}%" = "%%" ] && { info "${_func}:loginName:${_login}:passwd is blank, exiting..."; exit ${FALSE} ; }

   local APMaaSConfigAbsoluteName="$(getAPMaaSConfigAbsoluteName "${accountName}")"
   touch "${APMaaSConfigAbsoluteName}" # If account has no tests, at least create an empty configuration file. Without this, there will be no config for the account.

   getConfig_Thresholds "${_login}"
   [ ${?} -ne ${TRUE} ] && { info "${_func}:Failed to getConfig_Thresholds for ${_login}, exiting..."; exit ${FALSE}; }

   getAccountPopulationsData "${_login}"
   [ ${?} -ne ${TRUE} ] && { info "${_func}:Failed to getAccountPopulationsData for ${_login}, exiting..."; exit ${FALSE}; }

   getMonitorData "${_login}"
   [ ${?} -ne ${TRUE} ] && { info "${_func}:Failed to getMonitorData for ${_login}, exiting..."; exit ${FALSE}; }

   local monitorFile=$(getAccountMonitors2AbsoluteName "${accountName}")

   local monitor=${FALSE}
   local batchgroupmonitor=${FALSE}
   local monitorSitesAbsoluteName monitorSitesAbsoluteNameTmp
   local account class desc id line mid populationMonitorType siteId siteName status threshold
   local vtest_PM=0
   local vtest_BB=0
   local vtest_LM=0

   local AccountPopulations="$(getAccountPopulationsAbsoluteName "${accountName}")"
   local APMaaSConfigAbsoluteNameTmp="$(getAPMaaSConfigAbsoluteNameTmp "${accountName}")"
   > "${APMaaSConfigAbsoluteNameTmp}"

   info "${_func}:Assembling test configuration for the child account login:${_login} into ${APMaaSConfigAbsoluteName}."

   while read lineX
   do
      id=${FALSE}

      # We are looking for three lines:
      #    1. Monitor - has all info for BB
      #    2. BatchGroupMonitorIds and 3. Id to get mid for LM/PM tests
      #
      line=`echo "${lineX}" | grep "\<Monitor " | sed 's/\"/\\"/g'`
      
      echo "${lineX}" | grep "\<Monitor " > /dev/null 2>&1
      if [ ${?} -eq ${TRUE} ]
      then # Monitor
         # Process Monitor line. This line has all info, except for LM/PM tests where mid is wrong and we have to get it from BatchGroupMonitorIds + Id
         monitor=${TRUE}
         batchgroupmonitor=${FALSE}
         id=${FALSE}

         account=$(awk -F'=' '{print $7}' <<< "${line}" | awk -F'"' '{print $2}')
         class=$(awk -F'=' '{print $5}' <<< "${line}" | awk -F'"' '{print $2}')

         case "${class}" in
            "PP_MONITOR"|"PP_TRANSACTION") monitorType="PRIVATEPEER"; vtest_PM=$((vtest_PM+1));;
            "TRANSACTION") monitorType="UTATX"; vtest_BB=$((vtest_BB+1));;
            "LM_MONITOR"|"LM_TRANSACTION") monitorType="LASTMILE"; vtest_LM=$((vtest_LM+1));;
            *) monitorType="UNKNOWN"; info "${_func}:CRITICAL ALERT:Failed to understand class:${class}, exiting..."; exit ${FALSE};;
         esac

         status=$(awk -F'=' '{print $6}' <<< "${line}" | awk -F'"' '{print $2}')
         mid=$(awk -F'=' '{print $2}' <<< "${line}" | awk -F'"' '{print $2}')
         desc=$(awk -F'=' '{print $3}' <<< "${line}" | awk -F'"' '{print $2}')
         debug "${_func}:Processing Test:account:${account}:accountName:${accountName}:class:${class}:status:${status}:mid:${mid}:desc:${desc}"

         threshold=$(getThresholds "${accountName}" ${mid})

        if [ "${class}" = "TRANSACTION" ]
         then # TRANSACTION
      
            # For BackBone tests, we are ready to download data
            getConfig_Site "${_login}" ${mid}
            if [ ${?} -eq ${TRUE} ]
            then # getConfig_Site
               monitorSitesAbsoluteName="$(getMonitorSitesAbsoluteName "${accountName}" ${mid})"

               while read line
               do
                  siteId=$(awk -F"${separator_II}" '{print $1}' <<< "${line}")
                  siteName=$(awk -F"${separator_II}" '{print $2}' <<< "${line}")

                  echo "${accountId}${separator_II}${accountName}${separator_II}${monitorType}${separator_II}${mid}${separator_II}${desc}${separator_II}${siteId}${separator_II}${siteName}${separator_II}${threshold}" >> "${APMaaSConfigAbsoluteNameTmp}"
               done < <(cat "${monitorSitesAbsoluteName}")
            else  # getConfig_Site, Found no Sites for the test
               debug "${_func}:No site found for this test."
            fi # getConfig_Site
         else # TRANSACTION, this is not a TRANSACTION, we cannot download data without Population Id, which, if there is one, it is one the next lines. So we are done with this line then.
            debug "${_func}:This line is not TRANSACTION BackBone test. For LM and PLM we need to swap mid with Id listed few lines below. Skipping this line and looking for the LM/PM Batch Id..."
         fi # TRANSACTION
     
      else  # Monitor, below we process non Monitor line for LM/PM to get Population Id
         if [ "${class}" = "LM_TRANSACTION" ] || [ "${class}" = "LM_MONITOR" ] || [ "${class}" = "PP_TRANSACTION" ] || [ "${class}" = "PP_MONITOR" ]
         then
            debug "${_func}:Previous line was LAST or PRIVATE mile, not a TRANSACTION."
            if [ ${monitor} -eq ${TRUE} ]
            then
               monitor=${FALSE}
               debug "${_func}:Check if this line is BatchGroupMonitorIds..."
               echo "${lineX}" | grep "\<BatchGroupMonitorIds>" > /dev/null 2>&1
               if [ ${?} -eq ${TRUE} ]
               then
                  batchgroupmonitor=${TRUE}
                  debug "${_func}:This line is BatchGroupMonitor. Continue searching for mid. Let's see if the next line contains the Id and get data for it..."
               fi
            else
               if [ ${batchgroupmonitor} -eq ${TRUE} ]
               then
                  debug "${_func}:Previous line was BatchGroupMonitorIds, check if this line is Id..."
                  # We will take care only of the very first Id and ignore the rest, so reset BatchGroupMonitorIds
                  batchgroupmonitor=${FALSE}
                  echo "${lineX}" | grep "\<Id>" > /dev/null 2>&1
                  if [ ${?} -eq ${TRUE} ]
                  then
                     id=${TRUE}
                     mid=$(grep '\<Id>' <<< "${lineX}" | cut -d'>' -f2 | cut -d'<' -f1)
                     debug "${_func}:Found Monitoring Batch Id for LM/PM, changing mid to:${mid}."

                 threshold=$(getThresholds "${accountName}" ${mid})

                 monitorSitesAbsoluteName=$(getMonitorSitesAbsoluteName "${accountName}" ${mid})
                 monitorSitesAbsoluteNameTmp=$(getMonitorSitesAbsoluteNameTmp "${accountName}" ${mid})
                     debug "${_func}:Creating PLM config file for mid:${mid}, ${monitorSitesAbsoluteName}..."
                 
                     > "${monitorSitesAbsoluteNameTmp}"
                     debug "${_func}:Generating temp PLM config file to minimize issues running other functions in parallel, ${monitorSitesAbsoluteNameTmp}..."

                     # Loop through all LM nodes (populations) looking for data, select only PLM
                     while read measurementLine
                     do
                         populationMonitorType=`echo "${measurementLine}" | awk -F${separator_II} '{print $3}'`
                         siteId=`echo "${measurementLine}" | awk -F${separator_II} '{print $4}'`
                         siteName=`echo "${measurementLine}" | awk -F${separator_II} '{print $5}'`

                         debug "${_func}"
                    debug "${_func}:checkSiteConfigured:mid:${mid}:siteId:${siteId}:monitorType:${monitorType}:populationMonitorType:${populationMonitorType}:siteName:${siteName}"
                   
                         if [ "${monitorType}" = "PRIVATEPEER" ] && [ ${populationMonitorType} = 'PLM' ] 
                         then
                           checkSiteConfigured "${_login}" ${mid} ${siteId} "${monitorType}"
                           if [ ${?} -eq ${TRUE} ]
                           then
                               debug "${_func}:checkSiteConfigured:${TRUE}:siteName:${siteName}"

                         echo "${siteId}"${separator_II}"${siteName}" >> "${monitorSitesAbsoluteNameTmp}"
                               echo "${accountId}${separator_II}${accountName}${separator_II}${monitorType}${separator_II}${mid}${separator_II}${desc}${separator_II}${siteId}${separator_II}${siteName}${separator_II}${threshold}" >> "${APMaaSConfigAbsoluteNameTmp}"
                           else
                               debug "${_func}:checkSiteConfigured:${FALSE}:${siteName}"
                           fi
                         fi
                     done < <(grep "^${accountId}${separator_II}" "${AccountPopulations}" | grep ${PRIVATE_PEER_NETWORK_ID}) # We do not have LM / MBL tests, grep only PLM locations, to get all types use: ###               done < <(grep "^${accountId}:" "${AccountPopulations}")
                 
                     debug "${_func}:Refreshing PLM config file for mid:${mid}, ${monitorSitesAbsoluteName}"
                 mv "${monitorSitesAbsoluteNameTmp}" "${monitorSitesAbsoluteName}"
                  else
                     debug "${_func}:No site found for the test mid:${mid}."
                  fi

               else
                  debug "${_func}:Previous line was not BatchGroupMonitorIds, since we process only the first Id for LM/PM, skipping this line..."
               fi
            fi # Processed line for BatchGroupMonitorIds nor Id
         fi # Last test we found was LM/PP
      fi  # Monitor, processed test line for all three posibilites: Monitor, BatchGroupMonitorIds and Id

   debug "${_func}:Summary of the line we just processed:monitor=${monitor},batchgroupmonitor=${batchgroupmonitor},id=${id}."
   done < <(cat "${monitorFile}")

   sort -t'|' -k3,3 -k5,5 -k7,7 "${APMaaSConfigAbsoluteNameTmp}" > "${APMaaSConfigAbsoluteName}"
   rm -f "${APMaaSConfigAbsoluteNameTmp}"
}

### APMaaS_Functions:The End ###
