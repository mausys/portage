EAPI=6

inherit cmake-utils llvm


DESCRIPTION="A tool and a library for bi-directional translation between SPIR-V and LLVM IR"
HOMEPAGE="https://github.com/KhronosGroup/SPIRV-LLVM-Translator"
LICENSE="UoI-NCSA"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""
SRC_URI="https://github.com/KhronosGroup/SPIRV-LLVM-Translator/archive/v${PV}-1.tar.gz -> ${P}.tar.gz"

DEPEND="sys-devel/llvm:8"


S="${WORKDIR}/SPIRV-LLVM-Translator-8.0.0-1"

src_configure() {
        local mycmakeargs=(
        	-DBUILD_SHARED_LIBS=true
        )

        cmake-utils_src_configure
}