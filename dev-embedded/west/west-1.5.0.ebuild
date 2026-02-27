# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1

DESCRIPTION="West, Zephyr's meta-tool"
HOMEPAGE="https://github.com/zephyrproject-rtos/west"
SRC_URI="https://github.com/zephyrproject-rtos/west/archive/refs/tags/v${PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86 arm arm64"

RDEPEND="
	dev-python/colorama
	dev-python/packaging
	dev-python/pykwalify
	dev-python/pyyaml
"

DEPEND="${BDEPEND}"



BDEPEND=""
