#!/bin/bash
set -euo pipefail

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"
EXTRA_PACKAGES="${EXTRA_PACKAGES:-}"
TZ="${TZ:-UTC}"

echo "CRON_SCHEDULE=${CRON_SCHEDULE:-not set}"
echo "CRON_COMMAND=${CRON_COMMAND:-not set}"
echo "PUID=${PUID}"
echo "PGID=${PGID}"
echo "TZ=${TZ}"
echo "EXTRA_PACKAGES=${EXTRA_PACKAGES:-not set}"
echo "Current time: $(date)"
echo "==========================================="

if [[ -n "${EXTRA_PACKAGES// /}" ]]; then
  echo "Installing runtime packages: ${EXTRA_PACKAGES}"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends ${EXTRA_PACKAGES}
  rm -rf /var/lib/apt/lists/*
  echo "Package installation finished."
fi

export TZ
ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
echo "${TZ}" > /etc/timezone

pkill -x cron >/dev/null 2>&1 || true

if [[ -z "${CRON_SCHEDULE:-}" || -z "${CRON_COMMAND:-}" ]]; then
  echo "Error: CRON_SCHEDULE and CRON_COMMAND are required."
  exit 1
fi


USERNAME="u${PUID}"
GROUPNAME="u${PGID}"


if ! getent group "${GROUPNAME}" >/dev/null; then
  echo "Creating group '${GROUPNAME}' with GID=${PGID}"
  groupadd -g "${PGID}" "${GROUPNAME}"
fi

if ! id -u "${USERNAME}" >/dev/null 2>&1; then
  echo "Creating user '${USERNAME}' with UID=${PUID} and GID=${PGID}"
  useradd -u "${PUID}" -g "${GROUPNAME}" -m -s /bin/bash "${USERNAME}"
fi

CRON_CMD="/bin/sh -lc 'su -s /bin/bash ${USERNAME} -c \"${CRON_COMMAND}\" >/proc/1/fd/1 2>/proc/1/fd/2'"
echo "${CRON_SCHEDULE} ${CRON_CMD}" | crontab -

echo "Installed crontab (commands running as ${USERNAME}):"
crontab -l || true

exec cron -f
