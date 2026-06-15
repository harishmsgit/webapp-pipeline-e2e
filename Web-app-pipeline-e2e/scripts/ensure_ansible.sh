#!/usr/bin/env sh
set -eu

ANSIBLE_VERSION_SPEC="${ANSIBLE_VERSION_SPEC:-ansible-core>=2.16,<2.18}"
VENV_DIR="${ANSIBLE_VENV_DIR:-.ansible-venv}"

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "sudo is required to install Python packaging dependencies on this Jenkins agent." >&2
    return 1
  fi
}

install_python_packaging() {
  if command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get update
    run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y python3-venv python3-pip
  elif command -v dnf >/dev/null 2>&1; then
    run_as_root dnf install -y python3-pip python3-virtualenv
  elif command -v yum >/dev/null 2>&1; then
    run_as_root yum install -y python3-pip python3-virtualenv
  else
    echo "No supported package manager found. Install python3-venv and python3-pip on the Jenkins agent." >&2
    return 1
  fi
}

if command -v ansible >/dev/null 2>&1 && command -v ansible-playbook >/dev/null 2>&1; then
  return 0 2>/dev/null || exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to bootstrap Ansible on this Jenkins agent." >&2
  return 1 2>/dev/null || exit 1
fi

if [ ! -x "${VENV_DIR}/bin/ansible" ]; then
  rm -rf "${VENV_DIR}"

  if ! python3 -m venv "${VENV_DIR}"; then
    install_python_packaging
    rm -rf "${VENV_DIR}"
    python3 -m venv "${VENV_DIR}"
  fi

  "${VENV_DIR}/bin/python" -m pip install --upgrade pip
  "${VENV_DIR}/bin/python" -m pip install "${ANSIBLE_VERSION_SPEC}"
  export PATH="$(pwd)/${VENV_DIR}/bin:${PATH}"
else
  export PATH="$(pwd)/${VENV_DIR}/bin:${PATH}"
fi

if ! command -v ansible >/dev/null 2>&1 || ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "Ansible bootstrap completed, but ansible/ansible-playbook is still unavailable." >&2
  return 1 2>/dev/null || exit 1
fi
