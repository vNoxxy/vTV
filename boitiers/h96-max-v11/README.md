# H96 Max V11 (Android 11, Rockchip RK3318)

Le boîtier nettoyé en premier. Tout ce qui lui est propre est ici, sauf sa liste d'applis désactivées,
restée dans `listes/h96-max-v11.txt` : la sauvegarde de restauration de cleanyourtv est rangée sous le
chemin complet de la liste.

## Personnalisation

Depuis `N:\vTV`, après `git pull`, avec `$ip = '192.168.1.83'` :

| Étape | Commande |
|---|---|
| Désinstaller les applis inutilisées | `powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip boitiers\h96-max-v11\desinstaller.txt` |
| Installer add-ons et raccourcis (zip `addons-apk` dézippé dans `addons-apk\`) | `powershell -ExecutionPolicy Bypass -File installer-addons.ps1 -TvHost $ip -Dossier .\addons-apk` |
| Mettre à jour le lanceur (zip `lanceur-apk`) | `powershell -ExecutionPolicy Bypass -File reinstaller-lanceur.ps1 -TvHost $ip -Apk .\app-release.apk -MiseAJour` |
| Thème premium et photos de fond (dock, applis masquées, « Bonjour, Timéo ») | `powershell -ExecutionPolicy Bypass -File appliquer-theme.ps1 -TvHost $ip boitiers\h96-max-v11\theme` |
| Horloge en écran de veille après 10 min | `powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip commandes\ecran-de-veille.txt` |
| DNS anti-pub AdGuard (annuler : `dns-annuler.txt`) | `powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip commandes\dns-adguard.txt` |
| Image de l'écran de démarrage (Startup & Branding) | `powershell -ExecutionPolicy Bypass -File image-demarrage.ps1 -TvHost $ip C:\chemin\image.png` |
| Retirer le raccourci YouTube Web | `powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip boitiers\h96-max-v11\retirer-sites.txt` |
| Horloges World Clock (France, New York, Tokyo, São Paulo) | `powershell -ExecutionPolicy Bypass -File executer.ps1 -TvHost $ip commandes\world-clock.txt` |
| Captures d'écran à envoyer (dans `captures\`) | `powershell -ExecutionPolicy Bypass -File captures.ps1 -TvHost $ip` |

L'animation de démarrage du boîtier ne se remplace pas : elle est sur une partition système en
lecture seule, protégée par dm-verity (`ro.boot.veritymode=enforcing`). La lever risque d'empêcher
le boîtier de démarrer.

## Refermer l'ADB réseau (à la fin)

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

Les anciennes copies de la bibliothèque Trichrome de Chrome (environ 700 Mo) restent : le
gestionnaire de paquets refuse de les supprimer (`DELETE_FAILED_INTERNAL_ERROR`). Après les
désinstallations, il reste 2,9 Go libres.
