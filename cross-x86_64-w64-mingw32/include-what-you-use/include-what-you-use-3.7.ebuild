# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit eutils cmake-utils flag-o-matic

WEIRD_UPSREAM_VERSION=0.5

DESCRIPTION="find unused include directives in C/C++ programs"
HOMEPAGE="https://github.com/include-what-you-use/include-what-you-use"
SRC_URI="http://include-what-you-use.org/downloads/${PN}-${WEIRD_UPSREAM_VERSION}.src.tar.gz -> ${P}.src.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="=${CATEGORY}/llvm-3.7*
	=${CATEGORY}/clang-3.7*"
DEPEND="${RDEPEND}"

S=${WORKDIR}/${PN}
CTARGET=${CATEGORY#cross-}

src_prepare() {
	epatch_user
}

src_configure() {
	append-ldflags -L$(${CTARGET}-llvm-config --libdir)
	append-cppflags -I$(${CTARGET}-llvm-config --includedir)

	local mycmakeargs=(
		-DIWYU_LLVM_ROOT_PATH=$(${CTARGET}-llvm-config --libdir)
	)
	cmake-utils_src_configure
}
