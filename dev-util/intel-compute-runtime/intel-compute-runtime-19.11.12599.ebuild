EAPI=6

inherit cmake-utils llvm


DESCRIPTION="Intel(R) Graphics Compute Runtime for OpenCL(TM). Replaces Beignet for Gen8 (Broadwell) and beyond."
HOMEPAGE="https://github.com/intel/compute-runtime"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""
SRC_URI="https://github.com/intel/compute-runtime/archive/${PV}.tar.gz -> ${P}.tar.gz"

RDEPEND="sys-devel/llvm:8
         dev-util/intel-graphics-compiler"




S="${WORKDIR}/compute-runtime-${PV}"

src_configure() {
        local mycmakeargs=(
          -DTESTS_GEN8=FALSE -DTESTS_GEN10=FALSE -DTESTS_GEN9=FALSE
        )
        cmake-utils_src_configure
}