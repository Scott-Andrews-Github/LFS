Summary: Meta package for LFS Base installation
Name: base
Version: 9.0
Release: 1
License: None
URL: None
Group: LFS/Base
Vendor: Elizabeth
Requires:	filesystem
Requires:	linux-api-headers
Requires:	man-pages
Requires:	glibc
Requires:	tzdata
Requires:	zlib
Requires:	file
Requires:	readline
Requires:	m4
Requires:	bc
Requires:	binutils
Requires:	gmp
Requires:	mpfr
Requires:	mpc
Requires:	shadow
Requires:	gcc
Requires:	bzip2
Requires:	pkg-config
Requires:	ncurses
Requires:	attr
Requires:	acl
Requires:	libcap
Requires:	sed
Requires:	psmisc
Requires:	iana-etc
Requires:	bison
Requires:	flex
Requires:	grep
Requires:	bash
Requires:	libtool
Requires:	gdbm
Requires:	gperf
Requires:	expat
Requires:	inetutils
Requires:	perl
Requires:	XML-Parser
Requires:	intltool
Requires:	autoconf
Requires:	automake
Requires:	xz
Requires:	kmod
Requires:	gettext
Requires:	libelf
Requires:	libffi
Requires:	openssl
Requires:	python3
Requires:	ninja
Requires:	meson
Requires:	coreutils
Requires:	check
Requires:	diffutils
Requires:	gawk
Requires:	findutils
Requires:	groff
Requires:	less
Requires:	gzip
Requires:	iproute2
Requires:	kbd
Requires:	libpipeline
Requires:	make
Requires:	patch
Requires:	man-db
Requires:	tar
Requires:	texinfo
Requires:	vim
Requires:	procps-ng
Requires:	util-linux
Requires:	e2fsprogs
Requires:	sysklogd
Requires:	sysvinit
Requires:	eudev
Requires:	lfs-bootscripts
Requires:	raspberry-pi-kernel
Requires:	rpi-bootscripts
Requires:	raspberry-pi-firmware
Requires:	wget
Requires:	openssh
Requires:	popt
Requires:	rpm
BuildRoot: %{_buildrootdir}/%{name}-%{version}-%{release}.%{_arch}
%description
Meta package for LFS Base installation
#-----------------------------------------------------------------------------
%prep
#-----------------------------------------------------------------------------
%build
#-----------------------------------------------------------------------------
%install
#-----------------------------------------------------------------------------
%clean
rm -rf %{_builddir}
rm -rf %{buildroot}
#-----------------------------------------------------------------------------
%files
#-----------------------------------------------------------------------------
%changelog
*	Tue Jan 21 2020 baho-utot <baho-utot@columbus.rr.com> 9.0-1
-	Initial build.	First version
