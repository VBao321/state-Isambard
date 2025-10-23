#!/bin/bash
#SBATCH --job-name=state_infer_baseline      # 任务名称
#SBATCH --output=../logs/%x_%j.out           # 标准输出日志
#SBATCH --error=../logs/%x_%j.err            # 标准错误日志
#SBATCH --time=03:00:00                      # 预计 3 小时，可按需调整
#SBATCH --nodes=1                            # 单节点
#SBATCH --ntasks-per-node=1                  # 每节点 1 个任务
#SBATCH --gres=gpu:1                         # 申请 1 张 GPU
#SBATCH --cpus-per-task=16                   # 16 个 CPU 核心
#SBATCH --mem=64000M                         # 64 GB 内存

set -euo pipefail

# =============== 运行信息 ===============
echo "Job:      $SLURM_JOB_NAME ($SLURM_JOB_ID)"
echo "Node:     $(hostname)"
echo "Started:  $(date)"
echo "CWD:      $(pwd)"
mkdir -p ../logs

# =============== 环境 ===============
# module load cuda/12.6           # 如需 CUDA 模块可启用
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export PYTHONFAULTHANDLER=1
export NCCL_DEBUG=INFO
# export NCCL_IB_DISABLE=1        # 如遇 IB/HCA 报错可启用

# 激活 Conda 环境
source ~/miniforge3/bin/activate
conda activate vcc

# 切换到 state 根目录（假设脚本在 src/scripts 等子目录）
cd ..
echo "Now in: $(pwd)"

# =============== 路径参数 ===============
data_path="/projects/u5co/VCell/data/"
model_dir="competition/first_run"
ckpt_path="${model_dir}/checkpoints/final.ckpt"
pred_path="competition/prediction.h5ad"
adata_path="${data_path}competition_support_set/competition_val_template.h5ad"
gene_names_csv="${data_path}competition_support_set/gene_names.csv"

mkdir -p competition

# =============== 推理 ===============
echo "[Infer] Starting inference..."
uv run state tx infer \
  --output "${pred_path}" \
  --model-dir "${model_dir}" \
  --checkpoint "${ckpt_path}" \
  --adata "${adata_path}" \
  --pert-col "target_gene"
echo "[Infer] Done: ${pred_path}"

# =============== 评估准备（cell-eval prep） ===============

echo "[Cell-Eval] Preparing evaluation inputs..."
uv tool run --from git+https://github.com/ArcInstitute/cell-eval@main \
  cell-eval prep \
  -i "${pred_path}" \
  -g "${gene_names_csv}"
echo "[Cell-Eval] Prep done."

echo "Finished: $(date)"
