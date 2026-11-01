# Prend des captures d'écran du boîtier et les range dans captures\<date-heure>\, pour les envoyer.
# Sans -Touches : l'écran actuel, l'accueil, le dock, la grille et la bibliothèque d'applis.
# Avec -Touches : une seule capture après ces touches de télécommande (noms Android sans KEYCODE_).
# Avec -Ecrans : la bibliothèque d'applis, les réglages du lanceur et son menu rapide.
#
# Usage : powershell -ExecutionPolicy Bypass -File captures.ps1 -TvHost 192.168.1.83
#         powershell -ExecutionPolicy Bypass -File captures.ps1 -TvHost 192.168.1.83 -Touches HOME,DPAD_DOWN
#         powershell -ExecutionPolicy Bypass -File captures.ps1 -TvHost 192.168.1.83 -Ecrans
param(
    [string[]]$Touches = @(),
    [switch]$Ecrans,
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

# Chaque capture : un nom, les touches pressées avant (tools\tv.py --screenshot les envoie, puis attend) et
# une commande lancée avant, pour ouvrir un écran. « += , » ajoute le triplet tel quel : sans la virgule,
# PowerShell l'aplatirait dans la liste.
$plan = @()
if ($Touches) {
    $plan += , @('capture', $Touches, '')
} elseif ($Ecrans) {
    # La bibliothèque : pastille sous la grille. Les réglages ne sont pas exportés, mais le shell est root.
    $plan += , @('1-bibliotheque', @('HOME', 'DPAD_DOWN', 'DPAD_DOWN', 'DPAD_DOWN', 'DPAD_CENTER'), '')
    $plan += , @('2-bibliotheque-bas', @('DPAD_DOWN', 'DPAD_DOWN'), '')
    $plan += , @('3-reglages-lanceur', @(), 'input keyevent KEYCODE_HOME; am start -n com.gathin.tvhome/.LauncherSettingsActivity')
    $plan += , @('4-reglages-lanceur-bas', @('DPAD_DOWN', 'DPAD_DOWN', 'DPAD_DOWN', 'DPAD_DOWN', 'DPAD_DOWN', 'DPAD_DOWN'), '')
    $plan += , @('5-menu-rapide', @(), 'input keyevent KEYCODE_HOME; am start -n com.gathin.tvhome/.QuickSettingsActivity')
} else {
    $plan += , @('1-ecran-actuel', @(), '')
    $plan += , @('2-accueil', @('HOME'), '')
    $plan += , @('3-dock', @('HOME', 'DPAD_RIGHT'), '')
    $plan += , @('4-grille', @('HOME', 'DPAD_DOWN', 'DPAD_DOWN'), '')
    $plan += , @('5-grille-bas', @('DPAD_DOWN', 'DPAD_DOWN', 'DPAD_DOWN'), '')
}

foreach ($etape in $plan) {
    $nom = $etape[0]
    $cles = @($etape[1])
    if ($etape[2]) { & $py -I $tv $etape[2] | Out-Null }
    $png = Join-Path $dossier "$nom.png"
    & $py -I $tv --screenshot $png @cles --wait 2
    if ($LASTEXITCODE -ne 0) { Write-Warning "Capture $nom ratée" } else { Write-Host "OK : $nom.png" }
}
# Retour à l'accueil, pour ne pas laisser le boîtier au milieu de la grille.
if (-not $Touches) { & $py -I $tv 'input keyevent KEYCODE_HOME' | Out-Null }
Write-Host "Captures dans $dossier : envoie-les-moi."
