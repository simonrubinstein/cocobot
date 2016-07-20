#!/bin/sh
#Copies the wiki documentation in this directory.
baseurl=https://raw.githubusercontent.com/wiki/simonrubinstein/cocobot
for pagename in 'cocoRegistration' 'CodeDeVote' 'saveLoggedUserInDatabase'
do
    filename="$pagename.md"
    url="$baseurl/$filename" 
    echo $url
    wget  -q --no-check-certificate $url -O $filename
    sed -i -e 's#https://raw.githubusercontent.com/simonrubinstein/cocobot/master/docs/##g' $filename
    rm -f $filename-e
done
