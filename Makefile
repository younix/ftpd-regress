#	$OpenBSD$

.PHONY: start-ftpd

REGRESS_TARGETS =	run-regress-ftpd-get
REGRESS_TARGETS +=	run-regress-ftpd-ls
REGRESS_ROOT_TARGETS =	${REGRESS_TARGETS}
REGRESS_CLEANUP =	cleanup-ftpd

TCPSERVER = /usr/local/bin/tcpserver
FTPD ?= /usr/libexec/ftpd
FTPDIR != getent passwd ftp | cut -d: -f6

.if ! exists(${TCPSERVER}) || ! exists(${FTPD})
REGRESS_SKIP_TARGETS += ${REGRESS_TARGETS}
.endif

start-ftpd:
	@echo '\n======== $@ ========'
	${SUDO} pkill tcpserver || true
	${SUDO} pkill ftpd || true
	# start ftpd
	${SUDO} ${TCPSERVER} 127.0.0.1 21 ${KTRACE} ${FTPD} -A &	\
	timeout=$$(($$(date +%s) + 5));					\
	while ! (fstat -p $$! | grep -q 'tcp 0x0 127.0.0.1:21');	\
	    do test $$(date +%s) -lt $$timeout; done;
	# prepare test files
	${SUDO} dd if=/dev/random of="${FTPDIR}/ftpd.regress" count=1 bs=1m
	${SUDO} chown ftp:ftp "${FTPDIR}/ftpd.regress"

run-regress-ftpd-get: start-ftpd
	@echo '\n======== $@ ========'
	ftp -a ftp://127.0.0.1/ftpd.regress
	cmp ${FTPDIR}/ftpd.regress ftpd.regress
	rm ftpd.regress

run-regress-ftpd-ls: start-ftpd
	@echo '\n======== $@ ========'
	echo ls | ftp -a 127.0.0.1 21 | grep -q 'ftpd.regress'

cleanup-ftpd:
	${SUDO} pkill tcpserver || true
	${SUDO} rm -f ${FTPDIR}/ftpd.regress

.include <bsd.regress.mk>
