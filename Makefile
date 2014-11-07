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
FETCH_DEPENDS+= bzr:${PORTSDIR}/devel/bzr
FETCH_DEPENDS+= git:${PORTSDIR}/devel/git
FETCH_DEPENDS+= hg:${PORTSDIR}/devel/mercurial

USE_RC_SUBR=    influxdb

USES=			bison:build gmake

NO_CHECKSUM=1

GO_PKGNAME= github.com/influxdb/influxdb
CGO_CFLAGS=-DMDB_DSYNC=O_SYNC

TMP_WRKDIR=${WRKDIR}/../work.tmp
pre-clean:
	@${RM} -r ${TMP_WRKDIR}

post-fetch:
.for I in github.com/rakyll/statik \
	github.com/BurntSushi/toml \
	github.com/influxdb/go-cache \
	github.com/kimor79/gollectd \
	github.com/bmizerany/pat \
	github.com/dgnorton/goback \
	github.com/gorilla/mux \
	github.com/gorilla/context \
	github.com/influxdb/gomdb \
	github.com/jmhodges/levigo \
	code.google.com/p/gogoprotobuf
	@${MKDIR} ${TMP_WRKDIR}/src/${I}
	@${ECHO} "===> Fetching dependency ${I}"
	@git clone https://${I} ${TMP_WRKDIR}/src/${I} 2>/dev/null
.endfor
.for I in launchpad.net/gocheck
	@${MKDIR} ${TMP_WRKDIR}/src/${I:H}
	@${ECHO} "===> Fetching dependency ${I}"
	@bzr branch https://${I} ${TMP_WRKDIR}/src/${I} 2>/dev/null
.endfor
.for I in code.google.com/p/go.crypto \
	code.google.com/p/goprotobuf \
	code.google.com/p/log4go
	@${MKDIR} ${TMP_WRKDIR}/src/${I:H}
	@${ECHO} "===> Fetching dependency ${I}"
	@hg -q clone https://${I} ${TMP_WRKDIR}/src/${I} 2>/dev/null
.endfor

post-extract:
	@${MKDIR} ${GO_WRKSRC:H}
	@${LN} -sf ${WRKSRC} ${GO_WRKSRC}
	@${CP} -a ${TMP_WRKDIR}/* ${WRKDIR}
	@${RM} -r ${TMP_WRKDIR}

pre-build:
	${GMAKE} -C ${WRKSRC} build_version_string parser
	cd ${WRKSRC}; \
		${RM} protocol/*.pb.go; \
		${LOCALBASE}/bin/protoc --go_out=. protocol/*.proto

do-build:
.for I in admin api/http api/graphite cluster common configuration checkers coordinator datastore engine parser protocol wal
	@cd ${GO_WRKSRC}; \
		${SETENV} CC=clang ${GO_ENV} ${GO_CMD} build ${GO_PKGNAME}/${I}
.endfor
	@cd ${GO_WRKSRC}; \
		${SETENV} CC=clang ${GO_ENV} ${GO_CMD} build -o influxdb ${GO_PKGNAME}/daemon

do-install:
	@${INSTALL} -o root -g wheel -m 755 ${GO_WRKSRC}/influxdb ${STAGEDIR}${PREFIX}/bin/
	@${MKDIR} ${STAGEDIR}${PREFIX}/etc/influxdb
	@${INSTALL} -o root -g wheel -m 644 ${GO_WRKSRC}/configuration/config.toml ${STAGEDIR}${PREFIX}/etc/influxdb/
	@${MKDIR} ${STAGEDIR}${PREFIX}/share/${PORTNAME}
	@${CP} -a ${GO_WRKSRC}/shared/admin ${STAGEDIR}${PREFIX}/share/${PORTNAME}/

.include <bsd.port.pre.mk>
.include "${PORTSDIR}/lang/go/files/bsd.go.mk"
.include <bsd.port.post.mk>
