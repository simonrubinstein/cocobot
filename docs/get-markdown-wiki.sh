#!/bin/sh
#Copies the wiki documentation in this directory.
baseurl=https://raw.githubusercontent.com/wiki/simonrubinstein/cocobot
pages="cocoRegistration CodeDeVote saveLoggedUserInDatabase"
for pagename in $pages
do
    filename="$pagename.md"
    url="$baseurl/$filename" 
    echo $url
    wget  -q --no-check-certificate $url -O $filename
    sed -i -e 's#https://raw.githubusercontent.com/simonrubinstein/cocobot/master/docs/##g' $filename
    for name in $pages
    do
        sed -i -e "s/("$name")/("$name".md)/g" "$filename" 
    done
    rm -f $filename-e
done
