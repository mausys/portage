EAPI=5
PYTHON_COMPAT=( python2_7 )

inherit flag-o-matic gyp-utils eutils python-r1

DART_OPTIONAL="analysis_server dartanalyzer"

DESCRIPTION="Dart is a cohesive, scalable platform for building apps"
HOMEPAGE="https://www.dartlang.org/"
LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="${DART_OPTIONAL} debug"
#DART_REVISION="3211fb1"
SRC_URI="http://commondatastorage.googleapis.com/dart-archive/channels/stable/raw/${PV}/src/${P}.tar.gz"


RDEPEND="sys-libs/zlib
         dev-libs/nss"

DEPEND="${RDEPEND}"

DART_TARGETS="create_sdk dart2js runtime"


GYP_BUILD_FILE="dart.gyp"
BUILD_TARGET="Release"
S_DART="${S}/${PN}"
THIRD_PARTY="pkg pkg_tested observatory_pub_packages root_certificates boringssl"

pkg_setup() {
    for t in ${DART_OPTIONAL} ; do
        use ${t} || continue
        DART_TARGETS+=" ${t}"
	done

    use debug && BUILD_TARGET="Debug"
    case $ARCH in
	"amd64")
	    BUILD_TARGET+="X64"
	    ;;
	"x86")
	     BUILD_TARGET+="IA32"
	    ;;
	esac
}

src_prepare() {
    S=${S_DART}
    cd ${S}
    #remove all the unnecessary stuff
    mkdir third_party_tmp || die
    for tp in ${THIRD_PARTY} ; do
        mv third_party/${tp} third_party_tmp/ || die
	done
    rm -R third_party/* || die
    mv third_party_tmp/* third_party/ || die
    
    epatch "${FILESDIR}/${PN}-1.13.0.patch"
    epatch "${FILESDIR}/${PN}-system-zlib.patch"
    epatch "${FILESDIR}/${PN}-fortify.patch"
}

src_configure() {
    python_setup
    mygypargs="-I tools/gyp/all.gypi"
    for t in ${DART_TARGETS} ; do
        mygypargs+=" --root-target=${t}"
    done
    gyp-utils_src_configure
}

src_compile() {
    cd ${BUILD_DIR}
    emake BUILDTYPE="${BUILD_TARGET}" V=1  -j1
}

src_install() {
    local out=${BUILD_DIR}/${BUILD_TARGET}
    local instdir=/usr/$(get_libdir)/dart-sdk
    local bins="dart dart2js dartdoc dartfmt pub"
    
    use dartanalyzer && bins+=" dartanalyzer"
    
    insinto ${instdir}
    doins -r ${out}/dart-sdk/*
    for b in ${bins} ; do
        fperms 0775 ${instdir}/bin/${b}
		dosym ${instdir}/bin/${b} /usr/bin/${b}
	done
}
