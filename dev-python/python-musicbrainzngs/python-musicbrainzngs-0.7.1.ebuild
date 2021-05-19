# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
DESCRIPTION="This is a sample skeleton ebuild file"
HOMEPAGE="https://foo.example.org/"
SRC_URI="https://github.com/alastair/python-musicbrainzngs/archive/v${PV}.tar.gz"
#S="${WORKDIR}/${P}"
LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

PYTHON_COMPAT=( python3_{6,7,8,9} )
inherit distutils-r1 python-r1

RDEPEND="${PYTHON_DEPS}"
DEPEND="${RDEPEND}"
#BDEPEND="virtual/pkgconfig"

