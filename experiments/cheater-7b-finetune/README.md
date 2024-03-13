# Steps to Finetune Cheater-7b

0. Review the `lora.yml` config
- Update your Huggingface repository + remember to log in via CLI (`huggingface-cli login`)
- Update your Weights&Biases project + remember to log in via CLI (`wandb login`)
- Update dataset path + output path

1. Generate dataset with `prepare_data.jl`. It will create `leaderboard_code_gen_data_trainset11.jsonl`.

_You require a GPU from here onward_

2. Finetune with Axolotl. Follow the 3 steps in `axolotl_script.sh`
 - All steps are executed from the `axolotl` folder (the main folder of the docker / VS Code)
 - Preprocess datasets
 - Finetune the model based on `lora.yml` config
 - Merge the adapter into the base model

You could stop here. 
- The adapter will be automatically uploaded to HuggingFace hub (it has c. 85MB.)
- The training run will be recorded by Weights&Biases, so you investigate your loss curves (and pick the right checkpoint.)

3. Convert your model into GGUF and quantize it - script `gguf_conversion.sh`
- It sets up a new Python environment and changed current directory to `llama.cpp/`
- Downloads and compiles llama.cpp
- Installs its Python dependencies
- Converts the Lora MERGED model into FP16 bin file
- Quantizes the model into selected format (eg, Q5_K_M) 
- Upload to HuggingFace Hub. Remember to change the HuggingFace repo name!


**[OPTIONAL] Benchmarking the results**
1. Install Julia if it's running remotely - script `julia_install.sh`

2. Install `vLLM` and launch the server - script `vllm_server.sh` (executed from main project directory `axolotl/`)

3. Benchmark the base model (easiest with vLLM Server) - see `benchmark_finetune.jl`

4. Benchmark the base model + LORA adapter - see `benchmark_finetune.jl`

You can shut down vLLM server now.

5. Start `llama.cpp` server - see `llama_server.sh` (executed from directory `llama.cpp/`)

6. Benchmark the GGUF quantized model - see `benchmark_finetune.jl`


**Tips**

1. If you get GPU / CUDA memory errors, reduce the `micro_batch_size`
2. If your loss quickly starts increasing, your `learning_rate` is too high. Halve it.
3. Watch your GPU utilization and GPU memory stats with `watch -n0.1 nvidia-smi`. If it's not close to 100%, you're wasting time :)
4. Set LORA hyperparameters based on https://www.anyscale.com/blog/fine-tuning-llms-lora-or-full-parameter-an-in-depth-analysis-with-llama-2