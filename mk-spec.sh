#!/bin/bash
#-----------------------------------------------------------------------------
#	Title: make_spec_file.sh
#	Date: 2020-01-09
#	Version: 1.0
#	Author: scott-andrews@columbus.rr.com
#	Options: none
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
set -o errexit		# exit if error...insurance ;)
set -o nounset	# exit if variable not initalized
set +h			# disable hashall
#-----------------------------------------------------------------------------
#	Master variables
PRGNAME=${0##*/}	# script name minus the path
TOPDIR=${PWD}		# parent directory
PKGDIR=PKGDATA	# directory for package params, source
SPECDIR=../SPECS		# directory for finished files
#-----------------------------------------------------------------------------
#	Common support functions
function _die {
	local _red="\\033[1;31m"
	local _normal="\\033[0;39m"
	[ -n "$*" ] && printf "${_red}$*${_normal}\n"
	false
	exit 1
}
function _msg {
	printf '%s\n' "${1}"
	return
}
function _msg_line {
	printf '%s' "${1}"
	return
}
function _msg_failure {
	local _red="\\033[1;31m"
	local _normal="\\033[0;39m"
	printf "${_red}%s${_normal}\n" "FAILURE"
	exit 2
}
function _msg_success {
	local _green="\\033[1;32m"
	local _normal="\\033[0;39m"
	printf "${_green}%s${_normal}\n" "SUCCESS"
	return
}
function _msg_log {
	printf "\n%s\n\n" "${1}" >> ${_logfile} 2>&1
	return
}
function _end_run {
	local _green="\\033[1;32m"
	local _normal="\\033[0;39m"
	printf "${_green}%s${_normal}\n" "${PRGNAME}: Run Complete"
	return
}
#-----------------------------------------------------------------------------
#	local functions
function _header {
	local count=0
	local i=""
	local work=""
#	_msg "%undefine _disable_source_fetch" > ${TARGET}
	_msg "Summary: ${Summary}" >> ${TARGET}
	_msg "Name: ${Name}" >> ${TARGET}
	_msg "Version: ${Version}" >> ${TARGET}
	_msg "Release: ${Release}" >> ${TARGET}
	_msg "License: ${License}" >> ${TARGET}
	_msg "URL: ${Url}" >> ${TARGET}
	_msg "Group: ${Group}" >> ${TARGET}
	_msg "Vendor: Elizabeth" >> ${TARGET}
	for i in ${Source}; do
		_msg "Source${count}: ${i}" >> ${TARGET}
		let "count += 1"
	done
	count=0
	for i in ${Patch}; do
		_msg "Patch${count}: ${i}" >> ${TARGET}
		let "count += 1"
	done
	[ ! "${Requires}" = "" ] && _msg "${Requires}" >> ${TARGET}
	_msg "BuildRoot: %{_buildrootdir}/%{name}-%{version}-%{release}.%{_arch}" >> ${TARGET}
	_msg "%description" >> ${TARGET}
	_msg "${Description}" >> ${TARGET}
	return
}
function _prep {
	local i=""
	_msg "#-----------------------------------------------------------------------------" >> ${TARGET}
	_msg "%prep" >> ${TARGET}
	_msg "${Prep}" >> ${TARGET}
	_msg "#-----------------------------------------------------------------------------" >> ${TARGET}
	return
}
function _build {
	_msg "%build" >> ${TARGET}
	_msg '%{_cflags}' >> ${TARGET}
	_msg '%{_cxxflags}' >> ${TARGET}
	_msg "${Build}" >> ${TARGET}
_msg "#-----------------------------------------------------------------------------" >> ${TARGET}
	return
}
function _install {
	_msg "%install" >> ${TARGET}
	_msg 'directory=$(pwd)' >> ${TARGET}
	_msg "${Install}" >> ${TARGET}
	#	Create file list
	_msg "#	Create file list" >> ${TARGET}
	_msg 'cd ${directory}' >> ${TARGET}
	_msg '[ -e %{buildroot}/usr/share/info/dir ] && rm  %{buildroot}/usr/share/info/dir' >> ${TARGET}
	_msg_line  'find "%{buildroot}" -name '  >> ${TARGET}
	_msg_line "'*.la'" >> ${TARGET}
	_msg ' -delete' >> ${TARGET}
	_msg "find '%{buildroot}' -not -type d -print > filelist.rpm" >> ${TARGET}
	_msg "sed -i 's|^%{buildroot}||' filelist.rpm" >> ${TARGET}
#	_msg "sed -i '/man\/man/d' filelist.rpm" >> ${TARGET}
#	_msg "sed -i '/\/usr\/share\/info/d' filelist.rpm" >> ${TARGET}
	_msg "#-----------------------------------------------------------------------------" >> ${TARGET}
	return
}
function _clean {
	_msg "%clean" >> ${TARGET}
	_msg "rm -rf %{_builddir}" >> ${TARGET}
	_msg "rm -rf %{buildroot}" >> ${TARGET}
	_msg "#-----------------------------------------------------------------------------" >> ${TARGET}
	return
}
function _files {
	_msg "%files -f filelist.rpm" >> ${TARGET}
	_msg "${Files}" >> ${TARGET}
	_msg "#-----------------------------------------------------------------------------" >> ${TARGET}
	return
}
function _changelog {
_msg "%changelog" >> ${TARGET}
_msg "*	$(date +'%a %b %d %Y') scott andrews <scott-andrews@columbus.rr.com> ${Version}-${Release}" >> ${TARGET}
_msg "-	Initial build.	First version" >> ${TARGET}
	return
}
function _post {
	_msg "%post" >> ${TARGET}
	_msg "${Post}" >> ${TARGET}
	_msg "#-----------------------------------------------------------------------------" >> ${TARGET}
	return
}
function _postun {
	_msg "%postun" >> ${TARGET}
	_msg "${PostUN}" >> ${TARGET}
	_msg "#-----------------------------------------------------------------------------" >> ${TARGET}
	return
}
function _pre {
	_msg "%pre" >> ${TARGET}
	_msg "${Pre}" >> ${TARGET}
	_msg "#-----------------------------------------------------------------------------" >> ${TARGET}
	return
}
#_msg "${PRGNAME}"
#	Globals
Summary=""
Name=""
Version=""
Release=""
License=""
URL=""
Group="LFS/Base"
Vendor="Elizabeth"
Source=""
Patch0=""
Requires=""
BuildRoot='%{_buildrootdir}/%{name}-%{version}-%{release}.%{_arch}'
Description=""
Prep=""
Build=""
Install=""
Files=""
Clean=""
ChangeLog=""
Post=""
PostUN=""
Pre=""
#	Initialize
#[ -d ${PKGDIR} ]	||	_die "Package data directory missing"
[ -d ${SPECDIR} ]	||	mkdir ${SPECDIR}
#		read parmeter text file into variables
echo ${1}
source ./${1}
TARGET="${SPECDIR}/${Name}.spec"
[ -e "${TARGET}" ] && rm "${TARGET}"
_header
_prep
_build
_install
_clean
_files
[ ! "${Pre}" = '' ] && _pre
[ ! "${Post}" = '' ] && _post
[ ! "${PostUN}" = '' ] && _postun
_changelog
