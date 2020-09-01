# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake-utils
DESCRIPTION="A user space implementation of the kqueue(2) kernel event notification mechanism"
HOMEPAGE="https://github.com/mheily/libkqueue"
SRC_URI="https://github.com/mheily/libkqueue/archive/v${PV}.tar.gz"
LICENSE="MIT BSD-2"

SLOT="0"
KEYWORDS="~amd64"
IUSE="static"

RDEPEND=""
DEPEND="${RDEPEND}"
# set in cmake.eclass
#BDEPEND="virtual/pkgconfig"

src_configure() {
	local mycmakeargs=(
		-DSTATIC_KQUEUE="$(usex static)"
	)

	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
}

src_install() {
	cmake-utils_src_install
}
