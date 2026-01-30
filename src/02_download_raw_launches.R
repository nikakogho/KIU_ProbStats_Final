# src/02_download_raw_launches.R
# Step 2: Download raw Falcon 9 launches (minimal fields) via /v4/launches/query

library(httr)
library(jsonlite)

# Read Falcon 9 rocket id from Step 1
falcon9_id <- trimws(readLines("output/falcon9_rocket_id.txt", warn = FALSE))
if (is.na(falcon9_id) || nchar(falcon9_id) == 0) stop("Missing Falcon 9 id in output/falcon9_rocket_id.txt")

# Create folders
if (!dir.exists("data")) dir.create("data", recursive = TRUE)

# POST helper
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

  if (status != 200) {
    stop(sprintf("API POST failed. Status=%s\nURL=%s\nResponse=%s", status, url, txt))
  }
  fromJSON(txt, simplifyVector = FALSE)
}

# Query body
# We pull only what we need now: date, rocket, upcoming, success, cores, payloads.
query_body <- list(
  query = list(
    rocket = falcon9_id,
    upcoming = FALSE
  ),
  options = list(
    pagination = FALSE,
    select = c("id", "name", "date_utc", "success", "rocket", "upcoming", "cores", "payloads")
  )
)

url <- "https://api.spacexdata.com/v4/launches/query"
res <- api_post_json(url, query_body)

# Validate and save
if (is.null(res$docs)) stop("Unexpected response: missing 'docs'")

launches <- res$docs
n <- length(launches)

cat("Downloaded Falcon 9 launches:", n, "\n")
if (n == 0) stop("Got 0 launches — something is wrong with the query.")

# Save raw JSON so it is reproducible
writeLines(toJSON(res, pretty = TRUE, auto_unbox = TRUE), "data/raw_f9_launches_query_response.json")

# Quick sanity preview: first 3 launch names + dates
preview_n <- min(3, n)
for (i in seq_len(preview_n)) {
  cat(sprintf("- %s | %s\n",
              launches[[i]]$name %||% "(no name)",
              launches[[i]]$date_utc %||% "(no date)"))
}

cat("Saved: data/raw_f9_launches_query_response.json\n")

# helper for NULL-coalescing without extra packages
`%||%` <- function(a, b) if (!is.null(a)) a else b
