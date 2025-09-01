#!/bin/bash
set -euo pipefail

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"
EXTRA_PACKAGES="${EXTRA_PACKAGES:-}"

echo "CRON_SCHEDULE=${CRON_SCHEDULE:-not set}"
echo "CRON_COMMAND=${CRON_COMMAND:-not set}"
echo "PUID=${PUID}"
echo "PGID=${PGID}"
echo "EXTRA_PACKAGES=${EXTRA_PACKAGES:-not set}"
echo "==========================================="

if [[ -n "${EXTRA_PACKAGES// /}" ]]; then
  echo "Installing runtime packages: ${EXTRA_PACKAGES}"
  export DEBIAN_FRONTEND=noninteractive
  apt update
  apt install -y --no-install-recommends ${EXTRA_PACKAGES}
  rm -rf /var/lib/apt/lists/*
  echo "Package installation finished."
fi

pkill -x cron >/dev/null 2>&1 || true

if [[ -z "${CRON_SCHEDULE:-}" || -z "${CRON_COMMAND:-}" ]]; then
  echo "Error: CRON_SCHEDULE and CRON_COMMAND are required."
  exit 1
fi

if ! getent group "${PUID}" >/dev/null; then
  echo "Creating group '${PUID}' with GID=${PGID}"
  groupadd -g "${PGID}" "${PUID}" || true
fi


if ! id -u "${PUID}" >/dev/null 2>&1; then
  echo "Creating user '${PUID}' with UID=${PUID} and GID=${PGID}"
  useradd -u "${PUID}" -g "${PGID}" -m -s /bin/bash "${PUID}" || true
fi

CRON_CMD="/bin/sh -lc '${CRON_COMMAND} >/proc/1/fd/1 2>/proc/1/fd/2'"
echo "${CRON_SCHEDULE} ${CRON_CMD}" | crontab -u "${PUID}" -
echo "Installed crontab for ${PUID}:"

crontab -u "${PUID}" -l || true
exec cron -f