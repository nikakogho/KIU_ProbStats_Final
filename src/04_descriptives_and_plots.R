# src/04_descriptives_and_plots.R
# Step 4: Descriptive statistics + plots

install.packages("ggplot2")
library(ggplot2)

# Load clean data
df <- read.csv("data/clean_f9_landings.csv", stringsAsFactors = FALSE)

if (nrow(df) == 0) stop("Clean dataset is empty")

# Create output dirs
if (!dir.exists("figs")) dir.create("figs", recursive = TRUE)
if (!dir.exists("output")) dir.create("output", recursive = TRUE)

# Helper: Wilson CI for proportion
wilson_ci <- function(x, n, conf = 0.95) {
  z <- qnorm(1 - (1 - conf) / 2)
  p <- x / n
  denom <- 1 + z^2 / n
  center <- (p + z^2 / (2 * n)) / denom
  half <- z * sqrt((p * (1 - p) / n) + (z^2 / (4 * n^2))) / denom
  c(lower = center - half, upper = center + half)
}

# 1) Descriptive counts
by_reuse <- aggregate(
  landing_success ~ is_reused,
  data = df,
  FUN = function(x) c(sum = sum(x), n = length(x))
)

by_reuse$successes <- by_reuse$landing_success[, "sum"]
by_reuse$n <- by_reuse$landing_success[, "n"]
by_reuse$rate <- by_reuse$successes / by_reuse$n

ci_mat <- t(mapply(wilson_ci, by_reuse$successes, by_reuse$n))
by_reuse$ci_lower <- ci_mat[, 1]
by_reuse$ci_upper <- ci_mat[, 2]

by_reuse$group <- ifelse(by_reuse$is_reused == 1, "Reused", "New")

# 2) Reuse bucket stats
bucket_stats <- aggregate(
  landing_success ~ reuse_bucket,
  data = df,
  FUN = function(x) c(sum = sum(x), n = length(x))
)

bucket_stats$successes <- bucket_stats$landing_success[, "sum"]
bucket_stats$n <- bucket_stats$landing_success[, "n"]
bucket_stats$rate <- bucket_stats$successes / bucket_stats$n

# 3) Payload mass IQR outlier check
payload <- df$payload_mass_kg_total
payload_non_na <- payload[!is.na(payload)]

Q1 <- quantile(payload_non_na, 0.25)
Q3 <- quantile(payload_non_na, 0.75)
IQR_val <- Q3 - Q1
lower_bound <- Q1 - 1.5 * IQR_val
upper_bound <- Q3 + 1.5 * IQR_val

outlier_count <- sum(payload_non_na < lower_bound | payload_non_na > upper_bound)

# Write descriptive stats
sink("output/descriptive_stats.txt")
cat("=== Descriptive Statistics ===\n\n")

cat("Total observations:", nrow(df), "\n\n")

cat("Landing success by reuse status:\n")
print(by_reuse[, c("group", "successes", "n", "rate", "ci_lower", "ci_upper")])
cat("\n")

cat("Landing success by reuse bucket:\n")
print(bucket_stats[, c("reuse_bucket", "successes", "n", "rate")])
cat("\n")

cat("Payload mass (kg):\n")
cat("Q1 =", Q1, "\n")
cat("Q3 =", Q3, "\n")
cat("IQR =", IQR_val, "\n")
cat("Outliers (1.5*IQR rule):", outlier_count, "\n")

sink()

# 4) Plots

# Plot A: New vs Reused success rate
p1 <- ggplot(by_reuse, aes(x = group, y = rate)) +
  geom_col(fill = "steelblue") +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.2) +
  ylim(0, 1) +
  labs(
    title = "Falcon 9 Landing Success Rate",
    subtitle = "New vs Reused Boosters (Wilson 95% CI)",
    y = "Success Probability",
    x = ""
  ) +
  theme_minimal()

ggsave("figs/success_new_vs_reused.png", p1, width = 6, height = 4)

# Plot B: Success rate by reuse bucket
p2 <- ggplot(bucket_stats, aes(x = reuse_bucket, y = rate)) +
  geom_col(fill = "darkgreen") +
  ylim(0, 1) +
  labs(
    title = "Landing Success Rate by Booster Flight Number",
    x = "Reuse Flight Bucket",
    y = "Success Probability"
  ) +
  theme_minimal()

ggsave("figs/success_by_reuse_bucket.png", p2, width = 7, height = 4)

# Plot C: Payload mass distribution
p3 <- ggplot(df, aes(x = payload_mass_kg_total)) +
  geom_histogram(bins = 30, fill = "gray70", color = "black") +
  labs(
    title = "Distribution of Payload Mass (kg)",
    x = "Payload Mass (kg)",
    y = "Count"
  ) +
  theme_minimal()

ggsave("figs/payload_mass_distribution.png", p3, width = 7, height = 4)

# Plot D: Success vs payload mass (binned)
df_non_na <- df[!is.na(df$payload_mass_kg_total), ]
df_non_na$mass_bin <- cut(df_non_na$payload_mass_kg_total, breaks = 5)

p4 <- ggplot(df_non_na, aes(x = mass_bin, y = landing_success)) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun = mean, geom = "line", aes(group = 1)) +
  labs(
    title = "Landing Success vs Payload Mass (Binned)",
    x = "Payload Mass Bin",
    y = "Success Probability"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

ggsave("figs/success_vs_payload_bins.png", p4, width = 8, height = 4)

cat("Step 4 OK\n")
cat("Saved figures to figs/\n")
cat("Saved descriptive stats to output/descriptive_stats.txt\n")
