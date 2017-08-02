#!/bin/bash
#
# Copyright (c) 2015 Igor Pecovnik, igor.pecovnik@gma**.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of the Armbian build script
# https://github.com/armbian/build/

SRC=$(dirname $(realpath ${BASH_SOURCE}))
# fallback for Trusty
[[ -z $SRC ]] && SRC=$(pwd)
cd $SRC

if [[ -f $SRC/lib/general.sh && -L $SRC/main.sh ]]; then
	source $SRC/lib/general.sh
else
	echo "Error: missing build directory structure"
	echo "Please clone the full repository https://github.com/armbian/build/"
	exit -1
fi

# copy default config from the template
[[ ! -f $SRC/config-default.conf ]] && cp $SRC/config/templates/config-example.conf $SRC/config-default.conf

# source build configuration file
if [[ -n $1 && -f $SRC/config-$1.conf ]]; then
	display_alert "Using config file" "config-$1.conf" "info"
	source $SRC/config-$1.conf
else
	display_alert "Using config file" "config-default.conf" "info"
	source $SRC/config-default.conf
fi

if [[ $EUID != 0 ]]; then
	display_alert "This script requires root privileges, trying to use sudo" "" "wrn"
	sudo "$SRC/compile.sh" "$@"
	exit $?
fi

if [[ ! -f $SRC/.ignore_changes ]]; then
	echo -e "[\e[0;32m o.k. \x1B[0m] This script will try to update"
	git pull
	CHANGED_FILES=$(git diff --name-only)
	if [[ -n $CHANGED_FILES ]]; then
		echo -e "[\e[0;35m warn \x1B[0m] Can't update since you made changes to: \e[0;32m\n${CHANGED_FILES}\x1B[0m"
		echo -e "Press \e[0;33m<Ctrl-C>\x1B[0m to abort compilation, \e[0;33m<Enter>\x1B[0m to ignore and continue"
		read
	else
		git checkout ${LIB_TAG:- master}
	fi
fi

# daily beta build contains date in subrevision
if [[ $BETA == yes && -n $SUBREVISION ]]; then SUBREVISION="."$(date --date="tomorrow" +"%y%m%d"); fi

if [[ $BUILD_ALL == yes || $BUILD_ALL == demo ]]; then
	source $SRC/lib/build-all.sh
else
	source $SRC/lib/main.sh
fi
