INSTALL = /usr/bin/install
INSTALL_PROGRAM = ${INSTALL}
INSTALL_DATA = ${INSTALL} -m 644
PANDOC = pandoc
SHELLCHECK = shellcheck

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

SRC += ${SRC_DIR}/bootloader.sh
SRC += ${SRC_DIR}/config.sh
SRC += ${SRC_DIR}/fetch.sh
SRC += ${SRC_DIR}/util.sh
SRC += ${SRC_DIR}/output.sh
SRC += ${SRC_DIR}/partition.sh
SRC += ${SRC_DIR}/portage.sh
SRC += ${SRC_DIR}/server.sh
SRC += ${SRC_DIR}/spawn.sh
SRC += ${SRC_DIR}/step.sh
SRC += ${SRC_DIR}/stepcontrol.sh

all: ${PROGRAM_NAME} man

${PROGRAM_NAME}:
	@cp ${SRC_DIR}/$@.sh ${BUILD_DIR}/$@
	@mkdir -p ${BUILD_DIR}/modules
	@cp ${SRC} ${BUILD_DIR}/modules/
	@chmod +x ${BUILD_DIR}/${PROGRAM_NAME}

check:
	${SHELLCHECK} ${SRC_DIR}/${PROGRAM_NAME}.sh ${SRC}

install: all
	${INSTALL_PROGRAM} ${BUILD_DIR}/${PROGRAM_NAME} ${BIN_DIR}
	@mkdir -p ${MAN_DIR}/man5 ${SHARE_DIR}
	${INSTALL_DATA} ${BUILD_DIR}/${PROGRAM_NAME}.5 ${MAN_DIR}/man5
	@cp -R ${BUILD_DIR}/modules ${SHARE_DIR}

man:
	${PANDOC} -s -t man ${MAN_SRC} -o ${BUILD_DIR}/${PROGRAM_NAME}.5

clean: 
	@rm -rf ${PROGRAM_NAME} ${PROGRAM_NAME}.5 ${BUILD_DIR}/modules

