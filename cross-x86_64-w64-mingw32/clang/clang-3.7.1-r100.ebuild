# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

DESCRIPTION="C language family frontend for LLVM (meta-ebuild)"
HOMEPAGE="http://clang.llvm.org/"
SRC_URI=""

LICENSE="UoI-NCSA"
SLOT="0/3.7"
KEYWORDS="~amd64 ~x86"
IUSE="debug multitarget python +static-analyzer"

CTARGET=${CATEGORY#cross-}

RDEPEND="~${CATEGORY}/llvm-${PV}[clang(-),debug=,multitarget?,python?,static-analyzer?]"

# Please keep this package around since it's quite likely that we'll
# return to separate LLVM & clang ebuilds when the cmake build system
# is complete.

pkg_postinst() {
	if has_version ">=dev-util/ccache-3.1.9-r2" ; then
		#add ccache links as clang might get installed after ccache
		"${EROOT}"/usr/bin/ccache-config --install-links ${CTARGET}
	fi
}

pkg_postrm() {
	if has_version ">=dev-util/ccache-3.1.9-r2" && [[ -z ${REPLACED_BY_VERSION} ]]; then
		# --remove-links would remove all links, --install-links updates them
		"${EROOT}"/usr/bin/ccache-config --install-links ${CTARGET}
	fi
}
