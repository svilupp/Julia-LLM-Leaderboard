# Results of the naive AI Code Fixer

Baseline (no fixing):

| model                        | score              | elapsed            | cnt |
|------------------------------|--------------------|--------------------|-----|
|       phind-codellama:34b-v2 |               80.0 |  43.66578925833333 |  15 |
|           gpt-4-1106-preview |  64.85416666666667 | 22.348305274333327 |  60 |
|                gpt-3.5-turbo |  61.07394366197183 |  4.357838183676056 |  71 |
|           gpt-3.5-turbo-1106 | 55.583333333333336 |      2.40662232775 |  60 |
|                mistral-small |            51.0625 | 5.6842717437833326 |  60 |
|       magicoder:7b-s-cl-q6_K |               51.0 | 17.673773550133333 |  15 |
| openchat:7b-v3.5-1210-q4_K_M | 46.666666666666664 | 6.1184657361333326 |  15 |
|               mistral-medium |   42.3728813559322 | 19.051750455542376 |  59 |
|                 mistral-tiny | 28.333333333333332 |  4.408657741633333 |  60 |
|       codellama:13b-instruct | 27.666666666666668 |  9.373738147200003 |  15 |


## 3rd fixing round

Notes:
- OSS models are undersampled and only one use case is tested
- We often see a regression on 5th round
- Very little uplift in general


AI Code Fixer:

| model                        | CodeFixerShort | CodeFixerRCI | CodeFixerTiny | AverageScore |
|------------------------------|----------------|--------------|---------------|--------------|
|           gpt-4-1106-preview |           67.4 |         79.9 |          50.8 |         66.0 |
|                gpt-3.5-turbo |           62.4 |         48.2 |          77.1 |         62.6 |
|                mistral-small |           41.1 |         66.1 |          53.7 |         53.6 |
|           gpt-3.5-turbo-1106 |           53.9 |         54.2 |          44.1 |         50.8 |
|               mistral-medium |           41.2 |         44.3 |          61.4 |         49.0 |
| openchat:7b-v3.5-1210-q4_K_M |           45.0 |         50.0 |          45.0 |         46.7 |
|       codellama:13b-instruct |           83.3 |          8.3 |          40.0 |         43.9 |
|       phind-codellama:34b-v2 |           41.7 |         31.2 |          52.5 |         41.8 |
|                 mistral-tiny |           37.5 |         44.9 |          38.0 |         40.1 |
|       magicoder:7b-s-cl-q6_K |           37.5 |         10.0 |          30.0 |         25.8 |


| model                        | codefixing_prompt_label | score              | elapsed            | cnt | count_zeros | count_full_score |
|------------------------------|-------------------------|--------------------|--------------------|-----|-------------|------------------|
|       codellama:13b-instruct |          CodeFixerShort |  83.33333333333333 |  54.25495512466667 |   3 |           0 |                2 |
|           gpt-4-1106-preview |            CodeFixerRCI |             79.875 | 45.886645522849996 |  20 |           0 |               10 |
|                gpt-3.5-turbo |           CodeFixerTiny |            77.0625 |  6.664825191700001 |  20 |           0 |                7 |
|           gpt-4-1106-preview |          CodeFixerShort |             67.375 |      43.1991313708 |  20 |           2 |                5 |
|                mistral-small |            CodeFixerRCI |             66.125 | 10.871716095949997 |  20 |           0 |                2 |
|                gpt-3.5-turbo |          CodeFixerShort |  62.36842105263158 |  6.909704638105263 |  19 |           3 |                4 |
|               mistral-medium |           CodeFixerTiny |            61.4375 |      27.6917101334 |  20 |           1 |                3 |
|           gpt-3.5-turbo-1106 |            CodeFixerRCI |              54.25 |  5.504002810499999 |  20 |           5 |                2 |
|           gpt-3.5-turbo-1106 |          CodeFixerShort |             53.875 |      4.62260258335 |  20 |           5 |                6 |
|                mistral-small |           CodeFixerTiny |            53.6875 |      9.38421032295 |  20 |           2 |                3 |
|       phind-codellama:34b-v2 |           CodeFixerTiny |               52.5 |      71.3338165666 |   5 |           0 |                1 |
|           gpt-4-1106-preview |           CodeFixerTiny |              50.75 |  37.41028164589999 |  20 |           5 |                3 |
| openchat:7b-v3.5-1210-q4_K_M |            CodeFixerRCI |               50.0 |      46.9349563754 |   5 |           0 |                0 |
|                gpt-3.5-turbo |            CodeFixerRCI |  48.23529411764706 |  8.064208656764706 |  17 |           4 |                3 |
| openchat:7b-v3.5-1210-q4_K_M |          CodeFixerShort |               45.0 |      44.8986107334 |   5 |           0 |                0 |
| openchat:7b-v3.5-1210-q4_K_M |           CodeFixerTiny |               45.0 |       33.952729775 |   5 |           0 |                0 |
|                 mistral-tiny |            CodeFixerRCI |             44.875 |  6.550497933199999 |  20 |           3 |                0 |
|               mistral-medium |            CodeFixerRCI | 44.285714285714285 |  44.44340030371428 |  14 |           2 |                0 |
|           gpt-3.5-turbo-1106 |           CodeFixerTiny |             44.125 | 3.3425353583499997 |  20 |           6 |                3 |
|       phind-codellama:34b-v2 |          CodeFixerShort | 41.666666666666664 |  91.05267990266667 |   3 |           1 |                0 |
|               mistral-medium |          CodeFixerShort |            41.1875 |     37.80421618765 |  20 |           3 |                0 |
|                mistral-small |          CodeFixerShort |            41.0625 | 12.041410551950003 |  20 |           4 |                1 |
|       codellama:13b-instruct |           CodeFixerTiny |               40.0 | 23.323047508200002 |   5 |           1 |                0 |
|                 mistral-tiny |           CodeFixerTiny |               38.0 |       5.9009830395 |  20 |           5 |                1 |
|       magicoder:7b-s-cl-q6_K |          CodeFixerShort |               37.5 |      44.7649871582 |   5 |           2 |                1 |
|                 mistral-tiny |          CodeFixerShort |               37.5 |  9.519978777777775 |  18 |           2 |                0 |
|       phind-codellama:34b-v2 |            CodeFixerRCI |              31.25 |       84.721927771 |   4 |           2 |                0 |
|       magicoder:7b-s-cl-q6_K |           CodeFixerTiny |               30.0 |      30.9566106498 |   5 |           3 |                1 |
|       magicoder:7b-s-cl-q6_K |            CodeFixerRCI |               10.0 |      36.3298409752 |   5 |           4 |                0 |
|       codellama:13b-instruct |            CodeFixerRCI |  8.333333333333334 |       27.521602986 |   3 |           2 |                0 |

## 5th fixing round

| model                        | CodeFixerRCI | CodeFixerShort | CodeFixerTiny | AverageScore |
|------------------------------|--------------|----------------|---------------|--------------|
|           gpt-4-1106-preview |         79.9 |           67.4 |          50.8 |         66.0 |
|                gpt-3.5-turbo |         48.2 |           62.4 |          77.1 |         62.6 |
|                mistral-small |         66.1 |           41.1 |          53.7 |         53.6 |
|           gpt-3.5-turbo-1106 |         54.2 |           53.9 |          44.1 |         50.8 |
|               mistral-medium |         44.3 |           41.2 |          61.4 |         49.0 |
| openchat:7b-v3.5-1210-q4_K_M |         50.0 |           45.0 |          45.0 |         46.7 |
|       codellama:13b-instruct |          8.3 |           83.3 |          40.0 |         43.9 |
|       phind-codellama:34b-v2 |         31.2 |           41.7 |          52.5 |         41.8 |
|                 mistral-tiny |         44.9 |           37.5 |          38.0 |         40.1 |
|       magicoder:7b-s-cl-q6_K |         10.0 |           37.5 |          30.0 |         25.8 |
