#!/usr/bin/env python3
"""Verify curriculum depth, bilingual parity, and SCOP-native figure provenance."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PAGES = (
    "index",
    "start-here",
    "datasets",
    "input-formats",
    "concepts",
    "single-cell-case",
    "multi-sample",
    "annotation",
    "advanced",
    "spatial-case",
    "paper-framework",
    "reproducibility",
    "troubleshooting",
    "reference",
)
WORKFLOW_PAGES = (
    "input-formats",
    "single-cell-case",
    "multi-sample",
    "annotation",
    "advanced",
    "spatial-case",
)
FIGURE_RE = re.compile(r"!\[[^\]]*\]\((?:\.\./)?assets/figures/real-data/([^\)]+\.png)\)")


def fail(message: str) -> None:
    raise SystemExit(message)


def read(path: Path) -> str:
    if not path.is_file():
        fail(f"Missing required curriculum file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def require(text: str, token: str, path: Path) -> None:
    if token not in text:
        fail(f"{path.relative_to(ROOT)} is missing required teaching contract: {token}")


def main() -> None:
    manifest_path = ROOT / "evidence/real-data/manifest.json"
    manifest = json.loads(read(manifest_path))
    figures = manifest.get("figures", {})
    assertions = manifest.get("critical_assertions", {})

    if len(figures) != 11:
        fail(f"Expected exactly 11 registered real-data figures, found {len(figures)}")
    if not assertions or not all(assertions.values()):
        fail(f"Critical evidence assertions failed: {assertions}")
    if assertions.get("all_analysis_figures_use_scop_plotters") is not True:
        fail("Missing SCOP-native plotter assertion")

    for name, item in figures.items():
        for field in ("path", "sha256", "bytes", "plot_function", "dataset", "source_checkpoint"):
            if not item.get(field):
                fail(f"Figure {name} lacks provenance field {field}")
        plotters = item["plot_function"].split(" + ")
        if not plotters or not all(plotter.startswith("scop::") for plotter in plotters):
            fail(f"Figure {name} is not exclusively SCOP-native: {item['plot_function']}")
        if not (ROOT / item["path"]).is_file():
            fail(f"Registered figure does not exist: {item['path']}")

    referenced_figures: set[str] = set()
    for page in PAGES:
        en_path = ROOT / f"{page}.qmd"
        zh_path = ROOT / "zh" / f"{page}.qmd"
        en = read(en_path)
        zh = read(zh_path)

        minimum_en = 5_000 if page == "index" else 7_500
        # Chinese prose carries more information per Unicode code point than English.
        minimum_zh = 3_500 if page == "index" else 6_500
        if len(en) < minimum_en:
            fail(f"{en_path.relative_to(ROOT)} is too short: {len(en)} < {minimum_en} characters")
        if len(zh) < minimum_zh:
            fail(f"{zh_path.relative_to(ROOT)} is too short: {len(zh)} < {minimum_zh} characters")

        require(en, "::: {.boundary}", en_path)
        require(zh, "::: {.boundary}", zh_path)
        if page != "index":
            for token in ("## Learning outcomes", "::: {.checkpoint}", "::: {.exercise}"):
                require(en, token, en_path)
            for token in ("## 学习目标", "::: {.checkpoint}", "::: {.exercise}"):
                require(zh, token, zh_path)

        if page in WORKFLOW_PAGES:
            if len(en) < 10_000 or len(zh) < 8_000:
                fail(f"Workflow page {page} does not meet the detailed lesson size gate")
            require(en, "::: {.input-contract}", en_path)
            require(zh, "::: {.input-contract}", zh_path)
            if en.count("```r") < 8 or zh.count("```r") < 8:
                fail(f"Workflow page {page} must contain at least eight R code blocks per language")

        for path, text in ((en_path, en), (zh_path, zh)):
            page_figures = FIGURE_RE.findall(text)
            if len(page_figures) != text.count("::: {.scop-native}"):
                fail(
                    f"{path.relative_to(ROOT)} must provide one SCOP-native provenance block "
                    f"per analysis image: {len(page_figures)} images vs "
                    f"{text.count('::: {.scop-native}')} blocks"
                )
            for name in page_figures:
                if name not in figures:
                    fail(f"{path.relative_to(ROOT)} references unregistered analysis figure {name}")
                referenced_figures.add(name)

    unreferenced = set(figures) - referenced_figures
    if unreferenced:
        fail(f"Registered analysis figures are absent from the curriculum: {sorted(unreferenced)}")

    builder = read(ROOT / "scripts/build-real-evidence.R")
    forbidden = {
        "raw ggplot": r"(?<![A-Za-z0-9_])ggplot\(",
        "Seurat DimPlot": r"(?<![A-Za-z0-9_])DimPlot\(",
        "Seurat DotPlot": r"(?<![A-Za-z0-9_])DotPlot\(",
        "Seurat VlnPlot": r"(?<![A-Za-z0-9_])VlnPlot\(",
    }
    for label, pattern in forbidden.items():
        if re.search(pattern, builder):
            fail(f"Evidence builder contains forbidden non-SCOP analysis plot: {label}")

    print(
        f"Verified {len(PAGES)} bilingual page pairs, {len(WORKFLOW_PAGES)} detailed "
        f"workflow pairs, and {len(figures)} SCOP-native registered figures"
    )


if __name__ == "__main__":
    main()
