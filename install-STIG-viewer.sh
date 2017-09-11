#!/bin/bash

# Author: Abhishek Tamrakar
# Copyright: REAN CLOUD LLC
#  
# Summary: Wrapper to install stig-viewer.
###########################################
set -e 
# initialize variables
header='\n%s\t%s'
USER=$(whoami)
RELEASE_FILE=/etc/os-release
OPT=( install update remove purge )
PACKAGES=( openjfx wget unzip )
WORK_DIR=$HOME/rean-stig-viewer
# functions here
usage()
{
cat <<_EOF_

	USAGE:
	${0%%/*} [-h(help)] 
		OPTIONS: 
			-h	: displays this help
		SUMMARY:
			Installs necessary packages for stig viewer and starts the applet.

_EOF_
exit 1
}

get()
{
printf '\n%s' "GET" "$@"
}

info()
{
printf $header "INFO" "$@"
}

error()
{
printf $header "ERROR" "$@"
exit 1
}

warn()
{
printf $header "WARN" "$@"
}

getOS()
{
[[ ! -d ${WORK_DIR} ]] \
	&& mkdir -p ${WORK_DIR}

if [[ ! -f ${RELEASE_FILE} ]]; then
get "OS Name[without space]: "
read ID
	else
	. ${RELEASE_FILE} \
		&& info "Completed analyzing the OS information."
fi

case ${ID,,} in
ubuntu )
	CMD=apt-get
	GETPACKAGE="dpkg-query -W"
	;;
fedora|centos|redhat )
	CMD=yum
	GETPACKAGE="rpm -qa"
	;;
esac
}

cleanup()
{
rm -f /tmp/STIG*.jar && info "cleanup complete"
}

check_packages()
{
local package
for package in ${PACKAGES[@]}
do 
status=$(${GETPACKAGE} $package)
	if [[ ${status:-x} = "x" ]]; then
	warn "Package $package NOT FOUND"
	ABSENT=( ${ABSENT[@]} $package )
		else
		info "Package $package FOUND"
	fi
done
}

install_package()
{
local package
sudo ${CMD} ${OPT[0]} -y \
	${ABSENT[@]} \
	|| error "Installing package failed."
}

getStigViewer()
{
# remove any existing versions from tmp
	rm -f /tmp/STIG*.jar
	wget http://iasecontent.disa.mil/stigs/zip/U_STIGViewer-2.5.4.zip \
		-O /tmp/U_STIGViewer-2.5.4.zip	\
		&& unzip -u -d ${WORK_DIR} /tmp/U_STIGViewer-2.5.4.zip
}
# main
[[ $# -ge 1 ]] && usage
trap cleanup EXIT
getOS
info "Got OS Details"
cat << EOF

	OS:		${ID^^}
	RELEASE:	${VERSION}
	BASE:		${ID_LIKE^^}
EOF
check_packages
install_package
info "Downloading Stig Viewer .."
getStigViewer
# variables
JAVA=$(which java)
${JAVA} -jar ${WORK_DIR}/STIG*.jar &
info "STIG Viewer is running with process id: $!"
exit 0
