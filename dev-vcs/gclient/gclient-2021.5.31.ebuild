EAPI=7

PYTHON_COMPAT=( python3_{8,9} )

inherit distutils-r1

DESCRIPTION="gclient is a tool for managing a modular checkout of source code from multiple source code repositories."
HOMEPAGE="https://github.com/mausys/gclient"
SRC_URI="https://github.com/mausys/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ppc ppc64 ~s390 sparc x86 ~amd64-linux ~x86-linux"

BDEPEND="dev-python/schema
	dev-python/colorama"

RDEPEND="${BDEPEND}
	net-misc/cipd"



