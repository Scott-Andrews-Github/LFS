#!/bin/bash
#-----------------------------------------------------------------------------
#	Title: builder.sh
#	Date: 2019-12-29
#	Version: 1.0
#	Author: scott-andrews@columbus.rr.com
#	Options:
#-----------------------------------------------------------------------------
#	Copyright 2019 Scott Andrews
#-----------------------------------------------------------------------------
#	This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.

#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.

#	You should have received a copy of the GNU General Public License
#	along with this program.  If not, see <https://www.gnu.org/licenses/>.
#-----------------------------------------------------------------------------
#	Dedicated to Elizabeth my cat of 20 years, Euthanasia on 2019-05-16
#-----------------------------------------------------------------------------
set -o errexit	# exit if error...insurance ;)
set -o nounset	# exit if variable not initalized
set +h			# disable hashall
#-----------------------------------------------------------------------------
#	Master variables
#-----------------------------------------------------------------------------
#	GLOBALS
PRGNAME=${0##*/}					# script name minus the path
TOPDIR=${PWD}						# parent directory
PARENT=/usr/src/LFS				# build system master directory
RPMDB=""							# rpm database path for tool chain
SPECS=${TOPDIR}/SPECS			# rpm spec file directory
RPMS=${TOPDIR}/RPMS				# rpm binary package directory
LOGS=${TOPDIR}/LOGS				# build logs directory
INFOS=${TOPDIR}/INFO				# rpm info log directory
PROVIDES=${TOPDIR}/PROVIDES		# rpm provides log directory
REQUIRES=${TOPDIR}/REQUIRES		# rpm requires log directory
# rpm info
RPM_NAME=""		# name of binary rpm package
RPM_VERSION=""	# version of binary rpm package
RPM_RELEASE=""	# release of binary rpm package
RPM_SPEC=""		# filespec of rpm spec script
RPM_INSTALLED=""	# status of binary rpm package installed?
RPM_ARCH=""		# architecture/platform of binary rpm package
RPM_BINARY=""		# filepsec of binary rpm package
RPM_PACKAGE=""	# name of binary rpm package
RPM_EXISTS=""		# status of binary rpm package exists?
RPM_LOG=""			# log file for individual rpm package
#-----------------------------------------------------------------------------
#	Common support functions
_red="\\033[1;31m"		#	print string in red
_green="\\033[1;32m"
_normal="\\033[0;39m"	#	print string in green
function _die {
	[ -n "$*" ] && printf "${_red}%s${_normal}\n" "${*}"
	false
	exit 1
}
function _msg {
	printf "%s\n" "${1}"
	return
}
function _msg_line {
	printf "%s" "${1}"
	return
}
function _msg_failure {
	printf "${_red}%s${_normal}\n" "FAILURE"
	exit 2
}
function _msg_success {
	printf "${_green}%s${_normal}\n" "SUCCESS"
	return
}
function _msg_log {
	local log=${TOPDIR}/${PRGNAME}.log
	printf "%s\n" "${1}" >> ${log} 2>&1
	return
}
function _end_run {
	printf "${_green}%s${_normal}\n" "Run Complete"
	return
}
function _timer {
    if [[ $# -eq 0 ]]; then
        echo $(date '+%s')
    else
        local stime=$1
        etime=$(date '+%s')
        if [[ -z "$stime" ]]; then stime=$etime; fi
        dt=$((etime - stime))
        ds=$((dt % 60))
        dm=$(((dt / 60) % 60))
        dh=$((dt / 3600))
        printf '%02d:%02d:%02d' $dh $dm $ds
    fi
}
function _print {
	_msg "Status for ${RPM_BINARY}"
	_msg "Spec-------->	${RPM_SPEC}"
	_msg "Name-------->	${RPM_NAME}"
	_msg "Version----->	${RPM_VERSION}"
	_msg "Release----->	${RPM_RELEASE}"
	_msg "Arch-------->	${RPM_ARCH}"
	_msg "Package----->	${RPM_PACKAGE}"
	_msg "Binary------>	${RPM_BINARY}"
	_msg "Exists------>	${RPM_EXISTS}"
	_msg "Installed--->	${RPM_INSTALLED}"
	return
}
function _logger {
	_msg_log "Spec-------->	${RPM_SPEC}"
	_msg_log "Name-------->	${RPM_NAME}"
	_msg_log "Version----->	${RPM_VERSION}"
	_msg_log "Release----->	${RPM_RELEASE}"
	_msg_log "Arch-------->	${RPM_ARCH}"
	_msg_log "Package----->	${RPM_PACKAGE}"
	_msg_log "Binary------>	${RPM_BINARY}"
	return
}
function _params {
	local i=""
	RPM_NAME=""
	RPM_VERSION=""
	RPM_RELEASE=""
	RPM_ARCH=""
	RPM_BINARY=""
	RPM_PACKAGE=""
	RPM_EXISTS=""
	RPM_SPEC=${1}
	RPM_ARCH=""
	[ -e ${RPM_SPEC} ] || _die "_params: ${RPM_SPEC}: missing"
	if [ -e ${RPM_SPEC} ]; then
		while  read i; do
			i=$(echo ${i} | tr -d '[:cntrl:][:space:]')
			case ${i} in
				Name:*)	RPM_NAME=${i##Name:}			;;
				Version:*)	RPM_VERSION=${i##Version:}		;;
				Release:*)	RPM_RELEASE=${i##Release:}		;;
				*)	;;
			esac
		done < ${RPM_SPEC}
		#	remove trailing whitespace
		RPM_ARCH=$(rpm --eval %_target_cpu)
		RPM_BINARY="${RPM_NAME}-${RPM_VERSION}-${RPM_RELEASE}.${RPM_ARCH}.rpm"
		RPM_PACKAGE=${RPM_BINARY%.*}
		RPM_LOG=${LOGS}/${RPM_NAME}
		_logger
	else
		_msg "RPMSPEC: ${RPM_SPEC}"
	fi
	return
}
function _exists {
	[ -e "${RPMS}/${RPM_ARCH}/${RPM_BINARY}" ] && RPM_EXISTS="T" || RPM_EXISTS="F"
	_msg_log "Exists------>	${RPM_EXISTS}"
	return
}
function _installed {
	RPM_INSTALLED="?"
	RPM_PACKAGE=${RPM_PACKAGE%.*}
	$(rpm -q --dbpath ${RPMDB} ${RPM_NAME} > /dev/null 2>&1) && RPM_INSTALLED="T" || RPM_INSTALLED="F"
	_msg_log "Installed--->	${RPM_INSTALLED}"
	return
}
function _build {
	_exists
	if [ "F" = "${RPM_EXISTS}" ]; then
		> ${RPM_LOG}
		> ${INFOS}/${RPM_NAME}
		> ${PROVIDES}/${RPM_NAME}
		> ${REQUIRES}/${RPM_NAME}
		_msg_line "Building: "
		_msg_log "Building:"
		rm -rf ${TOPDIR}/BUILD/*
		rm -rf ${TOPDIR}/BUILDROOT/*
		rpmbuild -ba --undefine=_disable_source_fetch ${RPM_SPEC} >> ${RPM_LOG} 2>&1 || _msg_failure && _msg_success
		_exists
		[ "F" == ${RPM_EXISTS} ] && _die "ERROR: Binary Missing: ${RPM_BINARY}"
		rpm -qilp ${RPMS}/${RPM_ARCH}/${RPM_BINARY} > ${INFOS}/${RPM_NAME}	2>&1 || true
		rpm -qp --provides ${RPMS}/${RPM_ARCH}/${RPM_BINARY} > ${PROVIDES}/${RPM_NAME}	2>&1 || true
		rpm -qp --requires ${RPMS}/${RPM_ARCH}/${RPM_BINARY} > ${REQUIRES}/${RPM_NAME}	2>&1 || true
	fi	
	return
}
function _install {
	_installed
	if [ "F" = "${RPM_INSTALLED}" ]; then
		[ "F" == ${RPM_EXISTS} ] && die "ERROR: Binary Missing: ${RPM_BINARY}"
		_msg_line "Installing: "
		_msg_log "Installing:"
		rpm -Uvh --nodeps --force --dbpath ${RPMDB} ${RPMS}/${RPM_ARCH}/${RPM_BINARY} >> ${RPM_LOG} 2>&1 || _msg_failure && _msg_success
		_installed
	fi
	return
}
function _script {
	_msg "Script: ${1}"
	source SPECS/${1}
	return
}
function _spec {
	_msg "File: ${1}"
	_params "${SPECS}/${1}"
	_build
	_install
	return
}
#-----------------------------------------------------------------------------
#	Main line
[ $# -ne 1 ] && _die "${PRGNAME}: command line parameters incorrect: $@"
[ -e ${1} ]  || _die "${PRGNAME}: file not found: ${1}"
case ${1} in
	tools.text)	PATH=/tools/bin:/bin:/usr/bin;export PATH
				RPMDB=/mnt/lfs/usr/src/LFS/RPMDB ;;
	base.text)	PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin;export PATH
				RPMDB=/var/lib/rpm ;;
		*)	;;
esac
while  read i; do
	i=$(echo ${i} | tr -d '[:cntrl:][:space:]')
	_msg_log "Processing: ${i}"
	[ -e ${SPECS}/${i} ] || _die "File not found: ${i}"
	case ${i} in
		"#*")		;;
		*.spec)	_spec "${i}"		;;
		*)		_script "${i}"	;;
	esac
	_msg_log ""
done < ${1}
