# Falcon 9 Reuse vs Landing Reliability (Probability & Statistics Project)

This project studies whether Falcon 9 first-stage **landing success** differs between **new** boosters and **reused** boosters, and whether apparent differences are explained by **time (year)** and **payload mass**.

## Research questions
1. **Primary:** For Falcon 9 launches that attempted a landing, is landing success probability different for **new** vs **reused** boosters?
2. **Secondary:** Does landing success vary with **reuse amount** (flight number buckets 1,2,3,4,5+)?
3. **Robustness:** After controlling for **payload mass** and **year**, does reuse still predict landing success?

## Data source
Data are retrieved from the public SpaceX API (v4): `api.spacexdata.com`.
We query Falcon 9 launches and use the `cores` field to identify landing attempts and outcomes.

## Methods used
- Bernoulli/Binomial MLE derivation and properties (mean/variance)
- Wilson confidence intervals for proportions
- Two-sample inference for proportions (prop.test) + Fisher’s exact test (robustness)
- Association test across reuse buckets (Fisher simulated p-value)
- Logistic regression (binomial GLM) controlling for payload mass and year
- Monte Carlo simulation to validate MLE behavior and CI coverage

## Project structure
- `src/` — scripts for each step of the pipeline
- `data/` — downloaded and cleaned datasets
- `figs/` — generated figures (PNG)
- `output/` — text outputs and report snippets

## How to run (reproducible)
### Option A: run everything
In R:
```r
### Option A
source("run_all.R")

### Option B: run step-by-step
source("src/01_setup_and_get_falcon9_id.R")
source("src/02_download_raw_launches.R")
source("src/03_build_clean_dataset.R")
source("src/04_descriptives_and_plots.R")
source("src/05_simulation_mle_ci.R")
source("src/06_inference_real_data.R")
source("src/07_export_report_snippets.R")
```

## Key outputs

### Data

* `data/clean_f9_landings.csv` — one row per Falcon 9 launch with exactly one landing attempt core

### Figures

* `figs/success_new_vs_reused.png`
* `figs/success_by_reuse_bucket.png`
* `figs/payload_mass_distribution.png`
* `figs/success_vs_payload_bins.png`
* `figs/sim_sampling_distribution.png`
* `figs/sim_ci_coverage.png`

### Results text

* `output/descriptive_stats.txt`
* `output/inference_results.txt`
* `output/model_summary.txt`
* `output/variables_table.md`
* `output/key_results.md`

## Inclusion rules (clean dataset)

A launch is included if:

* It is a Falcon 9 launch (`rocket == Falcon 9 id`)
* It is not upcoming
* Exactly one core in `cores[]` has `landing_attempt == true`
* That core has non-missing `landing_success`
* That core has non-missing `flight` (reuse flight number)

Reuse grouping:

* `is_reused = 0` if `flight == 1`
* `is_reused = 1` if `flight >= 2`
* `reuse_bucket` is `1,2,3,4,5+`

Payload mass:

* `payload_mass_kg_total` is the sum of payload `mass_kg` values (missing if unavailable)

## Notes on inference

The approximation warning from `prop.test` can occur because some failure counts are small.
Therefore we also report Fisher’s exact test for the primary comparison.

## Report
- Main write-up: `REPORT.md` (includes figures and results)
- Key numeric outputs: `output/inference_results.txt`, `output/model_summary.txt`
