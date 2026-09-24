#!/bin/bash
set -euo pipefail
exec "$CI_PRIMARY_REPOSITORY_PATH/scripts/xcode-cloud/ci_preflight.sh"
