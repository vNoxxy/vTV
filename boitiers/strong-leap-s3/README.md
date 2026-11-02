# Strong LEAP-S3+ V2 (Google TV)

Le même résultat que sur le H96 : publicité et télémétrie coupées, le lanceur vTV (thème premium, photos de
fond, bibliothèque et réglages façon Apple TV), les add-ons, Cinejoy et FMHY, l'horloge en écran de veille,
le DNS anti-pub. Tout ce qui est propre à ce boîtier est dans ce dossier ; les outils communs sont à la
racine du dépôt.

> **Ce boîtier n'a pas de bouton reset.** Sur un LEAP-S3, désactiver d'un coup l'assistant de configuration
> et l'accueil de Google, puis redémarrer, a donné un écran noir réparé seulement par un reset sur la carte
> (`docs/devices/strong-leap-s3.md` dans cleanyourtv). D'où l'ordre ci-dessous, une étape à la fois, et
> **jamais les étapes 5 et 7 ensemble**.

Dans PowerShell, depuis `N:\vTV`, avec l'adresse IP du boîtier :

```powershell
cd N:\vTV
git pull
$ip = '192.168.1.XX'
```

## 1. Sur le boîtier

1. Fais la configuration Google TV normale (compte Google, réseau).
2. **Mieux : branche-le en câble Ethernet.** Le Wi-Fi enregistré à l'installation appartient à l'assistant de
   configuration, et l'étape 5 le couperait. En câble, ce risque disparaît.
3. Paramètres → Système → À propos → appuie 7 fois sur **Build de l'OS Android TV**.
4. Paramètres → Système → **Options pour les développeurs** → active **Débogage USB** (il ouvre le port 5555).
   Si **Débogage sans fil** existe, active-le aussi.
5. Note l'**adresse IP** : Paramètres → Réseau et Internet → ta connexion.

## 2. Connexion et lecture du boîtier (rien n'est modifié)

```powershell
powershell -ExecutionPolicy Bypass -File collecter-infos.ps1 -TvHost $ip
```

Accepte **« Autoriser le débogage ? »** sur la télé (coche « Toujours »). Envoie `infos-boitier.txt` et
`accueil.png` : la liste de l'étape 4 est vérifiée contre ce boîtier avant d'être appliquée, et les applis à
désinstaller ou à masquer en découlent.

## 3. Lanceur, add-ons et raccourcis

Mêmes fichiers que pour le H96 : `lanceur-apk` (dézippé en `N:\vTV\app-release.apk`) et `addons-apk`
(dézippé dans `N:\vTV\addons-apk`), depuis le dernier run vert de l'onglet Actions.

```powershell
powershell -ExecutionPolicy Bypass -File reinstaller-lanceur.ps1 -TvHost $ip -Apk .\app-release.apk -MiseAJour -Accueil none -ServiceTouches
powershell -ExecutionPolicy Bypass -File installer-addons.ps1 -TvHost $ip -Dossier .\addons-apk
powershell -ExecutionPolicy Bypass -File appliquer-theme.ps1 -TvHost $ip boitiers\strong-leap-s3\theme
```

`-MiseAJour` : le lanceur n'est pas encore là, il est simplement installé. `-Accueil none` : l'accueil Google
n'est pas touché ici (étape 7). `-ServiceTouches` : l'engrenage (code 83) et le bouton YouTube (code 266) de la
télécommande Strong continueront de marcher sans l'accueil Google. Ils se testent avec la vraie télécommande.

## 4. Nettoyage (publicité, télémétrie, outils d'usine)

```powershell
cd cleanyourtv
powershell -ExecutionPolicy Bypass -File tools\disable.ps1 -TvHost $ip ..\boitiers\strong-leap-s3\liste-1-nettoyage.txt
cd ..
```

## 5. L'assistant de configuration (seul)

D'abord, à qui appartient le Wi-Fi :

```powershell
powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip boitiers\strong-leap-s3\wifi.txt
```

Si `wifi.txt` montre `cname=com.google.android.tungsten.setupwraith`, oublie ton réseau Wi-Fi dans Paramètres
et reconnecte-toi, puis relance la vérification (ou passe en câble Ethernet). Ensuite :

```powershell
cd cleanyourtv
powershell -ExecutionPolicy Bypass -File tools\disable.ps1 -TvHost $ip ..\boitiers\strong-leap-s3\liste-2-assistant-config.txt
cd ..
```

`disable.ps1` refuse de lui-même tant que l'assistant possède le Wi-Fi.

## 6. Redémarrage de contrôle

Débranche, rebranche. Le boîtier doit revenir sur l'accueil Google, sur le réseau, et répondre :

```powershell
cleanyourtv\tools\venv\Scripts\python.exe -I cleanyourtv\tools\tv.py --probe
```

## 7. Le lanceur vTV devient l'accueil, puis l'accueil Google part

```powershell
powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip boitiers\strong-leap-s3\accueil.txt
cd cleanyourtv
powershell -ExecutionPolicy Bypass -File tools\disable.ps1 -TvHost $ip ..\boitiers\strong-leap-s3\liste-3-accueil-google.txt
cd ..
```

`accueil.txt` doit finir sur `com.gathin.tvhome/.MainActivity`. Appuie sur Accueil : c'est le lanceur vTV.
Puis **redémarre** et vérifie qu'il revient.

## 8. Les réglages communs

```powershell
powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip commandes\ecran-de-veille.txt
powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip commandes\world-clock.txt
powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip commandes\dns-adguard.txt
powershell -ExecutionPolicy Bypass -File captures.ps1 -TvHost $ip
```

Après le DNS, vérifie que les applis chargent encore : sur un LEAP-S3, deux essais ont cessé de résoudre les
noms avant de marcher (annuler : `commandes\dns-annuler.txt`). Stremio s'installe depuis le Play Store.

## Tout annuler

Chaque liste se restaure à part, dans l'ordre inverse (3, 2, 1) :

```powershell
cd cleanyourtv
powershell -ExecutionPolicy Bypass -File tools\restore.ps1 -TvHost $ip -Stock com.google.android.apps.tv.launcherx ..\boitiers\strong-leap-s3\liste-3-accueil-google.txt
```

## Différences avec le H96

| | H96 Max V11 | Strong LEAP-S3+ V2 |
|---|---|---|
| Système | Android 11 générique, root | Google TV certifié, sans root |
| ADB | ouvert à tout le réseau, sans autorisation | autorisation demandée sur la télé |
| Accueil d'origine | `com.droidlogic.mboxlauncher` | `launcherx` + l'assistant `setupwraith` |
| World Clock | écrit par le shell root | `commandes\world-clock.txt` a besoin du root : sans lui, choisis les villes dans l'appli |
EOF
