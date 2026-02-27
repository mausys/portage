# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/Xilinx/${PN}.git"

inherit toolchain-funcs git-r3

DESCRIPTION="Xilinx Bootgen for SoC devices"
HOMEPAGE="https://github.com/Xilinx/bootgen"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

RDEPEND="dev-libs/openssl"
DEPEND="${RDEPEND}"
BDEPEND=""

EGIT_COMMIT="xilinx_v${PV}"


PATCHES=(
        "${FILESDIR}/${P}.patch"
)

src_compile() {
	emake CC="$(tc-getCC)" \
		CXX="$(tc-getCXX)" \
		CXXFLAGS="-std=c++14" \
		CFLAGS="${CFLAGS}" \
		LDFLAGS="${LDFLAGS}" \
		VERBOSE=1
}

src_install() {
	dobin build/bin/bootgen
}	

