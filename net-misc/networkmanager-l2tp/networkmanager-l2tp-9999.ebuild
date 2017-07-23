# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"
GCONF_DEBUG="no"
EGIT_REPO_URI="https://github.com/nm-l2tp/network-manager-l2tp.git"

inherit autotools git-r3

SRC_URI=""
DESCRIPTION="NetworkManager Openswan plugin"
HOMEPAGE="https://wiki.gnome.org/Projects/NetworkManager"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS=""
IUSE="gtk"

RDEPEND="
	net-dialup/ppp
	net-dialup/xl2tpd

	>=dev-libs/glib-2.32:2
	>=dev-libs/libnl-3.2.8:3
	>=net-misc/networkmanager-1.1.90:=
	>=dev-libs/dbus-glib-0.74
	|| ( net-vpn/libreswan net-vpn/strongswan )
	gtk? (
		app-crypt/libsecret
		>=gnome-extra/nm-applet-1.1.0
		>=x11-libs/gtk+-3.4:3
	)
"
DEPEND="${RDEPEND}
	sys-devel/gettext
	dev-util/intltool
	virtual/pkgconfig
"

src_prepare() {
	#epatch "${FILESDIR}/disable-atmark.patch"
	eautoreconf
}

src_configure() {
	econf \
		--disable-more-warnings \
		--disable-static \
		--with-dist-version=Gentoo \
		--disable-maintainer-mode \
		--disable-silent-rules \
		--enable-more-warnings=yes \
		$(use_with gtk gnome)
}
