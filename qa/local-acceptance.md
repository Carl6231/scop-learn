# Detailed SCOP-native curriculum release acceptance record

Status: PASS for curriculum release `456e4d40cf0b57ce7aeed1791d3bddaaf116dc4b`

Runtime and evidence build:

- Quarto 1.10.18 locally and in GitHub Actions
- R 4.5.1
- SCOP 0.8.9
- Seurat 5.5.0
- axe-core 4.12.1
- deterministic seed `20260807`

Checks completed on 2026-08-08:

- Real-data evidence: PASS; five SCOP-bundled datasets plus the public 10x PBMC 1k v3 H5 were used, seven component manifests and 11 published analysis figures were rebuilt, and every committed component and figure hash matched `evidence/real-data/manifest.json`.
- SCOP-native figure gate: PASS; all 11 analysis images declare SCOP plotters only. Every manifest record contains the dataset, plot function, source checkpoint path, source SHA-256, byte size, and rebuild script. The actual source-resolution PNGs were inspected after the final rebuild.
- Input round trip: PASS; 10x H5, 10x three-file, and RDS dimensions and total UMI counts agreed. H5AD, Loom, and optional backend paths remain explicitly separated from executed results.
- Executed workflow spine: PASS; single-sample QC and doublet detection, Seurat v5 layer joining, cluster-tree and dimension selection, SCT plus Harmony cross-source integration, marker and reference-based annotation, CellTypist, edgeR pseudobulk, and spatial QC/feature/network/neighbourhood analyses produced recorded results.
- Curriculum contract: PASS; 14 English pages and 14 Chinese counterparts meet semantic topic gates. The six substantive workflow pairs contain explicit biological questions, input contracts, code, checkpoints, failure modes, exercises, and claim boundaries. All 233 R code blocks parsed successfully.
- Advanced scope: PASS; perturbation response, virtual knockout, and spatial validation now include exact SCOP 0.8.9 calls, prerequisites, interpretation, and stop rules. Unavailable SingleR, RCTD, and other optional backends are marked as not executed instead of receiving placeholder results.
- Quarto render: PASS; 30 English/Chinese HTML routes rendered locally and in quality run [`31224650391`](https://github.com/Carl6231/scop-learn/actions/runs/31224650391).
- Link and structure checks: PASS; all 30 routes, internal links, anchors, main/navigation landmarks, image alt text, and 64 HTTPS links passed.
- Metadata and publishing assets: PASS; canonical URLs, reciprocal `en`/`zh-Hans`/`x-default` alternates, descriptions, social preview, favicon, `robots.txt`, and `sitemap.xml` passed.
- Leakage scan: PASS; no local paths, tokens, localhost values, or sample identifiers were found in the rendered site.
- Accessibility automation: PASS; axe-core reported zero violations on the English and Chinese home routes. Automated coverage is supplemented by manual visual inspection.
- Local responsive audit: PASS; 12 bilingual workflow routes were checked at 1440 × 1000 and 390 × 844 CSS pixels, 22 rendered figure placements were checked on mobile, and 46 screenshots were captured. A discovered mobile overflow in wide tables, source code, inline identifiers, and long headings was fixed and rechecked.
- All-route mobile/no-JavaScript audit: PASS; all 30 routes exposed one H1 and core content at 390 × 844 with JavaScript disabled and no document-level horizontal overflow.
- Production HTTP audit: PASS; the English/Chinese roots, 12 workflow routes, `404.html`, `search.json`, `sitemap.xml`, `robots.txt`, and all 11 real-data PNGs returned HTTP 200. Two transient connection resets passed on retry and did not indicate missing assets.
- Production browser audit: PASS; 12 bilingual workflow routes passed desktop/mobile layout, deployed-commit, H1, content, and image-loading checks. All 22 figure placements loaded in both desktop and mobile contexts, yielding 44 successful production figure instances; representative screenshots were manually inspected. JavaScript-disabled English and Chinese roots retained core content and the deployed commit stamp.
- Build identity: PASS; public English and Chinese pages exposed commit `456e4d40cf0b57ce7aeed1791d3bddaaf116dc4b`. Pages run [`31224650386`](https://github.com/Carl6231/scop-learn/actions/runs/31224650386) and deployment `5803027587` completed successfully.
- Protected-main controls: PASS; PR [`#14`](https://github.com/Carl6231/scop-learn/pull/14) merged only after the required `quality` check passed. The one-review setting temporarily removed for the single-account merge was restored exactly: stale reviews dismissed, code-owner review disabled, last-push approval disabled, and one approving review required. Strict quality checks, admin enforcement, linear history, conversation resolution, force-push prohibition, and deletion prohibition remained in force.

Claim boundary: this acceptance record validates a reproducible teaching workflow, detailed learning contracts, named outputs, and the deployed presentation. It does not turn technical dataset sources into patient replicates, establish new biological discoveries, claim execution for missing optional backends, or guarantee that the templates fit a new study without a study-specific design review.
