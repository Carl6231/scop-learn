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

## Current production record

- Current deployed commit: `edfdf6a2bf55a2532612eba4857feb44493e1f67`
- Successful quality workflow run: `31129178994` ([run](https://github.com/Carl6231/scop-learn/actions/runs/31129178994))
- Successful Pages workflow run: `31129202917` ([run](https://github.com/Carl6231/scop-learn/actions/runs/31129202917))
- Successful Pages deployment: `5785562372` (environment `github-pages`, ref `main`)
- Production verification: root, `/zh/`, and `404.html` returned HTTP 200; canonical/alternate metadata, PNG social card, favicon, search, stamped commit, keyboard skip link, 390px overflow, no-JavaScript content, and axe-core home audits passed.
