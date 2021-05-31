# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..9} )

inherit distutils-r1

DESCRIPTION="Schema validation just got Pythonic"
HOMEPAGE="https://github.com/keleshev/schema"
SRC_URI="https://github.com/keleshev/${PN}/archive/refs/tags/v${PV}.tar.gz -> python-schema-${PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ppc ppc64 ~s390 sparc x86 ~amd64-linux ~x86-linux"

BDEPEND=">=dev-python/contextlib2-0.5.5"

RDEPEND="${BDEPEND}"



