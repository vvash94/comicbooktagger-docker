# syntax=docker/dockerfile:1
#
# ComicTagger (https://github.com/comictagger/comictagger) with a browser-based GUI.
# The desktop is served over noVNC by jlesage/baseimage-gui (web UI on 5800, VNC on 5900).

ARG BASEIMAGE=jlesage/baseimage-gui:debian-12-v4

# ---------------------------------------------------------------------------
# Builder: compile ComicTagger's Python deps (incl. native pyicu, unrar-cffi) into a venv
# ---------------------------------------------------------------------------
FROM ${BASEIMAGE} AS builder

ARG CT_VERSION=1.5.5
ARG DEBIAN_FRONTEND=noninteractive

# In the baseimage, /etc/passwd, /etc/group and /var/log are symlinks into
# locations that only exist once the container is running (it generates them at
# startup). Package post-install scripts need them at build time: fontconfig-config
# runs `chown root:staff`, fontconfig writes /var/log/fontconfig.log. Create the
# symlink targets and the users/groups those scripts expect.
RUN for p in /var/log /var/cache/fontconfig; do mkdir -p "$(readlink -m "$p")"; done; \
    for f in /etc/passwd /etc/group; do mkdir -p "$(dirname "$(readlink -m "$f")")"; done; \
    grep -qs '^root:' /etc/passwd || echo 'root:x:0:0:root:/root:/bin/sh' >> /etc/passwd; \
    grep -qs '^root:' /etc/group  || echo 'root:x:0:' >> /etc/group; \
    grep -qs '^staff:' /etc/group || echo 'staff:x:50:' >> /etc/group

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-venv python3-dev \
        build-essential pkg-config libicu-dev && \
    rm -rf /var/lib/apt/lists/*

# PyQt5 comes from Debian's python3-pyqt5 in the runtime image (pip's PyQt5 wheels
# bundle a Qt built for OpenSSL 1.1, so HTTPS from Qt fails on Debian 12's OpenSSL 3).
# The venv can see it via --system-site-packages; pip installs everything else.
RUN python3 -m venv --system-site-packages /opt/comictagger && \
    /opt/comictagger/bin/pip install --no-cache-dir --upgrade pip wheel && \
    /opt/comictagger/bin/pip install --no-cache-dir "comictagger[7z,cbr]==${CT_VERSION}"

# ---------------------------------------------------------------------------
# Runtime image
# ---------------------------------------------------------------------------
FROM ${BASEIMAGE}

ARG CT_VERSION=1.5.5
ARG ICON_URL=https://raw.githubusercontent.com/vvash94/comicbooktagger-docker/main/assets/icon.png

ARG DEBIAN_FRONTEND=noninteractive

# In the baseimage, /etc/passwd, /etc/group and /var/log are symlinks into
# locations that only exist once the container is running (it generates them at
# startup). Package post-install scripts need them at build time: fontconfig-config
# runs `chown root:staff`, fontconfig writes /var/log/fontconfig.log. Create the
# symlink targets and the users/groups those scripts expect.
RUN for p in /var/log /var/cache/fontconfig; do mkdir -p "$(readlink -m "$p")"; done; \
    for f in /etc/passwd /etc/group; do mkdir -p "$(dirname "$(readlink -m "$f")")"; done; \
    grep -qs '^root:' /etc/passwd || echo 'root:x:0:0:root:/root:/bin/sh' >> /etc/passwd; \
    grep -qs '^root:' /etc/group  || echo 'root:x:0:' >> /etc/group; \
    grep -qs '^staff:' /etc/group || echo 'staff:x:50:' >> /etc/group

# Python runtime, Debian's PyQt5 (Qt 5.15 built against OpenSSL 3, pulls in the xcb
# libraries), extra Qt image formats (WebP etc.), CA certificates for Qt's HTTPS,
# and ICU for pyicu.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pyqt5 \
        qt5-image-formats-plugins \
        ca-certificates \
        libicu72 \
        fonts-dejavu-core \
      || { echo '--- /var/log/fontconfig.log ---'; cat /var/log/fontconfig.log 2>/dev/null; exit 1; } && \
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
