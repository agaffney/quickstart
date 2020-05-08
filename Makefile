INSTALL = /usr/bin/install
INSTALL_PROGRAM = ${INSTALL}
INSTALL_DATA = ${INSTALL} -m 644
PANDOC = pandoc

PROGRAM_NAME = quickstart

PREFIX = /usr/local
BIN_DIR = ${PREFIX}/bin
MAN_DIR = ${PREFIX}/share/man
SHARE_DIR = ${PREFIX}/share/${PROGRAM_NAME}

TARGET_DIR = .
BUILD_DIR = ${TARGET_DIR}
SRC_DIR = ${TARGET_DIR}/src
DOC_DIR = ${TARGET_DIR}/doc

MAN_SRC = ${DOC_DIR}/man/${PROGRAM_NAME}.5.md

SRC = ${SRC_DIR}/${PROGRAM_NAME}.sh

all: ${PROGRAM_NAME} man

${PROGRAM_NAME}:
	cp ${SRC} ${BUILD_DIR}/${PROGRAM_NAME}
	chmod +x ${BUILD_DIR}/${PROGRAM_NAME}

check:
	@echo "checking for errors... NOT YET IMPLEMENTED"

install: all
	${INSTALL_PROGRAM} ${BUILD_DIR}/${PROGRAM_NAME} ${BIN_DIR}
	@mkdir -p ${MAN_DIR}
	${INSTALL_DATA} ${BUILD_DIR}/${PROGRAM_NAME}.1 ${MAN_DIR}/man5

man:
	${PANDOC} -s -t man ${MAN_SRC} -o ${BUILD_DIR}/${PROGRAM_NAME}.5

clean: 
	@rm -f ${PROGRAM_NAME} ${PROGRAM_NAME}.5

