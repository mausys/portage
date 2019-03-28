EAPI=6

inherit cmake-utils llvm


DESCRIPTION="Common clang is a thin wrapper library around clang. Common clang has OpenCL-oriented API and is capable to compile OpenCL C kernels to SPIR-V modules."
HOMEPAGE="https://github.com/intel/opencl-clang"
LICENSE="UoI-NCSA"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""
SRC_URI="https://github.com/intel/opencl-clang/archive/v${PV}.tar.gz -> ${P}.tar.gz"

DEPEND="sys-devel/llvm:8
	dev-libs/spirv-llvm-translator"

PATCHES=(
	"${FILESDIR}/${P}.patch"
)

rc_configure() {
        local mycmakeargs=(
		-DLLVMSPIRV_INCLUDED_IN_LLVM=OFF
        )

        cmake-utils_src_configure
}

