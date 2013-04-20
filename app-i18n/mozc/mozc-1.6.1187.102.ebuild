# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-i18n/mozc/mozc-1.6.1187.102.ebuild,v 1.1 2012/10/02 02:47:18 naota Exp $

EAPI="4"
PYTHON_DEPEND="2"
inherit elisp-common eutils multilib multiprocessing python toolchain-funcs

DESCRIPTION="The Mozc engine for IBus Framework"
HOMEPAGE="http://code.google.com/p/mozc/"

PROTOBUF_VER="2.4.1"
DICT_UT_VER="20121020"
GMOCK_VER="403"
MOZC_URL="http://mozc.googlecode.com/files/${P}.tar.bz2"
PROTOBUF_URL="http://protobuf.googlecode.com/files/protobuf-${PROTOBUF_VER}.tar.bz2"
DICT_UT_URL="http://jaist.dl.sourceforge.net/project/mdk-ut/30-source/source/mozcdic-ut-${DICT_UT_VER}.tar.bz2"
SRC_URI="${MOZC_URL} ${PROTOBUF_URL} dict_ut? ( ${DICT_UT_URL} )"

LICENSE="Apache-2.0 BSD Boost-1.0 ipadic public-domain unicode"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE_EX_DICT="+dict_ut +dict_ut_altcanna +dict_ut_zipcode +dict_ut_hatena
dict_ut_nicodic"
IUSE="${IUSE_EX_DICT} emacs +ibus +qt4 renderer"

REQUIRED_USE="dict_ut_altcanna? ( dict_ut )
	dict_ut_zipcode? ( dict_ut )
	dict_ut_hatena? ( dict_ut )
	dict_ut_nicodic? ( dict_ut )
"

RDEPEND="dev-libs/glib:2
	dev-libs/openssl
	x11-libs/libxcb
	emacs? ( virtual/emacs )
	ibus? ( >=app-i18n/ibus-1.4.1 )
	renderer? ( x11-libs/gtk+:2 )
	qt4? (
		x11-libs/qt-gui:4
		app-i18n/zinnia
	)
	"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	dict_ut? ( 
		>dev-lang/ruby-1.9
		app-arch/unzip
	)
	"

BUILDTYPE="${BUILDTYPE:-Release}"

RESTRICT="test"

SITEFILE=50${PN}-gentoo.el

pkg_setup() {
	python_set_active_version 2
	python_pkg_setup
}

src_unpack() {
	unpack $(basename ${MOZC_URL})

	cd "${S}"/protobuf
	unpack $(basename ${PROTOBUF_URL})
	mv protobuf-${PROTOBUF_VER} files

	if use dict_ut; then
		cd "${S}"
		unpack $(basename ${DICT_UT_URL})
	fi
}

src_configure() {
	if use dict_ut; then
		elog "Enabling Mozc-UT Dictionary..."
		if use dict_ut_nicodic; then
			ewarn " Enabling dict_ut_nicodic use flag,"
			ewarn " you will be unable to redistribute this package."
		fi
		cd "${S}"/mozcdic-ut-${DICT_UT_VER}
		# get official mozcdic
		cat ../data/dictionary/dictionary*.txt > mozcdic_all.txt

		# get mozcdic costlist
		ruby19 32-* mozcdic_all.txt
		mv mozcdic_all.txt.cost costlist

		# get hinsi ID
		cp ../data/dictionary/id.def .

		if use dict_ut_zipcode; then
			einfo Generating zipcode dictionary...
			cd chimei
			wget http://www.post.japanpost.jp/zipcode/dl/kogaki/zip/ken_all.zip
			wget http://www.post.japanpost.jp/zipcode/dl/jigyosyo/zip/jigyosyo.zip
			unzip ken_all.zip
			unzip jigyosyo.zip
			cp ../../dictionary/gen_zip_code_seed.py .
			"$(PYTHON)" gen_zip_code_seed.py --zip_code=KEN_ALL.CSV \
				--jigyosyo=JIGYOSYO.CSV \
				>> ../../data/dictionary/dictionary09.txt
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
		ruby19 12-* edict/edict.txt 300
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

		cat *.cost mozcdic_all.txt > ut-check-va.txt
		ruby19 60-* ut-check-va.txt
		ruby19 62-* ut-check-va.txt.va

		cat *.cost *.va.to_ba > dictionary-ut.txt
		cp dictionary-ut.txt ../data/dictionary/
		sed -i \
			"s/'..\/data\/dictionary\/dictionary00.txt',/'..\/data\/dictionary\/dictionary00.txt',\n'..\/data\/dictionary\/dictionary-ut.txt',/g" \
			../dictionary/dictionary.gyp
		sed -i \
			"s/'..\/<(test_data_subdir)\/dictionary00.txt',/'..\/<(test_data_subdir)\/dictionary00.txt',\n'..\/<(test_data_subdir)\/dictionary-ut.txt',/g" \
			../dictionary/dictionary_base.gyp
		sed -i \
			"s/\"data\/dictionary\/dictionary00.txt,\"/\"data\/dictionary\/dictionary00.txt,\"\n\"data\/dictionary\/dictionary-ut.txt,\"/g" \
			../prediction/suggestion_filter_test.cc
		
		cd ../rewriter/
		sed -i "s/\"Mozc\"\;/\"Mozc (+ut_dict)\"\;/g" version_rewriter.cc
		cd ${S}
	fi
	
	local myconf="--channel_dev=0"
	myconf+=" --server_dir=/usr/$(get_libdir)/mozc"

	if ! use qt4 ; then
		myconf+=" --noqt"
		export GYP_DEFINES="use_libzinnia=0"
	fi

	if ! use renderer ; then
		export GYP_DEFINES="${GYP_DEFINES} enable_gtk_renderer=0"
	fi

	"$(PYTHON)" build_mozc.py gyp ${myconf} || die "gyp failed"
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

	"$(PYTHON)" build_mozc.py build_tools -c "${BUILDTYPE}" ${myjobs} || die
	"$(PYTHON)" build_mozc.py build -c "${BUILDTYPE}" ${mytarget} ${myjobs} || die

	if use emacs ; then
		elisp-compile unix/emacs/*.el || die
	fi
}

src_test() {
	"$(PYTHON)" build_mozc.py runtests -c "${BUILDTYPE}" || die
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
		exeinto /usr/libexec || die
		newexe "out_linux/${BUILDTYPE}/ibus_mozc" ibus-engine-mozc || die
		insinto /usr/share/ibus/component || die
		doins "out_linux/${BUILDTYPE}/obj/gen/unix/ibus/mozc.xml" || die
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

