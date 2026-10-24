#!/usr/bin/env bash
# Stop every doitlive player (and the pi demo agent) on this host.
# Safe to run from an SSH session: patterns are written so they never match
# this script's own command line.
set -uo pipefail

readonly PLAYER='[d]oitlive play'
readonly AGENT='[u]sr/local/bin/pi'

kill_tree() {
  local pid=$1 child
  for child in $(pgrep -P "${pid}" 2>/dev/null); do
    kill_tree "${child}"
  done
  kill -TERM "${pid}" 2>/dev/null || true
}

found=0
for pattern in "${PLAYER}" "${AGENT}"; do
  pids=$(pgrep -f "${pattern}" 2>/dev/null || true)
  [[ -z ${pids} ]] && continue
  found=1
  echo "Termino: ${pids//$'\n'/ }"
  for pid in ${pids}; do
    kill_tree "${pid}"
  done
done

if (( found == 0 )); then
  echo "Nessun player attivo."
else
  sleep 1
  # Anything that ignored SIGTERM (for example, blocked on a tty read).
  for pattern in "${PLAYER}" "${AGENT}"; do
    for pid in $(pgrep -f "${pattern}" 2>/dev/null || true); do
      pkill -KILL -P "${pid}" 2>/dev/null || true
      kill -KILL "${pid}" 2>/dev/null || true
    done
  done
  left=$(pgrep -f "${PLAYER}" 2>/dev/null || true)
  [[ -z ${left} ]] && echo "Player terminati." || echo "Ancora attivi: ${left//$'\n'/ }"
fi

# VIDEO 1 stops fapolicyd and restores it through a trap: if the player was
# killed hard, the trap never ran.
if ! systemctl is-active --quiet fapolicyd; then
  systemctl start fapolicyd
  echo "fapolicyd riavviato."
fi
