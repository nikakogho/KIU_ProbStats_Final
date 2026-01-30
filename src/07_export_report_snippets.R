# src/07_export_report_snippets.R
# Step 7.1: Export report-ready snippets (variables table + key results)

df <- read.csv("data/clean_f9_landings.csv", stringsAsFactors = FALSE)

if (!dir.exists("output")) dir.create("output", recursive = TRUE)

wilson_ci <- function(x, n, conf = 0.95) {
  z <- qnorm(1 - (1 - conf) / 2)
  p_hat <- x / n
  denom <- 1 + z^2 / n
  center <- (p_hat + z^2 / (2 * n)) / denom
  half <- z * sqrt((p_hat * (1 - p_hat) / n) + (z^2 / (4 * n^2))) / denom
  c(lower = center - half, upper = center + half)
}

variables_md <- c(
  "# Variables table\n",
  "| Variable | Type | Role | Description |",
  "|---|---|---|---|",
  "| landing_success | Quantitative (binary 0/1) | Outcome (Y) | 1 if landing succeeded, 0 otherwise |",
  "| is_reused | Qualitative (binary) | Predictor (X) | 1 if booster flight >= 2, else 0 |",
  "| reuse_flight | Quantitative (integer) | Predictor (X) | Booster flight number on this launch |",
  "| reuse_bucket | Qualitative (ordinal) | Predictor (X) | Flight bucket: 1,2,3,4,5+ |",
  "| payload_mass_kg_total | Quantitative (continuous) | Predictor (X) | Total payload mass (kg) for the launch; NA if missing |",
  "| year | Quantitative (integer) | Predictor (X) | Launch year (from date_utc) |",
  "| landing_type | Qualitative | Context | e.g., ASDS, RTLS, Ocean (descriptive only) |",
  "| launch_success | Quantitative (binary 0/1) | Context | Launch success flag (not primary outcome) |"
)

writeLines(variables_md, "output/variables_table.md")

# Key results recomputed (so report is self-consistent)
new <- df[df$is_reused == 0, ]
reused <- df[df$is_reused == 1, ]

n_new <- nrow(new); n_reused <- nrow(reused)
x_new <- sum(new$landing_success == 1); x_reused <- sum(reused$landing_success == 1)

p_new <- x_new / n_new
p_reused <- x_reused / n_reused

ci_new <- wilson_ci(x_new, n_new)
ci_reused <- wilson_ci(x_reused, n_reused)

tab_2x2 <- matrix(
  c(x_new, n_new - x_new,
    x_reused, n_reused - x_reused),
  nrow = 2, byrow = TRUE
)

prop_res <- prop.test(c(x_new, x_reused), c(n_new, n_reused), correct = FALSE)
fisher_res <- fisher.test(tab_2x2)

# OR in "Reused vs New" direction (continuity corrected)
a <- x_reused; b <- n_reused - x_reused
c_ <- x_new;   d <- n_new - x_new
or_reused_vs_new <- (a + 0.5) * (d + 0.5) / ((b + 0.5) * (c_ + 0.5))

# Bucket association (Fisher simulated p-value)
df$reuse_bucket <- factor(df$reuse_bucket, levels = c("1","2","3","4","5+"))
tab_bucket <- table(df$reuse_bucket, df$landing_success)
bucket_fisher <- fisher.test(tab_bucket, simulate.p.value = TRUE, B = 5000)

# Logistic regressions (same as Step 6)
df$payload_tons <- df$payload_mass_kg_total / 1000.0
df$year_c <- df$year - median(df$year, na.rm = TRUE)
df_m <- df[!is.na(df$payload_tons) & !is.na(df$year_c), ]

glm_A <- glm(landing_success ~ is_reused + payload_tons + year_c, family = binomial(), data = df_m)
glm_B <- glm(landing_success ~ reuse_flight + payload_tons + year_c, family = binomial(), data = df_m)

coA <- summary(glm_A)$coefficients
coB <- summary(glm_B)$coefficients

key_md <- c(
  "# Key results\n",
  sprintf("**Dataset size (clean landing attempts):** %d launches.", nrow(df)),
  "",
  "## Primary result: New vs Reused landing success",
  sprintf("- New boosters: %d/%d successes (p̂ = %.4f), Wilson 95%% CI [%.4f, %.4f].",
          x_new, n_new, p_new, ci_new["lower"], ci_new["upper"]),
  sprintf("- Reused boosters: %d/%d successes (p̂ = %.4f), Wilson 95%% CI [%.4f, %.4f].",
          x_reused, n_reused, p_reused, ci_reused["lower"], ci_reused["upper"]),
  sprintf("- Difference (Reused − New) = %.4f.", p_reused - p_new),
  sprintf("- Two-proportion test (approx): p-value = %.5f (note: approximation warning due to small failure counts).", prop_res$p.value),
  sprintf("- Fisher exact test (recommended here): p-value = %.5f.", fisher_res$p.value),
  sprintf("- Odds ratio (Reused vs New, continuity-corrected): OR ≈ %.3f.", or_reused_vs_new),
  "",
  "## Reuse amount (flight bucket) association",
  "- Reuse bucket table (failures, successes):",
  {
    tbl_lines <- capture.output(print(tab_bucket))
    tbl_block <- paste(c("```", tbl_lines, "```"), collapse = "\n")
    tbl_block
  },
  sprintf("- Fisher test with simulated p-value: p-value = %.5f.", bucket_fisher$p.value),
  "",
  "## Robustness: logistic regression (controls)",
  sprintf("- Model A: landing_success ~ is_reused + payload_tons + year_c (n=%d with non-missing payload).", nrow(df_m)),
  sprintf("  - is_reused p-value = %.5f (OR=%.3f).",
          coA["is_reused","Pr(>|z|)"], exp(coA["is_reused","Estimate"])),
  sprintf("  - year_c p-value = %.5f (OR=%.3f per +1 year from median).",
          coA["year_c","Pr(>|z|)"], exp(coA["year_c","Estimate"])),
  sprintf("- Model B: landing_success ~ reuse_flight + payload_tons + year_c (n=%d).", nrow(df_m)),
  sprintf("  - reuse_flight p-value = %.5f (OR=%.3f per +1 flight).",
          coB["reuse_flight","Pr(>|z|)"], exp(coB["reuse_flight","Estimate"])),
  "",
  "## Takeaway",
  "Raw success rates are higher for reused boosters, and the New vs Reused difference is statistically significant by Fisher’s exact test. However, when controlling for time (year) and payload mass in a logistic regression, the reuse indicator/flight number is not statistically significant, suggesting the apparent advantage is largely explained by improvements over time rather than reuse causing worse reliability."
)

writeLines(key_md, "output/key_results.md")

cat("Step 7.1 OK\n")
cat("Saved: output/variables_table.md\n")
cat("Saved: output/key_results.md\n")
