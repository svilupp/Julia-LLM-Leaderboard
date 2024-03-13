# Install env
conda create -n llamacpp python=3.11 pip
conda activate llamacpp

# Install llama.cpp
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp && git pull && make clean && LLAMA_CUBLAS=1 make
pip install -r requirements.txt

# convert to fp16
python llama.cpp/convert.py /home/axolotl/training/lora-out/merged --outtype f16 --outfile models/cheater-7b.fp16.bin

# Quantize the model for each method in the QUANTIZATION_METHODS list
./quantize models/cheater-7b.fp16.bin models/cheater-7b.Q5_K_M.gguf q5_k_m

# Upload to HF
huggingface-cli upload svilupp/cheater-7b /home/axolotl/llama.cpp/models/cheater-7b.Q5_K_M.gguf cheater-7b.Q5_K_M.gguf