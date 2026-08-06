# SCOP Learn

SCOP Learn is a bilingual, source-grounded teaching site for the SCOP R package. It is separate from SCOP Studio and links to the upstream function reference rather than duplicating it.

The initial complete cases were executed locally with SCOP 0.8.9 and R 4.5.1 using fixed-seed synthetic inputs. Optional backends are labeled when they are not installed or not executed.

Local preview requires Quarto 1.10.18 or later:

```bash
Rscript scripts/single-cell-case.R
Rscript scripts/spatial-case.R
quarto render
quarto preview
```
