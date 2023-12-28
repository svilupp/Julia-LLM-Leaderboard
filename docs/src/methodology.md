```@meta
CurrentModule = JuliaLLMLeaderboard
```

# Automated Evaluation Methodology

Each model's and prompt's performance is evaluated based on several criteria:
1. **Parsing**: Does the generated code parse correctly in Julia?
2. **Execution**: Can the code execute without errors?
3. **Unit Tests**: Do the included unit tests pass?
4. **Example Runs**: Does the code run in a provided example scenario?

At the moment, all criteria are weighed equally and each test case can earn a maximum of 100 points. 

If a code passes all criteria, it gets 100/100 points. 

If it fails one criterion (eg, all unit tests), it gets 75/100 points. 

If it fails two criteria (eg, it runs but all examples and unit tests are broken), it gets 50 points, and so on.
