EAPI=6

inherit cmake-utils llvm


DESCRIPTION="The Intel(R) Graphics Compiler for OpenCL(TM) is an llvm based compiler for OpenCL(TM) targeting Intel Gen graphics hardware architecture."
HOMEPAGE="https://github.com/intel/intel-graphics-compiler"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""
SRC_URI="https://github.com/intel/intel-graphics-compiler/archive/igc-${PV}.tar.gz"

RDEPEND="sys-devel/llvm:8
         dev-libs/spirv-llvm-translator
         dev-libs/opencl-clang"



LLVM_MAX_SLOT=8

PATCHES=(
	"${FILESDIR}/${P}.patch"
)
S="${WORKDIR}/${PN}-igc-${PV}"

src_configure() {
        local mycmakeargs=(
          -DIGC_PREFERRED_LLVM_VERSION="8.0.0" -DLLVM_VERSION_MAJOR=8
        )
        cmake-utils_src_configure
}