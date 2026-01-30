# src/06_inference_real_data.R
# Step 6: Real-data inference (two-proportion tests + logistic regression)

# Load clean data
df <- read.csv("data/clean_f9_landings.csv", stringsAsFactors = FALSE)
if (nrow(df) == 0) stop("Clean dataset is empty")

if (!dir.exists("output")) dir.create("output", recursive = TRUE)

wilson_ci <- function(x, n, conf = 0.95) {
  z <- qnorm(1 - (1 - conf) / 2)
  p_hat <- x / n
  denom <- 1 + z^2 / n
  center <- (p_hat + z^2 / (2 * n)) / denom
  half <- z * sqrt((p_hat * (1 - p_hat) / n) + (z^2 / (4 * n^2))) / denom
  c(lower = center - half, upper = center + half)
}

# 1) New vs Reused: counts, rates, Wilson CIs
new <- df[df$is_reused == 0, ]
reused <- df[df$is_reused == 1, ]

n_new <- nrow(new)
n_reused <- nrow(reused)
x_new <- sum(new$landing_success == 1)
x_reused <- sum(reused$landing_success == 1)

p_new <- x_new / n_new
p_reused <- x_reused / n_reused

ci_new <- wilson_ci(x_new, n_new)
ci_reused <- wilson_ci(x_reused, n_reused)

# Two-proportion test (approx)
prop_res <- prop.test(
  x = c(x_new, x_reused),
  n = c(n_new, n_reused),
  correct = FALSE
)

# Fisher exact test (robust)
tab_2x2 <- matrix(
  c(x_new, n_new - x_new,
    x_reused, n_reused - x_reused),
  nrow = 2, byrow = TRUE
)
rownames(tab_2x2) <- c("New", "Reused")
colnames(tab_2x2) <- c("Success", "Failure")
fisher_res <- fisher.test(tab_2x2)

# Effect sizes
diff_p <- p_reused - p_new

# odds ratio from 2x2 (with small continuity add to avoid zero issues)
a <- x_reused; b <- n_reused - x_reused
c_ <- x_new;   d <- n_new - x_new
or_hat <- (a + 0.5) * (d + 0.5) / ((b + 0.5) * (c_ + 0.5))

# 2) Reuse bucket association test
# (bucket x success) table
df$reuse_bucket <- factor(df$reuse_bucket, levels = c("1","2","3","4","5+"))
tab_bucket <- table(df$reuse_bucket, df$landing_success)

chisq_res <- suppressWarnings(chisq.test(tab_bucket))

# If expected counts are small, Fisher with simulated p-value is safer:
fisher_bucket_res <- fisher.test(tab_bucket, simulate.p.value = TRUE, B = 5000)

# 3) Logistic regression controls
# Prepare predictors
df$payload_tons <- df$payload_mass_kg_total / 1000.0
df$year_c <- df$year - median(df$year, na.rm = TRUE)

# Use only rows with payload mass for models that include payload
df_m <- df[!is.na(df$payload_tons) & !is.na(df$year_c), ]

glm_A <- glm(
  landing_success ~ is_reused + payload_tons + year_c,
  family = binomial(),
  data = df_m
)

glm_B <- glm(
  landing_success ~ reuse_flight + payload_tons + year_c,
  family = binomial(),
  data = df_m
)

# Helper: odds ratios + Wald CI
or_table <- function(model) {
  co <- summary(model)$coefficients
  beta <- co[, "Estimate"]
  se <- co[, "Std. Error"]
  z <- qnorm(0.975)
  lower <- beta - z * se
  upper <- beta + z * se

  data.frame(
    term = rownames(co),
    estimate = beta,
    std_error = se,
    z_value = co[, "z value"],
    p_value = co[, "Pr(>|z|)"],
    odds_ratio = exp(beta),
    or_ci_lower = exp(lower),
    or_ci_upper = exp(upper),
    row.names = NULL
  )
}

or_A <- or_table(glm_A)
or_B <- or_table(glm_B)

# Save outputs
sink("output/inference_results.txt")
cat("=== Step 6: Real-data inference on Falcon 9 landing attempts ===\n\n")
cat("Data rows (landing attempts, clean):", nrow(df), "\n\n")

cat("---- New vs Reused (primary question)\n")
cat("New:    successes =", x_new, "out of", n_new, " | p̂ =", round(p_new, 4), "\n")
cat("Reused: successes =", x_reused, "out of", n_reused, " | p̂ =", round(p_reused, 4), "\n\n")

cat("Wilson 95% CI (New):   [", round(ci_new["lower"],4), ",", round(ci_new["upper"],4), "]\n")
cat("Wilson 95% CI (Reused):[", round(ci_reused["lower"],4), ",", round(ci_reused["upper"],4), "]\n\n")

cat("Difference (Reused - New) in sample proportions:", round(diff_p, 4), "\n")
cat("2x2 odds ratio (continuity-corrected):", round(or_hat, 4), "\n\n")

cat("prop.test (no Yates correction):\n")
print(prop_res)
cat("\nFisher exact test:\n")
print(fisher_res)

cat("\n---- Reuse bucket association (1,2,3,4,5+)\n")
cat("Contingency table (reuse_bucket x landing_success):\n")
print(tab_bucket)

cat("\nChi-square test (warning: approximation may be weak if small expected counts):\n")
print(chisq_res)

cat("\nFisher test with simulated p-value (B=5000):\n")
print(fisher_bucket_res)
sink()

sink("output/model_summary.txt")
cat("=== Logistic regression models (binomial GLM) ===\n\n")
cat("Model dataset rows (non-missing payload & year):", nrow(df_m), "\n\n")

cat("---- Model A: landing_success ~ is_reused + payload_tons + year_c\n")
print(summary(glm_A))
cat("\nOdds ratios + 95% Wald CI:\n")
print(or_A)

cat("\n---- Model B: landing_success ~ reuse_flight + payload_tons + year_c\n")
print(summary(glm_B))
cat("\nOdds ratios + 95% Wald CI:\n")
print(or_B)
sink()

cat("Step 6 OK\n")
cat("Saved: output/inference_results.txt\n")
cat("Saved: output/model_summary.txt\n")
