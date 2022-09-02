#!/bin/bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

set -o xtrace

MY_DIR="$(dirname "$0")"

# If this fails, see: https://macreports.com/terminal-says-operation-not-permitted-on-mac-fix/
# conda remove --name strain_library --all
conda env create -f "${MY_DIR}/environment.yml" # --prefix "${MY_DIR}/.conda"

# See: https://github.com/conda/conda/issues/7980
CONDA_BASE="$(conda info --base)"
source "${CONDA_BASE}"/etc/profile.d/conda.sh
conda activate strain_library

which pip

# Install kaleido via pip since it isn't in conda for M1 macs.
pip install kaleido

jupyter serverextension enable --py jupyter_http_over_ws
