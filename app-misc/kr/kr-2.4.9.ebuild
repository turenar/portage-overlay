# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
DESCRIPTION="krypt.co/kr"
HOMEPAGE="https://krypt.co"

RPM_RELEASE_NUM="1"
SRC_URI="https://kryptco.github.io/yum/kr-${PV}-${RPM_RELEASE_NUM}.el7.centos.x86_64.rpm"
S="${WORKDIR}"
RESTRICT="strip"

inherit rpm

LICENSE="kryptco-all-rights-reserved"

SLOT="0"
KEYWORDS="~amd64"
IUSE=""
#RDEPEND=""
#DEPEND="${RDEPEND}"
#BDEPEND="dev-lang/go"

src_unpack() {
	rpm_unpack
}

src_install() {
	dobin usr/bin/*

	dolib.so usr/lib/kr-pkcs11.so
}
