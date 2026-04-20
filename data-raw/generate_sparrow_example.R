## Generate sparrow_example dataset for the rsparrow package
## Run once from package root: source("data-raw/generate_sparrow_example.R")
##
## Creates a synthetic 60-reach dendritic watershed network suitable for
## demonstrating the full rsparrow workflow.
##
## Network structure (60 reaches):
##   Branch A1: reaches  1-10  (headwater, nodes   1..11)
##   Branch A2: reaches 11-20  (headwater, nodes 101..111)
##   A trunk:   reaches 21-25  (A1+A2 merge, nodes 11,111 → 50..53)
##   Branch B1: reaches 26-35  (headwater, nodes 201..211)
##   Branch B2: reaches 36-45  (headwater, nodes 301..311)
##   B trunk:   reaches 46-50  (B1+B2 merge, nodes 211,311 → 400..403)
##   Main stem: reaches 51-60  (A+B merge, nodes 53,403 → 500..508)

set.seed(42)

# ── 1. Network topology ───────────────────────────────────────────────────────
fnode <- c(
  1:10,                             # A1  (reaches  1-10)
  101:110,                          # A2  (reaches 11-20)
  11L, 111L, 50L, 51L, 52L,        # A trunk (reaches 21-25)
  201:210,                          # B1  (reaches 26-35)
  301:310,                          # B2  (reaches 36-45)
  211L, 311L, 400L, 401L, 402L,    # B trunk (reaches 46-50)
  53L, 403L, 500L:507L             # Main stem (reaches 51-60)
)

tnode <- c(
  2:11,                             # A1
  102:111,                          # A2
  50L, 50L, 51L, 52L, 53L,        # A trunk
  202:211,                          # B1
  302:311,                          # B2
  400L, 400L, 401L, 402L, 403L,   # B trunk
  500L, 500L, 501L:508L            # Main stem (tnode 508 = outlet)
)

waterid <- 1:60
stopifnot(length(fnode) == 60, length(tnode) == 60)

# ── 2. Headflag and termflag ──────────────────────────────────────────────────
headflag <- as.integer(!(fnode %in% tnode))   # 1 if no upstream reach
termflag <- c(rep(0L, 59), 1L)                # 1 for reach 60 (outlet)
# Verify: headwaters should be reaches 1, 11, 26, 36
stopifnot(which(headflag == 1) == c(1, 11, 26, 36))

# ── 3. Incremental drainage area (demiarea, km²) ──────────────────────────────
# Headwater reaches: 8-12 km²; connector/trunk reaches: 4-6 km²
demiarea <- c(
  round(runif(10, 8, 12), 1),   # A1
  round(runif(10, 8, 12), 1),   # A2
  c(5.0, 5.0, 6.0, 6.0, 6.0),  # A trunk
  round(runif(10, 8, 12), 1),   # B1
  round(runif(10, 8, 12), 1),   # B2
  c(5.0, 5.0, 6.0, 6.0, 6.0),  # B trunk
  c(5.0, 5.0, 7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 7.0, 7.0)  # Main stem
)

# ── 4. Total drainage area (demtarea, km²) by network accumulation ────────────
# Topological sort: process from most-upstream to terminal
demtarea <- demiarea
for (pass in 1:3) {
  # Multiple passes handle chains
  for (i in seq_along(waterid)) {
    ups <- which(tnode == fnode[i])   # reaches flowing into my fnode
    if (length(ups) > 0) {
      demtarea[i] <- demiarea[i] + sum(demtarea[ups])
    }
  }
}
# Reach 60 (terminal) should have total basin area
demtarea <- round(demtarea, 1)

# ── 5. Mean annual streamflow (meanq, m³/s) ──────────────────────────────────
# Rough rule: Q ≈ P * A / seconds_per_year; P ≈ 800 mm/year
# 800e-3 m/yr * A km² * 1e6 m²/km² / (365.25 * 86400 s/yr) ≈ 0.0000254 * A
meanq <- round(0.0000254 * demtarea, 4)

# ── 6. Source variable: agricultural N loading (agN, kg/km²/year) ────────────
agN <- round(runif(60, 5, 30), 1)

# ── 7. Delivery variable: mean annual precipitation (ppt, mm/year) ───────────
ppt <- round(runif(60, 600, 1200))

# ── 8. Monitoring sites and load response ────────────────────────────────────
# 5 monitoring sites at end-of-branch/main-stem locations
site_reaches <- c(10L, 20L, 35L, 45L, 58L)
calsites <- as.integer(waterid %in% site_reaches)

# Station IDs (non-zero at calibration sites)
staid_vec <- cumsum(calsites) * calsites

# Synthetic annual TN load (depvar, kg/year) at monitoring sites
# Simple SPARROW-like model: load = beta_agN * agN * demtarea * exp(beta_ppt * ppt)
# Using beta_agN = 0.15, beta_ppt = 0.0008 (realistic order of magnitude)
true_load_density <- 0.15 * agN * exp(0.0008 * ppt)  # kg/km²/year
true_total_load <- true_load_density * demtarea        # kg/year
# Add some multiplicative noise at monitoring sites (fix recycling: build full-length vector)
noise_full <- rep(1.0, 60)
noise_full[waterid %in% site_reaches] <- c(1.05, 0.93, 1.12, 0.88, 1.02)
depvar <- round(ifelse(waterid %in% site_reaches, true_total_load * noise_full, 0))

# ── 9. Other required/fixed attributes ───────────────────────────────────────
frac     <- rep(1.0, 60)
iftran   <- rep(1L, 60)
# rchtype: 0=river reach, 3=coastal outlet segment (terminal reach at coast)
rchtype  <- rep(0L, 60)
rchtype[60] <- 3L    # terminal reach flows to coast
# target: 1=target reach (compute delivery fraction to this reach), 0=non-target
# Set all reaches as target for full-network prediction
target   <- rep(1L, 60)
rchname  <- paste0("Reach_", waterid)

# Synthetic coordinates: eastern US watershed, outlet at ~39°N, 77.5°W
# Branch A: north fork (goes NW)
# Branch B: south fork (goes SW)
# Main stem: runs west-east
lon_outlet <- -77.5; lat_outlet <- 39.0
lon <- c(
  seq(-77.8, -78.3, length.out = 10),  # A1
  seq(-77.9, -78.4, length.out = 10),  # A2
  c(-78.2, -78.3, -78.1, -77.9, -77.7), # A trunk (W→E merge)
  seq(-77.2, -76.7, length.out = 10),  # B1
  seq(-77.1, -76.6, length.out = 10),  # B2
  c(-76.8, -76.7, -76.9, -77.1, -77.3), # B trunk
  c(-77.6, -77.4, -77.5, -77.4, -77.3, -77.2, -77.1, -77.0, -76.9, -76.8) # Main
)
lat <- c(
  seq(39.4, 39.9, length.out = 10),   # A1
  seq(39.3, 39.8, length.out = 10),   # A2
  c(39.6, 39.5, 39.5, 39.4, 39.3),   # A trunk
  seq(38.6, 38.1, length.out = 10),   # B1
  seq(38.7, 38.2, length.out = 10),   # B2
  c(38.4, 38.5, 38.5, 38.6, 38.7),   # B trunk
  c(39.1, 38.9, 39.0, 39.0, 39.0, 39.0, 39.0, 39.0, 39.0, 39.0) # Main
)

# ── 10. Assemble reaches data.frame ──────────────────────────────────────────
reaches <- data.frame(
  waterid  = waterid,
  fnode    = as.integer(fnode),
  tnode    = as.integer(tnode),
  frac     = frac,
  iftran   = iftran,
  rchtype  = rchtype,
  rchname  = rchname,
  demiarea = demiarea,
  demtarea = demtarea,
  headflag = headflag,
  termflag = termflag,
  meanq    = meanq,
  lat      = round(lat, 4),
  lon      = round(lon, 4),
  target   = target,
  staid    = staid_vec,
  depvar   = depvar,
  calsites = calsites,
  agN      = agN,
  ppt      = ppt,
  stringsAsFactors = FALSE
)

# ── 11. Site metadata ─────────────────────────────────────────────────────────
sites <- reaches[reaches$calsites == 1, c("waterid", "staid", "depvar",
                                           "demtarea", "lat", "lon")]
rownames(sites) <- NULL

# ── 12. Control file data.frames ──────────────────────────────────────────────
parameters <- data.frame(
  sparrowNames   = c("agN",       "ppt"),
  description    = c("Agricultural N source", "Precipitation delivery"),
  parmUnits      = c("fraction",  "dimensionless"),
  parmInit       = c(0.15,         0.0),
  parmMin        = c(0.0,         -5.0),
  parmMax        = c(5.0,          5.0),
  parmType       = c("SOURCE",     "DELIVF"),
  parmCorrGroup  = c(0L,           0L),
  stringsAsFactors = FALSE
)

design_matrix <- data.frame(
  sparrowNames = "agN",     # SOURCE row label
  ppt          = 1L,        # DELIVF column: agN uses ppt as delivery factor
  stringsAsFactors = FALSE
)

data_dictionary <- data.frame(
  varType        = c("REQUIRED","REQUIRED","REQUIRED","REQUIRED","REQUIRED",
                     "REQUIRED","REQUIRED","REQUIRED","REQUIRED",
                     "FIXED",   "FIXED",   "FIXED",   "FIXED",
                     "FIXED",   "FIXED",   "FIXED",   "FIXED",   "FIXED",
                     "SOURCE",  "DELIVF"),
  sparrowNames   = c("waterid","fnode","tnode","frac","iftran",
                     "demiarea","termflag","rchtype","calsites",
                     "rchname","demtarea","headflag","meanq",
                     "staid","lat","lon","depvar","target",
                     "agN","ppt"),
  data1UserNames = c("waterid","fnode","tnode","frac","iftran",
                     "demiarea","termflag","rchtype","calsites",
                     "rchname","demtarea","headflag","meanq",
                     "staid","lat","lon","depvar","target",
                     "agN","ppt"),
  varunits       = c("","","","fraction","",
                     "km2","","","",
                     "","km2","","m3/s",
                     "","degrees","degrees","kg/year","",
                     "kg/km2/year","mm/year"),
  explanation    = c("reach ID","from node","to node","transport fraction","transport indicator",
                     "incremental drainage area","terminal reach flag","reach type","calibration site indicator",
                     "reach name","total drainage area","headwater indicator","mean annual streamflow",
                     "station ID","latitude","longitude","mean annual TN load",
                     "terminal target reach (1=target; 0=non-target)",
                     "agricultural nitrogen source","mean annual precipitation"),
  stringsAsFactors = FALSE
)

# ── 13. Bundle into sparrow_example list ──────────────────────────────────────
sparrow_example <- list(
  reaches         = reaches,
  sites           = sites,
  parameters      = parameters,
  design_matrix   = design_matrix,
  data_dictionary = data_dictionary
)

# ── 14. Save ──────────────────────────────────────────────────────────────────
if (!dir.exists("data")) dir.create("data")
save(sparrow_example, file = "data/sparrow_example.rda", compress = "xz")
message("Created data/sparrow_example.rda (",
        round(file.size("data/sparrow_example.rda") / 1024, 1), " KB)")

# ── 15. Quick validation ──────────────────────────────────────────────────────
message("Reaches: ", nrow(sparrow_example$reaches))
message("Sites:   ", nrow(sparrow_example$sites))
message("depvar at sites: ",
        paste(round(sparrow_example$reaches$depvar[sparrow_example$reaches$calsites == 1]),
              collapse = ", "), " (kg/year)")
