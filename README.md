# Liquidsoap Docker Image

A Docker image for [Liquidsoap](https://www.liquidsoap.info/), built on top of the official `savonet/liquidsoap` image. It runs a ready-to-use radio automation pipeline that streams to [Icecast](https://icecast.org/), with jingle rotation, silence detection, audio normalization, cover art lookup via Discogs, and optional S3-backed playlists.

## Documentations

[onairhq/icecast2](https://github.com/onairhq/icecast2)
[onairhq/web](https://github.com/onairhq/web)

## Features

- Streams MP3 to Icecast through `output.icecast`
- Randomized track playlist with a jingle inserted every N tracks
- Optional S3 source for tracks and jingles (through the bundled `s3sg` gateway)
- Automatic skip of excessive silence (5 seconds below -45 dB)
- Audio normalization
- Last-resort fallback (known-good file or silence) so the stream never drops
- ICY metadata updates with cover art URL from [Discogs](https://www.discogs.com/developers)
- Runs as a non-root user (`10001:10001`)

## Supported Platforms

| OS    | Architecture |
| ----- | ------------ |
| Linux | `amd64`      |
| Linux | `arm64`      |

## Environment Variables

Configure the stream using the following environment variables.

### Icecast

| Variable              | Default       | Description                         |
| --------------------- | ------------- | ----------------------------------- |
| `ICECAST_HOST`        | `icecast`     | Icecast server hostname             |
| `ICECAST_PORT`        | `8000`        | Icecast server port                 |
| `ICECAST_USER`        | `source`      | Source username                     |
| `ICECAST_PASSWORD`    | `change-me`   | Source password (must not be empty) |
| `ICECAST_MOUNT`       | `/radio.mp3`  | Mount point                         |
| `ICECAST_NAME`        | `Radio Dream` | Stream name                         |
| `ICECAST_GENRE`       | `Rock`        | Stream genre                        |
| `ICECAST_DESCRIPTION` | `Radio Dream` | Stream description                  |
| `ICECAST_URL`         | _empty_       | Stream website URL                  |

### Stream

| Variable         | Default | Description                                                                                        |
| ---------------- | ------- | -------------------------------------------------------------------------------------------------- |
| `JINGLE_EVERY`   | `4`     | Play one jingle every N tracks (must be greater than 0)                                            |
| `STREAM_BITRATE` | `128`   | MP3 bitrate in kbps (between `8` and `320`)                                                        |
| `FALLBACK_FILE`  | _empty_ | Path to a known-good audio file used as last-resort fallback. If unset or missing, silence is used |
| `LOG_LEVEL`      | `3`     | Liquidsoap log level (set to `5` to debug requests)                                                |

### Discogs (optional)

Both variables must be set together, or both left empty.

| Variable                  | Default | Description             |
| ------------------------- | ------- | ----------------------- |
| `DISCOGS_CONSUMER_KEY`    | _empty_ | Discogs consumer key    |
| `DISCOGS_CONSUMER_SECRET` | _empty_ | Discogs consumer secret |

When configured, the cover image of the current track is looked up on Discogs and published in the `url` field of the ICY metadata.

### S3 (optional)

S3 streaming is enabled when `S3_BUCKET` is set. When enabled, `S3_ACCESS_KEY_ID` and `S3_SECRET_ACCESS_KEY` are required, and `S3_TRACKS_PREFIX` must differ from `S3_JINGLES_PREFIX`.

| Variable               | Default   | Description                                  |
| ---------------------- | --------- | -------------------------------------------- |
| `S3_BUCKET`            | _empty_   | Bucket name. Setting it enables S3 mode      |
| `S3_REGION`            | _empty_   | Bucket region                                |
| `S3_ENDPOINT`          | _empty_   | Custom endpoint (MinIO, Cloudflare R2, etc.) |
| `S3_ACCESS_KEY_ID`     | _empty_   | Access key ID                                |
| `S3_SECRET_ACCESS_KEY` | _empty_   | Secret access key                            |
| `S3_PREFIX`            | _empty_   | Optional global prefix inside the bucket     |
| `S3_TRACKS_PREFIX`     | `tracks`  | Prefix (folder) containing music tracks      |
| `S3_JINGLES_PREFIX`    | `jingles` | Prefix (folder) containing jingles           |

**Security:** Change the default `ICECAST_PASSWORD` and never commit S3 or Discogs credentials to version control.

## Getting Started

### Pull the Image

Pull the latest image:

```bash
docker pull ghcr.io/onairhq/liquidsoap:latest
```

Or pull a specific Liquidsoap version:

```bash
docker pull ghcr.io/onairhq/liquidsoap:2.4.5
```

### Run the Container

Start Liquidsoap with local media (the Icecast server must be reachable at `ICECAST_HOST`):

```bash
docker run -d \
  --name liquidsoap \
  --restart unless-stopped \
  -e ICECAST_HOST=icecast \
  -e ICECAST_PASSWORD='replace-with-your-source-password' \
  -v ./tracks:/app/storage/tracks \
  -v ./jingles:/app/storage/jingles \
  ghcr.io/onairhq/liquidsoap:latest
```

### Run with S3

```bash
docker run -d \
  --name liquidsoap \
  --restart unless-stopped \
  -e ICECAST_HOST=icecast \
  -e ICECAST_PASSWORD='replace-with-your-source-password' \
  -e S3_BUCKET=my-radio-bucket \
  -e S3_REGION=eu-central-1 \
  -e S3_ACCESS_KEY_ID='replace-with-access-key' \
  -e S3_SECRET_ACCESS_KEY='replace-with-secret-key' \
  -e S3_TRACKS_PREFIX=tracks \
  -e S3_JINGLES_PREFIX=jingles \
  ghcr.io/onairhq/liquidsoap:latest
```

### Docker Compose

Example together with the [Icecast image](https://github.com/onairhq/icecast2):

```yaml
services:
  icecast:
    image: ghcr.io/onairhq/icecast2:latest
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      ICECAST_SOURCE_PASSWORD: replace-with-your-source-password
      ICECAST_ADMIN_PASSWORD: replace-with-a-strong-admin-password
      ICECAST_RELAY_PASSWORD: replace-with-a-strong-relay-password

  liquidsoap:
    image: ghcr.io/onairhq/liquidsoap:latest
    restart: unless-stopped
    depends_on:
      - icecast
    environment:
      ICECAST_HOST: icecast
      ICECAST_PASSWORD: replace-with-your-source-password
      ICECAST_MOUNT: /radio.mp3
      ICECAST_NAME: Radio Dream
      JINGLE_EVERY: 4
      STREAM_BITRATE: 128
    volumes:
      - ./tracks:/app/storage/tracks
      - ./jingles:/app/storage/jingles
```

The stream will be available at:

http://localhost:8000/radio.mp3

> `ICECAST_PASSWORD` in Liquidsoap must match `ICECAST_SOURCE_PASSWORD` in Icecast.

## How It Works

1. **Source** — tracks and jingles are read from `/app/storage` (local mode) or streamed from S3 through the internal `s3sg` gateway (listening on `127.0.0.1:8090`).
2. **Rotation** — tracks are shuffled once per pass; a jingle is inserted every `JINGLE_EVERY` tracks.
3. **Silence skip** — the current track is skipped after 5 seconds below -45 dB.
4. **Fallback** — if the rotation fails, `FALLBACK_FILE` (or silence) keeps the stream alive.
5. **Processing** — audio is normalized and metadata is built as `Artist - Title`.
6. **Output** — the stream is encoded as MP3 and sent to Icecast. ICY metadata (song and cover URL) is pushed separately to preserve `StreamUrl` on clients.

## Volumes

| Path                   | Description               |
| ---------------------- | ------------------------- |
| `/app/storage/tracks`  | Music tracks (local mode) |
| `/app/storage/jingles` | Jingles (local mode)      |

Local playlists are watched for changes, so files added or removed are picked up without a restart.

## Image Tags

| Tag      | Description                                         |
| -------- | --------------------------------------------------- |
| `latest` | Latest published image                              |
| `2.4.5`  | Image built for Liquidsoap upstream version `2.4.5` |

The version tag identifies the upstream Liquidsoap version, not an immutable Docker image revision. The image may be rebuilt or updated with changes to the Docker packaging, configuration, dependencies, or entrypoint without changing the upstream Liquidsoap version.

For reproducible deployments, pin the image by digest when an immutable image reference is required.

## Version

The Liquidsoap version is configurable at build time through the `LIQUIDSOAP_VERSION` build argument:

```bash
docker build --build-arg LIQUIDSOAP_VERSION=2.4.5 -t liquidsoap .
```

The image is based on `savonet/liquidsoap` and includes the `s3sg` S3 stream gateway, built from source in a separate Go build stage.

<div align=center>
    <p>Built with passion for open-source streaming</p>
</div>
