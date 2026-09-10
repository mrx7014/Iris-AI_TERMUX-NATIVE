#!/data/data/com.termux/files/usr/bin/bash
# Iris AI - Termux setup (no root, no proot-distro)
# Usage: bash setup-termux.sh [--download-models] [--with-vision] [--no-update]

set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$ROOT_DIR"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'
info() { printf '%b\n' "${GREEN}[Iris-Termux]${RESET} $*"; }
warn() { printf '%b\n' "${YELLOW}[Iris-Termux]${RESET} $*"; }
die() { printf '%b\n' "${RED}[Iris-Termux] ERROR:${RESET} $*" >&2; exit 1; }

DOWNLOAD_MODELS=0
WITH_VISION=0
NO_UPDATE=0
for arg in "$@"; do
  case "$arg" in
    --download-models) DOWNLOAD_MODELS=1 ;;
    --with-vision) WITH_VISION=1 ;;
    --no-update) NO_UPDATE=1 ;;
    -h|--help)
      cat <<'HELP'
Usage: bash setup-termux.sh [options]

  --download-models  Download the Tiny text models (several GB).
  --with-vision      Also download the optional vision model (large).
  --no-update        Do not run pkg update/upgrade.

This script installs only the CPU/GGUF runtime. It does not require root,
proot-distro, a Linux desktop, CUDA, or Termux:API.
HELP
      exit 0
      ;;
    *) die "Unknown option: $arg (use --help)" ;;
  esac
done

[ -n "${PREFIX:-}" ] || die "Run this script inside Termux. PREFIX is not set."
case "${PREFIX:-}" in
  /data/data/com.termux/files/usr|/data/data/com.termux/files/usr/*) ;;
  *) die "This does not look like the official Termux environment." ;;
esac

command -v pkg >/dev/null 2>&1 || die "pkg was not found. Install Termux from F-Droid or the official GitHub releases."

if [ "$NO_UPDATE" -eq 0 ]; then
  info "Updating Termux packages..."
  pkg update -y
  pkg upgrade -y
fi

info "Installing native build tools and libraries..."
pkg install -y python clang cmake make pkg-config libopenblas rust git curl wget

# llama-cpp-python compiles llama.cpp locally on Android. Disable CPU-specific
# probing and OpenMP because these are the two most common Termux build issues.
export CMAKE_ARGS="${CMAKE_ARGS:--DGGML_NATIVE=OFF -DGGML_OPENMP=OFF}"
export FORCE_CMAKE="${FORCE_CMAKE:-1}"
export PIP_NO_CACHE_DIR="${PIP_NO_CACHE_DIR:-1}"

info "Installing the minimal Python runtime (no torch/CUDA/desktop automation)..."
python -m pip install --upgrade setuptools wheel
python -m pip install -r requirements-termux.txt

# The full project defaults to a desktop/server profile. Make a safe CPU
# profile for a phone, preserving the original config for easy rollback.
CONFIG="config/iris.conf"
if [ -f "$CONFIG" ] && [ ! -f "${CONFIG}.desktop-backup" ]; then
  cp "$CONFIG" "${CONFIG}.desktop-backup"
fi
if [ -f "$CONFIG" ]; then
  sed -i 's/"size": "[^"]*"/"size": "tiny"/' "$CONFIG"
  sed -i 's/"n_ctx_allocation": "[^"]*"/"n_ctx_allocation": "4096"/' "$CONFIG"
  sed -i 's/"n_gpu_layers": -1/"n_gpu_layers": 0/' "$CONFIG"
  sed -i 's/"n_batch": "auto"/"n_batch": 128/' "$CONFIG"
  sed -i 's/"n_ubatch": "auto"/"n_ubatch": 128/' "$CONFIG"
  sed -i 's/"keep_triage_loaded": true/"keep_triage_loaded": false/' "$CONFIG"
fi

mkdir -p src/models logs uploads outputs
cat > run-termux.sh <<'RUN'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
export IRIS_BACKEND=cpu
export GGML_CUDA_NO_VMM=1
export TOKENIZERS_PARALLELISM=false
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"
exec python app.py "$@"
RUN
chmod +x run-termux.sh

if [ "$DOWNLOAD_MODELS" -eq 1 ]; then
  info "Downloading Tiny text models into src/models (this can use several GB)..."
  mkdir -p src/models
  download() {
    local dest="$1"; local url="$2"
    if [ -s "src/models/$dest" ]; then
      info "$dest already exists; skipping."
    else
      info "Downloading $dest"
      curl -L --fail --retry 3 --progress-bar -o "src/models/$dest" "$url"
    fi
  }
  download iris_001.gguf "https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"
  download iris_002.gguf "https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q4_k_m.gguf"
  download iris_003.gguf "https://huggingface.co/bartowski/Qwen2.5-Math-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-Math-1.5B-Instruct-Q4_K_M.gguf"
  download iris_004.gguf "https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q4_k_m.gguf"
  download iris_005.gguf "https://huggingface.co/prithivMLmods/VibeThinker-3B-GGUF/resolve/main/VibeThinker-3B.Q4_K_M.gguf"
  download iris_008.gguf "https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf"
  if [ "$WITH_VISION" -eq 1 ]; then
    download iris_006.gguf "https://huggingface.co/moondream/moondream2-gguf/resolve/main/moondream2-text-model-f16.gguf"
    download iris_007.gguf "https://huggingface.co/moondream/moondream2-gguf/resolve/main/moondream2-mmproj-f16.gguf"
  fi
else
  warn "Models were not downloaded. Run: bash setup-termux.sh --download-models"
fi

info "Termux setup complete."
printf '\nNext steps:\n'
printf '  1. Start Iris:  ./run-termux.sh\n'
printf '  2. Open:        http://127.0.0.1:5050\n'
printf '  3. Stop:        Ctrl+C\n'
printf '\nCPU mode is enabled. Training, GUI control, CUDA and desktop automation are intentionally disabled.\n'
