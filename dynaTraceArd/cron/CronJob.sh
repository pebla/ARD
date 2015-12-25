#!/bin/bash

# Program scheduler to run this every 15 minutes, no interaction with desktop

HOME="/home/989136"
HOME="/home/045800"

DYNATRACE="${HOME}/dynaTrace"
cd "${DYNATRACE}/bin"

# At midnight run maintenance tasks
hnow=`echo $(date +%-H)` # Do not pad with 0
mnow=`echo $(date +%-M)` # Do not pad with 0

if [ "${hnow}" = "0" ]
then
   if [ "${mnow}" = "0" ] || [ "${mnow}" = "1" ]
   then
      > /tmp/CronJob.log # Clear CronJob log
      > /tmp/curlLog.log # Clear curlLog log
      # Generate a complete test configuration list for all Child Accounts. This is to get todays changes
      nohup "${DYNATRACE}/bin/runAPMaaS_AllAccounts.sh" CONFIGURE > /tmp/runAPMaaS_AllAccounts.log 2>&1 &

      find "${DYNATRACE}/tmp" -type f -mtime +2 -exec rm -f {} \;
      find "${DYNATRACE}/log" -type f -mtime +2 -exec rm -f {} \;
      find "${DYNATRACE}/config" -type f -name "*UNIQ*" -mtime +2 -delete
      find "${DYNATRACE}/config" -type f -empty -delete
   fi
fi

# Check every half hour. 
# Since it is executed from the scheduler, programmed to execute every 15 minutes, we can safely assume there will be no Cron executing at 0 and at 1, but if it is 1 it is because it has been delayed from the scheduler at 0.
if [ "${mnow}" = "0" ] || [ "${mnow}" = "1" ] || [ "${mnow}" = "30" ] || [ "${mnow}" = "31" ]
then
   # Generate a complete test Performance/Availability list for all Child Accounts.
   nohup "${DYNATRACE}/bin/runAPMaaS_AllAccounts.sh" MONITOR && "${DYNATRACE}/bin/runAPMaaS_AllAccounts.sh" DASHBOARD > /tmp/runAPMaaS_AllAccounts.log 2>&1 &
fi
