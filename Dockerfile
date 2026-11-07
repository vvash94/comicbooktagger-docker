# syntax=docker/dockerfile:1
#
# ComicTagger (https://github.com/comictagger/comictagger) with a browser-based GUI.
# The desktop is served over noVNC by jlesage/baseimage-gui (web UI on 5800, VNC on 5900).

ARG BASEIMAGE=jlesage/baseimage-gui:debian-12-v4

# ---------------------------------------------------------------------------
# Builder: compile ComicTagger and its native deps (pyicu, unrar-cffi) into a venv
# ---------------------------------------------------------------------------
FROM ${BASEIMAGE} AS builder

ARG CT_VERSION=1.5.5
ARG DEBIAN_FRONTEND=noninteractive

# The baseimage strips /etc/passwd and /etc/group down (it regenerates them at
# container start), so package post-install scripts that run e.g.
# `chown root:staff` (fontconfig-config) fail. Restore the entries they need.
RUN grep -q '^root:' /etc/passwd || echo 'root:x:0:0:root:/root:/bin/sh' >> /etc/passwd; \
    grep -q '^root:' /etc/group  || echo 'root:x:0:' >> /etc/group; \
    grep -q '^staff:' /etc/group || echo 'staff:x:50:' >> /etc/group

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-venv python3-dev \
        build-essential pkg-config libicu-dev && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/comictagger && \
    /opt/comictagger/bin/pip install --no-cache-dir --upgrade pip wheel && \
    /opt/comictagger/bin/pip install --no-cache-dir "comictagger[all]==${CT_VERSION}"

# ---------------------------------------------------------------------------
# Runtime image
# ---------------------------------------------------------------------------
FROM ${BASEIMAGE}

ARG CT_VERSION=1.5.5
ARG ICON_URL=https://raw.githubusercontent.com/vvash94/comicbooktagger-docker/main/assets/icon.png

ARG DEBIAN_FRONTEND=noninteractive

# The baseimage strips /etc/passwd and /etc/group down (it regenerates them at
# container start), so package post-install scripts that run e.g.
# `chown root:staff` (fontconfig-config) fail. Restore the entries they need.
RUN grep -q '^root:' /etc/passwd || echo 'root:x:0:0:root:/root:/bin/sh' >> /etc/passwd; \
    grep -q '^root:' /etc/group  || echo 'root:x:0:' >> /etc/group; \
    grep -q '^staff:' /etc/group || echo 'staff:x:50:' >> /etc/group

# Python runtime, ICU for pyicu, and the system libraries Qt5's xcb platform plugin needs.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        libicu72 \
        libdbus-1-3 \
        libfontconfig1 \
        libfreetype6 \
        libgl1 \
        libglib2.0-0 \
        libx11-xcb1 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-randr0 \
        libxcb-render-util0 \
        libxcb-shape0 \
        libxcb-xfixes0 \
        libxcb-xinerama0 \
        libxcb-xkb1 \
        libxkbcommon-x11-0 \
        fonts-dejavu-core && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/comictagger /opt/comictagger
COPY rootfs/ /

RUN chmod +x /startapp.sh /usr/local/bin/comictagger && \
    install_app_icon.sh "${ICON_URL}" && \
    set-cont-env APP_NAME "ComicTagger" && \
    set-cont-env APP_VERSION "${CT_VERSION}"

# Extra command-line flags passed to the GUI.
ENV COMICTAGGER_ARGS=""

LABEL org.opencontainers.image.title="ComicTagger" \
      org.opencontainers.image.description="ComicTagger comic metadata tagger with a web-based GUI" \
      org.opencontainers.image.source="https://github.com/vvash94/comicbooktagger-docker" \
      org.opencontainers.image.version="${CT_VERSION}" \
      org.opencontainers.image.licenses="Apache-2.0"
