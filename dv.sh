#!/bin/bash

API_KEY='f14e7c7af0ba4533bf6f4b7527f575ab42fb7369'
API_URI='http://api.daverze.com/v1/run'

__job_start()
{
    curl -s -X POST $API_URI -H "X-API-KEY: $API_KEY" -H "Content-Type: application/json" -d "{\"job_uid\": \"$1\"}"
}

__job_end()
{
    curl -s -X POST $API_URI -H "X-API-KEY: $API_KEY" -H "Content-Type: application/json" -d "{\"run_uid\": \"$1\", \"job_uid\": \"$2\"}"
}

__jsonval()
{
    tmp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $1| awk '{for (i = 2; i <= NF; i++) printf $i " "; print ""}'`
    echo ${tmp##*|}
}
__md5()
{
  if builtin command -v md5 > /dev/null; then
    echo "$1" | md5 -q
  elif builtin command -v md5sum > /dev/null ; then
    echo "$1" | md5sum | awk '{print $1}'
  else
    cron_error "Neither md5 nor md5sum were found in the PATH"
    return 1
  fi

  return 0
}

job_uid=$(__md5 $1)

json=`__job_start $job_uid`
ack=`__jsonval ack`
error=`__jsonval error`

if [ "$ack" == "success" ]; then
   echo "Job Start Success!"
   run_uid=`__jsonval run_uid`
else
   echo "error:" $error
fi

echo "Executing: $@"

# Execute job !
$@

if [ "$run_uid" != "" ]; then
  json=`__job_end $run_uid $job_uid`
  ack=`__jsonval ack`
  error=`__jsonval error`

  if [ "$ack" == "success" ]; then
     echo "Job End Success!"
     run_uid=`__jsonval run_uid`
  else
     echo "error:" $error
  fi
fi


