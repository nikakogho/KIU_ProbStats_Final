# src/04b_extra_descriptives_assoc.R
# Extra descriptives (mean/SD/median/IQR/quantiles) + X-X associations

library(ggplot2)

df <- read.csv("data/clean_f9_landings.csv", stringsAsFactors = FALSE)
if (!dir.exists("output")) dir.create("output", recursive = TRUE)
if (!dir.exists("figs")) dir.create("figs", recursive = TRUE)

# numeric helpers
summ_num <- function(x) {
  x <- x[!is.na(x)]
  c(
    n = length(x),
    mean = mean(x),
    sd = sd(x),
    median = median(x),
    Q1 = as.numeric(quantile(x, 0.25)),
    Q3 = as.numeric(quantile(x, 0.75)),
    IQR = IQR(x),
    p10 = as.numeric(quantile(x, 0.10)),
    p90 = as.numeric(quantile(x, 0.90))
  )
}

payload_stats <- summ_num(df$payload_mass_kg_total)
reuseflight_stats <- summ_num(df$reuse_flight)

# X-X associations (numeric)
df_num <- data.frame(
  reuse_flight = df$reuse_flight,
  payload_mass_kg_total = df$payload_mass_kg_total,
  year = df$year
)

corr <- cor(df_num, use = "pairwise.complete.obs")

# save to file (append to existing descriptives)
cat("\n\n=== Extra Descriptives & Associations (X-X) ===\n",
    file = "output/descriptive_stats.txt", append = TRUE)

cat("\nPayload mass (kg) summary:\n",
    file = "output/descriptive_stats.txt", append = TRUE)
capture.output(print(round(payload_stats, 3))) |>
  paste(collapse = "\n") |>
  write(file = "output/descriptive_stats.txt", append = TRUE)

cat("\n\nReuse flight (count) summary:\n",
    file = "output/descriptive_stats.txt", append = TRUE)
capture.output(print(round(reuseflight_stats, 3))) |>
  paste(collapse = "\n") |>
  write(file = "output/descriptive_stats.txt", append = TRUE)

cat("\n\nCorrelation matrix (pairwise complete obs):\n",
    file = "output/descriptive_stats.txt", append = TRUE)
capture.output(print(round(corr, 3))) |>
  paste(collapse = "\n") |>
  write(file = "output/descriptive_stats.txt", append = TRUE)

# plot: payload vs year (x-x)
df2 <- df[!is.na(df$payload_mass_kg_total) & !is.na(df$year), ]
p <- ggplot(df2, aes(x = year, y = payload_mass_kg_total)) +
  geom_point(alpha = 0.6) +
  labs(
    title = "Payload Mass vs Year (X-X association)",
    x = "Year",
    y = "Total Payload Mass (kg)"
  ) +
  theme_minimal()

ggsave("figs/payload_vs_year.png", p, width = 7, height = 4)

cat("\n\nSaved: figs/payload_vs_year.png\n",
    file = "output/descriptive_stats.txt", append = TRUE)

cat("Step 04b OK\n")
