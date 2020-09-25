EAPI=7
PYTHON_COMPAT=( python2_7 )

inherit flag-o-matic eutils python-r1 llvm ninja-utils
LLVM_MAX_SLOT=10


DESCRIPTION="Dart is a cohesive, scalable platform for building apps"
HOMEPAGE="https://www.dartlang.org/"
LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
IUSE="debug"
SRC_URI="http://commondatastorage.googleapis.com/dart-archive/channels/stable/raw/${PV}/src/${P}.tar.gz"

RDEPEND="sys-devel/clang"

DEPEND="dev-util/gn
		${RDEPEND}"

S_DART="${S}/${PN}"  
BUILD_DIR="${S}/out"     



src_prepare() {
    cd ${S}
    rm -R debian
    cd ${S_DART}
    rm -R buildtools
    rm -R build/linux/debian*
	rm -Rf third_party/fuchsia/
	rm -Rf third_party/llvm-build

#    rm -R sdk
    eapply "${FILESDIR}/${P}.patch"
    default
}

src_configure() {
	python_setup
	mkdir ${BUILD_DIR}
	cd ${BUILD_DIR}
	cat <<- EOF > args.gn
		llvm_prefix = "$(get_llvm_prefix)"   
		exclude_kernel_service = false
		is_product = false
		is_qemu = false
		dart_runtime_mode = "develop"
		is_lsan = false
		dart_use_crashpad = false
		dart_use_debian_sysroot = false
		dart_platform_bytecode = false
		use_goma = false
		dart_platform_sdk = false
		dart_precompiled_runtime_stripped_binary =
		"exe.stripped/dart_precompiled_runtime_product"
		is_msan = false
		is_release = false
		is_clang = true
		dart_stripped_binary = "exe.stripped/dart"
		dart_target_arch = "x64"
		dart_use_tcmalloc = true
		goma_dir = "None"
		dart_debug = true
		host_cpu = "x64"
		dart_snapshot_kind = "app-jit"
		is_tsan = false
		is_ubsan = false
		target_os = "linux"
		dart_vm_code_coverage = false
		dart_use_fallback_root_certificates = true
		target_cpu = "x64"
		is_asan = false
		is_debug = true
		verify_sdk_hash = true
		gen_snapshot_stripped_binary = "exe.stripped/gen_snapshot_product"
	EOF
	gn gen . --root=${S_DART} || die
}

src_compile() {
	cd ${BUILD_DIR}
	eninja most || die
}

src_install() {
    local instdir=/usr/$(get_libdir)/dart-sdk
    local bins="dart dartdevc dart2js dartdoc dartfmt pub dartanalyzer"
    insinto ${instdir}
    doins -r ${BUILD_DIR}/dart-sdk/*
    for b in ${bins} ; do
        fperms 0775 ${instdir}/bin/${b}
		dosym ${instdir}/bin/${b} /usr/bin/${b}
	done
}
