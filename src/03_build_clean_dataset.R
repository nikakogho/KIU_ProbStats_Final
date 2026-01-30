# src/03_build_clean_dataset.R
# Step 3: Build clean dataset for Falcon 9 landing attempts
# Output: data/clean_f9_landings.csv

library(httr)
library(jsonlite)

# Create folders
if (!dir.exists("data")) dir.create("data", recursive = TRUE)

# Helpers
`%||%` <- function(a, b) if (!is.null(a)) a else b

api_post_json <- function(url, body_list) {
  resp <- POST(
    url,
    user_agent("KIU-ProbStat-F9-Reuse/1.0"),
    add_headers(`Content-Type` = "application/json"),
    body = toJSON(body_list, auto_unbox = TRUE),
    encode = "raw"
  )
  status <- status_code(resp)
  txt <- content(resp, as = "text", encoding = "UTF-8")
  if (status != 200) stop(sprintf("API POST failed. Status=%s\nResponse=%s", status, txt))
  fromJSON(txt, simplifyVector = FALSE)
}

# Read Falcon 9 rocket id
falcon9_id <- trimws(readLines("output/falcon9_rocket_id.txt", warn = FALSE))
if (is.na(falcon9_id) || nchar(falcon9_id) == 0) stop("Missing Falcon 9 id")

# Query launches and populate payloads
# We request payload objects so we can sum mass_kg.
query_body <- list(
  query = list(
    rocket = falcon9_id,
    upcoming = FALSE
  ),
  options = list(
    pagination = FALSE,
    select = c(
      "id", "name", "date_utc", "success", "cores", "payloads"
    ),
    populate = list(
      list(path = "payloads", select = c("mass_kg"))
    )
  )
)

url <- "https://api.spacexdata.com/v4/launches/query"
res <- api_post_json(url, query_body)

if (is.null(res$docs)) stop("Unexpected response: missing docs")
launches <- res$docs
cat("Fetched launches with payload masses populated:", length(launches), "\n")

# Build rows using locked rules
rows <- list()

dropped <- list(
  no_landing_attempt = 0,
  multiple_attempts = 0,
  missing_landing_success = 0,
  missing_flight_number = 0
)

for (L in launches) {
  cores <- L$cores %||% list()

  # Find landing attempts
  attempt_idx <- which(vapply(cores, function(c) isTRUE(c$landing_attempt), logical(1)))

  if (length(attempt_idx) == 0) {
    dropped$no_landing_attempt <- dropped$no_landing_attempt + 1
    next
  }
  if (length(attempt_idx) != 1) {
    dropped$multiple_attempts <- dropped$multiple_attempts + 1
    next
  }

  c <- cores[[attempt_idx]]

  # landing_success must be TRUE/FALSE (not NULL)
  if (is.null(c$landing_success)) {
    dropped$missing_landing_success <- dropped$missing_landing_success + 1
    next
  }
  landing_success <- ifelse(isTRUE(c$landing_success), 1L, 0L)

  # flight number must exist
  if (is.null(c$flight)) {
    dropped$missing_flight_number <- dropped$missing_flight_number + 1
    next
  }
  reuse_flight <- as.integer(c$flight)

  # reuse bucket
  reuse_bucket <- if (reuse_flight >= 5) "5+" else as.character(reuse_flight)
  is_reused <- ifelse(reuse_flight >= 2, 1L, 0L)

  # payload mass total (sum of payload mass_kg ignoring NULL)
  payloads <- L$payloads %||% list()
  masses <- vapply(payloads, function(p) {
    if (is.null(p$mass_kg)) NA_real_ else as.numeric(p$mass_kg)
  }, numeric(1))

  if (all(is.na(masses))) {
    payload_mass_total <- NA_real_
  } else {
    payload_mass_total <- sum(masses, na.rm = TRUE)
  }

  # optional landing metadata
  landing_type <- c$landing_type %||% NA_character_
  landpad <- c$landpad %||% NA_character_

  date_utc <- L$date_utc %||% NA_character_
  year <- if (!is.na(date_utc)) as.integer(substr(date_utc, 1, 4)) else NA_integer_

  rows[[length(rows) + 1]] <- data.frame(
    launch_id = L$id %||% NA_character_,
    name = L$name %||% NA_character_,
    date_utc = date_utc,
    year = year,
    launch_success = ifelse(isTRUE(L$success), 1L, ifelse(isFALSE(L$success), 0L, NA_integer_)),
    landing_success = landing_success,
    reuse_flight = reuse_flight,
    reuse_bucket = reuse_bucket,
    is_reused = is_reused,
    payload_mass_kg_total = payload_mass_total,
    landing_type = landing_type,
    landpad = landpad,
    stringsAsFactors = FALSE
  )
}

if (length(rows) == 0) stop("No rows produced — rules too strict or API schema changed.")

df <- do.call(rbind, rows)

write.csv(df, "data/clean_f9_landings.csv", row.names = FALSE)

cat("\nStep 3 OK\n")
cat("Clean rows:", nrow(df), "\n")
cat("Dropped counts:\n")
print(dropped)

cat("\nPreview (first 6 rows):\n")
print(head(df, 6))

cat("\nReuse bucket counts:\n")
print(table(df$reuse_bucket))

cat("\nSaved: data/clean_f9_landings.csv\n")
