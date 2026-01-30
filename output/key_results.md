# Key results

**Dataset size (clean landing attempts):** 153 launches.

## Primary result: New vs Reused landing success
- New boosters: 38/46 successes (p̂ = 0.8261), Wilson 95% CI [0.6928, 0.9091].
- Reused boosters: 104/107 successes (p̂ = 0.9720), Wilson 95% CI [0.9208, 0.9904].
- Difference (Reused − New) = 0.1459.
- Two-proportion test (approx): p-value = 0.00136 (note: approximation warning due to small failure counts).
- Fisher exact test (recommended here): p-value = 0.00314.
- Odds ratio (Reused vs New, continuity-corrected): OR ≈ 6.592.

## Reuse amount (flight bucket) association
- Reuse bucket table (failures, successes):
```
    
      0  1
  1   8 38
  2   0 23
  3   0 14
  4   1 13
  5+  2 54
```
- Fisher test with simulated p-value: p-value = 0.04499.

## Robustness: logistic regression (controls)
- Model A: landing_success ~ is_reused + payload_tons + year_c (n=133 with non-missing payload).
  - is_reused p-value = 0.64067 (OR=1.691).
  - year_c p-value = 0.01064 (OR=2.141 per +1 year from median).
- Model B: landing_success ~ reuse_flight + payload_tons + year_c (n=133).
  - reuse_flight p-value = 0.83691 (OR=0.956 per +1 flight).

## Takeaway
Raw success rates are higher for reused boosters, and the New vs Reused difference is statistically significant by Fisher’s exact test. However, when controlling for time (year) and payload mass in a logistic regression, the reuse indicator/flight number is not statistically significant, suggesting the apparent advantage is largely explained by improvements over time rather than reuse causing worse reliability.
