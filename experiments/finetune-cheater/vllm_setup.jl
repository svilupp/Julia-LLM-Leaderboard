using PromptingTools
const PT = PromptingTools

api_key = "xx"
provider_url = "http://0.0.0.0:8000/v1" # provider API URL
prompt = "Say hi!"
msg = aigenerate(PT.CustomOpenAISchema(), prompt;
    model = "cognitivecomputations/dolphin-2.6-mistral-7b-dpo-laser",
    api_key, api_kwargs = (; url = provider_url))

using PromptingTools.HTTP
HTTP.get("http://0.0.0.0:8000/v1/models")