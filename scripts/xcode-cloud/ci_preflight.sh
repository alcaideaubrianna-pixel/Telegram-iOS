#!/bin/bash

set -euo pipefail

ROOT_DIR="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$ROOT_DIR"

: "${XCODE_CLOUD_CONFIGURATION_PATH:=build-system/template_minimal_development_configuration.json}"
: "${XCODE_CLOUD_BUILD_CONFIGURATION:=debug_arm64}"
: "${XCODE_CLOUD_BUILD_NUMBER:=1}"
: "${XCODE_CLOUD_CACHE_DIR:=$HOME/Library/Caches/telegram-bazel}"

log() { printf '[telegram-ci] %s\n' "$*"; }
fail() { printf '[telegram-ci] ERROR: %s\n' "$*" >&2; exit 1; }

command -v python3 >/dev/null || fail "python3 is required"
command -v xcodebuild >/dev/null || fail "xcodebuild is required"
test -f "$XCODE_CLOUD_CONFIGURATION_PATH" || fail "configuration not found: $XCODE_CLOUD_CONFIGURATION_PATH"

XCODE_VERSION="$(xcodebuild -version | awk '/^Xcode / { print $2; exit }')"
log "Xcode $XCODE_VERSION"
python3 --version

if [[ -n "${BAZEL_HTTP_CACHE_URL:-}" ]]; then
  case "$BAZEL_HTTP_CACHE_URL" in
    https://*) ;;
    *) fail "BAZEL_HTTP_CACHE_URL must use https://" ;;
  esac
  log "checking Bazel remote cache: $BAZEL_HTTP_CACHE_URL"
  curl --fail --silent --show-error --location --max-time "${BAZEL_CACHE_CHECK_TIMEOUT:-15}" \
    -o /dev/null -I "$BAZEL_HTTP_CACHE_URL" || fail "remote cache is unreachable"
else
  log "BAZEL_HTTP_CACHE_URL is unset; build will use local cache only"
fi

mkdir -p "$XCODE_CLOUD_CACHE_DIR"
test -w "$XCODE_CLOUD_CACHE_DIR" || fail "cache directory is not writable: $XCODE_CLOUD_CACHE_DIR"

log "checking Make.py command line"
python3 build-system/Make/Make.py --help >/dev/null
python3 build-system/Make/Make.py generateProject --help >/dev/null
python3 build-system/Make/Make.py build --help >/dev/null

if [[ "${CI_RUN_FULL_BUILD:-0}" != "1" ]]; then
  if [[ "${CI_RUN_GENERATE_PROJECT:-0}" != "1" ]]; then
    log "preflight passed; project generation and full build are disabled"
    log "set CI_RUN_GENERATE_PROJECT=1 to test generation, or CI_RUN_FULL_BUILD=1 to build"
    exit 0
  fi
fi

log "generating Xcode project"
python3 build-system/Make/Make.py \
  --cacheDir="$XCODE_CLOUD_CACHE_DIR" \
  generateProject \
  --configurationPath="$XCODE_CLOUD_CONFIGURATION_PATH" \
  --xcodeManagedCodesigning

if [[ "${CI_RUN_FULL_BUILD:-0}" != "1" ]]; then
  log "project generation passed; full build is disabled"
  exit 0
fi

log "running full build: $XCODE_CLOUD_BUILD_CONFIGURATION"
mkdir -p "${CI_ARCHIVE_PATH:-build/artifacts}"

python3 build-system/Make/Make.py \
  --cacheDir="$XCODE_CLOUD_CACHE_DIR" \
  build \
  --buildNumber="$XCODE_CLOUD_BUILD_NUMBER" \
  --configuration="$XCODE_CLOUD_BUILD_CONFIGURATION" \
  --configurationPath="$XCODE_CLOUD_CONFIGURATION_PATH" \
  --xcodeManagedCodesigning \
  --outputBuildArtifactsPath="${CI_ARCHIVE_PATH:-build/artifacts}"

log "full build passed"
