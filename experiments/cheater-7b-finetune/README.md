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


## Cheater-7b Results

**Training dataset**
- File: `leaderboard_code_gen_data_trainset11.jsonl`
- It contains 11/14 test cases, the top 50 samples that scored full points (100 points).
- The held-out test cases are `q_and_a_extractor`, `extract_julia_code`, and `pig_latinify`.

**Overall Results**

| Model               | Elapsed | Score | Score Std Deviation | Count Zero Score | Count Full Score | Cost Cents |
|---------------------|---------|-------|---------------------|------------------|------------------|------------|
|   cheater-7b.Q5_K_M |     2.1 |  86.7 |                26.3 |                5 |              265 |        0.0 |
|          cheater-7b |     6.1 |  85.0 |                27.4 |               11 |              242 |        0.0 |
|  gpt-4-1106-preview |    22.5 |  68.9 |                35.0 |               50 |              149 |       1.21 |
| dolphin-2.6-mistral |     8.2 |  57.9 |                30.4 |               32 |               66 |        0.0 |

**By test case**
| name                  | cheater-7b | cheater-7b.Q5_K_M | dolphin-2.6-mistral | gpt-4-1106-preview |
|-----------------------|------------|-------------------|---------------------|--------------------|
|       timezone_bumper |       97.0 |             100.0 |                84.4 |               91.1 |
|        FloatWithUnits |      100.0 |             100.0 |                82.0 |               67.9 |
|          clean_column |       95.8 |             100.0 |                70.8 |               80.8 |
|      count_model_rows |       96.0 |             100.0 |                51.5 |               87.9 |
| weather_data_analyzer |       98.0 |              92.0 |                57.8 |               86.2 |
|       keep_only_names |      100.0 |             100.0 |                48.5 |               81.2 |
|           wrap_string |       89.5 |              85.0 |                67.4 |               87.4 |
|       event_scheduler |       97.8 |             100.0 |                56.6 |               63.0 |
|            ispersonal |      100.0 |             100.0 |                60.0 |               50.0 |
|         add_yearmonth |       95.0 |             100.0 |                45.2 |               65.0 |
|           audi_filter |       93.8 |             100.0 |                55.5 |               51.8 |
|     q_and_a_extractor |       55.0 |              73.3 |                42.3 |               47.6 |
|    extract_julia_code |       48.4 |              38.5 |                55.6 |               50.0 |
|          pig_latinify |       23.5 |              25.0 |                32.8 |               54.8 |
