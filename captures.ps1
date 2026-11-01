# Prend des captures d'écran du boîtier et les range dans captures\<date-heure>\, pour les envoyer.
# Sans -Touches : l'écran actuel, l'accueil, le dock, la grille et la bibliothèque d'applis.
# Avec -Touches : une seule capture après ces touches de télécommande (noms Android sans KEYCODE_).
#
# Usage : powershell -ExecutionPolicy Bypass -File captures.ps1 -TvHost 192.168.1.83
#         powershell -ExecutionPolicy Bypass -File captures.ps1 -TvHost 192.168.1.83 -Touches HOME,DPAD_DOWN
param(
    [string[]]$Touches = @(),
    [string]$TvHost = $env:TV_HOST
)
$ErrorActionPreference = 'Stop'
$OutputEncoding = New-Object System.Text.UTF8Encoding $false
if (-not $TvHost) { throw 'Passe -TvHost <ip du boîtier>' }
$env:TV_HOST = $TvHost

$repo = Join-Path $PSScriptRoot 'cleanyourtv'
$py = Join-Path $repo 'tools\venv\Scripts\python.exe'
if (-not (Test-Path $py)) { throw 'Lance d''abord preparer-pc.ps1' }
$tv = Join-Path $repo 'tools\tv.py'
$dossier = Join-Path $PSScriptRoot ('captures\' + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
New-Item -ItemType Directory -Force $dossier | Out-Null

# Chaque capture : un nom et les touches pressées avant (tools\tv.py --screenshot les envoie, puis attend).
# « += , » ajoute le couple tel quel : sans la virgule, PowerShell l'aplatirait dans la liste.
$plan = @()
if ($Touches) {
    $plan += , @('capture', $Touches)
} else {
    $plan += , @('1-ecran-actuel', @())
    $plan += , @('2-accueil', @('HOME'))
    $plan += , @('3-dock', @('HOME', 'DPAD_RIGHT'))
    $plan += , @('4-grille', @('HOME', 'DPAD_DOWN', 'DPAD_DOWN'))
    $plan += , @('5-grille-bas', @('DPAD_DOWN', 'DPAD_DOWN', 'DPAD_DOWN'))
}

foreach ($etape in $plan) {
    $nom = $etape[0]
    $cles = @($etape[1])
    $png = Join-Path $dossier "$nom.png"
    & $py -I $tv --screenshot $png @cles --wait 2
    if ($LASTEXITCODE -ne 0) { Write-Warning "Capture $nom ratée" } else { Write-Host "OK : $nom.png" }
}
# Retour à l'accueil, pour ne pas laisser le boîtier au milieu de la grille.
if (-not $Touches) { & $py -I $tv 'input keyevent KEYCODE_HOME' | Out-Null }
Write-Host "Captures dans $dossier : envoie-les-moi."
