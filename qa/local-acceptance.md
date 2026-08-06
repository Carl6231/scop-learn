# Local acceptance record

Status: PASS for the locally rendered teaching-site candidate

Environment:

- Quarto 1.10.18
- R 4.5.1
- SCOP 0.8.9
- Google Chrome 150.0.7871.189 for browser checks
- axe-core 4.12.1

Checks completed on 2026-08-07:

- `Rscript scripts/single-cell-case.R`: PASS; 80 cells, 120 genes, 2 clusters, PCA and UMAP reductions.
- `Rscript scripts/spatial-case.R`: PASS; 36 spots, 60 genes, 81 KNN edges, ranked spatial features.
- `quarto render`: PASS; 18 English/Chinese routes.
- Internal route and anchor check: PASS; zero broken internal links.
- Search index check: PASS; English and Chinese content present in `search.json`.
- Leakage scan: PASS; no local paths, tokens, localhost values, or sample identifiers in the rendered site.
- Browser check: PASS; desktop, 390px mobile, search, reciprocal language links, one homepage H1, image alt text, and no horizontal overflow.
- axe checks: PASS; 0 violations on English and Chinese home routes.

The two PNG outputs and JSON evidence manifests are the actual inspected case artifacts. Optional `SpatialQM` is explicitly recorded as unavailable in this environment and is not claimed as executed.

Production re-check after Pages deployment: root, `/zh/`, and `404.html` returned HTTP 200; both language titles, search, stamped commit, and 390px mobile overflow checks passed.
