# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit git-r3 linux-mod

DESCRIPTION=""
HOMEPAGE="https://github.com/roadrunner2/macbook12-spi-driver"

EGIT_REPO_URI="https://github.com/roadrunner2/macbook12-spi-driver.git"
#EGIT_BRANCH="touchbar-driver-hid-driver"

HWDB_GIST_REPO="1289542a748d9a104e7baec6a92f9cd7"
HWDB_GIST_COMMIT="1e11088843900223e18f9d16509c5419b96cb8a8"
SRC_URI="hwdb? ( https://gist.github.com/roadrunner2/${HWDB_GIST_REPO}/archive/${HWDB_GIST_COMMIT}.zip -> ${HWDB_GIST_REPO}-${HWDB_GIST_COMMIT}.zip )"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="+hwdb systemd"

RDEPEND=""

BUILD_TARGETS="all"
BUILD_TARGET_ARCH="${ARCH}"
MODULE_NAMES="applespi(misc:${S}) apple-ibridge(misc:${S}) apple-ib-tb(misc:${S}) apple-ib-als(misc:${S})"

pkg_setup() {
	CONFIG_CHECK="SPI_PXA2XX MFD_INTEL_LPSS_PCI IIO_TRIGGERED_BUFFER"

	linux-mod_pkg_setup

	BUILD_PARAMS="KDIR=${KV_DIR} KERNELRELEASE=${KV_FULL} O=${KV_OUT_DIR} V=1 KBUILD_VERBOSE=1"
}

src_unpack() {
	git-r3_src_unpack

	default
}

src_install() {
	linux-mod_src_install

	if use hwdb; then
		insinto "${EROOT}/etc/udev/hwdb.d/"
		cd "${WORKDIR}/${HWDB_GIST_REPO}-${HWDB_GIST_COMMIT}"
		doins 61-evdev-local.hwdb 61-libinput-local.hwdb
	fi
}

pkg_postinst() {
	linux-mod_pkg_postinst

	if test -e "${EROOT}lib/modules/${KV_FULL}/misc/appletb.ko"; then
		ewarn ""
		ewarn "You must remove ${EROOT}lib/modules/${KV_FULL}/misc/appletb.ko"
		ewarn " and migrate from appletb to apple-ib-tb in modprobe.conf,"
		ewarn " otherwise you see unexpected behavior."
	fi

	if use hwdb; then
		if use systemd; then
			systemd-hwdb update
		else
			udevadm hwdb --update
			udevadm trigger
		fi
	fi
}
