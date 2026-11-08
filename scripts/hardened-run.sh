# hardened-run.sh
#!/usr/bin/env bash
#
# Run a one-shot Docker container with restrictive security settings.
#
# Usage:
#   ./hardened-run.sh IMAGE [COMMAND] [ARGS...]
#
# Examples:
#   ./hardened-run.sh alpine:latest
#   ./hardened-run.sh alpine:latest sh
#   ./hardened-run.sh python:3.13-slim python app.py
#
# Optional environment overrides:
#   CONTAINER_USER=1000:1000
#   MEMORY_LIMIT=512m
#   CPU_LIMIT=1
#   PID_LIMIT=64
#
# Requirements:
#   - Docker Engine
#   - Standard Docker daemon (rootful installation)
#
# Security:
#   - One-shot foreground execution
#   - Automatic container removal
#   - Non-root container user
#   - Read-only root filesystem
#   - All Linux capabilities dropped
#   - No privilege escalation
#   - Docker default seccomp profile
#   - Docker default AppArmor profile (when available)
#   - No network access
#   - Private namespaces
#   - Resource limits
#   - No host filesystem mounts

set -Eeuo pipefail

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------

CONTAINER_USER="${CONTAINER_USER:-65534:65534}"
MEMORY_LIMIT="${MEMORY_LIMIT:-256m}"
CPU_LIMIT="${CPU_LIMIT:-0.5}"
PID_LIMIT="${PID_LIMIT:-64}"

# -------------------------------------------------------------------
# Validation
# -------------------------------------------------------------------

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is not installed or not in PATH." >&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker daemon is unavailable or permission denied." >&2
    exit 1
fi

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 IMAGE [COMMAND] [ARGS...]" >&2
    exit 2
fi

IMAGE="$1"
shift

# -------------------------------------------------------------------
# Launch
# -------------------------------------------------------------------

echo "Starting hardened one-shot container: ${IMAGE}" >&2

exec docker run \
    --rm \
    --interactive \
    --tty \
    --pull=missing \
    --user "${CONTAINER_USER}" \
    --read-only \
    --cap-drop=ALL \
    --security-opt=no-new-privileges:true \
    --network=none \
    --ipc=private \
    --pids-limit="${PID_LIMIT}" \
    --memory="${MEMORY_LIMIT}" \
    --memory-swap="${MEMORY_LIMIT}" \
    --cpus="${CPU_LIMIT}" \
    --ulimit nofile=1024:1024 \
    --tmpfs /tmp:rw,noexec,nosuid,nodev,size=16m \
    --restart=no \
    "${IMAGE}" "$@"