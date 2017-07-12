#!/usr/bin/env playonlinux-bash
[ "$PLAYONLINUX" = "" ] && exit 0
source "$PLAYONLINUX/lib/sources"
  
POL_SetupWindow_Init
  
POL_SetupWindow_presentation "You Need a Budget 4 (YNAB4)" "YNAB" "https://www.youneedabudget.com/" "Ricardo Amendoeira" "YNAB4"

POL_System_TmpCreate "YNAB4"
cd "$POL_System_TmpDir"

curl 'http://classic.youneedabudget.com/dev/ynab4/liveCaptive/Win/update.xml' > version_metadata.xml 
url=$(grep -oPm1 "(?<=<url>)[^<]+" version_metadata.xml)
md5=$(grep -oPm1 "(?<=<md5>)[^<]+" version_metadata.xml)
md5="${md5,,}" # because PlayOnLinux isn't case insensitive when comparing md5...

POL_Wine_SelectPrefix "YNAB4"
POL_Wine_PrefixCreate

POL_SetupWindow_menu "What do you want to do?" "Install options" "Install YNAB4 and configure Dropbox|Install YNAB4|Configure Dropbox" "|"

if [ "$APP_ANSWER" = "Configure Dropbox" ] || [ "$APP_ANSWER" = "Install YNAB4 and configure Dropbox" ]
then
	cp /mnt/960Evo/Dropbox/Drive/GitHub/YNAB4-PlayOnLinux/installYNAB4.py installYNAB4
	python3 installYNAB4 4
fi
	
if [ "$APP_ANSWER" = "Install YNAB4" ] || [ "$APP_ANSWER" = "Install YNAB4 and configure Dropbox" ]
then
	POL_SetupWindow_wait "Please wait" "Download in progress"
	POL_Download "$url" "$md5"
	
	filename=$(echo "$url" | rev | cut -d"/" -f1 | rev)	
	mv "$filename" "setup.exe"
	POL_SetupWindow_wait "Please wait" "Installation in progress"
	POL_Wine "$POL_System_TmpDir/setup.exe"
fi

POL_SetupWindow_message "Installation complete" "Installation done"

POL_System_TmpDelete  
POL_SetupWindow_Close
exit

