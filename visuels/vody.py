"""Dessine les visuels vTV dans le style du site Vody Studio (frontend/src/index.css de
vBlueProjectGithub) : noir teinté de bleu, traits fins, équerres de cadrage, étiquettes numérotées
en JetBrains Mono, accent #2485ea, ni dégradé ni halo.

Usage : python3 visuels/vody.py <dossier des polices> themes/vody/wallpaper.jpg
        python3 visuels/vody.py <dossier des polices> raccourcis/sites.json   (tuiles des sites)
        python3 visuels/vody.py - visuels/bootanimation.zip                  (animation de démarrage)
        python3 visuels/vody.py - visuels/demarrage.png                      (image Startup & Branding)
Polices (licence OFL) : Syne 800 et JetBrains Mono 500/700, des paquets npm @fontsource/syne et
@fontsource/jetbrains-mono, converties en TTF (Syne-800.ttf, JBM-500.ttf, JBM-700.ttf).
"""

import os
import sys

from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080
ACCENT = (36, 133, 234)
# Le fond de l'écran de chargement du site : color-mix(accent 3 %, #09090c).
BG = tuple(round(0.03 * a + 0.97 * b) for a, b in zip(ACCENT, (9, 9, 12)))
ICI = os.path.dirname(os.path.abspath(__file__))
LOGO = os.path.join(ICI, "sources", "logo_vody.jpg")


def blend(couleur, alpha):
    return tuple(round(alpha * c + (1 - alpha) * b) for c, b in zip(couleur, BG))


def police(dossier, nom, taille):
    return ImageFont.truetype(os.path.join(dossier, nom), taille)


def trame(d):
    """La feuille de plan : une trame fine, plus marquée toutes les quatre cases."""
    for x in range(0, W + 1, 60):
        d.line([(x, 0), (x, H)], fill=blend((255, 255, 255), 0.045 if x % 240 == 0 else 0.022))
    for y in range(0, H + 1, 60):
        d.line([(0, y), (W, y)], fill=blend((255, 255, 255), 0.045 if y % 240 == 0 else 0.022))


def equerres(d, marge=36, long=30):
    c = blend((255, 255, 255), 0.4)
    for x, y, sx, sy in ((marge, marge, 1, 1), (W - marge, marge, -1, 1), (marge, H - marge, 1, -1), (W - marge, H - marge, -1, -1)):
        d.line([(x, y), (x + sx * long, y)], fill=c, width=2)
        d.line([(x, y), (x, y + sy * long)], fill=c, width=2)


def etiquette(d, x, y, numero, texte, f):
    """Comme le « 01 | VODY STUDIO — … » du site : deux cases cernées de bleu."""
    pad_x, haut = 18, 44
    n_l = d.textlength(numero, font=f)
    t_l = d.textlength(texte, font=f)
    x2 = x + pad_x * 2 + n_l
    x3 = x2 + pad_x * 2 + t_l
    d.rectangle([x, y, x3, y + haut], outline=ACCENT, width=2)
    d.line([(x2, y), (x2, y + haut)], fill=ACCENT, width=2)
    ty = y + haut / 2
    d.text((x + pad_x, ty), numero, font=f, fill=ACCENT, anchor="lm")
    d.text((x2 + pad_x, ty), texte, font=f, fill=blend(ACCENT, 0.95), anchor="lm")


def logo(taille):
    return Image.open(LOGO).convert("RGB").resize((taille, taille), Image.LANCZOS)


def fond_ecran(polices, sortie):
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    trame(d)
    equerres(d)
    mono = police(polices, "JBM-500.ttf", 20)
    etiquette(d, 72, H - 72 - 44, "01", "vTV — L'ÉCRAN DE TIMÉO", mono)
    # Le logo et son nom, en bas à droite, cernés d'un trait fin.
    t = 44
    x, y = W - 72 - t, H - 72 - t
    im.paste(logo(t), (x, y))
    d.rectangle([x - 1, y - 1, x + t, y + t], outline=blend((255, 255, 255), 0.18))
    d.text((x - 18, y + t / 2), "VODY STUDIO", font=police(polices, "JBM-700.ttf", 18), fill=blend((255, 255, 255), 0.75), anchor="rm")
    im.save(sortie, quality=88, optimize=True)


def ecran_chargement(progression):
    """L'écran de chargement du site (.boot de frontend/index.html) à l'échelle d'une télé 1080p :
    le logo 56 px aux coins de 9 px, 22 px d'écart, la barre de 132 × 2 px dont un tiers glisse.
    `progression` va de 0 (barre à gauche) à 1 (à droite)."""
    e = 2.5
    im = Image.new("RGB", (W, H), BG)
    t, r = round(56 * e), round(9 * e)
    bl, bh, ecart = round(132 * e), round(2 * e), round(22 * e)
    haut = t + ecart + bh
    x, y = (W - t) // 2, (H - haut) // 2
    masque = Image.new("L", (t, t), 0)
    ImageDraw.Draw(masque).rounded_rectangle([0, 0, t - 1, t - 1], radius=r, fill=255)
    im.paste(logo(t), (x, y), masque)
    d = ImageDraw.Draw(im)
    bx, by = (W - bl) // 2, y + t + ecart
    d.rectangle([bx, by, bx + bl - 1, by + bh - 1], fill=blend((255, 255, 255), 0.16))
    # .boot-bar::after : inset 0 62% 0 0, translateX jusqu'à 164 % de sa largeur.
    rempli = bl * 0.38
    gauche = bx + progression * 1.64 * rempli
    d.rectangle([round(gauche), by, round(min(gauche + rempli, bx + bl)) - 1, by + bh - 1], fill=ACCENT)
    return im


def animation_demarrage(sortie):
    """bootanimation.zip : la barre fait l'aller-retour en 1 s comme sur le site (ease-in-out,
    alternate), 30 images par seconde, en boucle jusqu'à la fin du démarrage. Zip sans compression,
    comme Android l'exige."""
    import math
    import tempfile
    import zipfile

    fps = 30
    images = []
    for i in range(2 * fps):
        p = (i % fps) / fps if i < fps else 1 - (i % fps) / fps
        images.append(ecran_chargement((1 - math.cos(math.pi * p)) / 2))
    with tempfile.TemporaryDirectory() as tmp, zipfile.ZipFile(sortie, "w", zipfile.ZIP_STORED) as z:
        z.writestr("desc.txt", f"{W} {H} {fps}\np 0 0 part0\n")
        for i, im in enumerate(images):
            f = os.path.join(tmp, f"{i:05d}.png")
            im.save(f, optimize=True)
            z.write(f, f"part0/{i:05d}.png")


def ajuster(d, texte, nom, polices, taille, largeur):
    """La plus grande taille, jusqu'à `taille`, où le texte tient dans `largeur`."""
    while taille > 10 and d.textlength(texte, font=police(polices, nom, taille)) > largeur:
        taille -= 1
    return police(polices, nom, taille)


def tuile_site(polices, site, numero, dossier):
    """La tuile (banner 320×180) et l'icône d'un raccourci, dans raccourcis/sites/<id>/res."""
    res = os.path.join(dossier, site["id"], "res", "drawable-xhdpi")
    os.makedirs(res, exist_ok=True)
    domaine = site["url"].split("//", 1)[-1].strip("/").removeprefix("www.")

    im = Image.new("RGB", (320, 180), BG)
    d = ImageDraw.Draw(im)
    d.rectangle([8, 8, 311, 171], outline=blend((255, 255, 255), 0.14))
    mono = police(polices, "JBM-500.ttf", 13)
    d.rectangle([20, 20, 52, 40], outline=ACCENT, width=1)
    d.text((36, 30), numero, font=mono, fill=ACCENT, anchor="mm")
    nom = site["nom"].upper()
    d.text((160, 92), nom, font=ajuster(d, nom, "Syne-800.ttf", polices, 40, 270), fill=(255, 255, 255), anchor="mm")
    d.text((160, 146), domaine, font=mono, fill=ACCENT, anchor="mm")
    im.save(os.path.join(res, "banner.png"), optimize=True)

    im = Image.new("RGB", (96, 96), BG)
    d = ImageDraw.Draw(im)
    d.rectangle([4, 4, 91, 91], outline=ACCENT, width=2)
    lettre = site["nom"][0].upper()
    d.text((48, 50), lettre, font=police(polices, "Syne-800.ttf", 50), fill=(255, 255, 255), anchor="mm")
    im.save(os.path.join(res, "icon.png"), optimize=True)


if __name__ == "__main__":
    import json

    polices, cible = sys.argv[1], sys.argv[2]
    if cible.endswith("bootanimation.zip"):
        animation_demarrage(cible)
    elif cible.endswith("demarrage.png"):
        ecran_chargement(0.5).save(cible, optimize=True)
    elif cible.endswith(".json"):
        # raccourcis/sites.json : une tuile par site, numérotées dans l'ordre de la liste.
        sites = json.load(open(cible, encoding="utf-8"))
        for i, site in enumerate(sites, 1):
            tuile_site(polices, site, f"{i:02d}", os.path.join(os.path.dirname(cible), "sites"))
    else:
        fond_ecran(polices, cible)
