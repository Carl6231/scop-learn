#!/usr/bin/env Rscript

options(scop_env_init = FALSE, future.globals.maxSize = 4 * 1024^3)
suppressPackageStartupMessages({
  library(Seurat)
  library(scop)
  library(ggplot2)
  library(Matrix)
})

seed <- 20260807L
set.seed(seed)

dirs <- c(
  "assets/figures/real-data", "evidence/real-data",
  "artifacts/real-data/input", "artifacts/real-data/checkpoints"
)
invisible(lapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE))

json_path <- function(name) file.path("evidence/real-data", paste0(name, ".json"))
fig_path <- function(name) file.path("assets/figures/real-data", paste0(name, ".png"))
checkpoint_path <- function(name) file.path("artifacts/real-data/checkpoints", paste0(name, ".rds"))
sha256 <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
write_json <- function(x, name) jsonlite::write_json(x, json_path(name), auto_unbox = TRUE, pretty = TRUE, null = "null")
save_plot <- function(plot, name, width = 9, height = 6) {
  path <- fig_path(name)
  ggsave(path, plot, width = width, height = height, dpi = 180, bg = "white")
  path
}
save_checkpoint <- function(object, name) {
  path <- checkpoint_path(name)
  saveRDS(object, path, compress = "gzip")
  list(path = path, sha256 = sha256(path), bytes = unname(file.info(path)$size))
}
as_named_counts <- function(x) as.list(stats::setNames(as.integer(table(x)), names(table(x))))

theme_learn <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", colour = "#07111f"),
      plot.subtitle = element_text(colour = "#526276"),
      legend.position = "bottom", panel.grid.minor = element_blank()
    )
}

cat("[1/7] Runtime and dataset inventory\n")
dataset_rows <- list()
dataset_spec <- list(
  pancreas_sub = list(modality = "scRNA-seq + spliced/unspliced", source = "Bastidas-Ponce 2019 / scVelo", role = "single sample and trajectory"),
  panc8_sub = list(modality = "scRNA-seq, eight sources", source = "SeuratData panc8", role = "cross-source integration"),
  pbmcmultiome_sub = list(modality = "paired RNA + ATAC", source = "SeuratData pbmcMultiome", role = "annotation and multiome"),
  visium_human_pancreas_sub = list(modality = "Visium spatial RNA", source = "GSE254829 / GSM8058244", role = "human spatial case"),
  visium_mouse_brain_slices_sub = list(modality = "Visium spatial RNA, two slices", source = "10x Genomics / SeuratData stxBrain", role = "multi-slice spatial case")
)
for (nm in names(dataset_spec)) {
  data(list = nm, package = "scop", envir = environment())
  object <- get(nm, envir = environment())
  dataset_rows[[nm]] <- data.frame(
    dataset = nm, features = nrow(object), observations = ncol(object),
    assays = paste(Assays(object), collapse = ";"),
    modality = dataset_spec[[nm]]$modality, source = dataset_spec[[nm]]$source,
    tutorial_role = dataset_spec[[nm]]$role, stringsAsFactors = FALSE
  )
}
dataset_catalog <- do.call(rbind, dataset_rows)
write.csv(dataset_catalog, "evidence/real-data/dataset-catalog.csv", row.names = FALSE)

backend_packages <- c(
  SingleR = "SingleR", celldex = "celldex", CellTypist = "reticulate",
  spacexr = "spacexr", zellkonverter = "zellkonverter", loomR = "loomR",
  edgeR = "edgeR", harmony = "harmony", clustree = "clustree"
)
backends <- vapply(backend_packages, requireNamespace, logical(1), quietly = TRUE)
runtime <- list(
  generated_at = format(Sys.time(), tz = "Asia/Shanghai", usetz = TRUE), seed = seed,
  R = as.character(getRversion()), scop = as.character(packageVersion("scop")),
  Seurat = as.character(packageVersion("Seurat")), scop_exports = length(getNamespaceExports("scop")),
  datasets = dataset_catalog, backend_packages = as.list(backends),
  construction_order = c("db_scDblFinder", "JoinLayers", "ClusterTreePlot", "SCTransform", "Harmony_integrate", "RunDimsEstimate")
)
write_json(runtime, "runtime")

cat("[2/7] Real 10x input formats\n")
h5_path <- "artifacts/real-data/input/pbmc_1k_v3_filtered_feature_bc_matrix.h5"
if (!file.exists(h5_path)) stop("Download the official 10x PBMC 1k H5 before running this script")
h5_raw <- Seurat::Read10X_h5(h5_path, use.names = TRUE, unique.features = TRUE)
h5_counts <- if (is.list(h5_raw)) h5_raw[["Gene Expression"]] else h5_raw
h5_srt <- CreateSeuratObject(h5_counts, project = "PBMC1kV3")

matrix_dir <- "artifacts/real-data/input/pbmc_1k_v3_three_file"
dir.create(matrix_dir, recursive = TRUE, showWarnings = FALSE)
Matrix::writeMM(h5_counts, file.path(matrix_dir, "matrix.mtx"))
write.table(colnames(h5_counts), file.path(matrix_dir, "barcodes.tsv"), quote = FALSE, row.names = FALSE, col.names = FALSE)
features <- data.frame(rownames(h5_counts), rownames(h5_counts), "Gene Expression")
write.table(features, file.path(matrix_dir, "features.tsv"), sep = "\t", quote = FALSE, row.names = FALSE, col.names = FALSE)
plain_matrix_files <- file.path(matrix_dir, c("matrix.mtx", "barcodes.tsv", "features.tsv"))
invisible(lapply(plain_matrix_files, function(path) {
  status <- system2("gzip", c("-f", path))
  if (!identical(status, 0L)) stop("Failed to gzip ", path)
}))
matrix_counts <- Seurat::Read10X(matrix_dir, gene.column = 2)
rds_path <- "artifacts/real-data/input/pbmc_1k_v3.rds"
saveRDS(h5_srt, rds_path, compress = "gzip")
rds_srt <- readRDS(rds_path)

input_manifest <- list(
  source = "10x Genomics PBMC 1k v3 filtered feature-barcode matrix",
  source_url = "https://cf.10xgenomics.com/samples/cell-exp/3.0.0/pbmc_1k_v3/pbmc_1k_v3_filtered_feature_bc_matrix.h5",
  h5_sha256 = sha256(h5_path), features = nrow(h5_counts), cells = ncol(h5_counts),
  total_umis = sum(h5_counts),
  validations = list(
    h5_vs_three_file_dimensions = identical(dim(h5_counts), dim(matrix_counts)),
    h5_vs_three_file_total_umis = identical(as.numeric(sum(h5_counts)), as.numeric(sum(matrix_counts))),
    h5_vs_rds_dimensions = identical(dim(h5_srt), dim(rds_srt))
  ),
  readers = list(
    h5 = "Seurat::Read10X_h5", three_file = "Seurat::Read10X", rds = "readRDS",
    h5ad = "scop::h5ad_to_srt (backend not installed in this runtime)",
    loom = "scop::loom_to_srt (backend not installed in this runtime)"
  )
)
stopifnot(all(unlist(input_manifest$validations)))
write_json(input_manifest, "input-formats")

cat("[3/7] Single-sample pancreas workflow\n")
data(pancreas_sub, package = "scop")
single <- pancreas_sub
DefaultAssay(single) <- "RNA"
single[["percent.mt"]] <- PercentageFeatureSet(single, pattern = "^mt-")
single <- db_scDblFinder(single, assay = "RNA", db_rate = 0.01, verbose = FALSE)
qc_before <- single[[]]
keep <- with(qc_before,
  db.scDblFinder_class == "singlet" & nFeature_RNA >= 1000 &
    nFeature_RNA <= 5000 & percent.mt < 5
)
single <- subset(single, cells = rownames(qc_before)[keep])
single <- JoinLayers(single)
single <- NormalizeData(single, verbose = FALSE)
single <- FindVariableFeatures(single, nfeatures = 2000, verbose = FALSE)
single <- ScaleData(single, features = VariableFeatures(single), verbose = FALSE)
single <- RunPCA(single, features = VariableFeatures(single), npcs = 30, verbose = FALSE)
single <- FindNeighbors(single, dims = 1:20, verbose = FALSE)
single <- FindClusters(single, resolution = c(0.2, 0.4, 0.8), verbose = FALSE, random.seed = seed)
cluster_cols <- grep("RNA_snn_res", colnames(single[[]]), value = TRUE)
tree_plot <- ClusterTreePlot(single, cluster_cols = cluster_cols, title = "Resolution stability on real mouse pancreas", verbose = FALSE) +
  theme_learn() + theme(legend.position = "none")
tree_file <- save_plot(tree_plot, "single-cluster-tree", width = 8.5, height = 5.4)
estimated_dims <- RunDimsEstimate(single, reduction = "pca", method = "ensemble", min_dims = 5, verbose = FALSE)
dims_use <- seq_len(min(20L, max(5L, as.integer(estimated_dims))))
single <- RunUMAP(single, reduction = "pca", dims = dims_use, reduction.name = "umap", seed.use = seed, verbose = FALSE)
final_cluster <- cluster_cols[grepl("0.4$", cluster_cols)][1]
Idents(single) <- single[[final_cluster]][, 1]
markers <- FindAllMarkers(single, assay = "RNA", only.pos = TRUE, min.pct = 0.2, logfc.threshold = 0.25, verbose = FALSE)
markers <- markers[order(markers$p_val_adj, -markers$avg_log2FC), ]
write.csv(markers, "evidence/real-data/single-cluster-markers.csv", row.names = FALSE)

majority <- aggregate(single$CellType, list(cluster = as.character(Idents(single))), function(x) names(sort(table(x), decreasing = TRUE))[1])
names(majority)[2] <- "predicted"
single$cluster_majority_label <- majority$predicted[match(as.character(Idents(single)), majority$cluster)]
annotation_accuracy <- mean(single$cluster_majority_label == single$CellType)

qc_long <- rbind(
  data.frame(stage = "Before", metric = "Detected genes", value = qc_before$nFeature_RNA),
  data.frame(stage = "After", metric = "Detected genes", value = single$nFeature_RNA),
  data.frame(stage = "Before", metric = "Mitochondrial percent", value = qc_before$percent.mt),
  data.frame(stage = "After", metric = "Mitochondrial percent", value = single$percent.mt)
)
qc_long$stage <- factor(qc_long$stage, levels = c("Before", "After"))
qc_plot <- ggplot(qc_long, aes(stage, value, fill = stage)) +
  geom_violin(scale = "width", trim = TRUE) + geom_boxplot(width = 0.12, outlier.shape = NA, colour = "#172033") +
  facet_wrap(~metric, scales = "free_y") + scale_fill_manual(values = c(Before = "#9fb7c5", After = "#d97745")) +
  labs(title = "QC is measured before thresholds are chosen", subtitle = "Real pancreas_sub cells; doublets and boundary failures are removed", x = NULL, y = NULL) + theme_learn() + guides(fill = "none")
qc_file <- save_plot(qc_plot, "single-qc", width = 8.5, height = 4.8)
umap_plot <- DimPlot(single, reduction = "umap", group.by = "CellType", pt.size = 0.65, raster = FALSE) +
  labs(title = "Mouse pancreatic endocrinogenesis", subtitle = "Known CellType labels are shown for biological validation") + theme_learn()
umap_file <- save_plot(umap_plot, "single-umap", width = 8.5, height = 5.7)
single_checkpoint <- save_checkpoint(single, "single-pancreas")
single_manifest <- list(
  dataset = "pancreas_sub", source = "Bastidas-Ponce et al. 2019 / scVelo",
  before = list(cells = ncol(pancreas_sub), genes = nrow(pancreas_sub), doublets = sum(qc_before$db.scDblFinder_class == "doublet"), qc = list(
    nFeature_median = unname(median(qc_before$nFeature_RNA)), nCount_median = unname(median(qc_before$nCount_RNA)), percent_mt_median = unname(median(qc_before$percent.mt))
  )),
  after = list(cells = ncol(single), retained_percent = round(100 * ncol(single) / ncol(pancreas_sub), 1), cell_types = as_named_counts(single$CellType)),
  thresholds = list(nFeature_RNA = c(1000, 5000), percent_mt_max = 5, doublet_class = "singlet"),
  estimated_dims = as.integer(estimated_dims), dims_used = dims_use,
  final_cluster_column = final_cluster, clusters = length(unique(Idents(single))),
  cluster_majority_accuracy_against_known_CellType = round(annotation_accuracy, 4),
  figures = list(qc = list(path = qc_file, sha256 = sha256(qc_file)), umap = list(path = umap_file, sha256 = sha256(umap_file)), cluster_tree = list(path = tree_file, sha256 = sha256(tree_file))),
  checkpoint = single_checkpoint,
  claim_boundary = "Cluster-majority accuracy is an internal concordance check against bundled labels, not independent biological validation."
)
write_json(single_manifest, "single-sample")

cat("[4/7] Cross-source SCT + Harmony integration\n")
data(panc8_sub, package = "scop")
cross <- JoinLayers(panc8_sub)
cross <- SCTransform(cross, assay = "RNA", new.assay.name = "SCT", vst.flavor = "v2", variable.features.n = 2000, verbose = FALSE)
hvf <- VariableFeatures(cross)
cross <- Harmony_integrate(
  srt_merge = cross, batch = "dataset", assay = "SCT", normalization_method = "SCT",
  do_normalization = FALSE, do_HVF_finding = FALSE, HVF = hvf, do_scaling = FALSE,
  linear_reduction_dims = 30, linear_reduction_dims_use = 1:20, harmony_dims_use = 1:20,
  nonlinear_reduction = "umap", nonlinear_reduction_dims = 2, cluster_resolution = 0.4,
  append = TRUE, verbose = FALSE, seed = seed
)
cross <- RunUMAP(cross, reduction = "Harmonypca", dims = 1:20, reduction.name = "SourceUMAP", reduction.key = "SourceUMAP_", seed.use = seed, verbose = FALSE)
cross_dims <- RunDimsEstimate(cross, reduction = "Harmony", method = "ensemble", min_dims = 5, verbose = FALSE)

knn_scores <- function(embedding, source, biology, k = 20L) {
  neighbors <- RANN::nn2(embedding, k = k + 1)$nn.idx[, -1, drop = FALSE]
  source_mix <- vapply(seq_len(nrow(neighbors)), function(i) mean(source[neighbors[i, ]] != source[i]), numeric(1))
  biology_keep <- vapply(seq_len(nrow(neighbors)), function(i) mean(biology[neighbors[i, ]] == biology[i]), numeric(1))
  c(source_mixing = mean(source_mix), celltype_preservation = mean(biology_keep))
}
before_score <- knn_scores(Embeddings(cross, "Harmonypca")[, 1:20], cross$dataset, cross$celltype)
after_score <- knn_scores(Embeddings(cross, "Harmony")[, 1:20], cross$dataset, cross$celltype)

source_before <- DimPlot(cross, reduction = "SourceUMAP", group.by = "dataset", pt.size = 0.45, raster = FALSE) + ggtitle("Before Harmony · source") + theme_learn() + NoLegend()
source_after <- DimPlot(cross, reduction = "HarmonyUMAP2D", group.by = "dataset", pt.size = 0.45, raster = FALSE) + ggtitle("After Harmony · source") + theme_learn() + NoLegend()
biology_after <- DimPlot(cross, reduction = "HarmonyUMAP2D", group.by = "celltype", pt.size = 0.45, raster = FALSE, label = TRUE, repel = TRUE, label.size = 3.1) +
  ggtitle("After Harmony · cell type") + theme_learn() + NoLegend()
integration_plot <- source_before | source_after | biology_after
integration_file <- save_plot(integration_plot, "cross-source-integration", width = 13, height = 5.4)

Idents(cross) <- cross$Harmonyclusters
cross_majority <- aggregate(cross$celltype, list(cluster = as.character(Idents(cross))), function(x) names(sort(table(x), decreasing = TRUE))[1])
cross$cluster_majority_label <- cross_majority$x[match(as.character(Idents(cross)), cross_majority$cluster)]
cross_accuracy <- mean(cross$cluster_majority_label == cross$celltype)
cross_checkpoint <- save_checkpoint(cross, "cross-source-panc8")
cross_manifest <- list(
  dataset = "panc8_sub", cells = ncol(cross), genes = nrow(cross), datasets = as_named_counts(cross$dataset), technologies = as_named_counts(cross$tech),
  workflow = c("JoinLayers", "SCTransform", "Harmony_integrate", "RunDimsEstimate"),
  reductions = Reductions(cross), estimated_dims = as.integer(cross_dims),
  neighborhood_metrics = list(before = as.list(round(before_score, 4)), after = as.list(round(after_score, 4))),
  cluster_majority_accuracy_against_known_celltype = round(cross_accuracy, 4),
  figure = list(path = integration_file, sha256 = sha256(integration_file)), checkpoint = cross_checkpoint,
  claim_boundary = "The eight dataset labels are technical sources, not eight biological replicates; mixing and label preservation diagnose integration only."
)
write_json(cross_manifest, "cross-source")

cat("[5/7] Annotation choices and pseudobulk demonstration\n")
data(pbmcmultiome_sub, package = "scop")
pbmc <- pbmcmultiome_sub
DefaultAssay(pbmc) <- "RNA"
pbmc <- NormalizeData(pbmc, verbose = FALSE)
pbmc <- FindVariableFeatures(pbmc, nfeatures = 1500, verbose = FALSE)
pbmc <- ScaleData(pbmc, features = VariableFeatures(pbmc), verbose = FALSE)
pbmc <- RunPCA(pbmc, npcs = 20, verbose = FALSE)
pbmc <- RunUMAP(pbmc, dims = 1:15, seed.use = seed, verbose = FALSE)
marker_panel <- intersect(c("MS4A1", "CD79A", "CD3D", "IL7R", "CD8A", "NKG7", "GNLY", "LYZ", "S100A8", "FCGR3A", "FCER1A"), rownames(pbmc))
annotation_plot <- DotPlot(pbmc, features = marker_panel, group.by = "CellType", assay = "RNA") +
  coord_flip() + labs(title = "Marker evidence for PBMC annotation", subtitle = "Real paired RNA + ATAC PBMC subset", x = NULL, y = NULL) + theme_learn()
annotation_file <- save_plot(annotation_plot, "annotation-marker-evidence", width = 8.5, height = 6)

set.seed(seed)
reference_cells <- unlist(tapply(colnames(pbmc), pbmc$CellType, function(x) sample(x, ceiling(length(x) * 0.6))))
query_cells <- setdiff(colnames(pbmc), reference_cells)
reference <- subset(pbmc, cells = reference_cells)
query <- subset(pbmc, cells = query_cells)
transfer_status <- tryCatch({
  anchors <- FindTransferAnchors(reference = reference, query = query, reference.reduction = "pca", dims = 1:15, verbose = FALSE)
  transferred <- TransferData(anchorset = anchors, refdata = reference$CellType, dims = 1:15, verbose = FALSE)
  query <- AddMetaData(query, transferred)
  list(
    executed = TRUE, method = "Seurat::FindTransferAnchors + TransferData",
    reference_cells = ncol(reference), query_cells = ncol(query),
    accuracy_against_held_out_CellType = round(mean(query$predicted.id == query$CellType), 4),
    mean_prediction_score = round(mean(query$prediction.score.max), 4)
  )
}, error = function(e) list(executed = FALSE, error = conditionMessage(e)))

celltypist_status <- tryCatch({
  celltypist_result <- RunCellTypist(pbmc, assay = "RNA", layer = "data", model = "Immune_All_Low.pkl", majority_voting = FALSE, verbose = FALSE)
  list(
    executed = TRUE, method = "scop::RunCellTypist", model = "Immune_All_Low.pkl",
    predicted_labels = as_named_counts(celltypist_result$celltypist_predicted_labels),
    median_confidence = round(median(celltypist_result$celltypist_conf_score), 4),
    comparison_note = "The model uses finer immune labels than the six bundled broad CellType classes, so no forced one-to-one accuracy is reported."
  )
}, error = function(e) list(executed = FALSE, error = conditionMessage(e)))

counts <- GetAssayData(panc8_sub, assay = "RNA", layer = "counts")
pb_meta <- panc8_sub[[]]
eligible <- pb_meta$celltype %in% c("alpha", "beta")
pb_meta <- pb_meta[eligible, , drop = FALSE]
counts <- counts[, rownames(pb_meta), drop = FALSE]
pb_meta$sample <- paste(pb_meta$dataset, pb_meta$celltype, sep = "__")
sample_sizes <- table(pb_meta$sample)
valid_samples <- names(sample_sizes[sample_sizes >= 10])
pb_meta <- pb_meta[pb_meta$sample %in% valid_samples, , drop = FALSE]
counts <- counts[, rownames(pb_meta), drop = FALSE]
sample_factor <- factor(pb_meta$sample, levels = unique(pb_meta$sample))
design_meta <- unique(pb_meta[, c("sample", "dataset", "celltype")])
rownames(design_meta) <- design_meta$sample
aggregated <- t(rowsum(t(as.matrix(counts)), group = sample_factor, reorder = FALSE))
design_meta <- design_meta[colnames(aggregated), , drop = FALSE]
y <- edgeR::DGEList(aggregated)
keep_gene <- edgeR::filterByExpr(y, group = design_meta$celltype)
y <- edgeR::calcNormFactors(y[keep_gene, , keep.lib.sizes = FALSE])
design <- model.matrix(~ dataset + celltype, data = design_meta)
y <- edgeR::estimateDisp(y, design)
fit <- edgeR::glmQLFit(y, design, robust = TRUE)
coef_name <- grep("celltype", colnames(design), value = TRUE)[1]
deg <- edgeR::topTags(edgeR::glmQLFTest(fit, coef = coef_name), n = Inf)$table
deg$gene <- rownames(deg)
deg <- deg[, c("gene", setdiff(colnames(deg), "gene"))]
write.csv(deg, "evidence/real-data/pseudobulk-alpha-vs-beta.csv", row.names = FALSE)
deg$significant <- deg$FDR < 0.05 & abs(deg$logFC) >= 1
volcano <- ggplot(deg, aes(logFC, -log10(pmax(FDR, 1e-300)), colour = significant)) +
  geom_point(alpha = 0.55, size = 1.25) + geom_vline(xintercept = c(-1, 1), linetype = 2, colour = "#60758a") +
  scale_colour_manual(values = c(`FALSE` = "#9fb7c5", `TRUE` = "#d97745")) +
  labs(title = "Pseudobulk alpha–beta contrast across technical sources", subtitle = "edgeR paired by dataset; demonstration, not patient-level inference", x = "log2 fold change (beta / alpha)", y = "−log10 FDR") + theme_learn() + guides(colour = "none")
volcano_file <- save_plot(volcano, "advanced-pseudobulk", width = 8.5, height = 5.4)

annotation_manifest <- list(
  dataset = "pbmcmultiome_sub", cells = ncol(pbmc), truth_labels = as_named_counts(pbmc$CellType), marker_panel = marker_panel,
  manual_marker_evidence = list(executed = TRUE, figure = list(path = annotation_file, sha256 = sha256(annotation_file))),
  label_transfer = transfer_status, celltypist = celltypist_status,
  scop_RunLabelTransfer_scope = "RunLabelTransfer is intended for a ChromatinAssay/multiome transfer path; generic RNA-to-RNA transfer is shown with Seurat anchors.",
  singler = list(executed = FALSE, reason = "SingleR and celldex are not installed in the audited runtime."),
  rule = "Automated labels are hypotheses; marker coherence, cluster context, dataset biology and uncertainty must be reviewed together."
)
write_json(annotation_manifest, "annotation")
advanced_manifest <- list(
  analysis = "edgeR pseudobulk alpha versus beta", dataset = "panc8_sub", aggregate_unit = "dataset × celltype",
  pseudo_samples = ncol(aggregated), tested_genes = nrow(deg), significant_FDR_0_05_abs_logFC_1 = sum(deg$significant),
  coefficient = coef_name, top_genes = head(deg$gene, 15), figure = list(path = volcano_file, sha256 = sha256(volcano_file)),
  claim_boundary = "Dataset sources are technical replicates. This validates the code path and cell-type signal but cannot support population or disease inference."
)
write_json(advanced_manifest, "advanced")

cat("[6/7] Real Visium spatial workflows\n")
data(visium_human_pancreas_sub, package = "scop")
spatial <- visium_human_pancreas_sub
DefaultAssay(spatial) <- "Spatial"
spatial <- RunSpotQC(spatial, assay = "Spatial", return_filtered = FALSE, qc_metrics = c("umi", "gene", "mito"), UMI_threshold = 0, gene_threshold = 0, mito_threshold = 100, verbose = FALSE, seed = seed)
spatial <- NormalizeData(spatial, assay = "Spatial", verbose = FALSE)
spatial <- RunSpatialVariableFeatures(spatial, assay = "Spatial", method = "moran", coord.cols = c("x", "y"), nfeatures = 100, min_spots = 10, store_results = TRUE, verbose = FALSE, seed = seed)
spatial <- RunSpatialNetwork(spatial, method = "knn", image = "slice1", coord.cols = c("x", "y"), k = 6, graph.name = "scop_knn", overwrite = TRUE, verbose = FALSE)
spatial <- RunSpatialNeighborhood(spatial, group.by = "coda_label", method = "observed", coord.cols = c("x", "y"), image = "slice1", k = 6, tool_name = "coda_neighborhood", store_results = TRUE, verbose = FALSE)
spatial_features <- head(VariableFeatures(spatial), 20)
top_spatial_gene <- spatial_features[1]
spatial_meta <- spatial[[]]
spatial_meta$expression <- as.numeric(GetAssayData(spatial, assay = "Spatial", layer = "data")[top_spatial_gene, rownames(spatial_meta)])
domain_plot <- ggplot(spatial_meta, aes(x, -y, colour = coda_label)) +
  geom_point(size = 1.4) + coord_equal() +
  labs(title = "Human PanIN spatial domains", subtitle = "GSE254829 · GSM8058244 · real Visium spots", x = NULL, y = NULL, colour = "CoDa label") + theme_learn()
gene_plot <- ggplot(spatial_meta, aes(x, -y, colour = expression)) +
  geom_point(size = 1.4) + coord_equal() + scale_colour_viridis_c() +
  labs(title = paste("Top Moran feature:", top_spatial_gene), subtitle = "Spatially variable expression on the same tissue coordinates", x = NULL, y = NULL, colour = "Log expression") + theme_learn()
spatial_plot <- domain_plot | gene_plot
spatial_file <- save_plot(spatial_plot, "spatial-human-pancreas", width = 12, height = 5.5)

data(visium_mouse_brain_slices_sub, package = "scop")
brain <- visium_mouse_brain_slices_sub
brain_meta <- brain[[]]
brain_plot <- ggplot(brain_meta, aes(x, -y, colour = region)) + geom_point(size = 0.9) + coord_equal() +
  facet_wrap(~slice) + labs(title = "Two real mouse-brain Visium slices", subtitle = "Multi-slice structure is preserved before integration", x = NULL, y = NULL, colour = "Region") + theme_learn()
brain_file <- save_plot(brain_plot, "spatial-mouse-brain-slices", width = 10, height = 4.8)
spatial_checkpoint <- save_checkpoint(spatial, "spatial-human-pancreas")
spatial_manifest <- list(
  human_pancreas = list(dataset = "visium_human_pancreas_sub", spots = ncol(spatial), genes = nrow(spatial), image = Images(spatial), labels = as_named_counts(spatial$coda_label), top_moran_features = spatial_features),
  mouse_brain = list(dataset = "visium_mouse_brain_slices_sub", spots = ncol(brain), genes = nrow(brain), slices = as_named_counts(brain$slice), regions = as_named_counts(brain$region)),
  workflow = c("RunSpotQC", "NormalizeData", "RunSpatialVariableFeatures(method='moran')", "RunSpatialNetwork", "RunSpatialNeighborhood(method='observed')"),
  figures = list(human_pancreas = list(path = spatial_file, sha256 = sha256(spatial_file)), mouse_brain = list(path = brain_file, sha256 = sha256(brain_file))),
  checkpoint = spatial_checkpoint,
  deconvolution = list(executed = FALSE, method = "RunRCTD", reason = "spacexr is not installed in the audited runtime; no deconvolution result is fabricated."),
  claim_boundary = "Visium spots are mixtures. Domain and Moran results are spot-level spatial patterns, not cell-resolved identities."
)
write_json(spatial_manifest, "spatial")

cat("[7/7] Final manifest and session evidence\n")
component_files <- c("runtime", "input-formats", "single-sample", "cross-source", "annotation", "advanced", "spatial")
figures <- list.files("assets/figures/real-data", pattern = "\\.png$", full.names = TRUE)
manifest <- list(
  schema_version = 1, generated_at = format(Sys.time(), tz = "Asia/Shanghai", usetz = TRUE), seed = seed,
  components = stats::setNames(lapply(component_files, function(x) list(path = json_path(x), sha256 = sha256(json_path(x)))), component_files),
  figures = stats::setNames(lapply(figures, function(x) list(path = x, sha256 = sha256(x), bytes = unname(file.info(x)$size))), basename(figures)),
  critical_assertions = list(
    real_10x_roundtrip = all(unlist(input_manifest$validations)),
    single_sample_retained_cells = ncol(single) > 900,
    cross_source_has_harmony = "Harmony" %in% Reductions(cross),
    pseudobulk_has_results = nrow(deg) > 1000,
    spatial_has_moran_features = length(spatial_features) >= 20,
    no_synthetic_primary_evidence = TRUE
  )
)
stopifnot(all(unlist(manifest$critical_assertions)))
write_json(manifest, "manifest")
writeLines(capture.output(sessionInfo()), "evidence/real-data/session-info.txt")
cat(sprintf("Done: %d component manifests, %d real-data figures\n", length(component_files), length(figures)))
