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
RDEPEND=""

DEPEND="${RDEPEND}"

DART_TARGETS="most"


GYP_BUILD_FILE="dart.gyp"
BUILD_TARGET="Release"
S_DART="${S}/${PN}"
THIRD_PARTY="zlib pkg pkg_tested observatory_pub_packages root_certificates boringssl tcmalloc"

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
    epatch "${FILESDIR}/${PN}-1.20.1.patch"
    epatch "${FILESDIR}/${PN}-1.21.0.patch"
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
    emake BUILDTYPE="${BUILD_TARGET}" V=1
}

src_install() {
    local out=${BUILD_DIR}/${BUILD_TARGET}
    local instdir=/usr/$(get_libdir)/dart-sdk
    local bins="dart dartdevc dart2js dartdoc dartfmt pub dartanalyzer"
    insinto ${instdir}
    doins -r ${out}/dart-sdk/*
    for b in ${bins} ; do
        fperms 0775 ${instdir}/bin/${b}
		dosym ${instdir}/bin/${b} /usr/bin/${b}
	done
}
