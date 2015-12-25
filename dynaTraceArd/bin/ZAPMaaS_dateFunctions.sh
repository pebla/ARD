dt2DefaultFormat ()
{
   local _func=${_program:-BASH}.dt2DefaultFormat
   if [ ${#} -ne 2 ]
   then
      cat << EOF

Run as:
${_func} "16/04/2015 13:00:00" "dmy"

This function reformats 24h dateTime, like 23/04/2015 18:34:34 to defalt date/time format ${DEFAULT_DATE_TIME_FORMAT}. Second parameter defines date input format order (ymd mdy dmy...)

EOF
      return ${FALSE}
   fi

   # DEFAULT_DATE_TIME_FORMAT='+%m/%Y/%d %H:%M:%S'
   #    local -r inDateHMS=${1//[!0-9]}    # Remove non-digits
   local -r inDateHMS=$(echo "${1}"|sed 's/-/\//g') # Sometimes date is "2015-06-22 08:16:54.787", change dash to slash
   local -r inDateFormat=${2}         # dmy myd ymd...

	debug "${_func}:Converting date time ${inDateHMS} from format ${inDateFormat} to format ${DEFAULT_DATE_TIME_FORMAT}..."

	local inArrDT=(${inDateHMS//\// }) # Slice "99/99/9999 99:99:99" into array separated by /. Will create four elements in array inArrDT
	local inArrT=(${inArrDT[3]//:/ }) # Slice "99:99:99" into array separated by :. Will create four elements in array inArrT
	local outArrDT=(${DEFAULT_DATE_TIME_FORMAT//\// }) # Slice "99/99/9999 99:99:99" into array separated by /. Will create four elements in array inArrDT
	local outArrT=(${outArrDT[3]//:/ }) # Slice "99:99:99" into array separated by :. Will create four elements in array inArrT
	
    # if (( ${#inDateHMS} != 14 )) ; then
        # echo "error - '$inDateHMS' is not a valid datetime" >&2
        # return 1
    # fi

    # Extract datetime components, possibly with leading zeros
	case "${inDateFormat}" in
       "dmy")  local -r day_z=${inArrDT[0]};
               local -r month_z=${inArrDT[1]};
	           local -r year=${inArrDT[2]};;
       "mdy")  local -r month_z=${inArrDT[0]};
	           local -r day_z=${inArrDT[1]};
			   local -r year=${inArrDT[2]};;
       "ymd")  local -r year=${inArrDT[0]};
               local -r month_z=${inArrDT[1]};
               local -r day_z=${inArrDT[2]};;
       * ) echo "${_func}:inDateHMS:${inDateHMS}:inDateFormat:${inDateFormat}:Parameter has unexpected value, exiting." ; exit ${FALSE};;
    esac
	# case "${inDateFormat}" in
       # "dmy")  local -r day_z=${inDateHMS:0:2};
               # local -r month_z=${inDateHMS:2:2};
	           # local -r year=${inDateHMS:4:4};;
       # "mdy")  local -r month_z=${inDateHMS:0:2};
	           # local -r day_z=${inDateHMS:2:2};
			   # local -r year=${inDateHMS:4:4};;
       # "ymd")  local -r year=${inDateHMS:0:4};
               # local -r month_z=${inDateHMS:4:2};
               # local -r day_z=${inDateHMS:6:2};;
       # * ) echo "${_func}:inDateFormat:${inDateFormat}:Parameter has unexpected value, exiting." ; exit ${FALSE};;
    # esac
#	local -r HMS=${inArrT[3]//[!0-9]}    # Remove non-digits
   local -r hour_z=${inArrT[0]}
   local -r minute_z=${inArrT[1]}
   local -r second_z=${inArrT[2]}
	local -r amPm=$(arrayGetIfElementExist inArrDT 4) # 4th element is AM or PM
	
   local _date=$(date -d "${month_z}/${day_z}/${year} ${hour_z}:${minute_z}:${second_z} ${amPm}" '+%s')
	echo $(date --date="@${_date}" "${DEFAULT_DATE_TIME_FORMAT}")

    return 0
}

dt ()
{
   local _func=${_program:-BASH}.dt
   local _dt=${1:0}
   case "${_dt}" in
      1) date '+%d/%m/%Y %H:%M:%S';;
      2) date '+%m/%d/%Y %H:%M:%S';;
      3) date '+%Y/%m/%d %H:%M:%S';;
      4) date '+%b %d, %H:%M %Z';;
	   5) 
			local -r dateHMS=${2};
			local -r dateFormat=${3:-dmy};         # dmy myd ymd...

			local inArrDT=(${dateHMS//\// });
			local inArrT=(${inArrDT[3]//:/ });

			debug "${_func}:$(for X in ${!inArrDT[*]}; do echo "$X:${inArrDT[$X]}"; done)"
			debug "${_func}:$(for X in ${!inArrT[*]}; do echo "$X:${inArrT[$X]}"; done)"
			
			case "${dateFormat}" in
			   "dmy") local -r day_z=${inArrDT[0]};
					   local -r month_z=${inArrDT[1]};
					   local -r year=${inArrDT[2]};;
			   "mdy") local -r month_z=${inArrDT[0]};
					   local -r day_z=${inArrDT[1]};
					   local -r year=${inArrDT[2]};;
			   "ymd") local -r year=${inArrDT[0]};
					   local -r month_z=${inArrDT[1]};
					   local -r day_z=${inArrDT[2]};;
			   * ) echo "${_func}:dateFormat:${dateFormat}:Parameter has unexpected value, exiting." ; exit ${FALSE};;
			esac;
			local -r hour_z=${inArrT[0]};
			local -r minute_z=${inArrT[1]};
			local -r second_z=${inArrT[2]};
			local -r AM_PM=${inArrDT[4]};

			date -d "${month_z}/${day_z}/${year} ${hour_z}:${minute_z}:${second_z} ${AM_PM}" '+%d %b %Y, %T %Z';;
	   
      *) date '+%Y%m%d_%H%M%S';;
   esac
}

dtGetTimeZoneOffset ()
{
   local _func=${_program:-BASH}.dtGetTimeZoneOffset
   local _ret=${FALSE}

   # returns current daylight Time Offset from UTC taking into account summer time too, in seconds
   # Get current time offset from UTC
   local _DATE_TIMEZONE=$( date +'%:z' ) 
   # Get timeoffset sign
   local _DATE_SN="${_DATE_TIMEZONE/[0-9:]*/}" 
   # Get timeoffset in hours
   local _DATE_HR="${_DATE_TIMEZONE/:*/}"; test 0 -gt "$_DATE_HR" && _DATE_HR="${_DATE_HR/-/}" 
   # Get timeoffset minutes
   local _DATE_MN="${_DATE_TIMEZONE/*:/}" 
   # Calculate timeoffset in seconds
   local _DATE_OFFSET=$(( ( _DATE_HR * 60 + _DATE_MN ) * 60 )) 
   # If we are in the minus timezone, negative timeoffset in seconds
   test X- = "X$_DATE_SN" && _DATE_OFFSET=-"$_DATE_OFFSET" 
   # Export to global variable #eval $1=\$_DATE_OFFSET
   
   debug "${_func}:Time Zone Offset is: ${_DATE_OFFSET}."
   echo ${_DATE_OFFSET}
   
   return ${TRUE}
}

getNowInEpoch ()
{
   date '+%s'
}

dtUTC2Epoch ()
{
   local _func=${_program:-BASH}.dtUTC2Epoch
   if [ ${#} -ne 1 ]
   then
      cat << EOF

Run as:
${_func} DateTime

This function converting dd/mm/yyyy hh:mm:ss (UTC) to Epoch

EOF
      return ${FALSE}
   fi

   debug "${_func}:Converting mm/dd/yyyy hh:mm:ss (UTC) to Epoch..."

   date --utc --date "$1" '+%s'
}

dtEpoch2LocalTimeZone ()
{
   local _func=${_program:-BASH}.dtEpoch2LocalTimeZone
   if [ ${#} -ne 1 ]
   then
      cat << EOF

Run as:
${_func} DateTimeInEpoch

This function returns Epoch date time to local time zone date time

EOF
      return ${FALSE}
   fi

   local _epoch="${1}"
   local _tz=`date +%Z`

   debug "${_func}:Converting Epoch time:${_epoch}, to my local time zone:${_tz}..."
   local _param="TZ=\"${_tz}\" @${_epoch}"

   date "+%d/%m/%Y %T" --date="${_param}"
}

dt2Epoch ()
{
   local _func=${_program:-BASH}.dt2Epoch
   if [ ${#} -ne 2 ]
   then
      cat << EOF

Run as:
${_func} "16/04/2015 13:00:00" "dmy"

This function converts 24h dateTime, like 23/04/2015 18:34:34 to Epoch time. Second parameter defines date order (ymd mdy dmy...)

EOF
      return ${FALSE}
   fi

   # local -r dateHMS=${1//[!0-9]}    # Remove non-digits
   local -r dateHMS=${1}
   local -r dateFormat=${2}         # dmy myd ymd...

	debug "${_func}:Converting date time from ${dateHMS}, with format ${dateFormat}, to Epoch..."

	local inArrDT=(${dateHMS//\// }) # Slice "99/99/9999 99:99:99" into array separated by /. Will create four elements in array inArrDT
	local inArrT=(${inArrDT[3]//:/ }) # Slice "99:99:99" into array separated by :. Will create four elements in array inArrT
	
   # Extract datetime components, possibly with leading zeros
	case "${dateFormat}" in
       "dmy") local -r day_z=${inArrDT[0]};
              local -r month_z=${inArrDT[1]};
	           local -r year=${inArrDT[2]};;
       "mdy") local -r month_z=${inArrDT[0]};
	           local -r day_z=${inArrDT[1]};
			     local -r year=${inArrDT[2]};;
       "ymd") local -r year=${inArrDT[0]};
              local -r month_z=${inArrDT[1]};
              local -r day_z=${inArrDT[2]};;
       * ) echo "${_func}:dateFormat:${dateFormat}:Parameter has unexpected value, exiting." ; exit ${FALSE};;
    esac
   # local -r HMS=${inArrT[3]//[!0-9]}    # Remove non-digits
   local -r hour_z=${inArrT[0]}
   local -r minute_z=${inArrT[1]}
   local -r second_z=${inArrT[2]}

   date -d "${month_z}/${day_z}/${year} ${hour_z}:${minute_z}:${second_z}" '+%s'

   return 0
}

dtInSec_FromNowTillDateTime ()
{
   local _func=${_program:-BASH}.dtInSec_FromNowTillDateTime

   if [ ${#} -ne 2 ]
   then
      cat << EOF

Run as:
${_func} "26/02/2015 15:45:23" "dmy"

This returns number of seconds from supplied date/time till now.
MAKE SURE ALL TIMES ARE IN THE SAME TIMEZONE!

EOF
      return ${FALSE}
   fi

   local _dt="${1}"
   local _dtFormat="${2}"

   debug "${_func}:Returning number of seconds since date time:${_dt}, in format ${_dtFormat}, till now - in seconds. MAKE SURE ALL TIMES ARE IN THE SAME TIMEZONE!"

   local _beforeEpoch=$(dt2Epoch "${_dt}" "${_dtFormat}")
   debug "${_func}:_dt:${_dt}:inEpoch:${_beforeEpoch}"
            
   local _nowEpoch=$(dt2Epoch "$(dt 1)" "dmy")
   debug "${_func}:nowEpoch:${_nowEpoch}"
            
   echo $((_nowEpoch-_beforeEpoch))
}

dtInSec_FromNowTillUTCDateTime ()
{
   local _func=${_program:-BASH}.dtInSec_FromNowTillUTCDateTime

   if [ ${#} -ne 2 ]
   then
      cat << EOF

Run as:
${_func} "26/02/2015 15:45:23" "dmy"

This returns number of seconds from supplied UTC date/time mm/dd/yyyy hh:mm:ss till now.
Supplied date time must be in UTC.

EOF
      return ${FALSE}
   fi

   local _dt="${1}"
   local _dtFormat="${2}"

   debug "${_func}:Returning number of seconds since the UTC date time:${_dt}, in format ${_dtFormat}, till now - in seconds. Make sure supplied date time is in UTC!"

   local _beforeEpochInDefaultDateFormat=$(dt2DefaultFormat "${_dt}" "${_dtFormat}") # Reformat input date into default date format
   local _beforeEpoch=$(dtUTC2Epoch "${_beforeEpochInDefaultDateFormat}")
   debug "${_func}:_dt:${_dt}:_dtFormat:${_dtFormat}:inEpoch:${_beforeEpoch}"
            
   #local _nowEpoch=$(dt2Epoch "$(dt 1)" "${_dtFormat}")
   local _nowEpoch=$(dt2Epoch "$(dt 1)" dmy) # Function dt 1 returns date in format d/m/y always.
   debug "${_func}:nowEpoch:${_nowEpoch}"
            
   echo $((_nowEpoch-_beforeEpoch))
}
