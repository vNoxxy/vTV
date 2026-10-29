# Prépare le PC Windows pour nettoyer la TV : récupère cleanyourtv à la version épinglée dans
# cleanyourtv.commit, crée l'environnement Python de ses outils et place l'APK compilé par
# GitHub Actions là où launcher\build-and-install.ps1 l'attend avec SKIP_BUILD=1.
#
# Usage : powershell -ExecutionPolicy Bypass -File preparer-pc.ps1 -Apk C:\chemin\app-release.apk
param(
    [Parameter(Mandatory = $true)][string]$Apk
)
$ErrorActionPreference = 'Stop'

foreach ($cmd in 'git', 'python') {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { throw "$cmd est introuvable : installe-le (voir README) puis relance." }
}
if (-not (Test-Path $Apk)) { throw "APK introuvable : $Apk" }

$commit = (Get-Content (Join-Path $PSScriptRoot 'cleanyourtv.commit') -Raw).Trim()
$dest = Join-Path $PSScriptRoot 'cleanyourtv'

# Seulement le commit épinglé, sans l'historique : le dépôt complet est lourd (images des thèmes).
if (-not (Test-Path (Join-Path $dest '.git'))) {
    git init -q $dest
    git -C $dest remote add origin https://github.com/Gathin23/cleanyourtv
}
git -C $dest fetch -q --depth 1 origin $commit
if ($LASTEXITCODE -ne 0) { throw 'Téléchargement de cleanyourtv échoué' }
git -C $dest checkout -q FETCH_HEAD
if ($LASTEXITCODE -ne 0) { throw 'Checkout de cleanyourtv échoué' }

$py = Join-Path $dest 'tools\venv\Scripts\python.exe'
if (-not (Test-Path $py)) {
    python -m venv (Join-Path $dest 'tools\venv')
    if ($LASTEXITCODE -ne 0) { throw 'Création du venv Python échouée' }
}
& $py -m pip install -q -r (Join-Path $dest 'tools\requirements.txt')
if ($LASTEXITCODE -ne 0) { throw 'Installation des dépendances Python échouée' }

$out = Join-Path $dest 'launcher\app\build\outputs\apk\release'
New-Item -ItemType Directory -Force $out | Out-Null
Copy-Item $Apk (Join-Path $out 'app-release.apk') -Force

Write-Host "Prêt. cleanyourtv est dans $dest (version $commit)."
