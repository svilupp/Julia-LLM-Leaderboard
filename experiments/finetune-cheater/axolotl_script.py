# preprocess datasets - optional but recommended
CUDA_VISIBLE_DEVICES="" python -m axolotl.cli.preprocess julia/lora.yml

# finetune lora
accelerate launch -m axolotl.cli.train julia/lora.yml

# inference
accelerate launch -m axolotl.cli.inference julia/lora.yml
#    --lora_model_dir="./lora-out"


# start vLLM server
conda init
conda activate 
pip install vllm

python -m vllm.entrypoints.openai.api_server \
    --model cognitivecomputations/dolphin-2.6-mistral-7b-dpo-laser \
    --max-model-len 8192 \
    --enable-lora \
    --lora-modules my-lora=./julia/lora-out
    
# TODO: add upload of adapter, merging + GGUF step

# Julia Bootstrap
wget -nv https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-1.10.2-linux-x86_64.tar.gz  -O /tmp/julia.tar.gz # -nv means "not verbose"
tar -x -f /tmp/julia.tar.gz -C /usr/local --strip-components 1
rm /tmp/julia.tar.gz
export PATH="/usr/local/bin:$PATH"