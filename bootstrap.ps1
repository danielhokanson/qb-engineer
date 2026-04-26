# bootstrap.ps1 — clone all qb-engineer sibling repos as siblings of this one.
#
# Run from inside the qb-engineer\ directory after a fresh clone.
# Idempotent: skips repos that already exist; runs `git pull` instead.

$ErrorActionPreference = "Stop"

$OWNER = "danielhokanson"
$SIBLINGS = @("qb-engineer-ui", "qb-engineer-server", "qb-engineer-deploy", "qb-engineer-test")

$PARENT_DIR = (Resolve-Path ..).Path

Write-Host "Bootstrapping qb-engineer siblings into: $PARENT_DIR"
Write-Host ""

foreach ($repo in $SIBLINGS) {
    $target = Join-Path $PARENT_DIR $repo
    if (Test-Path (Join-Path $target ".git")) {
        Write-Host "  $repo`: already cloned, pulling latest"
        Push-Location $target
        try { git pull --ff-only } catch { Write-Host "    (skipped — local changes?)" }
        Pop-Location
    } else {
        Write-Host "  $repo`: cloning"
        git clone "https://github.com/$OWNER/$repo.git" $target
    }
}

Write-Host ""
Write-Host "Done. Sibling layout:"
Get-ChildItem -Directory -Path $PARENT_DIR -Filter "qb-engineer*" | Select-Object -ExpandProperty FullName
Write-Host ""
Write-Host "Next: cd ..\qb-engineer-deploy ; .\setup.ps1"
