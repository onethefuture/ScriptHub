#!/bin/bash
dt=`date`
dd=`date|md5sum|cut -d ' ' -f1`
curl -l -H "Content-type: application/json" -X POST -d "{\"touser\": \"16020\", \"message\": \"${dt} $1\"}" "http://tcoaapi.17usoft.com/Api/WeChat/SendTextMessage?TCOA_Token=F996F635D5244D02A67724E67D2794DF&TCOA_Nonce=${dd}"
echo -e "msg ok"
