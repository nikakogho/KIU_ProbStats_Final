# src/05_simulation_mle_ci.R
# Step 5: Monte Carlo validation of Bernoulli MLE + CI coverage

library(ggplot2)

set.seed(42)

p_true <- 0.85        # realistic Falcon 9 landing success
n <- 50               # sample size per experiment
n_sim <- 10000        # number of Monte Carlo runs
conf <- 0.95

wilson_ci <- function(x, n, conf = 0.95) {
  z <- qnorm(1 - (1 - conf) / 2)
  p_hat <- x / n
  denom <- 1 + z^2 / n
  center <- (p_hat + z^2 / (2 * n)) / denom
  half <- z * sqrt((p_hat * (1 - p_hat) / n) + (z^2 / (4 * n^2))) / denom
  c(lower = center - half, upper = center + half)
}

# Monte Carlo simulation
p_hat <- numeric(n_sim)
ci_lower <- numeric(n_sim)
ci_upper <- numeric(n_sim)

for (i in seq_len(n_sim)) {
  y <- rbinom(n, size = 1, prob = p_true)
  x <- sum(y)
  p_hat[i] <- x / n

  ci <- wilson_ci(x, n, conf)
  ci_lower[i] <- ci[1]
  ci_upper[i] <- ci[2]
}

# Coverage
covered <- (ci_lower <= p_true) & (p_true <= ci_upper)
coverage_rate <- mean(covered)

# Summary stats
mean_hat <- mean(p_hat)
var_hat <- var(p_hat)
theoretical_var <- p_true * (1 - p_true) / n

# Save summary
sink("output/simulation_summary.txt")
cat("=== Monte Carlo Validation of Bernoulli MLE ===\n\n")
cat("True p:", p_true, "\n")
cat("Sample size n:", n, "\n")
cat("Simulations:", n_sim, "\n\n")

cat("Mean of p_hat:", mean_hat, "\n")
cat("Theoretical mean:", p_true, "\n\n")

cat("Variance of p_hat:", var_hat, "\n")
cat("Theoretical variance:", theoretical_var, "\n\n")

cat("95% Wilson CI coverage:", coverage_rate, "\n")
sink()

# Plot 1: Sampling distribution
df_hat <- data.frame(p_hat = p_hat)

p1 <- ggplot(df_hat, aes(x = p_hat)) +
  geom_histogram(aes(y = after_stat(density)),
                 bins = 40, fill = "skyblue", color = "black") +
  stat_function(fun = dnorm,
                args = list(mean = p_true, sd = sqrt(theoretical_var)),
                color = "red", linewidth = 1) +
  labs(
    title = "Sampling Distribution of MLE p̂",
    subtitle = "Histogram (blue) vs Normal approximation (red)",
    x = "p̂",
    y = "Density"
  ) +
  theme_minimal()

ggsave("figs/sim_sampling_distribution.png", p1, width = 7, height = 4)

# Plot 2: CI coverage visualization
df_ci <- data.frame(
  sim = seq_len(n_sim),
  covered = covered
)

p2 <- ggplot(df_ci, aes(x = sim, y = as.numeric(covered))) +
  geom_point(alpha = 0.2) +
  geom_hline(yintercept = conf, color = "red", linetype = "dashed") +
  labs(
    title = "Wilson CI Coverage Indicator",
    subtitle = paste("Empirical coverage =", round(coverage_rate, 3)),
    x = "Simulation index",
    y = "CI contains true p (1 = yes)"
  ) +
  theme_minimal()

ggsave("figs/sim_ci_coverage.png", p2, width = 7, height = 4)

cat("Step 5 OK\n")
cat("Saved simulation results to output/ and figs/\n")
