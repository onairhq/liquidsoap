#!/bin/sh

set -eu

# ============================================================
# Default environment variables
# ============================================================

: "${ICECAST_HOST:=icecast}"
: "${ICECAST_PORT:=8000}"
: "${ICECAST_USER:=source}"
: "${ICECAST_PASSWORD:=change-me}"
: "${ICECAST_MOUNT:=/radio.mp3}"

: "${ICECAST_NAME:=Radio Dream}"
: "${ICECAST_GENRE:=Rock}"
: "${ICECAST_DESCRIPTION:=Radio Dream}"
: "${ICECAST_URL:=}"

: "${DISCOGS_CONSUMER_KEY:=}"
: "${DISCOGS_CONSUMER_SECRET:=}"

: "${JINGLE_EVERY:=4}"
: "${STREAM_BITRATE:=128}"
: "${LOG_LEVEL:=3}"

: "${S3_BUCKET:=}"
: "${S3_REGION:=}"
: "${S3_ENDPOINT:=}"
: "${S3_ACCESS_KEY_ID:=}"
: "${S3_SECRET_ACCESS_KEY:=}"
: "${S3_PREFIX:=}"
: "${S3_TRACKS_PREFIX:=tracks}"
: "${S3_JINGLES_PREFIX:=jingles}"

: "${FALLBACK_FILE:=}"

# ============================================================
# Export environment variables
# ============================================================

export ICECAST_HOST ICECAST_PORT ICECAST_USER ICECAST_PASSWORD
export ICECAST_MOUNT ICECAST_NAME ICECAST_GENRE
export ICECAST_DESCRIPTION ICECAST_URL

export DISCOGS_CONSUMER_KEY DISCOGS_CONSUMER_SECRET

export JINGLE_EVERY STREAM_BITRATE LOG_LEVEL FALLBACK_FILE

export S3_BUCKET S3_REGION S3_ENDPOINT
export S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_PREFIX
export S3_TRACKS_PREFIX S3_JINGLES_PREFIX

# ============================================================
# Information
# ============================================================

echo "Liquidsoap ${LIQUIDSOAP_VERSION:-unknown}"

echo "Configuration:"
echo "  ICECAST_HOST: ${ICECAST_HOST}"
echo "  ICECAST_PORT: ${ICECAST_PORT}"
echo "  ICECAST_MOUNT: ${ICECAST_MOUNT}"
echo "  STREAM_BITRATE: ${STREAM_BITRATE}"
echo "  LOG_LEVEL: ${LOG_LEVEL}"

if [ -n "${S3_BUCKET}" ]; then
    echo "  S3 streaming: enabled"
    echo "  S3_BUCKET: ${S3_BUCKET}"
    echo "  S3_REGION: ${S3_REGION:-default}"
    echo "  S3_ENDPOINT: ${S3_ENDPOINT:-default}"
    echo "  S3_PREFIX: ${S3_PREFIX:-/}"
else
    echo "  S3 streaming: disabled"
fi

# ============================================================
# Start
# ============================================================

exec "$@"
