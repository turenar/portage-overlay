# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools pam systemd


DESCRIPTION="Highly configurable free RADIUS server"

if [ ${PV} = 9999 ]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/FreeRADIUS/freeradius-server.git"
	KEYWORDS=""
	MY_P="${P}"
else
	SRC_URI="
		ftp://ftp.freeradius.org/pub/radius/${MY_P}.tar.gz
		ftp://ftp.freeradius.org/pub/radius/old/${MY_P}.tar.gz
	"
	KEYWORDS="amd64 ~arm arm64 ~ppc ~ppc64 ~sparc x86"
	MY_P="${PN}-server-${PV}"
fi

HOMEPAGE="http://www.freeradius.org/"

LICENSE="GPL-2"
SLOT="0"

IUSE="
	debug doc firebird iodbc kerberos ldap libressl memcached mysql mongodb odbc oracle pam
	pcap postgres readline redis rest samba sqlite ssl systemd
"
RESTRICT="test firebird? ( bindist )"

# NOTE: Temporary freeradius doesn't support linking with mariadb client
#       libs also if code is compliant, will be available in the next release.
#       (http://lists.freeradius.org/pipermail/freeradius-devel/2018-October/013228.html)a

# TODO: rlm_mschap works with both samba library or without. I need to avoid
#       linking of samba library if -samba is used.
RDEPEND="acct-group/radius
	acct-user/radius
	!net-dialup/cistronradius
	dev-lang/perl:=
	dev-libs/libkqueue
	sys-libs/gdbm:=
	sys-libs/talloc
	doc? ( dev-ruby/asciidoctor app-text/pandoc )
	firebird? ( dev-db/firebird )
	iodbc? ( dev-db/libiodbc )
	kerberos? ( virtual/krb5 )
	ldap? ( net-nds/openldap )
	memcached? ( dev-libs/libmemcached )
	mysql? ( dev-db/mysql-connector-c )
	mongodb? ( >=dev-libs/mongo-c-driver-1.13.0-r1 )
	odbc? ( dev-db/unixODBC )
	oracle? ( dev-db/oracle-instantclient-basic )
	pam? ( sys-libs/pam )
	pcap? ( net-libs/libpcap )
	postgres? ( dev-db/postgresql:= )
	readline? ( sys-libs/readline:0= )
	redis? ( dev-libs/hiredis:= )
	rest? ( dev-libs/json-c:= )
	samba? ( net-fs/samba )
	sqlite? ( dev-db/sqlite:3 )
	ssl? (
		!libressl? ( dev-libs/openssl:0=[-bindist] )
		libressl? ( dev-libs/libressl:0= )
	)
	systemd? ( sys-apps/systemd )"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${MY_P}"

PATCHES=(
	"${FILESDIR}"/${P}-systemd-service.patch
	"${FILESDIR}"/${P}-python3-fix-cflags.patch
)

src_prepare() {
	# most of the configuration options do not appear as ./configure
	# switches. Instead it identifies the directories that are available
	# and run through them. These might check for the presence of
	# various libraries, in which case they are not built.  To avoid
	# automagic dependencies, we just remove all the modules that we're
	# not interested in using.

	eapply_user
	default

	use ssl || { rm -r src/modules/rlm_eap/types/rlm_eap_{tls,ttls,peap} || die ; }
	use ldap || { rm -r src/modules/rlm_ldap || die ; }
	use kerberos || { rm -r src/modules/rlm_krb5 || die ; }
	use memcached || { rm -r src/modules/rlm_cache/drivers/rlm_cache_memcached || die ; }
	use pam || { rm -r src/modules/rlm_pam || die ; }
	use rest || { rm -r src/modules/rlm_rest || die ; }
	use redis || { rm -r src/modules/rlm_redis{,who} || die ; }
	# Do not install ruby rlm module, bug #483108
	rm -r src/modules/rlm_mruby || die

	# these are all things we don't have in portage/I don't want to deal
	# with myself
	rm -r src/modules/rlm_opendirectory || die # requires some membership.h
	rm -r src/modules/rlm_sql/drivers/rlm_sql_{db2,freetds} || die

	# sql drivers that are not part of experimental are loaded from a
	# file, so we have to remove them from the file itself when we
	# remove them.
	usesqldriver() {
		local flag=$1
		local driver=rlm_sql_${2:-${flag}}

		if ! use ${flag}; then
			rm -r src/modules/rlm_sql/drivers/${driver} || die
			sed -i -e /${driver}/d src/modules/rlm_sql/stable || die
		fi
	}

	sed -i \
		-e 's:^#\tuser = :\tuser = :g' \
		-e 's:^#\tgroup = :\tgroup = :g' \
		-e 's:/var/run/radiusd:/run/radiusd:g' \
		-e '/^run_dir/s:${localstatedir}::g' \
		raddb/radiusd.conf.in || die

	# verbosity
	# build shared libraries using jlibtool --shared
	sed -i \
		-e '/$(LIBTOOL)/s|--quiet ||g' \
		-e 's:--mode=\(compile\|link\):& --shared:g' \
		Make.inc.in || die

	sed -i \
		-e 's|--silent ||g' \
		-e 's:--mode=\(compile\|link\):& --shared:g' \
		scripts/libtool.mk || die

	# crude measure to stop jlibtool from running ranlib and ar
	sed -i \
		-e '/LIBRARIAN/s|".*"|"true"|g' \
		-e '/RANLIB/s|".*"|"true"|g' \
		scripts/jlibtool.c || die

	usesqldriver mysql
	usesqldriver postgres postgresql
	usesqldriver firebird
	usesqldriver odbc unixodbc
	usesqldriver oracle
	usesqldriver sqlite

	eautoreconf
}

src_configure() {
	# do not try to enable static with static-libs; upstream is a
	# massacre of libtool best practices so you also have to make sure
	# to --enable-shared explicitly.
	local myeconfargs=(
		--enable-shared
		--disable-static
		--disable-ltdl-install
		--with-system-libtool
		--with-system-libltdl
		--with-ascend-binary
		--with-udpfromto
		--with-dhcp
		--with-iodbc-include-dir=/usr/include/iodbc
		--with-experimental-modules
		--with-docdir=/usr/share/doc/${PF}
		--with-logdir=/var/log/radius
		$(use_enable debug developer)
		$(use_with ldap edir)
		$(use_with ssl openssl)
		$(use_with systemd systemd)
	)
	# fix bug #77613
	if has_version app-crypt/heimdal; then
		myeconfargs+=( --enable-heimdal-krb5 )
	fi

	use readline || export ac_cv_lib_readline=no
	use pcap || export ac_cv_lib_pcap_pcap_open_live=no

	econf "${myeconfargs[@]}"
}

src_compile() {
	# verbose, do not generate certificates
	emake \
		Q='' ECHO=true \
		LOCAL_CERT_PRODUCTS=''
}

src_install() {
	dodir /etc
	diropts -m0750 -o root -g radius
	dodir /etc/raddb
	diropts -m0750 -o radius -g radius
	dodir /var/log/radius
	keepdir /var/log/radius/radacct
	diropts

	# verbose, do not install certificates
	# Parallel install fails (#509498)
	emake -j1 \
		Q='' ECHO=true \
		LOCAL_CERT_PRODUCTS='' \
		R="${D}" \
		install

	pamd_mimic_system radiusd auth account password session

	dodoc CREDITS

	rm "${ED}/usr/sbin/rc.radiusd" || die

	newinitd "${FILESDIR}/radius.init-r3" radiusd
	newconfd "${FILESDIR}/radius.conf-r4" radiusd

	if ! use systemd ; then
		# If systemd builtin is not enabled we need use Type=Simple
		# as systemd .service
		sed -i -e 's:^Type=.*::g' \
			-e 's:^WatchdogSec=.*::g' -e 's:^NotifyAccess=all.*::g' \
			"${S}"/debian/freeradius.service
	fi
	systemd_newtmpfilesd "${FILESDIR}"/freeradius.tmpfiles freeradius.conf
	systemd_dounit "${S}"/debian/freeradius.service

	find "${ED}" \( -name "*.a" -o -name "*.la" \) -delete || die
}

pkg_config() {
	if use ssl; then
		cd "${ROOT}"/etc/raddb/certs || die
		./bootstrap || die "Error while running ./bootstrap script."
		fowners root:radius "${ROOT}"/etc/raddb/certs
		fowners root:radius "${ROOT}"/etc/raddb/certs/ca.pem
		fowners root:radius "${ROOT}"/etc/raddb/certs/server.{key,crt,pem}
	fi
}

pkg_preinst() {
	if ! has_version ${CATEGORY}/${PN} && use ssl; then
		elog "You have to run \`emerge --config =${CATEGORY}/${PF}\` to be able"
		elog "to start the radiusd service."
	fi
}
