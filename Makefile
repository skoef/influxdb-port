# $FreeBSD: databases/influxdb/Makefile rschoof $

PORTNAME=       influxdb
PORTVERSION=    0.8.8
CATEGORIES=     databases

MAINTAINER=     reinier@skoef.nl
COMMENT=        Open-source distributed time series database

LICENSE=        MIT

USE_GITHUB=     yes
GH_ACCOUNT=     influxdb
GH_COMMIT=      afde71e
GH_TAGNAME=     ${GH_COMMIT}

GNU_CONFIGURE=  yes

PKGORIGIN=      databases/influxdb
USE_AUTOTOOLS=  autoconf

LIB_DEPENDS+=   libleveldb.so:${PORTSDIR}/databases/leveldb \
				librocksdb.so:${PORTSDIR}/databases/rocksdb
BUILD_DEPENDS+= go:${PORTSDIR}/lang/go \
				protoc:${PORTSDIR}/devel/protobuf \
				protoc-gen-go:${PORTSDIR}/devel/goprotobuf
FETCH_DEPENDS+= bzr:${PORTSDIR}/devel/bzr \
				git:${PORTSDIR}/devel/git \
				hg:${PORTSDIR}/devel/mercurial

USE_RC_SUBR=    influxdb

USES=           bison:build gmake

GO_PKGNAME= github.com/influxdb/influxdb
CGO_CFLAGS=-DMDB_DSYNC=O_SYNC
CGO_LDFLAGS=-lrocksdb
TMP_WRKDIR= ${WRKDIRPREFIX}${.CURDIR}/work.tmp/
GO_DEPENDS= github.com/rakyll/statik \
			github.com/BurntSushi/toml \
			github.com/influxdb/go-cache \
			github.com/kimor79/gollectd \
			github.com/bmizerany/pat \
			github.com/dgnorton/goback \
			github.com/gorilla/mux \
			github.com/gorilla/context \
			github.com/influxdb/gomdb \
			github.com/jmhodges/levigo \
			code.google.com/p/gogoprotobuf \
			launchpad.net/gocheck \
			code.google.com/p/go.crypto \
			code.google.com/p/goprotobuf \
			code.google.com/p/log4go

OPTIONS_DEFINE= COLLECTD_PROXY
OPTIONS_DEFAULT=

COLLECTD_PROXY_DESC= include collectdb-InfluxDB proxy

COLLECTD_PROXY_DEPENDS= github.com/hoonmin/influxdb-collectd-proxy \
						github.com/paulhammond/gocollectd

.include <bsd.port.options.mk>

.if ${PORT_OPTIONS:MCOLLECTD_PROXY}
GO_DEPENDS+= ${COLLECTD_PROXY_DEPENDS}
PLIST_FILES+= bin/influxdb-collectd-proxy
USE_RC_SUBR+= influxdb-collectd-proxy
.endif

pre-clean:
	@${RM} -r ${TMP_WRKDIR}

pre-fetch: post-fetch
post-extract:
	@${MKDIR} ${GO_WRKSRC:H}
	@${LN} -sf ${WRKSRC} ${GO_WRKSRC}
	@${CP} -a ${TMP_WRKDIR}/* ${WRKDIR}/src
	@${RM} -r ${TMP_WRKDIR}

pre-build:
	@${GMAKE} -C ${WRKSRC} build_version_string parser
	@${FIND} ${WRKDIR}/src/code.google.com/p/go.crypto -name '*.go' | \
		${XARGS} ${SED} -i '' 's#golang.org/x/crypto#code.google.com/p/go.crypto#g'
	@cd ${WRKSRC}; \
		${RM} protocol/*.pb.go; \
		${LOCALBASE}/bin/protoc --go_out=. protocol/*.proto

do-build:
.for I in admin api/http api/graphite cluster common configuration checkers coordinator datastore engine parser protocol wal
	@cd ${GO_WRKSRC}; \
		${SETENV} CC=clang ${GO_ENV} ${GO_CMD} build ${GO_PKGNAME}/${I}
.endfor
	@cd ${GO_WRKSRC}; \
		${SETENV} CC=clang ${GO_ENV} ${GO_CMD} build -o influxdb ${GO_PKGNAME}/daemon
.if ${PORT_OPTIONS:MCOLLECTD_PROXY}
	@cd ${GO_WRKSRC}/../src/github.com/hoonmin/influxdb-collectd-proxy; \
		${SETENV} CC=clang ${GO_ENV} ${GO_CMD} build -o bin/proxy
.endif

do-install:
	@${INSTALL} -o root -g wheel -m 755 ${GO_WRKSRC}/influxdb ${STAGEDIR}${PREFIX}/bin/
.if ${PORT_OPTIONS:MCOLLECTD_PROXY}
	@${INSTALL} -o root -g wheel -m 755 ${GO_WRKSRC}/../src/github.com/hoonmin/influxdb-collectd-proxy/bin/proxy ${STAGEDIR}${PREFIX}/bin/influxdb-collectd-proxy
.endif
	@${MKDIR} ${STAGEDIR}${PREFIX}/etc/influxdb
	@${INSTALL} -o root -g wheel -m 644 ${GO_WRKSRC}/configuration/config.toml ${STAGEDIR}${PREFIX}/etc/influxdb/
	@${MKDIR} ${STAGEDIR}${PREFIX}/share/${PORTNAME}
	@${CP} -a ${GO_WRKSRC}/shared/admin ${STAGEDIR}${PREFIX}/share/${PORTNAME}/

.include <bsd.port.pre.mk>
.include "${PORTSDIR}/lang/go/files/bsd.go.mk"

${TMP_WRKDIR}github.com/rakyll/statik \
${TMP_WRKDIR}github.com/BurntSushi/toml \
${TMP_WRKDIR}github.com/influxdb/go-cache \
${TMP_WRKDIR}github.com/kimor79/gollectd \
${TMP_WRKDIR}github.com/bmizerany/pat \
${TMP_WRKDIR}github.com/dgnorton/goback \
${TMP_WRKDIR}github.com/gorilla/mux \
${TMP_WRKDIR}github.com/gorilla/context \
${TMP_WRKDIR}github.com/influxdb/gomdb \
${TMP_WRKDIR}github.com/jmhodges/levigo \
${TMP_WRKDIR}code.google.com/p/gogoprotobuf \
${TMP_WRKDIR}github.com/hoonmin/influxdb-collectd-proxy \
${TMP_WRKDIR}github.com/paulhammond/gocollectd:
	@${ECHO} "===> Fetching dependency ${@:S,${TMP_WRKDIR},,}"
	@${MKDIR} $@
	@git clone https://${@:S,${TMP_WRKDIR},,} ${@} 2>/dev/null
${TMP_WRKDIR}launchpad.net/gocheck:
	@${ECHO} "===> Fetching dependency ${@:S,${TMP_WRKDIR},,}"
	@${MKDIR} ${@:H}
	@bzr branch https://${@:S,${TMP_WRKDIR},,} ${@} 2>/dev/null
${TMP_WRKDIR}code.google.com/p/go.crypto \
${TMP_WRKDIR}code.google.com/p/goprotobuf \
${TMP_WRKDIR}code.google.com/p/log4go:
	@${ECHO} "===> Fetching dependency ${@:S,${TMP_WRKDIR},,}"
	@${MKDIR} ${@:H}
	@hg -q clone https://${@:S,${TMP_WRKDIR},,} ${@} 2>/dev/null

post-fetch: ${GO_DEPENDS:S,^,${TMP_WRKDIR},g}

.include <bsd.port.post.mk>
