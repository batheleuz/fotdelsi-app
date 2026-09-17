#!/usr/bin/env python3
"""Image de présentation de la fiche Google Play — 1024 x 500.

C'est le seul visuel de la fiche qui ne soit pas une capture : Play l'affiche
en tête de page et s'en sert quand il met l'application en avant. Aucune
équivalence côté Apple.

─── Pourquoi un script, et pas une image dessinée à la main ───

Le texte de la fiche bougera : une formule ajoutée, un opérateur de paiement
de plus, une phrase d'accroche revue après les premiers retours. Un fichier
Photoshop introuvable six mois plus tard obligerait à tout refaire. Ici, la
phrase se change à la ligne qui la porte, et l'image se régénère à
l'identique.

─── Ce que Play fait de cette image ───

Elle est recadrée selon les surfaces, et Play superpose parfois l'icône et le
nom de l'application par-dessus. D'où deux règles suivies ici :

  1. tout ce qui porte du sens reste dans la moitié gauche et à plus de 70 px
     des bords — MARGE ci-dessous ;
  2. le hublot déborde volontairement à droite : c'est de la décoration, elle
     peut être coupée sans rien perdre.

─── Dépendance ───

Pillow, que le projet n'utilise nulle part ailleurs. À installer à côté
plutôt que dans le Python du système :

    python3 -m venv /tmp/venv && /tmp/venv/bin/pip install Pillow
    /tmp/venv/bin/python tool/image_presentation.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

RACINE = Path(__file__).resolve().parents[2]
POLICES = RACINE / "site/assets/fonts"
LOGO = RACINE / "site/assets/logo.png"
SORTIE = RACINE / "app/captures/android/image-presentation.png"

LARGEUR, HAUTEUR = 1024, 500
MARGE = 72

# La palette du site (`site/styles.css`), pour que la fiche et le site ne
# racontent pas deux marques différentes.
BLEU_NUIT = (11, 37, 89)
BLEU = (40, 97, 201)
ORANGE = (244, 123, 32)
TEXTE_DOUX = (191, 211, 245)

ACCROCHE = "Votre laverie,\nsans attendre"
SOUS_TITRE = (
    "Scannez la machine, payez avec Wave ou Orange Money,\n"
    "et suivez votre lavage en direct."
)


def police(nom: str, taille: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(POLICES / nom), taille)


def fond() -> Image.Image:
    """Dégradé diagonal.

    Dessiné en 64 x 32 puis agrandi : l'interpolation bilinéaire fait un
    dégradé parfaitement lisse, là où un remplissage pixel par pixel coûterait
    un demi-million d'itérations pour le même résultat.
    """
    petit = Image.new("RGB", (64, 32))
    px = petit.load()
    for y in range(32):
        for x in range(64):
            # Diagonale : les deux axes comptent, celui des x davantage.
            t = (x / 63 * 0.7) + (y / 31 * 0.3)
            px[x, y] = tuple(
                round(BLEU_NUIT[i] + (BLEU[i] - BLEU_NUIT[i]) * t) for i in range(3)
            )
    return petit.resize((LARGEUR, HAUTEUR), Image.BILINEAR)


def hublot(image: Image.Image) -> None:
    """Le hublot de la machine, à droite, débordant du cadre.

    Trois cercles concentriques de plus en plus opaques, plus quelques bulles :
    de loin, un tambour ; de près, rien qui attire l'œil au détriment du texte.
    """
    calque = Image.new("RGBA", (LARGEUR, HAUTEUR), (0, 0, 0, 0))
    dessin = ImageDraw.Draw(calque)
    cx, cy = 845, 250

    for rayon, alpha in ((232, 12), (196, 18), (150, 24)):
        dessin.ellipse(
            (cx - rayon, cy - rayon, cx + rayon, cy + rayon),
            fill=(255, 255, 255, alpha),
        )

    # Le liseré du hublot : un anneau clair, comme sur le logo.
    dessin.ellipse((cx - 196, cy - 196, cx + 196, cy + 196), outline=(255, 255, 255, 58), width=4)

    # Les bulles montent en diagonale et rapetissent : trois suffisent à
    # suggérer le mouvement. Éparpillées, elles ressemblaient à des taches.
    for bx, by, br, alpha in (
        (cx - 62, cy + 74, 30, 34),
        (cx + 10, cy - 6, 20, 40),
        (cx + 66, cy - 78, 12, 46),
    ):
        dessin.ellipse((bx - br, by - br, bx + br, by + br), fill=(255, 255, 255, alpha))

    image.alpha_composite(calque)


def carte_logo(image: Image.Image, haut: int) -> int:
    """Le logo dans une carte blanche — il est dessiné pour du blanc.

    Posé tel quel sur le dégradé, son bleu nuit disparaîtrait dans le fond et
    ses contours blancs feraient un rectangle sale. La carte est la même que
    celle des captures App Store.
    """
    logo = Image.open(LOGO).convert("RGBA")
    large = 272
    haut_logo = round(logo.height * large / logo.width)
    logo = logo.resize((large, haut_logo), Image.LANCZOS)

    marge_interne = 20
    carte = (
        MARGE,
        haut,
        MARGE + large + marge_interne * 2,
        haut + haut_logo + marge_interne * 2,
    )

    calque = Image.new("RGBA", (LARGEUR, HAUTEUR), (0, 0, 0, 0))
    ImageDraw.Draw(calque).rounded_rectangle(carte, radius=22, fill=(255, 255, 255, 255))
    image.alpha_composite(calque)
    image.paste(logo, (MARGE + marge_interne, haut + marge_interne), logo)

    return carte[3]


def main() -> None:
    image = fond().convert("RGBA")
    hublot(image)

    bas_carte = carte_logo(image, haut=56)
    dessin = ImageDraw.Draw(image)

    y = bas_carte + 46
    dessin.multiline_text(
        (MARGE, y),
        ACCROCHE,
        font=police("Poppins-Bold.ttf", 46),
        fill=(255, 255, 255),
        spacing=6,
    )

    # Le trait orange : la seule touche de la couleur d'accent, et elle sépare
    # l'accroche de l'explication.
    y_trait = y + 128
    dessin.rounded_rectangle((MARGE, y_trait, MARGE + 84, y_trait + 5), radius=3, fill=ORANGE)

    dessin.multiline_text(
        (MARGE, y_trait + 26),
        SOUS_TITRE,
        font=police("Poppins-Medium.ttf", 21),
        fill=TEXTE_DOUX,
        spacing=8,
    )

    SORTIE.parent.mkdir(parents=True, exist_ok=True)
    # En RGB : Play accepte PNG ou JPEG, et une couche alpha ne sert à rien sur
    # une image qui remplit tout son cadre.
    image.convert("RGB").save(SORTIE, "PNG", optimize=True)
    print(f"  ✓ {SORTIE.relative_to(RACINE)} — {LARGEUR}x{HAUTEUR}")


if __name__ == "__main__":
    main()
