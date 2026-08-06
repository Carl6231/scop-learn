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

set.seed(20260807)
n_genes <- 120
n_cells <- 80
group <- rep(c("state_A", "state_B"), each = n_cells / 2)
counts <- matrix(rpois(n_genes * n_cells, lambda = 1.5), nrow = n_genes,
  dimnames = list(sprintf("Gene%03d", seq_len(n_genes)), sprintf("Cell%03d", seq_len(n_cells))))
counts[1:12, group == "state_A"] <- counts[1:12, group == "state_A"] + rpois(12 * sum(group == "state_A"), 5)
counts[13:24, group == "state_B"] <- counts[13:24, group == "state_B"] + rpois(12 * sum(group == "state_B"), 5)

srt <- CreateSeuratObject(counts = counts, project = "scop-learn-single-cell")
srt$group <- group
srt <- RunCellQC(srt, qc_metrics = c("umi", "gene"), UMI_threshold = 0, gene_threshold = 0, verbose = FALSE)
srt <- NormalizeData(srt, verbose = FALSE)
srt <- FindVariableFeatures(srt, nfeatures = 60, verbose = FALSE)
srt <- ScaleData(srt, features = VariableFeatures(srt), verbose = FALSE)
srt <- RunPCA(srt, features = VariableFeatures(srt), npcs = 12, verbose = FALSE)
srt <- FindNeighbors(srt, dims = 1:8, verbose = FALSE)
srt <- FindClusters(srt, resolution = 0.4, verbose = FALSE)
srt <- RunUMAP(srt, dims = 1:8, seed.use = 20260807, verbose = FALSE)
estimated_dims <- RunDimsEstimate(srt, reduction = "pca", reduction_method = "scree", verbose = FALSE)

p <- DimPlot(srt, reduction = "umap", group.by = "group", pt.size = 1.4) +
  ggtitle("SCOP Learn · synthetic single-cell case") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"), legend.position = "bottom")
ggsave(file.path(out_dir, "single-cell-overview.png"), p, width = 8, height = 5.2, dpi = 160, bg = "white")
figure_path <- file.path(out_dir, "single-cell-overview.png")

summary <- list(
  case = "single-cell",
  scope = "synthetic two-state workflow",
  seed = 20260807,
  cells = ncol(srt),
  genes = nrow(srt),
  groups = as.list(table(srt$group)),
  clusters = length(unique(as.character(Idents(srt)))),
  reductions = Reductions(srt),
  estimated_dims = as.numeric(estimated_dims),
  package_versions = list(
    R = as.character(getRversion()),
    scop = as.character(packageVersion("scop")),
    Seurat = as.character(packageVersion("Seurat")),
    ggplot2 = as.character(packageVersion("ggplot2"))
  ),
  workflow = c("RunCellQC", "NormalizeData", "FindVariableFeatures", "ScaleData", "RunPCA", "FindNeighbors", "FindClusters", "RunUMAP", "RunDimsEstimate"),
  figure = "assets/figures/single-cell-overview.png",
  figure_sha256 = digest::digest(figure_path, algo = "sha256", file = TRUE),
  limitations = c("synthetic input", "declared groups are not discovered cell types", "not clinical or patient-level evidence")
)
jsonlite::write_json(summary, "evidence/single-cell-case.json", auto_unbox = TRUE, pretty = TRUE)
writeLines(capture.output(sessionInfo()), "evidence/single-cell-session.txt")
cat(sprintf("single-cell: %d cells, %d genes, %d clusters, reductions=%s\n", ncol(srt), nrow(srt), summary$clusters, paste(Reductions(srt), collapse = ",")))
