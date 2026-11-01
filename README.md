# vTV

Nettoyer ma TV Android avec [cleanyourtv](https://github.com/Gathin23/cleanyourtv) (licence MIT) :
enlever les pubs, la télémétrie et les applis préinstallées, et remplacer l'accueil par un lanceur
épuré. Rien n'est désinstallé : tout se restaure en une commande.

> **Ne marche que sur une TV Android TV ou Google TV.** Samsung, LG, Roku, Vizio et Hisense VIDAA
> ne sont pas compatibles : voir [cleanyour.tv/not-android](https://cleanyour.tv/not-android).

## Mon installation

| Appareil | Système | Rôle |
|---|---|---|
| TV **Philips 55PUS6503/12** (2019, châssis TPM18.6E LA) | Saphi, pas Android | Écran seulement : cleanyourtv ne peut rien y faire. |
| Boîtier **H96 Max V11** (Rockchip RK3318, 2 Go / 16 Go) | Android 11 | Le boîtier nettoyé : liste `listes/h96-max-v11.txt`, lanceur cleanyourtv. |
| Boîtier **X88 Pro 10** (Rockchip RK3318, 4 Go / 32 Go) | Android | Pas utilisé : pas d'ADB réseau, cité dans les rapports BADBOX 2.0. |

Ce dépôt ne recopie pas cleanyourtv. Il contient :

| Fichier | Rôle |
|---|---|
| `cleanyourtv.commit` | La version exacte de cleanyourtv utilisée (lanceur 3.1). |
| `.github/workflows/compiler-apk.yml` | GitHub compile le lanceur (`lanceur-apk`), les add-ons et les raccourcis (`addons-apk`). |
| `preparer-pc.ps1` | Récupère cleanyourtv sur le PC, installe ses outils Python et y place l'APK du lanceur. |
| `collecter-infos.ps1` | Lit le boîtier sans rien modifier et rassemble ce qu'il faut pour écrire sa liste. |
| `executer.ps1` + `commandes/` | Envoie au boîtier un fichier de commandes et garde sa réponse dans un `.txt`. |
| `installer-addons.ps1` | Installe les APK du zip `addons-apk` (add-ons et raccourcis). |
| `image-demarrage.ps1` | Envoie une image à l'add-on Startup & Branding. |
| `captures.ps1` | Prend des captures d'écran du boîtier (accueil, dock, grille) dans `captures\`. |
| `listes/` | Les listes d'applis désactivées, par boîtier. |
| `themes/premium/` | Le thème du lanceur, façon Apple TV : étagère cinématique, dock en verre, effets avancés. |
| `raccourcis/` | Une appli par site de `raccourcis/sites.json` : sa tuile sur l'accueil ouvre le site dans Chrome. Icône et bannière fournies par le propriétaire, dans `raccourcis/sites/<id>/res/drawable-nodpi/`. |

## H96 Max V11 : personnalisation

Depuis `N:\vTV`, après `git pull`, avec `$ip = '192.168.1.83'` :

| Étape | Commande |
|---|---|
| Désinstaller les applis inutilisées | `powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip commandes\desinstaller.txt` |
| Installer add-ons et raccourcis (zip `addons-apk` dézippé dans `addons-apk\`) | `powershell -ExecutionPolicy Bypass -File installer-addons.ps1 -TvHost $ip -Dossier .\addons-apk` |
| Thème premium (dock, applis masquées, « Bonjour, Timéo ») | `powershell -ExecutionPolicy Bypass -File cleanyourtv\tools\theme.ps1 -TvHost $ip themes\premium` |
| Horloge en écran de veille après 10 min | `powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip commandes\ecran-de-veille.txt` |
| DNS anti-pub AdGuard (annuler : `dns-annuler.txt`) | `powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip commandes\dns-adguard.txt` |
| Image de l'écran de démarrage (Startup & Branding) | `powershell -ExecutionPolicy Bypass -File image-demarrage.ps1 -TvHost $ip C:\chemin\image.png` |
| Retirer le raccourci YouTube Web | `powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip commandes\retirer-sites.txt` |
| Horloges World Clock (France, New York, Tokyo, São Paulo) | `powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip commandes\world-clock.txt` |
| Captures d'écran à envoyer (dans `captures\`) | `powershell -ExecutionPolicy Bypass -File captures.ps1 -TvHost $ip` |

L'animation de démarrage du boîtier ne se remplace pas : elle est sur une partition système en
lecture seule, protégée par dm-verity (`ro.boot.veritymode=enforcing`). La lever risque d'empêcher
le boîtier de démarrer.

### Refermer l'ADB réseau (à la fin)

Ce firmware ouvre l'ADB sur le port 5555 sans demander d'autorisation et en root
(`ro.adb.secure=0`). Deux scripts du fabricant s'en chargent : `init.rk30board.rc` ouvre le port
tant que `persist.internet_adb_enable=1`, et `init.hcy.rc` remet `service.adb.tcp.port=5555` à
chaque démarrage sans redémarrer adbd.

1. Quand tout est réglé : Options pour les développeurs → désactive **Débogage USB** (adbd s'arrête).
2. Redémarre le boîtier, puis vérifie depuis le PC :
   `cleanyourtv\tools\venv\Scripts\python.exe -I cleanyourtv\tools\adb-closed.py 192.168.1.83`
   doit dire que le port est fermé.
3. Pour modifier à nouveau : réactive **Débogage USB**. adbd redémarre sur le port 5555.

Si le port reste ouvert après l'étape 2 (débogage réactivé), `setprop persist.internet_adb_enable 0`
fait fermer le port 5555 par `init.rk30board.rc` ; `setprop persist.internet_adb_enable 1` le rouvre.

Le dock attend Stremio (`com.stremio.one`) : installe-le depuis le Play Store. Une appli absente
est simplement sautée. Pour ajouter un site : une ligne dans `raccourcis/sites.json`, et son icône
(`icon.png`) et sa bannière 320×180 (`banner.png`, facultative) dans
`raccourcis/sites/<id>/res/drawable-nodpi/`. Sans bannière, le lanceur montre l'icône.

## Étape 0 : récupérer l'APK du lanceur

1. Onglet **Actions** de ce dépôt → **Compiler l'APK du lanceur** → dernier run vert
   (ou **Run workflow** pour en relancer un).
2. En bas de la page du run, **Artifacts** → `lanceur-apk` : un zip qui contient `app-release.apk`.
3. Dézippe-le et **garde ce fichier**. Chaque compilation est signée avec une nouvelle clé : une
   autre version de l'APK ne pourra pas s'installer par-dessus celle-ci sans désinstaller d'abord.

## Option C : la clé USB (lanceur seulement)

Ce que la clé **ne fait pas** : enlever les pubs et la télémétrie du système. Pour ça il faut ADB
depuis le PC (option B). La clé sert seulement à installer le lanceur.

1. Clé formatée en FAT32 ou exFAT, copie `app-release.apk` à la racine.
2. Sur la TV, installe un gestionnaire de fichiers depuis le Play Store s'il n'y en a pas.
3. Autorise ce gestionnaire à installer des applis inconnues (selon le modèle : Paramètres →
   Préférences de l'appareil → Sécurité et restrictions → Sources inconnues, ou Paramètres → Applis →
   Sécurité). Le chemin exact dépend de la marque.
4. Branche la clé, ouvre `app-release.apk` dans le gestionnaire de fichiers, installe.
5. Pour en faire l'écran d'accueil : certaines TV demandent quel lanceur utiliser à l'appui sur
   **Home**, d'autres (surtout Google TV) ne le permettent pas sans ADB. Dans ce cas, passe à l'option B.

Si tu fais ensuite l'option B, utilise **le même fichier APK** : il est déjà installé, rien ne bloque.

## Option B : depuis le PC (nettoyage complet)

### Ce qu'il faut

- **Git pour Windows** : <https://git-scm.com/download/win>
- **Python 3** : <https://www.python.org/downloads/>, coche *Add python.exe to PATH* à l'installation.
- Le PC et la TV branchés sur **la même box**. Le PC en Ethernet et la TV en Wi-Fi, ça marche.

### 1. Sur la TV

1. Paramètres → Préférences de l'appareil → À propos → appuie 7 fois sur **Build** (Version).
2. Retour → **Options pour les développeurs** → active **Débogage USB**. Si tu vois aussi
   *Débogage réseau / ADB* ou *Débogage sans fil*, active-le.
3. Note l'**adresse IP** de la TV : Paramètres → Réseau et Internet → ton réseau.

> Sur certaines box Xiaomi, le débogage USB coupe les ports USB (clé, disque). Fais l'option C
> avant d'activer le débogage, ou désactive-le le temps d'utiliser la clé.

### 2. Sur le PC (PowerShell)

```powershell
git clone https://github.com/vNoxxy/vTV tvnoxxy
cd tvnoxxy
powershell -ExecutionPolicy Bypass -File preparer-pc.ps1 -Apk C:\chemin\vers\app-release.apk
cd cleanyourtv
$env:TV_HOST = '192.168.1.50'   # l'IP de ta TV
tools\venv\Scripts\python.exe -I tools\tv.py --probe
```

Accepte **« Autoriser le débogage USB ? »** sur la TV. `--probe` affiche le modèle, la version
d'Android et le firmware : c'est là que tu retrouves le modèle exact.

### 3. La liste des applis à désactiver

- Cherche ton modèle dans `cleanyourtv\examples\` ou sur [cleanyour.tv/tvs](https://cleanyour.tv/tvs).
  S'il y est, la liste est `examples\<modele>\debloat.txt`.
- Sinon, l'audit génère une liste de départ (voix, ACR, télémétrie) avec les preuves trouvées :
  ```powershell
  tools\venv\Scripts\python.exe -I tools\privacy.py
  tools\venv\Scripts\python.exe -I tools\privacy.py --write ..\ma-tv.txt
  ```
  **Relis la liste avant de l'appliquer.** Une appli que tu utilises ne doit pas y être.

### 4. Appliquer, puis installer le lanceur

```powershell
powershell -ExecutionPolicy Bypass -File tools\disable.ps1 -TvHost $env:TV_HOST <liste>
$env:SKIP_BUILD = '1'
powershell -ExecutionPolicy Bypass -File launcher\build-and-install.ps1 -TvHost $env:TV_HOST
```

`SKIP_BUILD=1` installe l'APK compilé par GitHub au lieu de le recompiler sur le PC. Le script
vérifie que le nouveau lanceur démarre **avant** de désactiver l'accueil d'origine.
Sur Google TV, lis d'abord la section *When something goes wrong* du README de cleanyourtv
(l'assistant de configuration `setupwraith`).

### 5. Refermer l'accès

Options pour les développeurs → désactive **Débogage USB / réseau / sans fil** et révoque les
autorisations, redémarre la TV, puis vérifie depuis le PC :

```powershell
tools\venv\Scripts\python.exe -I tools\adb-closed.py $env:TV_HOST
```

Le port doit être annoncé fermé. Le lanceur continue de marcher sans le débogage.

## Tout annuler

Réactive le débogage, puis avec **la même liste** :

```powershell
powershell -ExecutionPolicy Bypass -File tools\restore.ps1 -TvHost $env:TV_HOST <liste>
# Google TV : ajoute -Stock com.google.android.apps.tv.launcherx
```

Sans PC, Paramètres → Applis de la TV permet aussi de réactiver une appli désactivée.

## Après une mise à jour du firmware

Les applis désactivées peuvent revenir. Réactive le débogage et compare :

```powershell
tools\venv\Scripts\python.exe -I tools\check.py <liste>          # ajoute --fix pour réappliquer
```

Les anciennes copies de la bibliothèque Trichrome de Chrome (environ 700 Mo) restent : le
gestionnaire de paquets refuse de les supprimer (`DELETE_FAILED_INTERNAL_ERROR`). Après les
désinstallations, il reste 2,9 Go libres.
