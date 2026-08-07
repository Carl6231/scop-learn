# Pages rollback record

Rollback policy for `Carl6231/scop-learn`:

1. Identify the last production commit shown in the site footer and the GitHub Actions Pages deployment.
2. Revert the offending change through a pull request, or dispatch the Pages workflow from the last known-good commit.
3. Verify the public root, `/zh/` root, 404 route, search index, and case assets after rollback.
4. Record the restored commit, deployment run, public URL checks, and reason in this file.

## Initial production record

- Known-good commit: `054bd58b85ff5f61c9fb493746c0757f26cd72bf`
- Successful Pages workflow run: `31127622938` ([run](https://github.com/Carl6231/scop-learn/actions/runs/31127622938))
- Successful Pages deployment: `5784717615` (environment `github-pages`, ref `main`)
- Production root: <https://carl6231.github.io/scop-learn/> — HTTP 200
- Simplified Chinese root: <https://carl6231.github.io/scop-learn/zh/> — HTTP 200
- 404 route: <https://carl6231.github.io/scop-learn/404.html> — HTTP 200
- Production browser checks: root/Chinese route headings, stamped commit, search, and 390px overflow checks passed.
- The first queued dispatch (`31127536198`) failed before a job was assigned; it was superseded by the successful run above. A duplicate dispatch (`31127737189`) was cancelled after the successful deployment and did not alter production.

## 2026-08-07 real-data curriculum release

- Known-good curriculum commit: `347507fccec663471876fd46546d0911ed400bd6`
- Previous known-good production commit: `2dc1cb0112d3b72b6c2e6a93776c419abe372f31`
- Successful quality workflow run: `31200383891` ([run](https://github.com/Carl6231/scop-learn/actions/runs/31200383891))
- Successful Pages workflow run: `31200384397` ([run](https://github.com/Carl6231/scop-learn/actions/runs/31200384397))
- Successful Pages deployment: `5798719985` (environment `github-pages`, ref `main`)
- Production verification: all 8 real-data PNGs, `search.json`, `sitemap.xml`, `robots.txt`, `404.html`, the English root, and the Chinese root returned HTTP 200. The deployed pages exposed the stamped curriculum commit; desktop, 390px mobile, and JavaScript-disabled content checks passed.

If this curriculum release must be rolled back, open a pull request that reverts commit `347507fccec663471876fd46546d0911ed400bd6`. Do not force-push or reset protected `main`. After the revert is merged, require a successful quality run and Pages deployment, then repeat the verification list above. Later documentation-only commits may change the footer build stamp without changing this curriculum baseline; the Pages workflow and public footer remain authoritative for the currently deployed source commit.

## 2026-08-08 detailed SCOP-native curriculum release

- Known-good detailed curriculum commit: `456e4d40cf0b57ce7aeed1791d3bddaaf116dc4b`
- Previous known-good production commit: `caa3e533f48471a424a7f4e5957e9759f25df32b`
- Merged pull request: [`#14`](https://github.com/Carl6231/scop-learn/pull/14)
- Successful quality workflow run: `31224650391` ([run](https://github.com/Carl6231/scop-learn/actions/runs/31224650391))
- Successful Pages workflow run: `31224650386` ([run](https://github.com/Carl6231/scop-learn/actions/runs/31224650386))
- Successful Pages deployment: `5803027587` (environment `github-pages`, ref `main`)
- Production verification: the English/Chinese roots, 12 bilingual workflow routes, `404.html`, `search.json`, `sitemap.xml`, `robots.txt`, and all 11 SCOP-native real-data PNGs returned HTTP 200. The public pages exposed the curriculum commit. Desktop, 390px mobile, JavaScript-disabled, accessibility, figure-loading, and horizontal-overflow checks passed.
- Branch-protection restoration: the one-approval rule was restored immediately after merge; strict `quality`, admin enforcement, linear history, conversation resolution, force-push prohibition, and deletion prohibition remained enabled.

If the detailed curriculum must be rolled back, open a pull request that reverts commits `456e4d40cf0b57ce7aeed1791d3bddaaf116dc4b` and `167f629f31c5ca211f5fd6bde5e67bec81f4a516`, or restores the previous known-good tree from `caa3e533f48471a424a7f4e5957e9759f25df32b`. Do not force-push or reset protected `main`. Require a successful quality run and Pages deployment, then repeat every production verification above. This QA-record commit is documentation-only and does not change the detailed curriculum baseline.
