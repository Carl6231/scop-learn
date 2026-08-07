# SCOP Learn

SCOP Learn is a bilingual, real-data curriculum for the SCOP R package. It covers file input, single-sample and multi-sample construction, cross-source integration, cell annotation, paper-oriented advanced analysis, and spatial transcriptomics. It remains separate from SCOP Studio and routes exact function documentation to the upstream reference.

The primary evidence was executed locally with SCOP 0.8.9, R 4.5.1, and Seurat 5.5.0 using five datasets bundled with SCOP plus the official 10x PBMC 1k v3 H5. Generated JSON manifests hash the published figures and record executed, unavailable, and claim-bounded steps.

## Rebuild the evidence

```bash
mkdir -p artifacts/real-data/input
curl -L --fail \
  -o artifacts/real-data/input/pbmc_1k_v3_filtered_feature_bc_matrix.h5 \
  https://cf.10xgenomics.com/samples/cell-exp/3.0.0/pbmc_1k_v3/pbmc_1k_v3_filtered_feature_bc_matrix.h5
Rscript scripts/build-real-evidence.R
```

The expected source H5 SHA-256 is `8191f576550c1b449d03441b9eb098ee9f73fa82513d171ba87d31d551e3ffda`.

## Render the site

Local preview requires Quarto 1.10.18 or later:

```bash
quarto render
quarto preview
```

Large restartable RDS checkpoints live under ignored `artifacts/`; their paths, sizes, and hashes are recorded in the committed component manifests. The older synthetic scripts are retained only as code-level smoke tests and are not primary curriculum evidence.
