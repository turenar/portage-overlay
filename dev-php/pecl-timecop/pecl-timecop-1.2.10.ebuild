EAPI=6
SLOT="0"
IUSE=""

PHP_EXT_PEC_FILENAME="timecop-${PV}.tgz"
PHP_EXT_NAME="timecop"
PHP_EXT_INI="yes"
PHP_EXT_ZENDEXT="no"

USE_PHP="php7-0 php7-1 php7-2"

inherit php-ext-pecl-r3

KEYWORDS="~amd64 ~x86"

DESCRIPTION=""
LICENSE="BSD"

DEPEND=""
RDEPEND=""
PHP_EXT_ECONF_ARGS=""
