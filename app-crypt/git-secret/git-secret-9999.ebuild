# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
EGIT_REPO_URI="https://github.com/sobolevn/git-secret.git"
inherit git-r3

DESCRIPTION=""
HOMEPAGE="https://github.com/sobolevn/git-secret"

LICENSE="MIT"
SLOT="0"
if [ "${PV}" = 9999 ]; then
	KEYWORDS=""
else
	KEYWORDS="~amd64 ~x86"
fi
IUSE=""

DEPEND="
	>=app-shells/bash-3.2.57"
RDEPEND="${DEPEND}
	>=sys-apps/gawk-4.0.2
	>=dev-vcs/git-1.8.3.1
	>=app-crypt/gnupg-1.4
	"
BDEPEND=""

src_compile() {
	emake
}

src_install() {
	make DESTDIR=${D} install
}
