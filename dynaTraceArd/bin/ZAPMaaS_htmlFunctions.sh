HTML_INDEX='/cygdrive/c/Apache/htdocs/index.html'
APMaaS_HTML_CHART_CONFIG="${configDir}/Charts/${myName}.chart.cfg"

HTML_HEADER="${htmlDir}/HTML_HEADER.html"
HTML_BODY_TABS="${htmlDir}/HTML_BODY_TABS.html"
HTML_BODY_TABLE="${htmlDir}/HTML_BODY_TABLE.html"
HTML_BODY_END="${htmlDir}/HTML_BODY_END.html"

HTML_BODY_TABSTmp="${tmpDir}/HTML_BODY_TABS.${dateTime}.${$}.tmp"
HTML_BODY_TABLETmp="${tmpDir}/HTML_BODY_TABLE.${dateTime}.${$}.tmp"

HTML_PLM_AGENT_STATUS="${htmlDir}/HTML_PLM_AGENT_STATUS.html"
HTML_PLM_AGENT_STATUSTmp="${tmpDir}/HTML_PLM_AGENT_STATUS.${dateTime}.${$}.tmp"

HTML_TEST_STATUS="${htmlDir}/HTML_TEST_STATUS.html"
HTML_TEST_STATUSTmp="${tmpDir}/HTML_TEST_STATUS.${dateTime}.${$}.tmp"

HTML_ACCOUNTS_SUMMARY="${htmlDir}/HTML_ACCOUNTS_SUMMARY.html"
HTML_ACCOUNTS_SUMMARYTmp="${tmpDir}/HTML_ACCOUNTS_SUMMARY.${dateTime}.${$}.tmp"

HTML_COLOR_TEST_OK='class="cellOk"'
HTML_COLOR_TEST_WARNING='class="cellWarning"'
HTML_COLOR_TEST_SEVERE='class="cellSevere"'
HTML_COLOR_TEST_FAILED='class="cellFailed"'
HTML_COLOR_TEST_THRESHOLD_MISSING='class="cellGrey"'

HTML_EMAIL=$(cat << EOF
<div class="cellSevereEmail">
<span title="Send Email to Desktop Owner"><a id="box-link"  href="mailto:REPLACE_TO?cc=${HTML_EMAIL_ADDRESS};REPLACE_CC&amp;subject=REPLACE_SUBJECT&amp;body=Hello%2C%0A%0AThe%20reason%20for%20this%20email%20is%20to%20inform%20you%20that%20we%20cannot%20connect%20to%20the%20PLM%20client%20installed%20on%20computer%20%22REPLACE_COMPUTER%22.%0A%0AIt%20seems%20that%20this%20computer%20is%20not%20available%20since%20%E2%80%9CREPLACE_DATETIME%20CET%22.%0A%0AI'd%20appreciate%20if%20you%20could%20follow%20up%20on%20this%20note%2C%20and%20if%20necessary%20proceed%20to%20re-start%20it%20so%20that%20the%20PLM%20becomes%20operational%20again.%0A%0AWe%20are%20looking%20forward%20to%20hearing%20from%20you.%0A%0ARegards%2C"></a></span></div>
EOF
)

### Functions ###
htmlHeader_01a ()
{
#		<meta http-equiv="refresh" content="60" > 

   cat << EOF > "${HTML_HEADER}"
<!DOCTYPE html>
<html lang="en">
    <head>
		<meta charset="UTF-8" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"> 
        
        <title>${HTML_HEADER_COMPANY} Application e2e Monitoring - Synthetic Web</title>
        
        <meta name="viewport" content="width=device-width, initial-scale=1.0"> 
        <meta name="description" content="APMaaS" />
        <meta name="keywords" content="APMaaS Dashboard" />
        <meta name="author" content="Codrops" />
        <link rel="shortcut icon" href="../favicon.ico"> 

		<link rel="stylesheet" type="text/css" href="css/demo.css" />
        <link rel="stylesheet" type="text/css" href="css/style.css" />
		<link rel="stylesheet" type="text/css" href="css/table.css">
		<script type="text/javascript" src="js/modernizr.custom.29473.js"></script>
		
		<style>	
		.cellRed {
			font-weight:bold;
			background:rgba(210,255,82,1);
		}

		.cellAmber { 
			font-weight:bold;
			background: url(../images/Warning.png) rgba(255,175,75,1) no-repeat right center;
		}
		.cellOk { 
			font-weight:bold;
			background: url(../images/circle_green.png) rgba(210,255,82,1) no-repeat right center;
		}
		.cellGrey { 
			font-weight:bold;
			color:red;
			background:url(../images/circle_green.png) rgba(215, 215, 196, 1) no-repeat right center;
		}
		.cellWarning { 
			font-weight:bold;
			background: url(../images/circle_green.png) rgba(255,175,75,1) no-repeat right center;
		}
		.cellSevere { 
			font-weight:bold;
			background: url(../images/circle_green.png) rgba(248,80,50,1) no-repeat right center;
		}
		.cellFailed {
			font-weight:bold;
			color:white;
			background: url(../images/circle_red.png) rgba(76,76,76,1) no-repeat right center;
		}

		.cellSevereEmail { 
			position: relative; 
			font-weight:bold;
			background: url(../images/icon_send_on.gif) rgba(248,80,50,1) no-repeat right center; 
		}
		#box-link { 
			position: absolute; 
			top: 0px; 
			right: 0px; 
			width: 15px; 
			height: 15px; 
			background-color: transparent; 
			border: 1px solid #F84D32; 
		}
		</style>		
	
    </head>
    <body>
        <div class="container">
			<!-- Codrops top bar -->
            <div class="codrops-top">
                <span class="right">
					<a href="${HTML_HEADER_TITLE_URL}" target="_blank">${HTML_HEADER_TITLE}</a>
                    <a href="${HTML_HEADER_COMPANY_URL}" target="_blank">
                        <strong>${HTML_HEADER_COMPANY}</strong>
                    </a>
                </span>
                <div class="clr"></div>
            </div><!--/ Codrops top bar -->
			<header>
				<h1>${HTML_TITLE_LEFT} <span>${HTML_TITLE_RIGHT}</span></h1>
				<h2>${HTML_SUBTITLE}</h2>
			</header>
			<section class="ac-container">

EOF
}

htmlBodyTables_03a ()
{
   local morningHtmlTestStatus
   local jAccountName
   MATRIX_getColForHeader accountName jAccountName
   # Other tabs are for each child account; add 2 for the previous two tabs (PLM AGENT STATUS, TEST LOCATION SUMMARY)
   local _firstTabs
   
   declare -a _Atitles=('Accounts Summary' 'PLM Agents Status' 'Backbone Location Usage' 'PLM Location Usage' 'Tests per Location')
   declare -a _Achecked=('checked' 'checked' '' '' '') # Check (open=) first two tables
   declare -a _Afiles=("${HTML_ACCOUNTS_SUMMARY}" "${HTML_PLM_AGENT_STATUS}" "$(getHtmlLocationUsageAbsoluteName UTATX)" "$(getHtmlLocationUsageAbsoluteName PRIVATEPEER)" "$(getHtmlLocationTestAbsoluteName)")

   # Define tab content here. Copy tables.
   cp /dev/null "${HTML_BODY_TABLETmp}"
   
   for _firstTabs in ${!_Atitles[*]}
   do
      cat << EOF >> "${HTML_BODY_TABLETmp}"
				<div>
					<input id="ac-${_firstTabs}" name="accordion-1" type="checkbox" ${_Achecked[${_firstTabs}]}/>
					<label for="ac-${_firstTabs}">${_Atitles[${_firstTabs}]}</label>
					<article class="ac-large">
EOF
      echo '<h3><br></h3>' >> "${HTML_BODY_TABLETmp}"
      cat "${_Afiles[${_firstTabs}]}" >> "${HTML_BODY_TABLETmp}"
      cat << EOF >> "${HTML_BODY_TABLETmp}"
                  <h3><br></h3>
					</article>
				</div>
EOF
   done
   _firstTabs=$((_firstTabs+1)) # Array _Atitles starts with 0, add 1 for the rest of tabs
   
   for ((i=0;i<=${MATRIX_ROWS};i++)) do
      cat << EOF  >> "${HTML_BODY_TABLETmp}"
				<div>
					<input id="ac-$((${i}+${_firstTabs}))" name="accordion-1" type="checkbox" />
					<label for="ac-$((${i}+${_firstTabs}))">${MATRIX[${i},${jAccountName}]}</label>
					<article class="ac-large">
EOF
      morningHtmlTestStatus=$(getHtmlTestStatusAbsoluteName "${MATRIX[${i},${jAccountName}]}")
      echo '<h3><br></h3>' >> "${HTML_BODY_TABLETmp}"
      cat "${morningHtmlTestStatus}" >> "${HTML_BODY_TABLETmp}"
      #cat "${HTML_TEST_STATUS}_${MATRIX[${i},${_matrixAccountNameCol}]}.html" >> "${HTML_BODY_TABLETmp}"
      cat << EOF >> "${HTML_BODY_TABLETmp}"  
                  <h3><br></h3>
					</article>
				</div>
EOF
   done
   mv "${HTML_BODY_TABLETmp}" "${HTML_BODY_TABLE}"
}

htmlBodyEnd_04a ()
{
   cat << EOF > "${HTML_BODY_END}"

			</section>
        </div>

    </body>
</html>
EOF
}

htmlTable_PLMAgentStatus ()
{
   local _func=${_program:-BASH}.htmlTable_PLMAgentStatus
   local _totalPLMAgents=0
   local PLMCountry PLMAgentComputer PLMAgentName PLMAgentID PLMLastCheckInUTC distance distance_minutes
   # Pick first login and get PLM agent status for it.
   local _login="$(head -n 1 ${PASSWD_COMPUWARE} | awk -F"${separator_II}" '{print $1}')"

   info "${_func}:Updating HTML table with PLM Agent Status..."

   getConfig_PlmAgents "${_login}"

   cat << EOF > "${HTML_PLM_AGENT_STATUSTmp}"
<h3 align="right" >$(dt 4)</h3>

<table class="bordered">
  <thead>
  <tr>
    <th>Country</th>
    <th>Computer</th>
    <th>Agent Name</th>
    <th>Agent ID</th>
    <th>Last Checkin in UTC</th>
    <th>Distance in minutes</th>
  </tr>
  </thead>
  
  <tbody>
EOF

   while read _line
   do
      PLMCountry=$(awk -F${separator} '{print $1}' <<< "${_line}")
      PLMAgentComputer=$(awk -F${separator} '{print $2}' <<< "${_line}")
      PLMAgentName=$(awk -F${separator} '{print $3}' <<< "${_line}")
      PLMAgentID=$(awk -F${separator} '{print $4}' <<< "${_line}")

      # Get PLMLastCheckIn and find the distance from NOW
      PLMLastCheckInUTC=$(awk -F${separator} '{print $5}' <<< "${_line}")
      distance=$(dtInSec_FromNowTillUTCDateTime "${PLMLastCheckInUTC}" 'mdy') # DateTime is in UTC + take into account summer TIME_OFFSET from the local NOW time, when calculating distance from the given time till NOW. Distance returned is in seconds.
      distance_minutes=$(( ${distance} / 60 )) # Convert seconds to minutes
      debug "${_func}:PLMLastCheckInUTC:${PLMLastCheckInUTC}:distance:$distance:HTML_PLM_CHECKIN_DISTANCE_TO_HIGHLIGHT:${HTML_PLM_CHECKIN_DISTANCE_TO_HIGHLIGHT}"

      cat << EOF >> "${HTML_PLM_AGENT_STATUSTmp}"
    <tr>
EOF

      echo "${PLMCountry}" | egrep "${HTML_PLM_COUNTRY_TO_HIGHLIGHT}" > /dev/null 2>&1
      if [ ${?} -eq ${TRUE} ]
      then
         echo "<td ${HTML_PLM_COUNTRY_TO_HIGHLIGHT_COLOR} > ${PLMCountry}</td>" >> "${HTML_PLM_AGENT_STATUSTmp}"
      else
         echo "<td> ${PLMCountry}</td>" >> "${HTML_PLM_AGENT_STATUSTmp}"
      fi

      cat << EOF >> "${HTML_PLM_AGENT_STATUSTmp}"
      <td><a href="http:rdp/${PLMAgentComputer}.rdp" target="_blank"><u>${PLMAgentComputer}</u></td>
      <td>${PLMAgentName}</td>
      <td>${PLMAgentID}</td>
      <td>${PLMLastCheckInUTC}</td>
      <td 
EOF

      _totalPLMAgents=$((_totalPLMAgents+1))

      if [ ${distance} -gt ${HTML_PLM_CHECKIN_DISTANCE_TO_HIGHLIGHT} ] # If PLM agent did not checked in in last 60 minutes, highlight
      then
         cat << EOF >> "${HTML_PLM_AGENT_STATUSTmp}"
       ${HTML_PLM_CHECKIN_DISTANCE_TO_HIGHLIGHT_COLOR} > `getDesktopAdminEmail "${PLMAgentComputer}" "${PLMLastCheckInUTC}"` ${distance_minutes} </td>
    </tr>
EOF
      else

   cat << EOF >> "${HTML_PLM_AGENT_STATUSTmp}"
            >${distance_minutes}</td>
    </tr>
EOF
      fi

   done < <(egrep -v 'PLMAgentName' "${PLM_AGENTS}")

   local _totalUniqueCountries=$(sort  -t${separator} -k1,1 -r -u "${PLM_AGENTS}" | wc -l)

   cat << EOF >> "${HTML_PLM_AGENT_STATUSTmp}"
  </tbody>
</table>
<a href="${HTML_PLM_MAP}" target="_new">* Click here to see ${HTML_HEADER_COMPANY} PLM Agents Map</a><br>
* Total Countries:${_totalUniqueCountries}, Total PLM Agents: ${_totalPLMAgents}. (Status updated once every 30 minutes)
<br>

EOF
   debug "${_func}:_totalUniqueCountries:${_totalUniqueCountries}:_totalPLMAgents:${_totalPLMAgents}."

   mv "${HTML_PLM_AGENT_STATUSTmp}" "${HTML_PLM_AGENT_STATUS}"
}

htmlTable_AccountsStatus ()
{
   local _func=${_program:-BASH}.htmlTable_AccountsStatus
   local _ret=${FALSE}

   if [ ${#} -ne 1 ]
   then
      cat << EOF

Run as:
${_func} loginName

This function creates a html table with the latest tests status.

EOF
      return ${FALSE}
   fi

   loginName="${1}"
   debug "${_func}:Making HTML table with Tests Status for login:${loginName}..."
   
   local accountId=$(getAccountIdForLogin "${loginName}")
   local accountName=$(getAccountNameForLogin "${loginName}")

   local morningCheckLog=$(getAPMaaSCheckAbsoluteName "${accountName}")
   local morningHtmlTestStatus=$(getHtmlTestStatusAbsoluteName "${accountName}")
   local morningHtmlTestStatusTmp=$(getHtmlTestStatusAbsoluteNameTmp "${accountName}")

   local _totalTests=0
   local _color distance

   cat << EOF > "${morningHtmlTestStatusTmp}"
<h3 align="right" >$(dt 4)</h3>
Note: PLM test configuration could contain obsolete PLM Population setup.
<br>

<table class="bordered">

  <tbody>
    <tr>
      <th>Account Name</th>
      <th>Monitor Type</th>
      <th>Test Execution in UTC Time </th>
      <th>Performance (ms)/Availability</th>
      <th>Test Description</th>
      <th>Location</th>
    </tr>
EOF

   local accountName monitorType testStatus testDescription nodeName testTimeExecution testPerformance testOkKo testID locationID _totalTest background
   local _totalUniqueTests=$(getTotalUniqueTestsForAccount "${loginName}")

   debug "${_func}:Making HTML for Table Test Status..."

   while read _line
   do
      accountId=`echo ${_line} | cut -d${separator} -f1`
      accountName=`echo ${_line} | cut -d${separator} -f2`
      monitorType=`echo ${_line} | cut -d${separator} -f3`
      testStatus=`echo ${_line} | cut -d${separator} -f4`
      testDescription=`echo ${_line} | cut -d${separator} -f5`
      nodeName=`echo ${_line} | cut -d${separator} -f6`
      testTimeExecution=`echo ${_line} | cut -d${separator} -f7 | tr '-' '/'`
      testPerformance=`echo ${_line} | cut -d${separator} -f8`
      testOkKo=`echo ${_line} | cut -d${separator} -f9`

      testID=`echo ${_line} | cut -d${separator} -f10`
      locationID=`echo ${_line} | cut -d${separator} -f11`

      _totalTests=$((_totalTests+1))

      cat << EOF >> "${morningHtmlTestStatusTmp}"
    <tr>
      <td>${accountName}</td>
      <td>${monitorType}</td>
EOF

      distance=$(dtInSec_FromNowTillUTCDateTime "${testTimeExecution}" ymd) # DateTime is in UTC + take into account summer TIME_OFFSET from the local NOW time, when calculating distance from the given time till NOW. Distance returned is in seconds.
      #distance_minutes=$(( ${distance} / 60 )) # Convert seconds to minutes
      debug "${_func}:testTimeExecution:${testTimeExecution}:distance:$distance:HTML_TEST_EXECUTION_DISTANCE_TO_HIGHLIGHT:${HTML_TEST_EXECUTION_DISTANCE_TO_HIGHLIGHT}"

      if [ ${distance} -gt ${HTML_TEST_EXECUTION_DISTANCE_TO_HIGHLIGHT} ] # If PLM agent did not checked in in last 4 hours, mark it RED
      then
         cat << EOF >> "${morningHtmlTestStatusTmp}"
      <td ${HTML_TEST_EXECUTION_DISTANCE_TO_HIGHLIGHT_COLOR}>${testTimeExecution}</td>
      <td align="center"
EOF
      else
         cat << EOF >> "${morningHtmlTestStatusTmp}"
      <td>${testTimeExecution}</td>
      <td align="center"
EOF
      fi

      if [ ${testOkKo} = 'KO' ] # If test failed, mark it RED
      then
         echo "${HTML_COLOR_TEST_FAILED} width='111'>Failed</td>" >> "${morningHtmlTestStatusTmp}"
      else
         declare -a arrayThresholds=( $(getThresholds "${accountName}" "${testID}"|sed "s/${separator_II}/ /g") );

         if [ ${testPerformance} -gt 0 ]
         then
           if [ ${testPerformance} -ge ${arrayThresholds[1]} ] && [ ${arrayThresholds[1]} -gt 0 ]
           then
             _color="${HTML_COLOR_TEST_SEVERE}"
           elif [ ${testPerformance} -ge ${arrayThresholds[0]} ] && [ ${arrayThresholds[0]} -gt 0 ]
           then
             _color="${HTML_COLOR_TEST_WARNING}"
           elif [ ${arrayThresholds[1]} -le 0 ] && [ ${arrayThresholds[0]} -le 0 ]
           then
             _color="${HTML_COLOR_TEST_THRESHOLD_MISSING}"
             else
            _color="${HTML_COLOR_TEST_OK}"
           fi
         else
           _color="${HTML_COLOR_TEST_FAILED}"	  
         fi

         debug "${_func}:accountName:${accountName}:testID:${testID}:testPerformance:${testPerformance}:warningThreshold:${arrayThresholds[0]}:severeThreshold:${arrayThresholds[1]}:color:${_color}"
      
         echo "${_color} width='111'>${testPerformance}</td>" >> "${morningHtmlTestStatusTmp}"
      fi

      cat << EOF >> "${morningHtmlTestStatusTmp}"
	  <td> <a href="`getPublicChart ${accountId} ${testID} ${locationID}`" target="_blank">${testDescription}</a></td>
      <td>${nodeName}</td>
    </tr>
EOF

      debug "${_func}:accountId:${accountId}:accountName:${accountName}:monitorType:${monitorType}:testTimeExecution:${testTimeExecution}:testPerformance:${testPerformance}:testOkKo:${testOkKo}:testID:${testID}:locationID:${locationID}."
   done < <(egrep -v 'AccountName' "${morningCheckLog}")

   cat << EOF >> "${morningHtmlTestStatusTmp}"
  </tbody>
</table>

* Total Tests: ${_totalUniqueTests}, listing all locations: ${_totalTests}. (Status updated once per hour. Configuration updated at midnight.)
EOF
   debug "${_func}:_totalUniqueTests:${_totalUniqueTests}:_totalTests:${_totalTests}."
   mv "${morningHtmlTestStatusTmp}" "${morningHtmlTestStatus}"
#echo "<br>We are experiencing technical issues with APMaaS Tests Status and will update this page as soon as possible.<br>" > "${HTML_ACCOUNTS_SUMMARY}"
}

htmlTable_TestSummary ()
{
   local _func=${_program:-BASH}.htmlTable_TestSummary
   local _ret=${FALSE}

   info "${_func}:Updating HTML table with Tests Summary..."
   
   cat << EOF > "${HTML_ACCOUNTS_SUMMARYTmp}"
<h3 align="right" >$(dt 4)</h3>

<table class="bordered">
  <thead>
  <tr>
    <th>Account ID</th>
    <th>Account Name</th>
    <th>Tests/Locations</th>
    <th>OK</th>
    <th>Failed</th>
    <th>Missing Data</th>
    <th>Backbone</th>
    <th>Last Mile</th>
    <th>Private Last Mile</th>
    <th>Time Stamp</th>
  </tr>
  </thead>
  
  <tbody>
EOF
   eval total=("$(printStringNoOfTimes '0 ' $((${MATRIX_COLS}+1)))") # Declare array to hold totals for each column and initialize it to zeros. Array has the same number of elements as MATRIX has number of columns.

   local _summary accountName loginName _totalUniqueTests
   local _totalAccounts=0
   local jtestsLocations=2 # Tests/Locations column, starting from zero in global "${MATRIX_HEADER}"
   local jFailed=4 # Failed column, starting from zero in global "${MATRIX_HEADER}"
   local _grandTotalNumberOfTests=0
   
   while read line
   do
      loginName=`echo ${line} | cut -d"${separator_II}" -f1`
      accountName=$(getAccountNameForLogin "${loginName}")
      _totalAccounts=$((_totalAccounts+1))
      debug "${_func}:accountName:${accountName}:_totalAccounts:${_totalAccounts}"
	  
      unset _accountSummary
      IFS="${separator}" read -a _accountSummary <<< "$( cat $(getAPMaaSCheckSummaryAbsoluteName "${accountName}") | grep -v accountName )"
		echo "<tr>" >> "${HTML_ACCOUNTS_SUMMARYTmp}"
		for ((j=0;j<=$((${#_accountSummary[@]}-1));j++)) do
			if [ ${j} -eq ${jFailed} ] && [ ${_accountSummary[$j]} -gt 0 ] # Column "Failed", make numbers with red background
			then
			   echo "<td ${HTML_COLOR_TEST_FAILED}>${_accountSummary[$j]}</td>" >> "${HTML_ACCOUNTS_SUMMARYTmp}"
			elif [ ${j} -eq ${jtestsLocations} ] # Column "Tests/Locations", count number of unique tests
			then
            _totalUniqueTests=$(getTotalUniqueTestsForAccount "${loginName}")
            _grandTotalNumberOfTests=$((${_grandTotalNumberOfTests}+${_totalUniqueTests}))
            echo "<td align='center'>${_totalUniqueTests}/${_accountSummary[$j]}</td>" >> "${HTML_ACCOUNTS_SUMMARYTmp}"
         else
            echo "<td align='center'>${_accountSummary[$j]}</td>" >> "${HTML_ACCOUNTS_SUMMARYTmp}"
			fi
			if [ ${j} -gt 1 ] # Skip first two no numbers columns: accountId"${separator}"accountName
            then
               if [ ${j} -ne $((${#_accountSummary[@]}-1)) ] # Skip the last no numbers column timeStamp
               then
                  total[${j}]=$(( ${total[${j}]}+${_accountSummary[${j}]} ))
				  debug "${_func}:accountName:${accountName}:total[${j}]:${total[${j}]}:_accountSummary[$j]:${_accountSummary[$j]}"
               fi
            fi
		done
   done < <(cat "${LOGIN_ACCOUNT_DIRECTORY}"/* | sort -t${separator} -k3,3) # Sort accounts by name
   
   echo "</tr>" >> "${HTML_ACCOUNTS_SUMMARYTmp}"
   echo "</tbody>" >> "${HTML_ACCOUNTS_SUMMARYTmp}"
	
   debug "${_func}:Building row with totals..."
   cat << EOF >> "${HTML_ACCOUNTS_SUMMARYTmp}"
<tfoot>
<td align='center'></td>
<th align='center'>Total</td>
<th align='center'>${_grandTotalNumberOfTests}/${total[2]}</td>
<th align='center'>${total[3]}</td>
<th align='center'>${total[4]}</td>
<th align='center'>${total[5]}</td>
<th align='center'>${total[6]}</td>
<th align='center'>${total[7]}</td>
<th align='center'>${total[8]}</td>
<td align='center'></td>
</tr>
</tfoot>
EOF

   cat << EOF >> "${HTML_ACCOUNTS_SUMMARYTmp}"
</table>

* Total Child Accounts: ${_totalAccounts}. (Status updated once per hour. Configuration updated at midnight.)

EOF
   mv "${HTML_ACCOUNTS_SUMMARYTmp}" "${HTML_ACCOUNTS_SUMMARY}"
   #echo "<br>We experience technical issues with APMaaS Tests Summary Status. We will update this page as soon as possible.<br>" > "${_HTML_SUMMARY}"

   info "${_func}: ${statusDesignator} tests summary: Total Tests/Locations:${_grandTotalNumberOfTests}/${total[2]}; OK:${total[3]}; Failed:${total[4]}; BackBone tests:${total[6]}; LastMile tests:${total[7]}; PrivateMile tests:${total[8]};"
}

getDesktopAdminEmail ()
{
   local _func=${_program:-BASH}.getDesktopAdminEmail
   if [ ${#} -ne 2 ]
   then
      cat << EOF

Run as:
${_func} computerName lastCheckIn

This function returns HTML for supplied Computer Name and the Last Time Computer checked in, to embed into a HTML page. When user clickes on the provided HTML link, user browser will automatically open an email program with requered information: mailTo, mailCC, mailSubject and mailBody.

EOF
      return ${FALSE}
   fi

   local _computerName="${1}"
   local _lastCheckIn="${2}"

   local _emailPrefix="${configDir}/PLM/Email/email"
   local _emailTOFile="${_emailPrefix}.TO.${_computerName}"
   local _emailCCFile="${_emailPrefix}.CC.${_computerName}"

   debug "${_func}:Returning Desktop Admin Email in HTML format..."

   if [ ! -f "${_emailTOFile}" ]; then
      echo "File ${_emailTOFile} not found! Create and populate the file, then retry..."
   else
      if [ ! -f "${_emailTOFile}" ]; then
         echo "File ${_emailTOFile} not found! Create and populate the file, then retry..."
      else
            local _emailReplaceTO=`cat "${_emailTOFile}"`
            local _emailReplaceCC=`cat "${_emailCCFile}"`
            local _emailReplaceSubject="${_computerName}"
            local _emailReplaceComputer="${_computerName}"
            local _emailReplaceDateTime=$(dt 5 "${_lastCheckIn}" mdy)

		    echo "${HTML_EMAIL}" | sed "s/REPLACE_TO/${_emailReplaceTO}/g" | sed "s/REPLACE_CC/${_emailReplaceCC}/g" | sed "s/REPLACE_SUBJECT/${_emailReplaceSubject}/g" | sed "s/REPLACE_COMPUTER/${_emailReplaceComputer}/g" | sed "s/REPLACE_DATETIME/${_emailReplaceDateTime}/g"
      fi
   fi
}

getPublicChart ()
{
   local _func=${_program:-BASH}.getPublicChart
   if [ ${#} -ne 3 ]
   then
      cat << EOF

Run as:
${_func} accountId testId locationId

This returns URL of the public chart for this test/location.

EOF
      return ${FALSE}
   fi

   local _accountId=${1}
   local _testId=${2}
   local _locationId=${3}

   debug "${_func}:Returning public APMKaaS chart for accountId:${_accountId}:testId:${_testId}:locationId:${_locationId}..."

   # URL is the last in the column
   grep "${_accountId}${separator_II}" "${APMaaS_HTML_CHART_CONFIG}" | grep "${separator_II}${_testId}${separator_II}" | grep "${separator_II}${_locationId}${separator_II}" | awk -F"${separator_II}" '{print $NF}'
}

listMissingPublicChart ()
{
   local _func=${_program:-BASH}.listMissingPublicChart
   local _line _accountId _accountName _testType _mid _midName _siteId _siteName _reportAbsoluteName

   info "${_func}:Listing missing public charts:"
   _reportAbsoluteName="$(getReportAbsoluteName "${_func}")"
   > "${_reportAbsoluteName}"
   
   while read _line
   do
      _accountId=$(awk -F"${separator}" '{print $1}' <<< "${_line}")
      _accountName=$(awk -F"${separator}" '{print $2}' <<< "${_line}")
      _testType=$(awk -F"${separator}" '{print $3}' <<< "${_line}")
      _mid=$(awk -F"${separator}" '{print $10}' <<< "${_line}")
      _midName=$(awk -F"${separator}" '{print $5}' <<< "${_line}")
      _siteId=$(awk -F"${separator}" '{print $11}' <<< "${_line}")
      _siteName=$(awk -F"${separator}" '{print $6}' <<< "${_line}")
	  
      debug "${_func}:Looking for accountId:${_accountId}:mid:${_mid}:siteId:${_siteId}:APMaaS_HTML_CHART_CONFIG:${APMaaS_HTML_CHART_CONFIG}"

      grep ${_accountId} "${APMaaS_HTML_CHART_CONFIG}" | grep ${_mid} | grep ${_siteId} > /dev/null 2>&1
      if [ $? -ne 0 ]
      then
         echo "${_accountId}${separator}${_accountName}${separator}${_testType}${separator}${_mid}${separator}${_midName}${separator}${_siteId}${separator}${_siteName}${separator}" >> "${_reportAbsoluteName}"
      fi
   done < <(cat "${APMaaS_CHECK_ABSOLUTE_NAME}")
   cat "${_reportAbsoluteName}"
}

htmlTable_LocationUsage ()
{
   local _func=${_program:-BASH}.htmlTable_LocationUsage
   local _locationUsageAbsoluteName _locationUsageAbsoluteNameHtml

   getLocationUsage
   
   for _BB_PLM in ${BB_PLM}
   do
      _locationUsageAbsoluteName="$(getLocationUsageAbsoluteName "${_BB_PLM}")"
      info "${_func}:${_locationUsageAbsoluteName}:Updating HTML tables with Location Usage..."
      _locationUsageAbsoluteNameHtml="$(getHtmlLocationUsageAbsoluteName "${_BB_PLM}")"

      cat << EOF > "${_locationUsageAbsoluteNameHtml}"
<h3 align="right" >$(dt 4)</h3>

<table class="bordered">
  <thead>
  <tr>
    <th>Location</th>
    <th>Total Tests Execution Time in Minutes</th>
  </tr>
  </thead>
  
  <tbody>
EOF

      while IFS="${separator}" read key value
      do
         echo "<tr>" >> "${_locationUsageAbsoluteNameHtml}"
         echo "<td> ${key}</td>" >> "${_locationUsageAbsoluteNameHtml}"
         echo "<td> ${value}</td>" >> "${_locationUsageAbsoluteNameHtml}"
         echo "</tr>" >> "${_locationUsageAbsoluteNameHtml}"
      done < <(cat "${_locationUsageAbsoluteName}")

      cat << EOF >> "${_locationUsageAbsoluteNameHtml}"
  </tbody>
</table>
<br>

EOF

   done
   
   local _locationTestAbsoluteNameHtml="$(getHtmlLocationTestAbsoluteName)"

      cat << EOF > "${_locationTestAbsoluteNameHtml}"
<h3 align="right" >$(dt 4)</h3>

<table class="bordered">
  <thead>
  <tr>
    <th>Location</th>
    <th>Account Name</th>
    <th>Test</th>
  </tr>
  </thead>
  
  <tbody>
EOF

  	local _previousLocation=''
	local _previousAccountName=''
   
	while IFS="${separator}" read _location _accountName _test
    do
      echo "<tr>" >> "${_locationTestAbsoluteNameHtml}"
      
		if [ "%${_previousLocation}%" = "%${_location}%" ]
		then # Group by Location (do not print location but use previous as title)
         _location=''
			
			if [ "%${_previousAccountName}%" = "%${_accountName}%" ]
			then # Group by Account (do not print location but use previous as title)
            _accountName=''
			else
				_previousAccountName="${_accountName}"
			fi
		else
			_previousLocation="${_location}"
			_previousAccountName="${_accountName}"
		fi
			
      echo "<td>${_location}</td>" >> "${_locationTestAbsoluteNameHtml}"
      echo "<td>${_accountName}</td>" >> "${_locationTestAbsoluteNameHtml}"
      echo "<td>${_test}</td>" >> "${_locationTestAbsoluteNameHtml}"

      echo "</tr>" >> "${_locationTestAbsoluteNameHtml}"
    done < <(cat "${APMaaS_CHECK_ABSOLUTE_NAME}" | awk -F"${separator}" -v _separator="${separator}" '{print $6 _separator $2 _separator $5}' | sort -t"${separator}" -k1,1 -k2,2 -k3,3)
    
      cat << EOF >> "${_locationTestAbsoluteNameHtml}"
  </tbody>
</table>
<br>

EOF
}

######################
mainUpdateDashboard ()
{
   MATRIX_init
   htmlTable_PLMAgentStatus
   htmlTable_TestSummary
   htmlTable_LocationUsage
   
   htmlHeader_01a
   htmlBodyTables_03a
   htmlBodyEnd_04a

   cat "${HTML_HEADER}" > "${HTML_INDEX}"
   cat "${HTML_BODY_TABLE}" >> "${HTML_INDEX}"
   cat "${HTML_BODY_END}" >> "${HTML_INDEX}"
}
######################
