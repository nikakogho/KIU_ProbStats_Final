# R/01_setup_and_get_falcon9_id.R
# Step 1: project skeleton + API connectivity + Falcon 9 rocket ID

# Packages
install.packages(c("httr", "jsonlite"))

library(httr)
library(jsonlite)

# Create folders
dirs <- c("R", "data", "output", "figs")
for (d in dirs) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

# Simple API GET helper with checks
api_get_json <- function(url) {
  resp <- GET(url, user_agent("KIU-ProbStat-F9-Reuse/1.0"))
  status <- status_code(resp)

  if (status != 200) {
    stop(sprintf("API request failed. Status=%s, URL=%s", status, url))
  }

  txt <- content(resp, as = "text", encoding = "UTF-8")
  fromJSON(txt, simplifyVector = TRUE)
}

# 1) Fetch rockets list
rockets_url <- "https://api.spacexdata.com/v4/rockets"
rockets <- api_get_json(rockets_url)

# 2) Find Falcon 9
# rockets is a data.frame-like structure with columns like "name" and "id"
if (!("name" %in% names(rockets)) || !("id" %in% names(rockets))) {
  stop("Unexpected rockets schema: missing 'name' or 'id' fields.")
}

f9 <- rockets[rockets$name == "Falcon 9", , drop = FALSE]

if (nrow(f9) != 1) {
  stop(sprintf("Expected exactly 1 Falcon 9 rocket entry, found %d.", nrow(f9)))
}

falcon9_id <- f9$id[[1]]

# 3) Persist rocket id
writeLines(falcon9_id, "output/falcon9_rocket_id.txt")

# 4) Print confirmation
cat("Step 1 OK\n")
cat("Falcon 9 rocket id:", falcon9_id, "\n")
cat("Saved to output/falcon9_rocket_id.txt\n")
