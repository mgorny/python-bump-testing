# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{9..11} )
DISTUTILS_USE_SETUPTOOLS=no
inherit distutils-r1

MY_PN=BitTornado
MY_P=${MY_PN}-${PV}
EGIT_COMMIT="ed327c4e1ebbe1fe949be81723527cfda87aeb8d"

DESCRIPTION="John Hoffman's fork of the original bittorrent"
HOMEPAGE="https://github.com/effigies/BitTornado"
SRC_URI="https://github.com/effigies/BitTornado/archive/${EGIT_COMMIT}.tar.gz -> ${MY_P}.tar.gz"
# GPL-2 is just for the init script from FILESDIR.
LICENSE="MIT GPL-2"
SLOT="0"

KEYWORDS="~alpha amd64 ~hppa ppc ppc64 ~sparc x86 ~amd64-linux ~x86-linux ~x86-solaris"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	dev-python/pycryptodome[${PYTHON_USEDEP}]
"
# Block dev-python/pytest-testmon for bug #693508.
DEPEND="
	test? (
		!!dev-python/pytest-testmon
	)
"

S=${WORKDIR}/${MY_PN}-${EGIT_COMMIT}

distutils_enable_tests pytest

python_prepare_all() {
	# https://github.com/effigies/BitTornado/pull/53
	sed -e 's:"BitTornado.Tracker":\0, "BitTornado.Types":' -i setup.py || die
	find "${S}" -name '*.py' -print0 | \
		xargs --null -- \
		sed -r -i '
			s:time.clock\(\):time.perf_counter():g;
			s:collections.(MutableSet|Set|Sequence|Mapping):collections.abc.\1:g
		' || die
	distutils-r1_python_prepare_all
}

python_test() {
	epytest BitTornado/tests
}

python_install_all() {
	distutils-r1_python_install_all

	newconfd "${FILESDIR}"/bttrack.conf bttrack
	newinitd "${FILESDIR}"/bttrack.rc bttrack
}
