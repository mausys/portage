# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2



if [[ ${___ECLASS_ONCE_GYP_UTILS} != "recur -_+^+_- spank" ]] ; then
___ECLASS_ONCE_GYP_UTILS="recur -_+^+_- spank"


# @ECLASS-VARIABLE: WANT_GYP
# @DESCRIPTION:
# Specify if gyp-utils eclass should depend on gyp optionally or not.
# This is usefull when only part of aplication is using gyp build system.
# Valid values are: always [default], optional (where the value is the useflag
# used for optionality)
WANT_GYP="${WANT_GYP:-always}"

# @ECLASS-VARIABLE: GYP_MAKEFILE_GENERATOR
# @DESCRIPTION:
# Specify a makefile generator to be used by gyp.
# At this point only "emake" and "ninja" are supported.
GYP_MAKEFILE_GENERATOR="${GYP_MAKEFILE_GENERATOR:-emake}"

GYPDEPEND=""
case ${WANT_GYP} in
	always)
		;;
	*)
		IUSE+=" ${WANT_GYP}"
		CMAKEDEPEND+="${WANT_GYP}? ( "
		;;
esac

inherit toolchain-funcs multilib flag-o-matic base

GYP_EXPF="src_compile"

case ${EAPI:-0} in
	5) GYP_EXPF+=" src_prepare src_configure" ;;
	*) die "Unknown EAPI, Bug eclass maintainers." ;;
esac

EXPORT_FUNCTIONS ${GYP_EXPF}

case ${GYP_MAKEFILE_GENERATOR} in
	emake)
		GYPDEPEND+=" sys-devel/make"
		;;
	ninja)
		GYPDEPEND+=" dev-util/ninja"
		;;
	*)
		eerror "Unknown value for \${GYP_MAKEFILE_GENERATOR}"
		die "Value ${GYP_MAKEFILE_GENERATOR} is not supported"
		;;
esac




DEPEND="dev-util/gyp
        ${GYPDEPEND}"

unset GYPDEPEND

# @ECLASS-VARIABLE: BUILD_DIR
# @DESCRIPTION:
# Build directory where all gyp processed files should be generated.
# For in-source build it's fixed to ${GYP_USE_DIR}.
# For out-of-source build it can be overriden, by default it uses
# ${WORKDIR}/${P}_build.

# @ECLASS-VARIABLE: GYP_BUILDTYPE
# @DESCRIPTION:
# set the gyp Configuration
: ${GYP_BUILDTYPE:=Release}

# @ECLASS-VARIABLE: GYP_BUILD_FILE
# @DESCRIPTION:
# The gyp build file
: ${GYP_BUILD_FILE:=${PN}.gyp}

# @ECLASS-VARIABLE: GYP_DEPTH
# @DESCRIPTION:
# The gyp DEPTH variable
: ${GYP_DEPTH:=.}

# @ECLASS-VARIABLE: GYP_IN_SOURCE_BUILD
# @DESCRIPTION:
# Set to enable in-source build.

# @ECLASS-VARIABLE: GYP_USE_DIR
# @DESCRIPTION:
# Sets the directory where we are working with gyp.
# For example when application uses autotools and only one
# plugin needs to be done by gyp.
# By default it uses ${S}.

# @ECLASS-VARIABLE: GYP_VERBOSE
# @DESCRIPTION:
# Set to OFF to disable verbose messages during compilation
: ${GYP_VERBOSE:=ON}

# @ECLASS-VARIABLE: PREFIX
# @DESCRIPTION:
# Eclass respects PREFIX variable, though it's not recommended way to set
# install/lib/bin prefixes.
# Use -DGYP_INSTALL_PREFIX=... gyp variable instead.
: ${PREFIX:=/usr}

# @ECLASS-VARIABLE: GYP_SCRIPT
# @DESCRIPTION:
# Eclass can use different gyp python scripts than the one provided in by system.
: ${GYP_SCRIPT:=gyp}


# Determine using IN or OUT source build
_check_build_dir() {
	: ${GYP_USE_DIR:=${S}}
	if [[ -n ${GYP_IN_SOURCE_BUILD} ]]; then
		# we build in source dir
		BUILD_DIR="${GYP_USE_DIR}"
	else
		: ${BUILD_DIR:=${WORKDIR}/${P}_build}
	fi

	mkdir -p "${BUILD_DIR}"
	echo ">>> Working in BUILD_DIR: \"$BUILD_DIR\""
}

# Determine which generator to use
_generator_to_use() {
	local generator_name

	case ${GYP_MAKEFILE_GENERATOR} in
		ninja)
			generator_name="ninja"
			;;
		emake)
			generator_name="make"
			;;
		*)
			eerror "Unknown value for \${GYP_MAKEFILE_GENERATOR}"
			die "Value ${GYP_MAKEFILE_GENERATOR} is not supported"
			;;
	esac

	echo ${generator_name}
}

enable_gyp-utils_src_prepare() {
	debug-print-function ${FUNCNAME} "$@"

	base_src_prepare
}

# @VARIABLE: mygypargs
# @DEFAULT_UNSET
# @DESCRIPTION:
# Optional gyp defines as a bash array. Should be defined before calling
# src_configure.
# @CODE
# src_configure() {
# 	local mygypargs=(
# 		-D openconnect=1
# 	)
# 	gyp-utils_src_configure
# }


enable_gyp-utils_src_configure() {
	debug-print-function ${FUNCNAME} "$@"

	_check_build_dir

	# check if gyp build file exist and if no then die
	if [[ ! -e ${GYP_BUILD_FILE} ]] ; then
		eerror "Unable to locate gyp build file under:"
		eerror "\"${GYP_BUILD_FILE}\""
		eerror "Consider not inheriting the gyp eclass."
		die "FATAL: Unable to find the gyp build file"
	fi


	# Fix xdg collision with sandbox
	export XDG_CONFIG_HOME="${T}"

	export CC_target="$(tc-getCC)" 
	export CXX_target="$(tc-getCXX)" 
	export LD_target="$(tc-getLD)"
	export AR_target="$(tc-getAR)"

	export CC_host="$(tc-getBUILD_CC)" 
	export CXX_host="$(tc-getBUILD_CXX)" 
	export LD_host="$(tc-getBUILD_LD)"
	export AR_host="$(tc-getBUILD_AR)"
	export ENVVAR_GYP_GENERATORS="$(_generator_to_use)"
	

	# Convert mygypargs to an array, for backwards compatibility
	# Make the array a local variable since <=portage-2.1.6.x does not
	# support global arrays (see bug #297255).
	if [[ $(declare -p mygypargs 2>&-) != "declare -a mygypargs="* ]]; then
		local mygypargs_local=(${mygypargs})
	else
		local mygypargs_local=("${mygypargs[@]}")
	fi

	# Common configure parameters (overridable)
	local gypargs=(
    --generator-output "${BUILD_DIR}"
    #--toplevel-dir=${S}
    --depth=${GYP_DEPTH}
    -Goutput_dir="${BUILD_DIR}"
    -D sysroot="${SYSROOT:-/}"
		"${mygypargs_local[@]}"
	)

	pushd "${BUILD_DIR}" > /dev/null
	cd ${S} || die "cd ${S} failed "
	debug-print "${LINENO} ${ECLASS} ${FUNCNAME}: mygypargs is ${mygypargs_local[*]}"
	echo "${GYP_SCRIPT}" "${GYP_BUILD_FILE}" "${gypargs[@]}"
	"${GYP_SCRIPT}" "${GYP_BUILD_FILE}" "${gypargs[@]}" || die "gyp failed"
	popd > /dev/null
}

enable_gyp-utils_src_compile() {
	debug-print-function ${FUNCNAME} "$@"

	has src_configure ${GYP_EXPF} || gyp-utils_src_configure
	gyp-utils_src_make "$@"
}


_ninjaopts_from_makeopts() {
	if [[ ${NINJAOPTS+set} == set ]]; then
		return 0
	fi
	local ninjaopts=()
	set -- ${MAKEOPTS}
	while (( $# )); do
		case $1 in
			-j|-l|-k)
				ninjaopts+=( $1 $2 )
				shift 2
				;;
			-j*|-l*|-k*)
				ninjaopts+=( $1 )
				shift 1
				;;
			*) shift ;;
		esac
	done
	export NINJAOPTS="${ninjaopts[*]}"
}

# @FUNCTION: ninja_src_make
# @INTERNAL
# @DESCRIPTION:
# Build the package using ninja generator
ninja_src_make() {
		debug-print-function ${FUNCNAME} "$@"

	[[ -e build.ninja ]] || die "build.ninja not found. Error during configure stage."

	_ninjaopts_from_makeopts

	if [[ "${GYP_VERBOSE}" != "OFF" ]]; then
		set -- ninja ${NINJAOPTS}  BUILDTYPE=${GYP_BUILDTYPE} -v "$@"
	else
		set -- ninja ${NINJAOPTS}  BUILDTYPE=${GYP_BUILDTYPE} "$@"
	fi

	echo "$@"
	"$@" || die
}

# @FUNCTION: make_src_make
# @INTERNAL
# @DESCRIPTION:
# Build the package using make generator
emake_src_make() {
	debug-print-function ${FUNCNAME} "$@"

		[[ -e Makefile ]] || die "Makefile not found. Error during configure stage."

		if [[ "${GYP_VERBOSE}" != "OFF" ]]; then
		  emake V=1 BUILDTYPE=${GYP_BUILDTYPE} "$@" || die
		else
		  emake  BUILDTYPE=${GYP_BUILDTYPE} "$@" || die
	fi

}

# @FUNCTION: gyp-utils_src_make
# @DESCRIPTION:
# Function for building the package. Automatically detects the build type.
# All arguments are passed to emake.
gyp-utils_src_make() {
	debug-print-function ${FUNCNAME} "$@"

	_check_build_dir
	pushd "${BUILD_DIR}" > /dev/null

	${GYP_MAKEFILE_GENERATOR}_src_make $@

	popd > /dev/null
}

# @FUNCTION: gyp-utils_src_prepare
# @DESCRIPTION:
# Wrapper function around base_src_prepare, just to expand the eclass API.
gyp-utils_src_prepare() {
	_execute_optionaly "src_prepare" "$@"
}

# @FUNCTION: gyp-utils_src_configure
# @DESCRIPTION:
# General function for configuring with gyp. Default behaviour is to start an
# out-of-source build.
gyp-utils_src_configure() {
	_execute_optionaly "src_configure" "$@"
}

# @FUNCTION: gyp-utils_src_compile
# @DESCRIPTION:
# General function for compiling with gyp. Default behaviour is to check for
# EAPI and respectively to configure as well or just compile.
# Automatically detects the build type. All arguments are passed to emake.
gyp-utils_src_compile() {
	_execute_optionaly "src_compile" "$@"
}

# Internal functions used by gyp-utils_use_*

gyp-utils_use() { 
	debug-print-function ${FUNCNAME} "$@"
	echo "-D $3=$(use $2 && echo 1 || echo 0)"
}

# Optionally executes phases based on WANT_GYP variable/USE flag.
_execute_optionaly() {
	local phase="$1" ; shift
	if [[ ${WANT_GYP} = always ]]; then
		enable_gyp-utils_${phase} "$@"
	else
		use ${WANT_GYP} && enable_gyp-utils_${phase} "$@"
	fi
}


fi
