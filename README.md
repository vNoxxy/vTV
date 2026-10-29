# vTV

Nettoyer ma TV Android avec [cleanyourtv](https://github.com/Gathin23/cleanyourtv) (licence MIT) :
enlever les pubs, la télémétrie et les applis préinstallées, et remplacer l'accueil par un lanceur
épuré. Rien n'est désinstallé : tout se restaure en une commande.

> **Ne marche que sur une TV Android TV ou Google TV.** Samsung, LG, Roku, Vizio et Hisense VIDAA
> ne sont pas compatibles : voir [cleanyour.tv/not-android](https://cleanyour.tv/not-android).

Ce dépôt ne recopie pas cleanyourtv. Il contient :

| Fichier | Rôle |
|---|---|
| `cleanyourtv.commit` | La version exacte de cleanyourtv utilisée. |
| `.github/workflows/compiler-apk.yml` | GitHub compile l'APK du lanceur : pas besoin de JDK ni de SDK Android sur le PC. |
| `preparer-pc.ps1` | Récupère cleanyourtv sur le PC, installe ses outils Python et y place l'APK. |

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
