#!/bin/bash
######### INFO #########
#cit is a commnd to keep your repo full ciphered inside one folder
#Code by: jjavieralv
# Version: 0.1v

######### GLOBAL VARIABLES #########
#Dependencies
DEPENDENCIES=(ssh expect gpg git)


######### INDIVIDUAL FUNCTIONS #########
##### GRAPHICAL FUNCTIONS #####
	function red_messages() {
	  #crittical and error messages
	  echo -e "\033[31m$1\e[0m"
	}

	function green_messages() {
	  #starting functions and OK messages
	  echo -e "\033[32m$1\e[0m"
	}

	function magenta_messages(){
	  #what part which is executting
	  echo -e "\e[45m$1\e[0m"
	}

#### CONNECTIVITY FUNCTIONS #####
function install_dependencies(){
	echo -e "Installing $1"
	sudo apt install "$1" -y
	if [[ $? -eq 0 ]];then
		green_messages "$1 installed correctly"
	else
		red_messages "Not able to install $1. Exiting"
		exit 20
	fi
}

function check_dependencies(){
	echo -e "\n"
	magenta_messages "### Checking dependencies ###"
	for i in ${DEPENDENCIES[@]}; do
		which $i >/dev/null
		if [[ $? -eq 0 ]];then
			green_messages " $i is installed "
		else
			red_messages "$i is not installed"
			install_dependencies "$i"
		fi
	done
}

function add_ssh_key(){
	# $1	SSH key route
	# $2	SSH key pass
	echo -e "\n"
	magenta_messages "### Add private ssh key ###"
	echo "ROUTE: $1"
	eval `ssh-agent -s`

	expect << EOF
	  spawn ssh-add $1
	  expect "Enter passphrase"
	  send "$2\r"
	  expect eof
EOF
}

function decrypt(){
	# $1	Folder with all sensitive data
	echo -e "\n"
	magenta_messages "### Decrypt ###"
	gpg -o ${1}.tar.gz -d ${1}.tar.gz.gpg.enc
	tar xvzf ${1}.tar.gz
	rm -rf ${1}.tar.gz*
}

function encrypt(){
	# $1	Document with all sensitive data
	echo -e "\n"
	magenta_messages "### Encrypt ###"
	tar cvzf ${1}.tar.gz ${1} --remove-files
	gpg -o ${1}.tar.gz.gpg.enc --symmetric --cipher-algo AES256 ${1}.tar.gz 
	rm -rf ${1}.tar.gz 
}

function check_if_git(){
	#check if you are on root of git repo
	echo -e "\n"
	magenta_messages "### Check if you are on repo root direcotry ###"
	if [[ -d '.git' ]];then 
		green_messages "You are on repo root directory"
	else
		red_messages "You are NOT on repo root directory. Exiting"
		exit
	fi
}

function git_all(){
	git add *
	git commit -m "new update"
	git push
}


######### AGREGATED FUNCTIONS #########

function decrypt_process(){
	magenta_messages "\n ######### Decrypt process #########"
	# $1	Output name
	# $2	Files to be decrypted
	check_dependencies
	decrypt ${1}

}

function encrypt_process(){
	magenta_messages "\n ######### Encrypt process #########"
	check_dependencies
	encrypt ${1}
}

function push_process(){
	magenta_messages "\n ######### Push process #########"
	ssh-add
	check_if_git
	encrypt_process "${1}"
	git_all

}

function help(){
	echo -e "dsa"
}

######### MAIN #########
ARGX=($(getopt -q -o "c:e:d:p:h" -l "cert:,encrypt,decrypt,push,help,file:" -n "argumentos" -- "$@"));

if [ $? -ne 0 ];
then
    echo "There isn an error. No argumments detected"
    exit 1
fi


for (( arg=0; $arg<$# ; arg++ ))
do
  case "${ARGX[$arg]}" in
  	-c|--cert)
	  add_ssh_key "${2}" "${3}"
	  shift;
	  shift;
	  ;;
    -e|--encrypt)
	  echo "going to encrypt"
	  FILE=$2
	  echo "File selected is $FILE"
	  shift;
      ACTION=1
      ;;
    -d|--decrypt)
	  echo "going to decrypt"
	  FILE=$2
	  echo "File selected is $FILE"
	  shift;
      ACTION=2
      ;;
    -p|--push)
      ACTION=3
      FILE=$2
	  echo "File selected is $FILE"
	  shift;
      ;;
    -h|--help)
      show_help
      ;;
      *)red_messages " Problem in execution. Exiting";exit
	  ;;

  esac
  shift
done

case $ACTION in 
	1)encrypt_process "${FILE}"
	;;
	2)decrypt_process "${FILE}"
	;;
	3)push_process "${FILE}"
	;;
	*)red_messages " Problem in execution. Exiting";exit
	;;
esac