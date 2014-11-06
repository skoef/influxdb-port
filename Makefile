# $FreeBSD: databases/influxdb/Makefile rschoof $

PORTNAME=       influxdb
PORTVERSION=    0.8.5
CATEGORIES=     databases

MAINTAINER=     reinier@skoef.nl
COMMENT=        Open-source distributed time series database

LICENSE=        MIT

USE_GITHUB=     yes
GH_ACCOUNT=     influxdb
GH_COMMIT=      9485e99
GH_TAGNAME=     ${GH_COMMIT}

GNU_CONFIGURE=  yes

PKGORIGIN=      databases/influxdb
USE_AUTOTOOLS=  autoconf

LIB_DEPENDS+=   libleveldb.so:${PORTSDIR}/databases/leveldb
BUILD_DEPENDS+= go:${PORTSDIR}/lang/go
BUILD_DEPENDS+= protoc:${PORTSDIR}/devel/protobuf
BUILD_DEPENDS+= hg:${PORTSDIR}/devel/mercurial
BUILD_DEPENDS+= bzr:${PORTSDIR}/devel/bzr
BUILD_DEPENDS+= git:${PORTSDIR}/devel/git
BUILD_DEPENDS+= svn:${PORTSDIR}/devel/subversion

USE_RC_SUBR=    influxdb

USES= bison:build gmake

BUILDSRC=${WRKSRC}/src/github.com/${GH_ACCOUNT}/${PORTNAME}

pre-build:
	@${MKDIR} ${WRKSRC}/src/github.com/${GH_ACCOUNT}/${PORTNAME}
	@cd ${WRKSRC}; ls -1 | ${GREP} -vw src | ${XARGS} -n 1 -I X ${CP} -a X src/github.com/${GH_ACCOUNT}/${PORTNAME}/

do-build:
	@cd ${BUILDSRC}; \
	${GMAKE} pre_build ; \
	CC=clang GOPATH=${WRKSRC} CGO_LDFLAGS=-L${PREFIX}/lib CGO_CFLAGS="-I${PREFIX}/include -DMDB_DSYNC=O_SYNC" ${GMAKE} parser valgrind binary_package

do-install:
	@${INSTALL} -o root -g wheel -m 755 ${BUILDSRC}/build/influxdb ${STAGEDIR}${PREFIX}/bin/
	@${MKDIR} ${STAGEDIR}${PREFIX}/etc/influxdb
	@${INSTALL} -o root -g wheel -m 644 ${BUILDSRC}/build/config.toml ${STAGEDIR}${PREFIX}/etc/influxdb/

.include <bsd.port.mk>
