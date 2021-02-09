# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
PYTHON_COMPAT=( python3_{8,9} )

SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x64-macos ~x64-solaris"

inherit distutils-r1

DESCRIPTION="Uberdoc is a wrapper script for pandoc which provides a build system for large documents"
HOMEPAGE="https://github.com/sbrosinski/uberdoc"

LICENSE="MIT"
SLOT="0"
IUSE="+pdf"
RESTRICT="test"

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND="
	app-text/pandoc
	dev-python/jinja
	pdf? ( app-text/texlive[luatex] )
"

#python_install_all() {
#	distutils-r1_python_install_all
#}
