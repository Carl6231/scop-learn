#!/usr/bin/env Rscript

options(scop_env_init = FALSE)
suppressPackageStartupMessages({
  library(Seurat)
  library(scop)
  library(ggplot2)
})

out_dir <- if (length(commandArgs(trailingOnly = TRUE))) commandArgs(trailingOnly = TRUE)[[1]] else "assets/figures"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create("evidence", recursive = TRUE, showWarnings = FALSE)

set.seed(20260808)
n_spots <- 36
n_genes <- 60
grid <- expand.grid(col = 1:6, row = 1:6)
counts <- matrix(rpois(n_genes * n_spots, lambda = 2.5), nrow = n_genes,
  dimnames = list(sprintf("Gene%03d", seq_len(n_genes)), sprintf("Spot%03d", seq_len(n_spots))))
corner <- grid$col <= 3 & grid$row >= 4
counts[1:6, corner] <- counts[1:6, corner] + rpois(6 * sum(corner), 5)

srt <- CreateSeuratObject(counts = counts, project = "scop-learn-spatial")
srt$col <- grid$col
srt$row <- grid$row
srt$region_hint <- ifelse(corner, "synthetic_corner", "synthetic_background")
srt <- NormalizeData(srt, verbose = FALSE)
srt <- RunSpatialVariableFeatures(srt, method = "moran", coord.cols = c("col", "row"), nfeatures = 10, min_spots = 5, verbose = FALSE)
srt <- RunSpatialNetwork(srt, method = "knn", coord.cols = c("col", "row"), k = 4, verbose = FALSE)

p <- SpatialVariableFeaturePlot(srt, plot_type = "combined", nfeatures = 3, coord.cols = c("col", "row"))
ggsave(file.path(out_dir, "spatial-overview.png"), p, width = 9, height = 5.8, dpi = 160, bg = "white")
figure_path <- file.path(out_dir, "spatial-overview.png")

network <- srt@tools$SpatialNetwork$summary
spatial_features <- srt@tools$SpatialVariableFeatures$summary
summary <- list(
  case = "spatial",
  scope = "synthetic 6 by 6 grid",
  seed = 20260808,
  spots = ncol(srt),
  genes = nrow(srt),
  coordinate_columns = c("col", "row"),
  variable_feature_method = "moran",
  top_features = as.list(spatial_features$top_features),
  network = as.list(network),
  package_versions = list(
    R = as.character(getRversion()),
    scop = as.character(packageVersion("scop")),
    Seurat = as.character(packageVersion("Seurat")),
    ggplot2 = as.character(packageVersion("ggplot2"))
  ),
  workflow = c("NormalizeData", "RunSpatialVariableFeatures", "RunSpatialNetwork", "SpatialVariableFeaturePlot"),
  figure = "assets/figures/spatial-overview.png",
  figure_sha256 = digest::digest(figure_path, algo = "sha256", file = TRUE),
  limitations = c("synthetic grid", "spot-level descriptive evidence", "SpatialQM optional backend not installed in the local environment")
)
jsonlite::write_json(summary, "evidence/spatial-case.json", auto_unbox = TRUE, pretty = TRUE)
writeLines(capture.output(sessionInfo()), "evidence/spatial-session.txt")
cat(sprintf("spatial: %d spots, %d genes, %d edges, top=%s\n", ncol(srt), nrow(srt), network$n_edges, paste(head(spatial_features$top_features, 3), collapse = ",")))
