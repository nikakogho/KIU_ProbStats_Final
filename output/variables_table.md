# Variables table

| Variable | Type | Role | Description |
|---|---|---|---|
| landing_success | Quantitative (binary 0/1) | Outcome (Y) | 1 if landing succeeded, 0 otherwise |
| is_reused | Qualitative (binary) | Predictor (X) | 1 if booster flight >= 2, else 0 |
| reuse_flight | Quantitative (integer) | Predictor (X) | Booster flight number on this launch |
| reuse_bucket | Qualitative (ordinal) | Predictor (X) | Flight bucket: 1,2,3,4,5+ |
| payload_mass_kg_total | Quantitative (continuous) | Predictor (X) | Total payload mass (kg) for the launch; NA if missing |
| year | Quantitative (integer) | Predictor (X) | Launch year (from date_utc) |
| landing_type | Qualitative | Context | e.g., ASDS, RTLS, Ocean (descriptive only) |
| launch_success | Quantitative (binary 0/1) | Context | Launch success flag (not primary outcome) |
