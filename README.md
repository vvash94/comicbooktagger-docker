# comicbooktagger-docker

Unofficial Docker image for [ComicTagger](https://github.com/comictagger/comictagger), the comic book metadata tagger. It runs the full ComicTagger desktop GUI inside the container and serves it to your browser, with an Unraid template included.

- **Image:** `ghcr.io/vvash94/comictagger`
- **Tags:** `latest` (newest stable ComicTagger release), `<version>` (e.g. `1.5.5`), `sha-<commit>`
- **Base:** [jlesage/baseimage-gui](https://github.com/jlesage/docker-baseimage-gui) (Debian 12, noVNC web UI)
- **Platform:** linux/amd64

The image is rebuilt automatically when a new stable ComicTagger release appears on PyPI, and weekly to pick up base-image security updates.

## Quick start

```bash
docker run -d --name ComicTagger \
  -p 5800:5800 \
  -v /path/to/appdata/comictagger:/config \
  -v /path/to/comics:/comics \
  -e USER_ID=99 -e GROUP_ID=100 \
  ghcr.io/vvash94/comictagger:latest
```

Open `http://<server-ip>:5800`. On first run, set your [Comic Vine API key](https://comicvine.gamespot.com/api/) in ComicTagger's Settings. It is saved under `/config`.

### Docker Compose

```yaml
services:
  comictagger:
    image: ghcr.io/vvash94/comictagger:latest
    container_name: ComicTagger
    ports:
      - "5800:5800"
    volumes:
      - ./config:/config
      - /path/to/comics:/comics
    environment:
      USER_ID: 1000
      GROUP_ID: 1000
      TZ: America/Los_Angeles
      KEEP_APP_RUNNING: 1
    restart: unless-stopped
```

## Unraid

**Until the template is in Community Applications**, install it manually:

1. Open the Unraid terminal and run:
   ```bash
   wget -O /boot/config/plugins/dockerMan/templates-user/my-ComicTagger.xml \
     https://raw.githubusercontent.com/vvash94/comicbooktagger-docker/main/unraid/comictagger.xml
   ```
2. Go to **Docker → Add Container**, pick **ComicTagger** from the *Template* dropdown, set your **Comics** path and click **Apply**.
3. Click the container icon and choose **WebUI**.

## Volumes

| Path | Purpose |
|---|---|
| `/config` | Settings, Comic Vine API key, cache and logs (`/config/.ComicTagger`) |
| `/comics` | Your comic library (read/write). File dialogs open here by default. |

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `USER_ID` / `GROUP_ID` | `1000` | User/group the app runs as (use `99`/`100` on Unraid) |
| `UMASK` | `0022` | Permission mask for new files |
| `TZ` | `Etc/UTC` | Timezone |
| `KEEP_APP_RUNNING` | `0` | `1` restarts ComicTagger if it's closed or crashes |
| `DISPLAY_WIDTH` / `DISPLAY_HEIGHT` | `1920` / `1080` | Virtual screen size |
| `DARK_MODE` | `0` | Dark theme for the web page around the app |
| `COMICTAGGER_ARGS` | *(empty)* | Optional extra command-line flags for the GUI |
| `SECURE_CONNECTION` | `0` | `1` serves the web UI over HTTPS |
| `WEB_AUTHENTICATION` | `0` | `1` adds a login page (requires `SECURE_CONNECTION=1`) |
| `WEB_AUTHENTICATION_USERNAME` / `_PASSWORD` | *(empty)* | Single-user web login credentials |

The base image supports more options; see the [baseimage-gui docs](https://github.com/jlesage/docker-baseimage-gui#environment-variables).

## Using the CLI

The `comictagger` command in the container shares the GUI's settings and API key, and drops to `USER_ID`/`GROUP_ID` automatically so file ownership stays correct:

```bash
# Show tags
docker exec ComicTagger comictagger -p -t CR "/comics/Saga/Saga 001.cbz"

# Auto-tag a whole folder from Comic Vine (ComicRack tags), recursively
docker exec ComicTagger comictagger -s -o -f -t CR -R /comics/Saga

# Rename files from their tags
docker exec ComicTagger comictagger -r -t CR -R /comics/Saga
```

On Unraid you can schedule these with the *User Scripts* plugin.

## Notes

- **CBR files are read-only.** Reading works, but writing RAR archives needs the proprietary `rar` program, which is not included. Use *File → Export to Zip* (or `comictagger -e`) to convert them to CBZ.
- **ComicTagger 1.6 (beta)** switches to Qt6 and a new settings format and location. This image tracks stable releases only. You can build a specific version with `--build-arg CT_VERSION=...`, but 1.6 needs extra system packages that aren't in this Dockerfile yet.

## Building locally

```bash
docker build -t comictagger:local --build-arg CT_VERSION=1.5.5 .
```

## Credits

ComicTagger is developed by the [ComicTagger team](https://github.com/comictagger/comictagger) under the Apache 2.0 license. The icon in `assets/` comes from that project. This repository only packages it and is not affiliated with the ComicTagger project.
