# Pages rollback record

Rollback policy for `Carl6231/scop-learn`:

1. Identify the last production commit shown in the site footer and the GitHub Actions Pages deployment.
2. Revert the offending change through a pull request, or dispatch the Pages workflow from the last known-good commit.
3. Verify the public root, `/zh/` root, 404 route, search index, and case assets after rollback.
4. Record the restored commit, deployment run, public URL checks, and reason in this file.

The initial production commit and deployment run are filled after the first public deployment. No manual edits to a compiled Pages branch are permitted.
