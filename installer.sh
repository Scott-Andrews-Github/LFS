#!/bin/bash
#-----------------------------------------------------------------------------
#	  Title: installer.sh
#	   Date: 2019-05-22
#	Version: 1.0
#	 Author: baho-utot@columbus.rr.com
#	Options:
#-----------------------------------------------------------------------------
#	Copyright 2019 Baho Utot
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
#	This script installs LFS base rpms to a partition mounted at /mnt
#	the partition should be a new/clean partition as it will be overwritten
#-----------------------------------------------------------------------------
#	Dedicated to Elizabeth my cat of 20 years, Euthanasia on 2019-05-16
#-----------------------------------------------------------------------------
set -o errexit	# exit if error...insurance ;)
set -o nounset	# exit if variable not initalized
set +h			# disable hashall
#-----------------------------------------------------------------------------
PRGNAME=${0##*/}			#	script name minus the path
REPOPATH="RPMS/armv7hnl"		#	path to the binary rpms
ROOTPATH="/mnt/installer"		#	path to install filesystem
BASE="SPECS/base.spec"	#	filespec SPECS/base.spec
DBPATH="/var/lib/rpm"		#	path to the rpm database rel to ROOTPATH
LIST=""				#	list of packages to install 
#-----------------------------------------------------------------------------
function _die() {
	local _red="\\033[1;31m"
	local _normal="\\033[0;39m"
	[ -n "$*" ] && printf "${_red}$*${_normal}\n"
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
	printf "${_green}%s${_normal}\n" "Run Complete"
	return
}
#-----------------------------------------------------------------------------
_msg ""
_msg "${PRGNAME}:"
[ ${EUID} -eq 0 ] || _die "Not running as user root, you should be!"
if [ ! /usr/bin/mountpoint ${ROOTPATH} > /dev/null 2>&1 ]; then _die "Hey ${ROOTPATH} is not mounted"; fi
_msg "Variable:  PRGNAME: ${PRGNAME}"
_msg "Variable: REPOPATH: ${REPOPATH}"
_msg "Variable: ROOTPATH: ${ROOTPATH}"
_msg "Variable:     BASE: ${BASE}"
_msg "Variable:   DBPATH: ${DBPATH}"
install -vdm 755 "${ROOTPATH}${DBPATH}"
rpmdb --verbose --initdb --dbpath="${ROOTPATH}${DBPATH}"
#	This reads all the rpm binary packages from SPECS/base.spec
while  read i; do
	i=$(echo ${i} | tr -d '[:cntrl:][:space:]')
	case ${i} in
		Requires:*)	
			j="${i##Requires:}"
			case ${j} in
				base*)		;;
				filesystem*)	;;
				*)	LIST+="${j} " ;;
			esac
			;;
		*) ;;
	esac
done < "${BASE}"
LIST="filesystem ${LIST} "
LIST+="base"
for i in ${LIST}; do
#	_msg "Installing: %s\n" "${i}"
	j=$(echo ${REPOPATH}/${i}* | cut -d ' ' -f 1)
	rpm --upgrade --verbose --hash --ignorearch --nodeps --noscripts --root ${ROOTPATH} --dbpath ${DBPATH} ${j}
done
#SWAP_FILE_SIZE=2048
#if [ ! -e ${ROOTPATH}/swapfile ]; then
#	_msg "Creating swap file: ${ROOTPATH}/swapfile: "
#	dd if=/dev/zero of=${ROOTPATH}/swapfile status=progress bs=1M count=${SWAP_FILE_SIZE}
#	chmod 600 ${ROOTPATH}/swapfile
#	mkswap ${ROOTPATH}/swapfile
#	swapon -v ${ROOTPATH}/swapfile
#	_msg_success
#fi
cat > ${ROOTPATH}/tmp/script.sh <<- EOF
	/sbin/ldconfig
	/sbin/locale-gen
	/usr/sbin/pwconv
	/usr/sbin/grpconv
	/usr/sbin/groupadd -g 50 sshd
	/usr/sbin/useradd -c 'sshd PrivSep' -d /var/lib/sshd -g sshd -s /bin/false -u 50 sshd
       /usr/bin/ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ""
	/usr/bin/ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ""
	/usr/bin/ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ""
	/usr/bin/ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
	/usr/bin/vim /etc/sysconfig/clock
	/usr/bin/vim /etc/passwd
	/usr/bin/vim /etc/hosts
	/usr/bin/vim /etc/hostname
	/usr/bin/vim /etc/fstab
	/usr/bin/vim /etc/sysconfig/ifconfig.eth0
	/usr/bin/vim /etc/resolv.conf
	/usr/bin/vim /etc/lsb-release
	/usr/bin/vim /etc/sysconfig/rc.site
	/usr/bin/vim /etc/ssh/sshd_config
	/usr/sbin/useradd -m rpi
	/bin/passwd -delete rpi
EOF
chmod +x ${ROOTPATH}/tmp/script.sh
chroot ${ROOTPATH} /usr/bin/env -i \
	HOME=/root \
	TERM="${TERM}" \
	PS1='(installer) \u:\w:\$' \
	PATH=/bin:/usr/bin:/sbin:/usr/sbin \
	/bin/bash --login -c 'cd /tmp;./script.sh'
_end_run
