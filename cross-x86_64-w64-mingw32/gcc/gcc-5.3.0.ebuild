# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="4"

PATCH_VER="1.0"
UCLIBC_VER="1.0"

# Hardened gcc 4 stuff
PIE_VER="0.6.5"
SPECS_VER="0.2.0"
SPECS_GCC_VER="4.4.3"
# arch/libc configurations known to be stable with {PIE,SSP}-by-default
PIE_GLIBC_STABLE="x86 amd64 mips ppc ppc64 arm ia64"
PIE_UCLIBC_STABLE="x86 arm amd64 mips ppc ppc64"
SSP_STABLE="amd64 x86 mips ppc ppc64 arm"
# uclibc need tls and nptl support for SSP support
# uclibc need to be >= 0.9.33
SSP_UCLIBC_STABLE="x86 amd64 mips ppc ppc64 arm"
#end Hardened stuff

inherit toolchain

KEYWORDS="~amd64 ~x86"

RDEPEND=""
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.8 )
	thread_posix? ( ${CATEGORY}/mingw64-runtime[libraries] )
	>=${CATEGORY}/binutils-2.20"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.8 )"
fi

IUSE="${IUSE} thread_posix +thread_win32"
REQUIRED_USE+="
	^^ ( thread_posix thread_win32 )
	crosscompile_opts_headers? ( !thread_posix )"

if [[ $(tc-arch) == amd64 ]]; then
	IUSE="${IUSE} +ehtype_seh"
else
	IUSE="${IUSE} +ehtype_sjlj ehtype_dwarf2"
	REQUIRED_USE+="^^ ( ehtype_sjlj ehtype_dwarf2 )"
fi

src_prepare() {
	if has_version '<sys-libs/glibc-2.12' ; then
		ewarn "Your host glibc is too old; disabling automatic fortify."
		ewarn "Please rebuild gcc after upgrading to >=glibc-2.12 #362315"
		EPATCH_EXCLUDE+=" 10_all_default-fortify-source.patch"
	fi
	is_crosscompile && EPATCH_EXCLUDE+=" 05_all_gcc-spec-env.patch"

	toolchain_src_prepare
}

src_configure() {
	local extra_conf=()
	if use ehtype_dwarf2 && ! use crosscompile_opts_headers-only; then
		extra_conf+=( --disable-sjlj-exceptions --with-dwarf2 )
	fi
	if use thread_posix && ! use crosscompile_opts_headers-only; then
		extra_conf+=( --enable-threads=posix )
	fi
	EXTRA_ECONF="${extra_conf[@]} ${EXTRA_ECONF}"

	toolchain_src_configure
}

src_install() {
	toolchain_src_install

	dosym ${STDCXX_INCDIR} ${LIBPATH}/include/c++
}
