# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit check-reqs toolchain-funcs flag-o-matic multiprocessing

DESCRIPTION=".NET SDK (includes .NET Runtime + ASP.NET)"
HOMEPAGE="https://dotnet.microsoft.com/"




# Using fedora source archive, since Microsoft doesn't provide one.
# If you wish to build one yourself, see https://github.com/dotnet/source-build/
# Do note that it isn't currently possible to generate a source archive without
#  the proprietary "Darc CLI" tool, and downloading a bunch of nuget packages.

# Fedora package script:
# https://src.fedoraproject.org/rpms/dotnet5.0/blob/rawhide/f/build-dotnet-tarball
# Or just run ./build-source-tarball.sh from the root of the source-build repo.
# (the --base-tarball option might be worth using now it's added)

# https://github.com/dotnet/runtime/blob/release/5.0/src/installer/pkg/packaging/deb/dotnet-runtime-deps-debian_config.json#L27
LICENSE="MIT Apache-2.0 BSD"
SLOT="6.0"
KEYWORDS="~amd64"
IUSE="dotnet-symlink system-bootstrap"

BOOT_PV="6.0.100"

PKGS_ARCHIVE=Private.SourceBuilt.Artifacts.0.1.0-${BOOT_PV}-bootstrap.29.tar.gz
SDK_ARCHIVE=dotnet-sdk-${BOOT_PV}-linux-x64.tar.gz

PKGS_URI="https://dotnetcli.azureedge.net/source-built-artifacts/assets/${PKGS_ARCHIVE}"

SDK_URI="https://dotnetcli.azureedge.net/dotnet/Sdk/${BOOT_PV}/${SDK_ARCHIVE}"

SHA512="dcb4102b1a6c9e1889d80f8cecf30da00ad16320cbbf14de891db632ebaa0b872501865957429107ade0caef569a2f2ed5ccb70111de7772838b820997f0c36e"

SRC_URI="https://src.fedoraproject.org/lookaside/pkgs/dotnet$(ver_cut 1-2)/dotnet-v${PV}.tar.gz/sha512/${SHA512}/dotnet-v${PV}.tar.gz
		https://src.fedoraproject.org/rpms/dotnet$(ver_cut 1-2)/raw/rawhide/f/sdk-telemetry-optout.patch  -> ${P}-telemetry-optout.patch
		!system-bootstrap? ( ${PKGS_URI} ${SDK_URI} )"


RDEPEND="
	app-crypt/mit-krb5
	dev-libs/icu
	>=dev-util/lttng-ust-2.13.1
	dotnet-symlink? ( !dev-dotnet/dotnet-sdk-bin[dotnet-symlink(+)] )"
	
DEPEND="${RDEPEND}"

BDEPEND="
	dev-util/cmake
	dev-vcs/git"



CHECKREQS_DISK_BUILD="24G"
CHECKREQS_DISK_USR="1200M"


# Use ninja unless emake is explicitly requested
# Adapted from cmake.eclass
case ${CMAKE_MAKEFILE_GENERATOR:-ninja} in
	emake)
		BDEPEND+=" sys-devel/make"
		CMAKE_GENERATOR_FLAG=""
		;;
	ninja|*)
		BDEPEND+=" dev-util/ninja"
		CMAKE_GENERATOR_FLAG="-ninja"
		;;
esac


if ${DOTNET_FORCE_CLANG}; then
	BDEPEND+=" sys-devel/clang"
fi

S="${WORKDIR}/dotnet-v${PV}"


PATCHES=( 
	"${FILESDIR}/${P}"-rid.patch
	"${FILESDIR}/${P}"-telemetry-optout.patch )


dotnet_find() {
	if ! use system-bootstrap; then
		DOTNET_ROOT="${WORKDIR}"/dotnet-bootstrap
		return
	fi

	for x in "${DOTNET_ROOT}" "${BROOT}"/usr/lib/dotnet-sdk-${SLOT} "${BROOT}"/opt/dotnet-sdk-bin-${SLOT}; do
		if [[ -d "${x}" ]] && [[ -d "${x}"/source-artifacts ]]; then
			DOTNET_ROOT="${x}"
			break
		fi
	done

	if [[ ! -d "${DOTNET_ROOT}" ]]; then
		die "Can't find installed .NET SDK (including Source-built Artifacts)"
	fi
}


dotnet_unpack() {
	
	if ! use system-bootstrap; then
		mkdir -p ${WORKDIR}/dotnet-bootstrap || die
		cd ${WORKDIR}/dotnet-bootstrap
		unpack ${SDK_ARCHIVE}
		
		mkdir source-artifacts
		
		cd source-artifacts
		unpack ${PKGS_ARCHIVE}
	else
		dotnet_find
		# dotnet wants to mess with the original installation
		cp -R ${DOTNET_ROOT} ${WORKDIR}/dotnet-bootstrap || die
	fi
}


src_unpack() {
	unpack "dotnet-v${PV}.tar.gz"
	dotnet_unpack
}


src_compile() {
	dotnet_find
	# Required for --with-packages to work
	rm -R ${S}/packages/archive
	
	local mybuildargs=(
		--with-sdk ${WORKDIR}/dotnet-bootstrap
		--with-packages ${WORKDIR}/dotnet-bootstrap/source-artifacts
		--
		
		/p:UseSystemLibraries=true
		
		/p:LogVerbosity=normal
		/p:MinimalConsoleLogOutput=false
		/verbosity:normal

		# Not sure if this has any effect on the subprocesses
		/maxCpuCount:$(makeopts_jobs)

		/p:TargetRid=gentoo-x64
	)


	./build.sh "${mybuildargs[@]}" || die
}


src_install() {
	local dest="/usr/lib/${PN}-${SLOT}"
	local ddest="${ED}/${dest#/}"

	dodir "${dest}"
	tar xf artifacts/*/Release/dotnet-sdk-*.tar.gz -C "${ddest}" || die

	dodir "${dest}"/source-artifacts
	tar xf artifacts/*/Release/Private.SourceBuilt.Artifacts.*.tar.gz -C "${ddest}"/source-artifacts || die

	dosym "../../${dest#/}/dotnet" /usr/bin/dotnet-${SLOT}

	if use dotnet-symlink; then
		dosym "../../${dest#/}/dotnet" /usr/bin/dotnet

		echo "DOTNET_ROOT=\"${EPREFIX}${dest}\"" > "${T}/90${PN}-${SLOT}"
		doenvd "${T}/90${PN}-${SLOT}"
	fi
}
