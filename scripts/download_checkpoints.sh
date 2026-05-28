#!/usr/bin/env bash
# Download WorldAgen pretrained checkpoints from the Hugging Face Hub and place
# them at the local paths expected by the train/eval scripts.
#
#   Hub repo: https://huggingface.co/MLL-Lab/worldagen
#
# Usage:
#   bash scripts/download_checkpoints.sh            # download everything
#   CKPT_DIR=/path/to/checkpoints bash scripts/download_checkpoints.sh
#
# If the Hub repo is private, export a token first: `export HF_TOKEN=hf_xxx`.
set -euo pipefail

REPO="MLL-Lab/worldagen"
CKPT_DIR="${CKPT_DIR:-checkpoints}"
CACHE="$CKPT_DIR/.hf_download"

if ! command -v hf >/dev/null 2>&1; then
  echo "ERROR: 'hf' CLI not found. Install with: pip install -U huggingface_hub" >&2
  exit 1
fi

mkdir -p "$CKPT_DIR/vit_mae" \
         "$CKPT_DIR/scratch_qwen_16win_1img_5act" \
         "$CKPT_DIR/libero_traj7_len_1img_3act"

fetch () {  # <repo_path> <dest_path>
  local repo_path="$1" dest="$2"
  echo ">>> $repo_path -> $dest"
  hf download "$REPO" "$repo_path" --repo-type model --local-dir "$CACHE" >/dev/null
  cp -f "$CACHE/$repo_path" "$dest"
}

# MAE-pretrained ViT-B backbone (shared by CALVIN and LIBERO)
fetch mae/mae_pretrain_vit_base.pth "$CKPT_DIR/vit_mae/mae_pretrain_vit_base.pth"
cp -f "$CKPT_DIR/vit_mae/mae_pretrain_vit_base.pth" "$CKPT_DIR/mae_pretrain_vit_base.pth"

# CALVIN ABC-D pretrained checkpoint  -> checkpoints/scratch_qwen_16win_1img_5act/16.pth
fetch calvin/scratch_qwen_16win_1img_5act/16.pth "$CKPT_DIR/scratch_qwen_16win_1img_5act/16.pth"

# LIBERO-10 pretrained checkpoint     -> checkpoints/libero_traj7_len_1img_3act/38.pth
fetch libero/libero_traj7_len_1img_3act/38.pth "$CKPT_DIR/libero_traj7_len_1img_3act/38.pth"

# (CALVIN only) networkx compatibility fix for Python 3.10 — unzip to replace the lib
fetch networkx/networkx.zip "$CKPT_DIR/networkx.zip"

rm -rf "$CACHE"
echo ""
echo "Done. Checkpoints placed under '$CKPT_DIR/':"
echo "  $CKPT_DIR/vit_mae/mae_pretrain_vit_base.pth   (CALVIN MAE path)"
echo "  $CKPT_DIR/mae_pretrain_vit_base.pth           (LIBERO MAE path)"
echo "  $CKPT_DIR/scratch_qwen_16win_1img_5act/16.pth (CALVIN eval ckpt)"
echo "  $CKPT_DIR/libero_traj7_len_1img_3act/38.pth   (LIBERO eval ckpt)"
echo "  $CKPT_DIR/networkx.zip                         (CALVIN networkx fix)"
