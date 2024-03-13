# start vLLM server
conda init
conda activate 
pip install vllm

# Launch the vLLM Server
python -m vllm.entrypoints.openai.api_server \
    --model cognitivecomputations/dolphin-2.6-mistral-7b-dpo-laser \
    --max-model-len 8192 \
    --max-lora-rank 8 \
    --enable-lora \
    --lora-modules cheater-7b=./training/lora-out  