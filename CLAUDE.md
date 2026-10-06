# Notes for Claude

## Commits

- Every commit is by **severd8**: author and committer `severd8 <44451903+severd8@users.noreply.github.com>`. Set it before committing:
  `git config user.name severd8 && git config user.email 44451903+severd8@users.noreply.github.com`
- No `Co-Authored-By`, `Claude-Session` or other Claude lines in commit messages, tags, PR titles or PR bodies.

## Releases

- A version tag (`v1.2.3`) uploads to CurseForge. Tag the commit on `main` and push the tag once; pushing it again uploads a second file.
- See `DEVNOTES.md` for how the addon is put together.
