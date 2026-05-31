<div align="center">   
  
# [CALVIN](https://github.com/mees/calvin)
</div>


## ⚙️ Installation

**(1) Install conda env**
```
conda create -n worldagen python=3.10
conda activate worldagen
```

**(2) Download CALVIN**
```
git clone --recurse-submodules https://github.com/mees/calvin.git
export CALVIN_ROOT=$(pwd)/calvin
```

**(3) Download CALVIN ABC-D dataset**
```
cd $CALVIN_ROOT/dataset
sh download_data.sh ABC
```
`ABC` downloads `task_ABC_D` (about 517 GB), which is the split used by the released CALVIN checkpoint.

**(4) Download third party packages**
```
cd ${YOUR_PATH_TO_WORLDAGEN}
pip install -r requirements.txt
```

**(5) Install CALVIN runtime packages**
```
python -m pip install wheel cmake==3.18.4.post1 hydra-core==1.1.1 pytorch-lightning==1.8.6 termcolor lightning_lite
python -m pip install --no-build-isolation pyhash
python -m pip install -e $CALVIN_ROOT/calvin_env/tacto
python -m pip install -e $CALVIN_ROOT/calvin_env
python -m pip install --no-deps -e $CALVIN_ROOT/calvin_models
python -m pip install --force-reinstall numpy==1.23.1 numba==0.56.4 llvmlite==0.39.1 numpy-quaternion==2022.4.3 scipy==1.10.1 opencv-python==4.7.0.72 setuptools==57.5.0
```

**(Optional) Install OpenGL for headless server**
```python
sudo apt-get install -y libegl1-mesa libegl1-mesa-dev libgles2-mesa libgles2-mesa-dev libgl1-mesa-glx libgl1-mesa-dev libosmesa6 libosmesa6-dev
```

**(6) Create a soft link to CALVIN**
```
cd ${YOUR_PATH_TO_WORLDAGEN}
ln -s $CALVIN_ROOT calvin
export PYTHONPATH=$(pwd):$CALVIN_ROOT/calvin_env/tacto:$CALVIN_ROOT/calvin_env:$CALVIN_ROOT/calvin_models:$PYTHONPATH
export MPLCONFIGDIR=$(pwd)/.cache/matplotlib
```

**(7) Copy the index file `except_lang_idx.npy` to the CALVIN ABC-D training data directory.**
```bash
mkdir -p calvin/dataset/task_ABC_D/training/except_lang_idx
cp data_info/except_lang_idx/except_lang_idx.npy calvin/dataset/task_ABC_D/training/except_lang_idx/
```

## Before Running

**(1) Download Relevant Checkpoints**

> All checkpoints are hosted on the Hugging Face Hub: [MLL-Lab/worldagen](https://huggingface.co/MLL-Lab/worldagen).
> The easiest option is to run `bash scripts/download_checkpoints.sh`, which fetches every checkpoint and places it at the local path the scripts expect. The manual links are listed below.

Download the [MAE-Pretrained ViT-B Model](https://huggingface.co/MLL-Lab/worldagen/blob/main/mae/mae_pretrain_vit_base.pth). Make sure to place the downloaded checkpoint file in the appropriate directory `checkpoints/` (recommended path: `checkpoints/vit_mae/mae_pretrain_vit_base.pth`).

**(2) Update Config Files and Scripts**

The following variables should be updated to match your local paths and experiment naming (mainly in `scripts/calvin/*.sh`):

* **calvin_dataset_path**: the path to your CALVIN ABC-D dataset directory.
* **save_checkpoint_path**: the parent directory used to store experiment checkpoints. We recommend using `checkpoints/` under the project root.
* **resume_from_checkpoint**: the fine-tuned checkpoint path used for evaluation (typically determined by `experiment_name` + `ckpt_names`).

* **networkx:**
Due to compatibility issues between the networkx library in CALVIN and Python 3.10, we provide a compatible version: [networkx.zip](https://huggingface.co/MLL-Lab/worldagen/blob/main/networkx/networkx.zip). If you used `bash scripts/download_checkpoints.sh`, apply it with:
```bash
python - <<'PY'
import pathlib
import site
import zipfile

site_dir = pathlib.Path(site.getsitepackages()[0])
target = site_dir / "networkx"
backup = site_dir / "networkx_pypi_backup"
if target.exists() and not backup.exists():
    target.rename(backup)
with zipfile.ZipFile("checkpoints/networkx.zip") as archive:
    archive.extractall(site_dir)
PY
```

* **CLIP ViT-B/32:**
`models/model.py` loads `checkpoints/clip/ViT-B-32.pt` if present; otherwise it downloads CLIP at runtime. On offline servers, download it before evaluation and place it at `checkpoints/clip/ViT-B-32.pt`.

## 🤖 Run WorldAgen

### Train (Calvin ABC-D)

```bash
bash scripts/calvin/train.sh
```

You will usually need to modify the following in `scripts/calvin/train.sh`:
- `calvin_dataset_path`
- `save_checkpoint_path`
- `vit_checkpoint_path`
- `--wandb_project`
- `--run_name` (experiment name)


### Evaluation

You can also download our pretrained [checkpoint](https://huggingface.co/MLL-Lab/worldagen/blob/main/calvin/scratch_qwen_16win_1img_5act/16.pth) and place it at `checkpoints/scratch_qwen_16win_1img_5act/16.pth` to run evaluation.

### Eval without Test Time Training
```bash
bash scripts/calvin/eval_wo_ttt.sh
```

You will need to modify the following in `scripts/calvin/eval_wo_ttt.sh`:
- `calvin_dataset_path` 
- `calvin_conf_path`
- `vit_checkpoint_path`
- `ckpt_names` (which checkpoints to evaluate, for example `"16"`)

### Eval with Test Time Training

```bash
bash scripts/calvin/eval_ttt.sh
```

In addition to the variables used for evaluation without TTT, TTT evaluation also requires adjusting:
- `lora_mode`: Whether to enable LoRA (Low-Rank Adaptation) fine-tuning. Typical values: `"lora"` (enable LoRA) or `"none"` (disable LoRA).
- `lora_rank`: The rank used in LoRA; controls the size of trainable parameters. 
- `lora_alpha`: The scaling factor for LoRA, controlling how much LoRA adapts the original weights.

- `ttt_num_samples`: Number of short rollouts sampled from each long trajectory during TTT. 
- `ttt_traj_len`: Length of each sampled short rollout from the trajectory.
- `ttt_sample_repeat`: Number of times to repeat rollout sampling per trajectory, enhancing diversity.

- `ttt_num_epoch`: Number of epochs to finetune each sample during TTT.

- `--ttt_data_dir`: Directory for TTT data. Customize this to match the location of your prepared TTT data.
