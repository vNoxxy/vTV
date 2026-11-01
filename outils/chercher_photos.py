"""Cherche sur Wikimedia Commons des photos sous licence libre pour les fonds par appli du lanceur.

Usage : python3 outils/chercher_photos.py <dossier de sortie> "<recherche>" ["<recherche>" ...]
Pour chaque recherche : jusqu'à 8 photos d'au moins 1920 px de large, sous CC0, domaine public,
CC BY ou CC BY-SA, en miniature 960 px (<dossier>/<recherche>/NN.jpg) avec credits.json (titre,
auteur, licence, page, adresse de l'original). Lancé par GitHub Actions : la session de travail
n'a pas accès à Wikimedia.
"""

import json
import os
import re
import sys
import urllib.parse
import urllib.request

API = "https://commons.wikimedia.org/w/api.php"
# Wikimedia demande un User-Agent qui identifie l'outil.
UA = "vTV-chercher-photos/1.0 (https://github.com/vNoxxy/vTV)"
LIBRES = re.compile(r"^(CC0|Public domain|PD|CC BY(-SA)? \d)", re.I)


def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": UA}), timeout=60).read()


def texte(html):
    return re.sub(r"<[^>]+>", "", html or "").strip()


def chercher(recherche, sortie):
    q = {"action": "query", "format": "json", "generator": "search", "gsrnamespace": "6", "gsrlimit": "40",
         "gsrsearch": recherche + " filetype:bitmap", "prop": "imageinfo", "iiprop": "url|size|extmetadata",
         "iiurlwidth": "960", "iiextmetadatafilter": "LicenseShortName|Artist"}
    pages = json.loads(get(API + "?" + urllib.parse.urlencode(q))).get("query", {}).get("pages", {})
    dossier = os.path.join(sortie, re.sub(r"[^a-z0-9]+", "-", recherche.lower()).strip("-"))
    os.makedirs(dossier, exist_ok=True)
    credits = []
    for page in sorted(pages.values(), key=lambda p: p.get("index", 0)):
        info = (page.get("imageinfo") or [{}])[0]
        meta = info.get("extmetadata", {})
        licence = texte(meta.get("LicenseShortName", {}).get("value"))
        if info.get("width", 0) < 1920 or info.get("width", 0) < info.get("height", 0) or not LIBRES.match(licence):
            continue
        n = len(credits) + 1
        with open(os.path.join(dossier, f"{n:02d}.jpg"), "wb") as f:
            f.write(get(info["thumburl"]))
        credits.append({"n": n, "titre": page["title"], "auteur": texte(meta.get("Artist", {}).get("value")),
                        "licence": licence, "page": info.get("descriptionurl"), "original": info.get("url"),
                        "taille": f"{info.get('width')}x{info.get('height')}"})
        if n == 8:
            break
    with open(os.path.join(dossier, "credits.json"), "w", encoding="utf-8") as f:
        json.dump(credits, f, ensure_ascii=False, indent=2)
    print(f"{recherche}: {len(credits)} photo(s)")


if __name__ == "__main__":
    for r in sys.argv[2:]:
        if r.strip():
            chercher(r.strip(), sys.argv[1])
