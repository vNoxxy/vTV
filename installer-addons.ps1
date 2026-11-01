# Installe sur le boîtier les APK des add-ons et raccourcis compilés par GitHub Actions (artefact
# addons-apk, dézippé dans un dossier). Chaque APK porte le nom de son paquet Android ; il est envoyé et
# vérifié par tools\b64push.py, puis installé.
#
# Usage (depuis le dossier du dépôt, après preparer-pc.ps1) :
#   powershell -ExecutionPolicy Bypass -File installer-addons.ps1 -TvHost 192.168.1.83 -Dossier .\addons-apk
#   ... -Seulement weather,site.cinejoy      pour n'installer que ceux-là (fin du nom de paquet)
#   ... -Remplacer                           désinstalle d'abord un add-on signé avec une autre clé
#                                            (ses réglages sont perdus)
param(
    [Parameter(Mandatory = $true)][string]$Dossier,
    [string[]]$Seulement = @(),
    [switch]$Remplacer,
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
$b64push = Join-Path $repo 'tools\b64push.py'

# -Recurse : le dézippage de Windows met souvent les APK dans un sous-dossier du même nom.
$apks = @(Get-ChildItem -Path $Dossier -Filter *.apk -Recurse | Sort-Object Name)
if ($Seulement) { $apks = @($apks | Where-Object { $nom = $_.BaseName; $Seulement | Where-Object { $nom -like "*$_" } }) }
if (-not $apks) { throw "Aucun APK à installer dans $Dossier" }

$echecs = @()
foreach ($apk in $apks) {
    Write-Host "== $($apk.BaseName)"
    & $py -I $b64push $apk.FullName /data/local/tmp/addon.apk
    if ($LASTEXITCODE -ne 0) { $echecs += $apk.BaseName; continue }
    $sortie = (& $py -I $tv 'pm install -r /data/local/tmp/addon.apk') -join "`n"
    # Installé avant le passage à la clé fixe (signature/) : Android refuse la mise à jour. Un raccourci
    # de site n'a pas de données, on le remplace toujours ; un add-on, seulement avec -Remplacer.
    if ($sortie -match 'INSTALL_FAILED_UPDATE_INCOMPATIBLE') {
        if ($Remplacer -or $apk.BaseName -like 'io.github.vnoxxy.vtv.site.*') {
            $sortie = (& $py -I $tv "pm uninstall $($apk.BaseName); pm install /data/local/tmp/addon.apk") -join "`n"
        } else {
            Write-Warning "$($apk.BaseName) est signé avec une autre clé : relance avec -Remplacer (ses réglages seront perdus)."
        }
    }
    & $py -I $tv 'rm -f /data/local/tmp/addon.apk' | Out-Null
    Write-Host $sortie
    if ($sortie -notmatch 'Success') { $echecs += $apk.BaseName }
}

if ($echecs) { throw "Échec pour : $($echecs -join ', ') (voir les messages ci-dessus)" }
Write-Host "Terminé : $($apks.Count) add-on(s) installé(s)."
