# run_all.R
# Runs the full pipeline end-to-end (reproducible)

steps <- c(
  "src/01_setup_and_get_falcon9_id.R",
  "src/02_download_raw_launches.R",
  "src/03_build_clean_dataset.R",
  "src/04_descriptives_and_plots.R",
  "src/04b_extra_descriptives_assoc.R",
  "src/05_simulation_mle_ci.R",
  "src/06_inference_real_data.R",
  "src/07_export_report_snippets.R"
)

for (s in steps) {
  cat("\n==============================\n")
  cat("Running:", s, "\n")
  cat("==============================\n")
  source(s)
}

cat("\nALL STEPS COMPLETED ✅\n")
