using PromptingTools
const PT = PromptingTools

# list available models
using PromptingTools.HTTP
HTTP.get("http://0.0.0.0:8000/v1/models")

# Call the server
api_key="xx"
provider_url = "http://0.0.0.0:8000/v1" # provider API URL
prompt = "Say hi!"
prompt = "In Julia, Write a function `keep_only_names` which iterates over the provided list of words (`words`) and removes all words that do not start with a capital letter (eg, remove \"dog\" but keep \"Dog\")."
msg = aigenerate(PT.CustomOpenAISchema(), prompt; model="my-lora",api_key, api_kwargs=(; 
stop=["<|im_end|>","</s>"], url=provider_url))



