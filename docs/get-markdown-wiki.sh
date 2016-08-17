#!/bin/sh
#Copies the wiki documentation in this directory.
baseurl=https://raw.githubusercontent.com/wiki/simonrubinstein/cocobot
pages="Home cocoRegistration cocoweb CodeDeVote dbSearch LesAlertes MyAvatar saveLoggedUserInDatabase"
for pagename in $pages
do
    filename="$pagename.md"
    url="$baseurl/$filename" 
    echo $url
    wget  -q --no-check-certificate $url -O $filename
    #Change the absolute links from images in relative links
    sed -i -e 's#https://raw.githubusercontent.com/simonrubinstein/cocobot/master/docs/##g' $filename
    for name in $pages
    do
        sed -i -e "s/("$name")/("$name".md)/g" "$filename" 
    done
    rm -f $filename-e
done
