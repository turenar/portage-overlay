# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-i18n/mozc/mozc-2.16.2037.102.ebuild,v 1.1 2015/02/25 07:27:12 naota Exp $

EAPI="5"
PYTHON_COMPAT=( python{2_6,2_7} )
inherit elisp-common eutils multilib multiprocessing python-single-r1 toolchain-funcs

DESCRIPTION="The Mozc engine for IBus Framework"
HOMEPAGE="http://code.google.com/p/mozc/"

PROTOBUF_VER="2.5.0"
GMOCK_VER="1.6.0"
GTEST_VER="1.6.0"
JSONCPP_VER="0.6.0-rc2"
GYP_DATE="20140602"
JAPANESE_USAGE_DICT_VER="10"
DICT_UT_VER="20150214"
MOZC_URL="http://dev.gentoo.org/~naota/files/${P}.tar.bz2"
PROTOBUF_URL="http://protobuf.googlecode.com/files/protobuf-${PROTOBUF_VER}.tar.bz2"
GMOCK_URL="https://googlemock.googlecode.com/files/gmock-${GMOCK_VER}.zip"
GTEST_URL="https://googletest.googlecode.com/files/gtest-${GTEST_VER}.zip"
JSONCPP_URL="mirror://sourceforge/jsoncpp/jsoncpp-src-${JSONCPP_VER}.tar.gz"
GYP_URL="http://dev.gentoo.org/~naota/files/gyp-${GYP_DATE}.tar.bz2"
JAPANESE_USAGE_DICT_URL="http://dev.gentoo.org/~naota/files/japanese-usage-dictionary-${JAPANESE_USAGE_DICT_VER}.tar.bz2"
DICT_UT_URL="http://einzbern.turenar.mydns.jp/pub/mozcdic-ut-${DICT_UT_VER}.tar.bz2"

SRC_URI="${MOZC_URL} ${PROTOBUF_URL} ${GYP_URL} ${JAPANESE_USAGE_DICT_URL}
	test? ( ${GMOCK_URL} ${GTEST_URL} ${JSONCPP_URL} )
	dict_ut? ( ${DICT_UT_URL} )"

LICENSE="BSD ipadic public-domain unicode"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE_EX_DICT="+dict_ut +dict_ut_altcanna +dict_ut_ejdic +dict_ut_zipcode +dict_ut_hatena dict_ut_nicodic"
IUSE="${IUSE_EX_DICT} emacs +ibus +qt4 renderer test"

REQUIRED_USE="dict_ut_altcanna? ( dict_ut )
	dict_ut_ejdic? ( dict_ut )
	dict_ut_zipcode? ( dict_ut )
	dict_ut_hatena? ( dict_ut )
	dict_ut_nicodic? ( dict_ut )"


RDEPEND="dev-libs/glib:2
	dev-libs/openssl
	>=dev-libs/protobuf-2.5.0
	x11-libs/libxcb
	emacs? ( virtual/emacs )
	ibus? ( >=app-i18n/ibus-1.4.1 )
	renderer? ( x11-libs/gtk+:2 )
	qt4? (
		dev-qt/qtgui:4
		app-i18n/zinnia
	)
	${PYTHON_DEPS}"
DEPEND="${RDEPEND}
	dict_ut? ( 
		=dev-lang/ruby-1.9*
		app-arch/unzip
	)

	dev-util/ninja
	virtual/pkgconfig"

BUILDTYPE="${BUILDTYPE:-Release}"

RESTRICT="test"

SITEFILE=50${PN}-gentoo.el

src_unpack() {
	unpack $(basename ${MOZC_URL})

	unpack $(basename ${GYP_URL})
	unpack $(basename ${JAPANESE_USAGE_DICT_URL})
	mv gyp-${GYP_DATE} "${S}"/third_party/gyp || die
	mv japanese-usage-dictionary-${JAPANESE_USAGE_DICT_VER} "${S}"/third_party/japanese_usage_dictionary || die

	cd "${S}"/protobuf
	unpack $(basename ${PROTOBUF_URL})
	mv protobuf-${PROTOBUF_VER} files || die

	if use test; then
		cd "${S}"/third_party
		unpack $(basename ${GMOCK_URL}) $(basename ${GTEST_URL}) \
			$(basename ${JSONCPP_URL})
		mv gmock-${GMOCK_VER} gmock || die
		mv gtest-${GTEST_VER} gtest || die
		mv jsoncpp-src-${JSONCPP_VER} jsoncpp || die
	fi
}

src_prepare() {
	# verbose build
	sed -i -e "/RunOrDie(\[make_command\]/s/build_args/build_args + [\"-v\"]/" \
		build_mozc.py || die
	sed -i -e "s/<!(which clang)/$(tc-getCC)/" \
		-e "s/<!(which clang++)/$(tc-getCXX)/" \
		gyp/common.gypi || die

	if use dict_ut; then
		cd "${S}"
		unpack $(basename ${DICT_UT_URL})
	fi

	epatch_user
}

src_configure() {
	local myconf="--server_dir=/usr/$(get_libdir)/mozc"

	if use dict_ut; then
		elog "Enabling Mozc-UT Dictionary..."
		if use dict_ut_nicodic; then
			ewarn " Enabling dict_ut_nicodic use flag,"
			ewarn " you will be unable to redistribute this package."
		fi
		cd "${S}"/mozcdic-ut-${DICT_UT_VER}
		# get official mozcdic
		cat ../data/dictionary_oss/dictionary*.txt > mozcdic_all.txt

		# get mozcdic costlist
		ruby19 32-* mozcdic_all.txt
		mv mozcdic_all.txt.cost costlist

		# get hinsi ID
		cp ../data/dictionary_oss/id.def .

		if use dict_ut_zipcode; then
			einfo Generating zipcode dictionary...
			cd chimei
			wget http://www.post.japanpost.jp/zipcode/dl/kogaki/zip/ken_all.zip
			wget http://www.post.japanpost.jp/zipcode/dl/jigyosyo/zip/jigyosyo.zip
			unzip ken_all.zip
			unzip jigyosyo.zip
			cp ../../dictionary/gen_zip_code_seed.py .
			"${PYTHON}" gen_zip_code_seed.py --zip_code=KEN_ALL.CSV \
				--jigyosyo=JIGYOSYO.CSV \
				>> ../../data/dictionary_oss/dictionary09.txt
			ruby19 get-entries.rb KEN_ALL.CSV
			cd ..
		fi
		einfo "check major ut dictionaries..."
		ruby19 12-* altcanna/altcanna.txt 300
		ruby19 12-* jinmei/jinmei.txt 20
		ruby19 12-* ekimei/ekimei.txt 300
		ruby19 12-* chimei/chimei.txt 300

		cat altcanna/altcanna.txt.r jinmei/jinmei.txt.r ekimei/ekimei.txt.r \
			chimei/chimei.txt.r > ut-dic1.txt

		ruby19 44-* mozcdic_all.txt ut-dic1.txt
		ruby19 36-* ut-dic1.txt.yomihyouki
		cat ut-dic1.txt.yomihyouki.cost mozcdic_all.txt > mozcdic_all.txt.utmajor

		einfo "check minor ut dictionaries..."
		ruby19 12-* skk/skk.txt 300
		if use dict_ut_ejdic; then
			ruby19 12-* edict/edict.txt 300
		fi
		if use dict_ut_hatena; then
			ruby19 12-* hatena/hatena.txt 30
		fi
		if use dict_ut_nicodic; then
			ruby19 12-* niconico/niconico.txt 300
		fi

		cat skk/skk.txt.r edict/edict.txt.r \
			$(use dict_ut_hatena && echo hatena/hatena.txt.r) \
			$(use dict_ut_nicodic && echo niconico/niconico.txt.r) \
			> ut-dic2.txt

		ruby19 42-* mozcdic_all.txt.utmajor ut-dic2.txt
		ruby19 40-* mozcdic_all.txt.utmajor ut-dic2.txt.yomi
		ruby19 36-* ut-dic2.txt.yomi.hyouki

		cd edict-katakanago/
		sh generate-katakanago.sh
		cd -

		cat *.cost mozcdic_all.txt edict-katakanago/edict.kata.cost > ut-check-va.txt
		ruby19 60-* ut-check-va.txt
		ruby19 62-* ut-check-va.txt.va

		cat *.cost edict-katakanago/edict.kata.cost *.va.to_ba > dictionary-ut.txt
		cat dictionary-ut.txt ../data/dictionary_oss/dictionary00.txt > dictionary00.txt
		mv dictionary00.txt ../data/dictionary_oss/

		cd ../base/
		sed -i "s/\"Mozc\"\;/\"Mozc-UT\"\;/g" const.h
		cd ${S}
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

	local my_makeopts=$(makeopts_jobs)
	# This is for a safety. -j without a number, makeopts_jobs returns 999.
	local myjobs=-j${my_makeopts/999/1}

	local mytarget="server/server.gyp:mozc_server"
	use emacs && mytarget="${mytarget} unix/emacs/emacs.gyp:mozc_emacs_helper"
	use ibus && mytarget="${mytarget} unix/ibus/ibus.gyp:ibus_mozc"
	use renderer && mytarget="${mytarget} renderer/renderer.gyp:mozc_renderer"
	if use qt4 ; then
		export QTDIR="${EPREFIX}/usr"
		mytarget="${mytarget} gui/gui.gyp:mozc_tool"
	fi

	# V=1 "${PYTHON}" build_mozc.py build_tools -c "${BUILDTYPE}" ${myjobs} || die
	"${PYTHON}" build_mozc.py build -v -c "${BUILDTYPE}" ${mytarget} ${myjobs} || die

	if use emacs ; then
		elisp-compile unix/emacs/*.el || die
	fi
}

src_test() {
	tc-export CC CXX AR AS RANLIB LD
	V=1 "${PYTHON}" build_mozc.py runtests -c "${BUILDTYPE}" || die
}

src_install() {
	if use dict_ut; then
		cd "${S}"/mozcdic-ut-${DICT_UT_VER}
		newdoc altcanna/doc/README_euc.txt dict_ut_altcanna_README.txt
		newdoc altcanna/doc/COPYING dict_ut_altcanna_COPYING
		newdoc altcanna/doc/Changes.txt dict_ut_altcanna_Chenges.txt
		newdoc altcanna/doc/orig-README.ja dict_ut_altcanna_orig-README.ja

		if use dict_ut_zipcode; then
			newdoc chimei/doc/README dict_ut_zipcode_README
		fi
		newdoc edict/doc/README dict_ut_edict_README
		newdoc ekimei/doc/README dict_ut_ekimei_README
		if use dict_ut_hatena; then
			newdoc hatena/doc/README dict_ut_hatena_README
		fi
		newdoc jinmei/doc/AUTHORS dict_ut_jinmei_AUTHORS
		newdoc jinmei/doc/COPYING dict_ut_jinmei_COPYING
		if use dict_ut_nicodic; then
			newdoc niconico/doc/README dict_ut_nicodic_README
		fi
		newdoc skk/doc/README dict_ut_skk_README
		newdoc README dict_ut_README
		newdoc ChangeLog dict_ut_ChangeLog
		cd "${S}"
	fi

	if use emacs ; then
		dobin "out_linux/${BUILDTYPE}/mozc_emacs_helper" || die
		elisp-install ${PN} unix/emacs/*.{el,elc} || die
		elisp-site-file-install "${FILESDIR}/${SITEFILE}" ${PN} || die
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
