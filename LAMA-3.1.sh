#!/bin/bash

today=$(date)
timestamp=$(date +%Y%m%d%H%M%S)
remote="origin" #please set to the name of your remote repository
branch="main" #please set to the name of the branch you want to pull from and push to
conflictPath="${timestamp}-conflict.txt"
SCRIPT=`realpath $0`
directory=`dirname $SCRIPT`
user=`git config user.name`
user="${user%\"}"
user="${user#\"}"
#messages in the script
conflictecho="ATTENTION: The local repository cannot be updated because of a conflict. The merge process will be aborted and a mattermost message will be sent to the git maintainers."
pullsuccessful="Updating of your files was successful, thank you for your time."
localchanges="ATTENTION: There are local changes on the files. Please remove them or save them with LAMA before updating."
nolocalchanges="There are no changes in your local files."
#this could happen if there would be large binary files without git lfs for example
pullerror="ATTENTION: The pull operation was faulty. Please fix it in ${directory} by ${user}."
version="3.1" #version of LAMA

echo "

.____       _____      _____      _____   
|    |     /  _  \    /     \    /  _  \  
|    |    /  /_\  \  /  \ /  \  /  /_\  \ 
|    |___/    |    \/    Y    \/    |    \
|
|_______ \____|__  /\____|__  /\____|__  /
        \/       \/         \/         \/ 



Welcome to Git with LAMA
"
echo " "
echo "############### Configuration ###############"
echo "LAMA version: ${version}"
echo "Git version:" 
git --version            
if [ "$(git ls-remote 2> /dev/null)" ]; then
    echo "Git repository is accessible"
else
    echo "ERROR: Git repository is not accessible"
fi
echo "#############################################"
echo " "

options=("See the current state of your local repository." "Update your local repository." "Save all your changes, add a message, publish your changes to the main repository and update your local repository." "Viewing your current configuration." "Setting up your configuration." "Help!" "Quit")
PS3="
Please choose an option (1-${#options[@]}) or press ENTER to display menu: "
select opt in "${options[@]}"
do
	case $opt in
		"Viewing your current configuration.")
			echo "Your username is:"	
			git config user.name
			echo "Your email is:"
			git config user.email
			;;
		"Setting up your configuration.")
			read -p "Enter your user name: " usrname
					 git config --global user.name "\"$usrname\""
			read -p "Enter your email: " usrmail
					 git config --global user.email "\"$usrmail\""
            echo "Thank you for setting your user name to"
            git config user.name
            echo "and your user email to"
            git config user.email
			;;
		"See the current state of your local repository.")
			git status
			;;
        #uncomment here and add option "See the changes in the files of your local repository." to options if you want to display changes via git diff
		#"See the changes in the files of your local repository.")
		# 	if [[ $(git diff) ]]; then
		#		echo "To close the following list of differences press 'q'"
		#		git diff
		#	else
		#		echo $nolocalchanges
		#	fi
		#	read -n 1 -s -r -p "Press any key to continue"
		#	;;
		"Update your local repository.")
			CONFLICTS=$(git ls-files -u | wc -l)
			if [ "$CONFLICTS" -gt 0 ]
				then
                    echo $conflictecho
                    #this is important so people can work further on the files and the conflict can be solved later
					git merge --abort
					git status >> $conflictPath
					echo $conflictmessage >> $conflictPath
					read
					exit 1
				else
					if [ -z "$(git status --porcelain)" ] 
													then
														echo $nolocalchanges
                                                        echo "Updating will be started."
														git fetch
														git merge ${remote}/${branch}  
														CONFLICTS=$(git ls-files -u | wc -l)
														if [ "$CONFLICTS" -gt 0 ]
															then
																echo $conflictecho
                                                                #this is important so people can work further on the files and the conflict can be solved later
																git merge --abort
																git status >> $conflictPath
																echo $conflictmessage >> $conflictPath																
																read
                                                                exit 1
														else																
                                                                echo "Updating will be carried out." 
														fi
														if [ -z "$(git status --porcelain)" ] 
															then
																echo $pullsuccessful
														else
																git status
																echo $pullerror
																git status >> $conflictPath
																echo $pullerror >> $conflictPath																
																read																
														fi	
													else									            								            
														git status
														echo $localchanges
														read														
					fi							
			fi
			;;	
		"Save all your changes, add a message, publish your changes to the main repository and update your local repository.")
			CONFLICTS=$(git ls-files -u | wc -l)
			if [ "$CONFLICTS" -gt 0 ]
				then
                    echo $conflictecho
                    #this is important so people can work further on the files and the conflict can be solved later
				    git merge --abort
				    git status >> $conflictPath
				    echo $conflictmessage >> $conflictPath				    
				    read
                    exit 1
				else
					echo "Great, there is no merge conflict to begin with."
						#show all the files that are changed and ask if they should be added
						echo "The files that are changed by you are:"
						git status
						read -p "Do you want to add these changes to the main repository? (y/n)" yn
						case $yn in
							[Yy]* ) 
									while true; do
										read -p "Enter your commit message: " message		
										echo "Your commit message is: $message"
										read -p "Is the message correct? (y/n)" yn2
										case $yn2 in
											[YyJj]* )	break;;
											[Nn]* )  	echo "Please enter the message again";;		
											* ) 		echo "Please answer yes or no.";;
										esac
									done		
									git add -A
									git commit -m "$message"								
									git fetch
									git merge ${remote}/${branch} 
									CONFLICTS=$(git ls-files -u | wc -l)
									if [ "$CONFLICTS" -gt 0 ]
										then
											echo $conflictecho
											git merge --abort
											echo $conflictmessage >> $conflictPath
											echo "The merge process was stopped and LAMA will be closed."
											read
											exit
									else
											echo "Merging was successful or not needed." 
											git push $remote $branch
									fi
									if [ -z "$(git status --porcelain)" ] 
										then
											echo $pullsuccessful
											read	
									else
											git status
											echo "ATTENTION: The pull was faulty. Please fix it. "
											git status >> $conflictPath
											echo $pullerror >> $conflictPath
											read		
									fi												
									;;		
							[Nn]* ) echo "The process was stopped.";;
							* ) echo "Please answer yes or no.";;
						esac				
			fi
			;;
		"Help!")
			clear
			echo "This script can be used to add changes you made to the main Git repository so everyone working with the data can receive them."
			echo "Please press ENTER to display the menu and type the number of the option you want to use, confirm wit the ENTER key."
			echo "If there is a conflict or something goes wrong, please contact the maintaining team."
            echo " "
            echo "LAMA version: ${version}"
            echo "Git version:" 
            git --version            
            if [ "$(git ls-remote 2> /dev/null)" ]; then
                 echo "Git repository is accessible"
            else
                echo "ERROR: Git repository is not accessible"
            fi
			;;
		"Quit")
			clear
			break
			;;
		*) if [ "$REPLY" == "0" ]; then
				 read -p "Enter your command (but take care, you have superpowers now) or just press ENTER to go back: `echo $'\n> '`" command
				 eval $command
            else
                echo "Nice try ;-) The option $REPLY is not available. See https://github.com/anneferger/lama for more."
            fi
		;;
	esac
done




