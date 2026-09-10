#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
export IRIS_BACKEND=cpu
export GGML_CUDA_NO_VMM=1
export TOKENIZERS_PARALLELISM=false
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"
exec python app.py "$@"
