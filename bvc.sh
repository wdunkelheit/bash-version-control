#!/bin/bash

# Define some useful strings.
RETURN_TO_MENU=("Press the return (enter) key to return to the menu.")
STARTING_DIRECTORY=$(pwd)
EDITOR=("$(cat .editor.txt)")
#Functions above main program.

useProjects (){
	cd projects/$1/
	while [ "$choice" != 0 ]
	do
		echo -e "You are accessing project $1"
		cat << SUBMENU
<------------------------
Project Options
-------------------------
1. View files in the project repository.
2. Commit new version.
3. View repository log.
4. Add File.
5. Edit File.
6. Compress project.
7. Rollback
0. Exit to main menu.
------------------------>
SUBMENU
read choice
case "$choice" in
	1) #Print the contents of the project repo.
		ls -R
		echo -e "$RETURN_TO_MENU"
		read
		;;
	2)  #Commit - Copies contents of the main directory to a new directory, adds comment
		#and creates a log.
		typeset -i pversion=("$(ls history/ | wc -w)")
		echo -e "Please enter a comment for this commit."
		read comment
		#Creates the logging files directory for this commit and the appropriate parents.
		mkdir -p history/v"$pversion"/ log/v"$pversion"
		echo "$comment" > history/v"$pversion"/.comment.txt
		cp -r main/* history/v"$pversion"/
		# Sets a variable up to hold the value of the previous version
		typeset -i lastver=(pversion-1)
		# Create log
		diff -u main/ history/v"$lastver" > log/v"$pversion"/changes.patch
		echo "<-- v$pversion changes begin---" >> log/log.txt
		cat log/v"$pversion"/changes.patch >> log/log.txt
		echo "--- v$pversion changes end-->" >> log/log.txt
		# Unset variables that are no longer needed to prevent accidental use.
		unset lastver
		unset pversion
		echo -e "$RETURN_TO_MENU"
		read
		;;
	3) #Prints the repo log to the screen.
		cat log/log.txt
		echo -e "$RETURN_TO_MENU"
		read
		;;
	4) # Add file.
		echo -e "What name should the file have?"
		read filename
		touch "main/$filename"
		# Adds the file to the log
		echo "File: $filename added to repo." >> log/log.txt
		echo -e "$RETURN_TO_MENU"
		read
		;;
	5) #Edit files.
		echo -e "Which file would you like to edit?"
		cd main
		ls -R
		echo -e "Please enter the full path and name as shown."
		read filetoload
		if [ ! -e "$filetoload" ]
		then echo -e "Invalid, please check casing and spacing."
		else
			$EDITOR "$filetoload"
		fi
		cd ..
		echo -e "$RETURN_TO_MENU"
		read
		;;
	6) # Archive project.
		cd ..
		tar czvf $1.tar.gz $1 
		echo -e "Directory packaged and compressed\n$RETURN_TO_MENU"
		read
		;;
	7) #Rollback
		echo -e "Are you abolutely sure you want to do this?(y/n)\nThis process cannot be undone easily!"
		read confirm
		case "$confirm" in
			y|Y)
				# Clears old rollback backup and creates new directory for the new one.
				rm -r backups/rollback/
				mkdir -p backups/rollback
				#Ask for user input
				echo -e "Which version do you wish to roll back to?"
				ls history/
				read num
				# Check options is valid
				if [ -d history/"$num" ]
				then
					cp -r main/* backups/rollback/
					rm -r main/*
					cp -r history/v"$num"/* main/
					echo -e "Your previous main directory has been backed up in backups/rollback/"
					echo -e "$RETURN_TO_MENU"
					read
				else echo -e "Invalid Selection\n$RETURN_TO_MENU"
					read
				fi
				;;
			n|N)
				echo -e "$RETURN_TO_MENU"
				read
				;;
			*) echo -e "Invalid option.zn$RETURN_TO_MENU"
				read
				;;
		esac
		;;
	0)  #Prevents errors with the choice value when returning to the main menu
		choice=0;
		;;
esac
done
cd ../../
#Unsets to prevent contamination with the other choice variable.
unset choice
}

while [ "$choice" != 0 ]
do
	clear
	cat << MENU
<------------------------
Main Menu
-------------------------
1. Create New Project
2. Select Existing Project
3. Display Existing Projects
4. View License (GNU GPL3)
5. Configure Editor Preferences - Please use this on first use.
0. Exit
------------------------>
MENU
#Returns the user to the starting directory in case of error when returning to this loop.
if [ ! "$(pwd)" = "$STARTING_DIRECTORY" ]
then cd "$STARTING_DIRECTORY"
fi
#Check if required directory exists, add it if not and inform user.
if [ ! -d projects ];
then
	echo -e "This appears to be your first time running this software.\nThe projects directory will be created for you.\n"
	mkdir projects
fi
read choice
case "$choice" in  
	1) #Ask user to name the new project.
		#This should be relatively straight forward in terms of logic.
		#DUMMY SPACE
		echo -e "Please enter the name of your new project."
		read projectTitle
		case "$projectTitle" in
			*\ *)   #Checks for white space in name.
				echo -e "White space in name detected. Please remove and try again."
				;;
			*)  #If no white space is detected. Continue as normal.
				#Removes trailing white spaces. Really hacky but it works.
				echo -e "Your project name is $projectTitle.\nIs this correct? (y/n)"
				read confirm
				#Check that the user input the correct name that they wanted to use,
				case "$confirm" in
					yes|y|Y)
						if [ ! -d projects/"$projectTitle" ];
						then
							#Create group for the project.
							sudo groupadd "$projectTitle"
							#Add current user to the group.
							sudo usermod -a -G "$projectTitle" $USER
							#Create directory for the project.
							mkdir -p projects/"$projectTitle"/history projects/"$projectTitle"/log projects/"$projectTitle"/backups projects/"$projectTitle"/main
							#Create needed files in new directories
							touch projects/"$projectTitle"/log/log.txt projects/"$projectTitle"/settings projects/"$projectTitle"/main/README.md
							#Take ownership of project
							sudo chown -R $USER:$projectTitle projects/"$projectTitle"
							#Give access permissions to user and group
							sudo chmod 770 projects/"$projectTitle"
							#Inform user of success.
							echo -e "Project: $projectTitle successfully created."
						else
							#Inform user that a project of that name already exists.
							echo -e "A project with this title already exists.\nPlease try again and select a valid name.\nYou can view existing projects from the main menu."
						fi
						;;
					no|n|N)                  
						echo -e "Please try again."
						;;
					*)
						echo -e "Invalid option."
						;;
				esac
				;;
		esac
		echo -e $RETURN_TO_MENU
		read
		;;
	2) #Ask the user to select an existing project
		#This is where the meat of the program will likely be written.
		if [ ! -d projects/* ]
		then
			echo -e "No projects found.\n$RETURN_TO_MENU"
			read
		else
			echo -e "--------------\nWhich project would you like to access?\n--------------"
			declare -i j=0
			for i in $( 'ls' projects/ ); do
				j+=1
				echo -e "$j. $i"
			done
			echo "--------------"
			read projectTitle
			#Checks if the project exists
			if [ -d projects/$projectTitle ] 
			then
				echo -e "What do you wish to do with this project?"
				#A menu goes here
				#Function?
				useProjects "$projectTitle"
			else
				echo -e "A project with the name $projectTitle does not exist. Please check sensitivity."
				#Returns user to the main menu.
				echo -e $RETURN_TO_MENU
				read
			fi
		fi
		;;
	3)  #Display the existing projects (if any).
		projects=$('ls' projects/)
		echo -e "${projects[*]}\n$RETURN_TO_MENU"
		read
		unset projects
		;;
	4) #Print the software license to screen
		cat gpl.txt
		echo -e $RETURN_TO_MENU
		read
		;;
	5) # Select your prefered editor.
		echo -e "Which editor would you like to use?\nEnter Terminal Alias of editor:"
		read editpref
		# Creates the directory to store the user settings, sends errors to blackhole.
		mkdir ~/.bvc 2> /dev/null
		echo "$editpref" > ~/.bvc/.editor.txt
		unset editpref
		echo -e "$RETURN_TO_MENU"
		read
		;;
	0) #Goodbye message
		echo "Goodbye. :)"
		;;
	*) #Fallback Scenario handling.
		echo "This is an invalid option. Please select from the list provided"
		echo -e $RETURN_TO_MENU
		read
		;;
esac
done
