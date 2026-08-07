# Real-data release acceptance record

Status: PASS for curriculum release `347507fccec663471876fd46546d0911ed400bd6`

Runtime and evidence build:

- Quarto 1.10.18 in GitHub Actions
- R 4.5.1
- SCOP 0.8.9
- Seurat 5.5.0
- axe-core 4.12.1
- deterministic seed `20260807`

Checks completed on 2026-08-07:

- Real-data evidence: PASS; 5 SCOP-bundled datasets plus the public 10x PBMC 1k v3 H5 were used, 8 published figures were generated and inspected, and every component and figure hash matched `evidence/real-data/manifest.json`.
- Input round trip: PASS; 10x H5, 10x three-file, and RDS dimensions and total UMI counts agreed.
- Executed workflow spine: PASS; single-sample QC and doublet detection, Seurat v5 layer joining, cluster-tree and dimension selection, SCT plus Harmony cross-source integration, marker and reference-based annotation, CellTypist, edgeR pseudobulk, and spatial QC/feature/network/neighbourhood analyses all produced recorded results.
- Honest execution states: PASS; unavailable H5AD/Loom conversion backends, SingleR, RCTD, and unsupported biological claims remain explicitly marked as not executed or not established.
- Quarto render: PASS; 30 English/Chinese HTML routes rendered in quality run [`31200383891`](https://github.com/Carl6231/scop-learn/actions/runs/31200383891).
- Link and structure checks: PASS; 30 routes, internal links, anchors, main/nav landmarks, image alt text, and 64 HTTPS links passed.
- Metadata and publishing assets: PASS; canonical URLs, reciprocal `en`/`zh-Hans`/`x-default` alternates, descriptions, social preview, favicon, `robots.txt`, and `sitemap.xml` passed.
- Leakage scan: PASS; no local paths, tokens, localhost values, or sample identifiers were found in the rendered site.
- Accessibility automation: PASS; axe-core reported 0 violations on the English and Chinese home routes. Automated coverage is supplemented by manual visual inspection.
- Production assets: PASS; all 8 real-data PNGs, `search.json`, `sitemap.xml`, `robots.txt`, and `404.html` returned HTTP 200.
- Responsive production view: PASS; the public English home page was visually inspected at a 390 × 844 CSS-pixel viewport, with the hero, evidence counters, curriculum cards, result figure, boundary notice, and footer readable in a single-column layout.
- No-JavaScript resilience: PASS; JavaScript-disabled production HTML still exposed the page H1, core curriculum description, and stamped commit.
- Build identity: PASS; the public English and Chinese pages exposed commit `347507fccec663471876fd46546d0911ed400bd6`, and Pages deployment `5798719985` completed successfully.

Claim boundary: this acceptance record validates a reproducible teaching workflow and its named outputs. It does not turn technical dataset sources into patient replicates, establish new biological discoveries, or claim execution for missing optional backends.
