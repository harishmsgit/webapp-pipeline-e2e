#!/usr/bin/env sh
set -eu

ANSIBLE_VERSION_SPEC="${ANSIBLE_VERSION_SPEC:-ansible-core>=2.16,<2.18}"
VENV_DIR="${ANSIBLE_VENV_DIR:-.ansible-venv}"

if command -v ansible >/dev/null 2>&1 && command -v ansible-playbook >/dev/null 2>&1; then
  return 0 2>/dev/null || exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to bootstrap Ansible on this Jenkins agent." >&2
  return 1 2>/dev/null || exit 1
fi

if [ ! -x "${VENV_DIR}/bin/ansible" ]; then
  if python3 -m venv "${VENV_DIR}"; then
    "${VENV_DIR}/bin/python" -m pip install --upgrade pip
    "${VENV_DIR}/bin/python" -m pip install "${ANSIBLE_VERSION_SPEC}"
    export PATH="$(pwd)/${VENV_DIR}/bin:${PATH}"
  else
    python3 -m pip install --user "${ANSIBLE_VERSION_SPEC}"
    USER_BASE="$(python3 -m site --user-base)"
    export PATH="${USER_BASE}/bin:${PATH}"
  fi
else
  export PATH="$(pwd)/${VENV_DIR}/bin:${PATH}"
fi

if ! command -v ansible >/dev/null 2>&1 || ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "Ansible bootstrap completed, but ansible/ansible-playbook is still unavailable." >&2
  return 1 2>/dev/null || exit 1
fi
