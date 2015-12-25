info ()
{
   echo "$(dt):INFO: $*" >&2; 
   return ${TRUE}
}

debug ()
{
   [ ${DEBUG} -eq ${TRUE} ] && echo "$(dt):DEBUG: $*" >&2; 
   return ${TRUE}
}

help ()
{
   grep ' ()' "${binDir}"/ZAPMaaS*.sh | grep -v grep | sort -u
}

printStringNoOfTimes ()
{
   String="${1}"
   noOfTimes="${2}"
   printf -v line '%*s' "${noOfTimes}"; echo ${line// /${String}}
}

pause ()
{
return
#This has bug, skipping as we lose one line from the input file on each pause!!!
   if [ -t 0 ]
   then
      debug "STDIN connected to the terminal"
   else
      debug "STDIN is not connected to the terminal, function 'pause' has to be hacked to work."
   fi
   [ -t 1 ] && debug "STDOUT connected to the terminal"

   local text="${*:-Press any key to continue...}"
   local dummy

   exec 3<&0       # Save stdin to file descriptor 3.
   exec 0</dev/tty # Redirect terminal input into standard input.

   if [ "${text}" = "Press any key to continue..." ]
   then
      read -s -r -p "${text}" -n 1 dummy   # -s (silent mode, characters are not echoed); -r (use always, backslash does not act as an escape character); -p (prompt); -n (exit after readin number of characters)
   else
      read -r -p "${text}" dummy   # -r (use always, backslash does not act as an escape character); -p (prompt);
      echo "${dummy}"
   fi

   exec 0<&3       # Restore original stdin.
   exec 3<&-       # Close temporary file descriptor 3.
}

waitall ()
{
   local _func=${_program:-BASH}.waitall
   debug "${_func}:Waiting for alll background processes to complete:$@..."

   # PID...
   ## Wait for children to exit and indicate whether all exited with 0 status.
   local errors=0
   while :; do
      debug "${_func}:Processes remaining: $*"
      for pid in "$@"; do
         shift
         if kill -0 "$pid" 2>/dev/null; then
            debug "${_func}:$pid is still alive."
            set -- "$@" "$pid"
         elif wait "$pid"; then
            debug "${_func}:$pid exited with zero exit status."
         else
            debug "${_func}:$pid exited with non-zero exit status."
            ((++errors))
         fi
      done

      (("$#" > 0)) || break
      # TODO: how to interrupt this sleep when a child terminates?
      sleep ${WAITALL_DELAY:-1}
   done
   ((errors == 0))

# Use as:
# local _pids
# while read line
# do
   # _loginName=`echo ${line} | cut -d':' -f1`
   # _passwd=`echo ${line} | cut -d':' -f2`

   # getThresholdsConfig "${_loginName}" "${_passwd}" &
   # _pids="$_pids $!"
   # debug "${_func}:_pids:${_pids}."
   # # Wait 2s before forking another process
   # sleep 2
# done < <(cat "${PASSWD_COMPUWARE}")
# waitall ${_pids}
#
}

leftzeropad ()
{
   local _func=${_program:-BASH}.leftzeropad
   if [ ${#} -ne 2 ]
   then
         cat << EOF

Run as:
${_func} numberToPad targetNumberOfDigits

This function returns left padded numberToPad left zero padded to total targetNumberOfDigits.

EOF
      return ${FALSE}
   fi

   expo=$((10 ** $2))
   [ $1 -gt $expo ] && { echo $1; return; }
   formatd=$(($1 + $expo))
   echo ${formatd:1}
}

split2Array ()
{
   local arrIN=(${1//${2}/ })
   for X in ${!arrIN[*]}; do echo "$X:${arrIN[$X]}"; done
}

arrayFindElement ()
{
  local element
  for element in "${@:2}"; do [[ "$element" == "$1" ]] && return 0; done
  return 1

	# Usage:
	# $ array=("something to search for" "a string" "test2000")
	# $ containsElement "a string" "${array[@]}"
	# $ echo $?
	# 0
	# $ arrayFindElement "blaha" "${array[@]}"
	# $ echo $?
	# 1
}

arrayCheckIfElementExist () 
{
   eval 'local keys=${!'$1'[@]}';
   eval "case '$2' in
      ${keys// /|}) return 0 ;;
      * ) return 1 ;;
   esac";

	# Usage:
	# $ arrayCheckIfElementExist arrayName 2 && echo exist || echo don\'t
	# exist
	# $ arrayCheckIfElementExist arrayName 5 && echo exist || echo don\'t
	# don't
}

arrayGetIfElementExist () 
{
   eval 'local keys=${!'$1'[@]}';
   eval "case '$2' in
      ${keys// /|}) echo \${$1[$2]};return 0 ;;
      * ) return 1 ;;
   esac";
	  
	# Usage:
	# $ arrayGetIfElementExist array key1
	# red
	# $ echo $?
	# 0

	# $ # now with an empty defined value
	# $ array["key4"]=""
	# $ arrayGetIfElementExist array key4

	# $ echo $?
	# 0
	# $ arrayGetIfElementExist array key5
	# $ echo $?
	# 1	  
}
