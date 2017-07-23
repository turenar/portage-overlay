# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"
PYTHON_COMPAT=( python2_7 )
PLOCALES="de ja zh_CN zh_TW"
inherit elisp-common eutils l10n multilib multiprocessing python-single-r1 toolchain-funcs versionator

DESCRIPTION="The Mozc engine for IBus Framework"
HOMEPAGE="https://github.com/google/mozc"

MOZC_VER="$(get_version_component_range 1-4 ${PV})"
NEOLOGD_VER="$(get_version_component_range 5 ${PV})"
DICT_UT_VER="20170525"
DICT_UT_REV="1"

PROTOBUF_VER="3.3.0"
GMOCK_VER="1.6.0"
GTEST_VER="1.6.0"
JSONCPP_VER="0.6.0-rc2"
GYP_DATE="20160404"
JAPANESE_USAGE_DICT_VER="10"
FCITX_PATCH_BASE_VER="2.18.2612.102"
FCITX_PATCH_VER="1"
FCITX_PATCH="fcitx-mozc-${FCITX_PATCH_BASE_VER}.${FCITX_PATCH_VER}.patch"
#MOZC_URL="https://dev.gentoo.org/~naota/files/${P}.tar.bz2"
MOZC_URL="https://turenar.xyz/pub/mozc-${MOZC_VER}-with-deps.tar.xz"
#PROTOBUF_URL="https://protobuf.googlecode.com/files/protobuf-${PROTOBUF_VER}.tar.bz2"
PROTOBUF_URL="https://github.com/google/protobuf/archive/v${PROTOBUF_VER}.zip"
GMOCK_URL="https://googlemock.googlecode.com/files/gmock-${GMOCK_VER}.zip"
GTEST_URL="https://googletest.googlecode.com/files/gtest-${GTEST_VER}.zip"
JSONCPP_URL="mirror://sourceforge/jsoncpp/jsoncpp-src-${JSONCPP_VER}.tar.gz"
#GYP_URL="https://dev.gentoo.org/~naota/files/gyp-${GYP_DATE}.tar.bz2"
GYP_URL="https://turenar.xyz/pub/gyp-${GYP_DATE}.tar.xz"
JAPANESE_USAGE_DICT_URL="https://dev.gentoo.org/~naota/files/japanese-usage-dictionary-${JAPANESE_USAGE_DICT_VER}.tar.bz2"

DICT_UT_URL="https://turenar.xyz/pub/mozcdic-neologd-ut-${DICT_UT_VER}.${DICT_UT_REV}.tar.bz2"
NEOLOGD_DICT_URL="https://turenar.xyz/pub/mecab-user-dict-seed.${NEOLOGD_VER}.csv.xz"

FCITX_PATCH_URL="http://download.fcitx-im.org/fcitx-mozc/${FCITX_PATCH}"
SRC_URI="${MOZC_URL}
	fcitx? ( ${FCITX_PATCH_URL} )
	test? ( ${GMOCK_URL} ${GTEST_URL} ${JSONCPP_URL} )
	dict_neologd? ( ${DICT_UT_URL} ${NEOLOGD_DICT_URL} )"

LICENSE="BSD ipadic public-domain unicode"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="emacs fcitx +ibus +qt4 renderer test"
IUSE="${IUSE} dict_neologd"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="app-i18n/tegaki-zinnia-japanese
	dev-libs/glib:2
	>=dev-libs/protobuf-3.0.0
	x11-libs/libxcb
	emacs? ( virtual/emacs )
	fcitx? ( app-i18n/fcitx )
	ibus? (
		>=app-i18n/ibus-1.4.1
		qt4? ( app-i18n/ibus-qt )
	)
	renderer? ( x11-libs/gtk+:2 )
	qt4? (
		dev-qt/qtgui:4
		app-i18n/zinnia
	)
	${PYTHON_DEPS}"
DEPEND="${RDEPEND}
	dev-util/ninja
	virtual/pkgconfig
	dict_neologd? ( dev-lang/ruby )"

BUILDTYPE="${BUILDTYPE:-Release}"

RESTRICT="test"

SITEFILE=50${PN}-gentoo.el

S="${WORKDIR}/${PN}-${MOZC_VER}/src"
DICT_UT_S="${WORKDIR}/mozcdic-neologd-ut-${DICT_UT_VER}.${DICT_UT_REV}"

src_unpack() {
	unpack $(basename ${MOZC_URL})

	#unpack $(basename ${GYP_URL})
	#unpack $(basename ${JAPANESE_USAGE_DICT_URL})
	#test -d "${S}"/third_party/gyp && rm -rf "${S}"/third_party/gyp
	#mv gyp-${GYP_DATE} "${S}"/third_party/gyp || die
	#test -d "${S}"/third_party/japanese_usage_dictionary && rm -rf "${S}"/third_party/japanese_usage_dictionary
	#mv japanese-usage-dictionary-${JAPANESE_USAGE_DICT_VER} "${S}"/third_party/japanese_usage_dictionary || die

	#cd "${S}"/protobuf
	#unpack $(basename ${PROTOBUF_URL})
	#mv protobuf-${PROTOBUF_VER} files || die

	if use test; then
		cd "${S}"/third_party
		#unpack $(basename ${GMOCK_URL}) $(basename ${GTEST_URL}) \
		#	$(basename ${JSONCPP_URL})
		#mv gmock-${GMOCK_VER} gmock || die
		#mv gtest-${GTEST_VER} gtest || die
		#mv jsoncpp-src-${JSONCPP_VER} jsoncpp || die
	fi

	if use dict_neologd; then
		cd "${WORKDIR}"
		unpack $(basename ${DICT_UT_URL})
		cp ${DISTDIR}/$(basename ${NEOLOGD_DICT_URL}) \
			${DICT_UT_S}/mecab-ipadic-neologd/ || die
		cd "${S}"
	fi
}

src_prepare() {
	local my_makeopts=$(makeopts_jobs)
	# This is for a safety. -j without a number, makeopts_jobs returns 999.
	local myjobs=-j${my_makeopts/999/1}

	# verbose build and restrict parallelism
	sed -i -e "/RunOrDie(\[make_command\]/s/build_args/build_args + [\"-v\"]/" \
		-e "s/RunOrDie(\[ninja, '-C', build_arg\] + ninja_targets)/RunOrDie([ninja, '-C', build_arg, '${myjobs}', '-v'] + ninja_targets)/" \
		build_mozc.py || die
	sed -i -e "s/<!(which clang)/$(tc-getCC)/" \
		-e "s/<!(which clang++)/$(tc-getCXX)/" \
		gyp/common.gypi || die
	if use fcitx; then
		EPATCH_OPTS="-p2" epatch "${DISTDIR}/${FCITX_PATCH}"
	fi
	if use dict_neologd; then
		# do not rename mozc and compress tar
		cd "${DICT_UT_S}"
		EPATCH_OPTS="-p1" epatch "${FILESDIR}/neologd-build-20170717.patch" || die
		sed -i -e 's/MOZCVER=".\+"/MOZCVER="'${MOZC_VER}'"/' \
			-e 's/DICVER=".\+"/DICVER="'${NEOLOGD_VER}'"/' \
			-e 's/REVISION=".\+"/REVISION="'${DICT_UT_REV}'"/' \
			generate-dictionary.sh || die
	fi
	epatch_user
}

src_configure() {
	local myconf="--server_dir=/usr/$(get_libdir)/mozc"

	if use dict_neologd; then
		cd "${DICT_UT_S}"
		elog "generating neologd dictionary"
		bash -xe generate-dictionary.sh || die
		cd "${S}"
	fi

	if ! use qt4 ; then
		myconf+=" --noqt"
		export GYP_DEFINES="use_libzinnia=0"
	fi

	if ! use renderer ; then
		export GYP_DEFINES="${GYP_DEFINES} enable_gtk_renderer=0"
	fi

	export GYP_DEFINES="${GYP_DEFINES} use_libprotobuf=1 compiler_target=gcc compiler_host=gcc"

	tc-export CC CXX AR AS RANLIB LD NM

	"${PYTHON}" build_mozc.py gyp -v ${myconf} || die "gyp failed"
}

src_compile() {
	tc-export CC CXX AR AS RANLIB LD

	local mytarget="server/server.gyp:mozc_server"
	use emacs && mytarget="${mytarget} unix/emacs/emacs.gyp:mozc_emacs_helper"
	use fcitx && mytarget="${mytarget} unix/fcitx/fcitx.gyp:fcitx-mozc"
	use ibus && mytarget="${mytarget} unix/ibus/ibus.gyp:ibus_mozc"
	use renderer && mytarget="${mytarget} renderer/renderer.gyp:mozc_renderer"
	if use qt4 ; then
		export QTDIR="${EPREFIX}/usr"
		mytarget="${mytarget} gui/gui.gyp:mozc_tool"
	fi

	# V=1 "${PYTHON}" build_mozc.py build_tools -c "${BUILDTYPE}" ${myjobs} || die
	"${PYTHON}" build_mozc.py build -v -c "${BUILDTYPE}" ${mytarget} || die

	if use emacs ; then
		elisp-compile unix/emacs/*.el || die
	fi
}

src_test() {
	tc-export CC CXX AR AS RANLIB LD
	V=1 "${PYTHON}" build_mozc.py runtests -c "${BUILDTYPE}" || die
}
src_install() {
	install_fcitx_locale() {
		lang=$1
		insinto "/usr/share/locale/${lang}/LC_MESSAGES/"
		newins out_linux/${BUILDTYPE}/gen/unix/fcitx/po/${lang}.mo fcitx-mozc.mo
	}

	if use emacs ; then
		dobin "out_linux/${BUILDTYPE}/mozc_emacs_helper" || die
		elisp-install ${PN} unix/emacs/*.{el,elc} || die
		elisp-site-file-install "${FILESDIR}/${SITEFILE}" ${PN} || die
	fi

	if use fcitx; then
		exeinto /usr/$(get_libdir)/fcitx
		doexe "out_linux/${BUILDTYPE}/fcitx-mozc.so"
		insinto /usr/share/fcitx/addon
		doins "unix/fcitx/fcitx-mozc.conf"
		insinto /usr/share/fcitx/inputmethod
		doins "unix/fcitx/mozc.conf"
		insinto /usr/share/fcitx/mozc/icon
		(
			cd data/images
			newins product_icon_32bpp-128.png mozc.png
			cd unix
			for f in ui-* ; do
				newins ${f} mozc-${f/ui-}
			done
		)
		l10n_for_each_locale_do install_fcitx_locale
	fi

	if use ibus ; then
		exeinto /usr/$(get_libdir)/ibus-mozc || die
		newexe "out_linux/${BUILDTYPE}/ibus_mozc" ibus-engine-mozc || die
		insinto /usr/share/ibus/component || die
		doins "out_linux/${BUILDTYPE}/gen/unix/ibus/mozc.xml" || die
		insinto /usr/share/ibus-mozc || die
		(
			cd data/images/unix
			newins ime_product_icon_opensource-32.png product_icon.png || die
			for f in ui-*
			do
				newins ${f} ${f/ui-} || die
			done
		)

	fi

	exeinto "/usr/$(get_libdir)/mozc" || die
	doexe "out_linux/${BUILDTYPE}/mozc_server" || die

	if use qt4 ; then
		exeinto "/usr/$(get_libdir)/mozc" || die
		doexe "out_linux/${BUILDTYPE}/mozc_tool" || die
	fi

	if use renderer ; then
		exeinto "/usr/$(get_libdir)/mozc" || die
		doexe "out_linux/${BUILDTYPE}/mozc_renderer" || die
	fi
}

pkg_postinst() {
	if use emacs ; then
		elisp-site-regen
		elog "You can use mozc-mode via LEIM (Library of Emacs Input Method)."
		elog "Write the following settings into your init file (~/.emacs.d/init.el"
		elog "or ~/.emacs) in order to use mozc-mode by default, or you can call"
		elog "\`set-input-method' and set \"japanese-mozc\" anytime you have loaded"
		elog "mozc.el"
		elog
		elog "  (require 'mozc)"
		elog "  (set-language-environment \"Japanese\")"
		elog "  (setq default-input-method \"japanese-mozc\")"
		elog
		elog "Having the above settings, just type C-\\ which is bound to"
		elog "\`toggle-input-method' by default."
	fi
}

pkg_postrm() {
	use emacs && elisp-site-regen
}
