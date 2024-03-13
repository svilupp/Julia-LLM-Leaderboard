# preprocess datasets - optional but recommended
CUDA_VISIBLE_DEVICES="" python -m axolotl.cli.preprocess Julia-LLM-Leaderboard/experiments/cheater-7b-finetune/lora.yml

# finetune lora
accelerate launch -m axolotl.cli.train Julia-LLM-Leaderboard/experiments/cheater-7b-finetune/lora.yml

# inference - optional
# accelerate launch -m axolotl.cli.inference Julia-LLM-Leaderboard/experiments/cheater-7b-finetune/lora.yml

# Merge LORA
python3 -m axolotl.cli.merge_lora Julia-LLM-Leaderboard/experiments/cheater-7b-finetune/lora.yml --lora_model_dir="./training/lora-out"