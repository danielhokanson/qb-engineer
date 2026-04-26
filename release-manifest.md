# Release Manifest

Each row is a tested combination of sibling repo versions that ship
together as a release of the qb-engineer platform.

When installing, pull the sibling versions named in the row matching the
master tag you're targeting. The `qb-engineer-deploy` repo's
`docker-compose.yml` references the `qb-engineer-ui` and
`qb-engineer-server` image tags by version, so checking out the right
deploy tag automatically pulls the right images.

## Releases

| Master tag | UI | Server | Deploy | Test | Notes |
|---|---|---|---|---|---|
| `v0.0.1` | `v0.0.1` | `v0.0.1` | `v0.0.1` | `v0.0.1` | Initial extraction from monorepo. Same code as `qb-engineer-wrapper@7820bdd` (the last commit before the split). |

## How to release

1. Pick the sibling versions to bundle. They must already be tagged in
   their own repos.
2. Update `qb-engineer-deploy/docker-compose.yml` to reference the
   chosen image tags. Tag and release `qb-engineer-deploy`.
3. Add a row to this manifest with the master tag + sibling versions.
4. Tag this repo (`git tag -a vX.Y.Z -m "..."`) and push.
5. Create a GitHub release on this repo summarizing what's in the bundle
   (link the sibling release pages for full changelogs).

## Versioning policy

- **Independent semver per repo.** A bug fix in the UI doesn't bump the
  server's version.
- **Master version is set by the maintainer**, not auto-derived. Use it
  to signal "this is a recommended bundle" — typically minor or patch
  for refreshes, major when the platform behavior changes meaningfully.
- **Breaking API changes** (server major bump) MUST coincide with a UI
  major bump that consumes the new contract. The master tag MAY (but
  doesn't have to) bump major to flag the discontinuity to users.
