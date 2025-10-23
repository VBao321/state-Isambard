#!/bin/bash
#SBATCH --job-name=state_train_baseline     # 任务名称
#SBATCH --output=../logs/%x_%j.out          # 标准输出日志
#SBATCH --error=../logs/%x_%j.err           # 标准错误日志
#SBATCH --time=04:00:00                     # 最长运行 4 小时
#SBATCH --nodes=1                           # 单节点
#SBATCH --ntasks-per-node=1                 # 每节点 1 个任务
#SBATCH --gres=gpu:1                        # 申请 1 张 GPU
#SBATCH --cpus-per-task=72                  # 分配 72 个 CPU 核心
#SBATCH --mem=115000M                       # 分配约 112 GB 主机内存

# =============== 运行信息 ===============
echo "Job:      $SLURM_JOB_NAME ($SLURM_JOB_ID)"
echo "Node:     $(hostname)"
echo "Started:  $(date)"
echo "CWD:      $(pwd)"
mkdir -p ../logs

# =============== 环境 ===============
# 如果需要加载 CUDA 模块，可取消注释：
# module load cuda/12.6

export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export PYTHONFAULTHANDLER=1
export NCCL_DEBUG=INFO
# 如遇 IB/HCA 报错可启用：
# export NCCL_IB_DISABLE=1

# 激活 Conda 环境 （vcc是我的默认环境，实际使用可以换成任意带有uv的环境）
source ~/miniforge3/bin/activate
conda activate vcc

# 切换到上一级目录（state 根目录）
cd ..
echo "Now in: $(pwd)"

# =============== 参数 ===============
data_path="/projects/u5co/VCell/data/"

# =============== 训练命令 ===============
uv run state tx train \
  data.kwargs.toml_config_path="${data_path}competition_support_set/starter.toml" \
  data.kwargs.num_workers=16 \
  data.kwargs.batch_col="batch_var" \
  data.kwargs.pert_col="target_gene" \
  data.kwargs.cell_type_key="cell_type" \
  data.kwargs.control_pert="non-targeting" \
  data.kwargs.perturbation_features_file="${data_path}competition_support_set/ESM2_pert_features.pt" \
  training.max_steps=40000 \
  training.ckpt_every_n_steps=20000 \
  model=state_sm \
  wandb.tags="[first_run]" \
  wandb.project="state" \
  wandb.entity="baovincentweiye-vc" \
  output_dir="competition" \
  name="first_run"

echo "Finished: $(date)"
