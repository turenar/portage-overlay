# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
DESCRIPTION="This is a sample skeleton ebuild file"
HOMEPAGE="https://foo.example.org/"
SRC_URI="https://s3.amazonaws.com/session-manager-downloads/plugin/${PV}/linux_64bit/session-manager-plugin.rpm -> ${P}.rpm"
S="${WORKDIR}"

# FIXME
LICENSE="all-rights-reserved"
RESTRICT="strip"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

inherit rpm systemd

src_unpack() {
	rpm_unpack ${P}.rpm || die
}

src_prepare() {
	default

	#sed -i \
	#	-e "s@usr/local@usr@g" \
	#	-e "s@usr/sessionmanagerplugin@usr@g" \
	#	etc/systemd/system/session-manager-plugin.service
}

src_install() {
	dobin usr/local/sessionmanagerplugin/bin/session-manager-plugin
	#systemd_dounit etc/systemd/system/session-manager-plugin.service
}

src_postinst() {
	default
	#einfo "You should start session-manager-plugin when machine powered"
	#einfo "With systemd,"
    #einfo "  systemctl daemon-reload"
    #einfo "  systemctl enable session-manager-plugin"
    #einfo "  systemctl start session-manager-plugin"
}
