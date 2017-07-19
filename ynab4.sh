#!/usr/bin/bash
# Date: 2017-07-16
# Last Revision: 2017-07-16
# Wine version used: 2.0.1
# Distribution used to test: Ubuntu (17.04)
# Author: Ricardo Amendoeira (github.com/ric2b)
# Script license: MIT
# Program Licence: Proprietary (with 1 month Trial)

[ "$PLAYONLINUX" = "" ] && exit 0
source "$PLAYONLINUX/lib/sources"

TITLE="You Need a Budget 4 (YNAB4)"
PREFIX="YNAB4"
  
POL_SetupWindow_Init

POL_Debug_Init

POL_SetupWindow_presentation "$TITLE" "YNAB" "https://www.youneedabudget.com/" "Ricardo Amendoeira" $PREFIX

POL_System_TmpCreate $PREFIX
cd "$POL_System_TmpDir"

if [ ! -f .dropbox/host.db ]; then
    POL_SetupWindow_question "Dropbox doesn't seem to be installed, continue? (YNAB4 won't be correctly configured for Dropbox sync" "Dropbox configuration not found"
    
    disableDropbox="$APP_ANSWER" 
    if [ "$disableDropbox" = "FALSE" ]
    then
        POL_SetupWindow_message "Installation complete" "Installation done"

        POL_System_TmpDelete  
        POL_SetupWindow_Close
        exit
    fi
fi

curl 'http://classic.youneedabudget.com/dev/ynab4/liveCaptive/Win/update.xml' > version_metadata.xml 
url=$(grep -oPm1 "(?<=<url>)[^<]+" version_metadata.xml) # get the url from the xml file
md5=$(grep -oPm1 "(?<=<md5>)[^<]+" version_metadata.xml) # get the md5 from the xml file
md5="${md5,,}" # because PlayOnLinux isn't case insensitive when comparing md5...

POL_Wine_SelectPrefix $PREFIX
POL_Wine_PrefixCreate

POL_SetupWindow_menu "What do you want to do?" "Install options" "Install YNAB4 and configure Dropbox|Install YNAB4|Configure Dropbox" "|"

if [ "$APP_ANSWER" = "Configure Dropbox" ] || [ "$APP_ANSWER" = "Install YNAB4 and configure Dropbox" ]
then
    if [ "$disableDropbox" = "" ]
    then
        NativeDropboxLocation=$(cat .dropbox/host.db | tail -n 1 | base64 --decode) # Get the location of the native dropbox folder
        
        WineDropboxLocation=".wine_YNAB4/drive_c/users/$USER/Application Data/Dropbox"
        mkdir "$WineDropboxLocation"
        echo "0000000000000000000000000000000000000000" >> "$WineDropboxLocation/host.db" # recreate the host.db file on the wine directory
        echo -n "C:\Dropbox" | base64 --encode >> "$WineDropboxLocation/host.db"

        ln -s "$NativeDropboxLocation" "$WineDropboxLocation" # symlink the wine dropbox directory to the actual, native, dropbox directory
    fi
fi
    
if [ "$APP_ANSWER" = "Install YNAB4" ] || [ "$APP_ANSWER" = "Install YNAB4 and configure Dropbox" ]
then
    POL_SetupWindow_wait "Please wait" "Download in progress"
    POL_Download "$url" "$md5"
    
    filename=$(echo "$url" | rev | cut -d"/" -f1 | rev) # get the filename from the installer url 
    mv "$filename" "setup.exe" # change to a simpler name
    POL_SetupWindow_wait "Please wait while $TITLE is installed." "Installation in progress"
    POL_Wine "$POL_System_TmpDir/setup.exe"
fi

POL_SetupWindow_message "$TITLE has been successfully installed." "Installation complete"

POL_System_TmpDelete  
POL_SetupWindow_Close
exit
