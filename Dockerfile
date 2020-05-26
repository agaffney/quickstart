FROM gentoo/portage:latest as portage

FROM gentoo/stage3-amd64:latest

COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

WORKDIR /usr/src/quickstart
COPY . /usr/src/quickstart

RUN make install

