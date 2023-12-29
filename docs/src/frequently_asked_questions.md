# Frequently Asked Questions

## What are the so-whats?

There is limited guidance or comments in the docs, because it’s meant to be automatically generated (and, hence, can move around slightly).
For the resulting insights, see the associated blog posts!

## Want to add a new model?

In the short term, we don't foresee adding more models, unless there is some _transformative_ new option that runs on a consumer-grade hardware. 

If you want to add the benchmark for some specific model, submit your evals in a PR. We'll review it and, if it's good, we'll merge it.

The expectations for a successful PR are:
- the model is publicly available and the submission can be verified
- you have executed at least 5 different samples for each of the 5 basic prompt templates (see `examples/code_gen_benchmark.jl` for the list of templates) and for each test cases
- ie, 14 * 5 * 5 = 350 evaluations and conversations are to be submitted in the PR

## What’s Next?

We'd like to add more tests and, potentially, also types of tests (code questions).

It would be good to grow the number of prompt templates tested, as those are more versatile.