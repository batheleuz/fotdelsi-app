import type { GoldieConfig } from "goldie";

/**
 * Assets App Store de FOTDELSY.
 *
 * ─── Le binaire est la VITRINE, pas l'app ordinaire ───
 *
 * `appPath` pointe sur un build de `lib/main_showcase.dart` : réseau simulé,
 * session client déjà ouverte, données figées. Deux raisons, et la seconde
 * est celle qui compte :
 *
 *  1. Une capture marketing ne doit pas dépendre de l'état réel de la laverie
 *     — un jour sans lavage donnerait des écrans vides.
 *  2. Goldie réinstalle l'app avec des données effacées avant CHAQUE flow.
 *     La vitrine ressème sa session à chaque lancement ; l'app ordinaire
 *     s'ouvrirait sur l'écran de liaison du numéro, et aucun flow ne
 *     passerait.
 *
 * Le build ne fixe PAS `SHOWCASE_ROUTE` : Goldie relance le même binaire pour
 * chaque scène, donc les flows naviguent dans l'interface au lieu de sauter à
 * une route.
 *
 * Reconstruire après toute modification des fixtures :
 *     flutter build ios --simulator --debug -t lib/main_showcase.dart
 */
const APP_ROOT = "/Users/marndiaye/workspace/client-projects/fotdelsy/app";

const config: GoldieConfig = {
  appRoot: APP_ROOT,
  appPath: `${APP_ROOT}/build/ios/iphonesimulator/Runner.app`,
  bundleId: "sn.fotdelsi.app",

  devices: ["iphone-6.9"],
  locales: ["fr-FR"],
  appearance: "light",

  frame: { variant: "17-pro-blue" },

  theme: {
    // Le bleu de la marque en très pâle, vers le blanc : les captures sont
    // elles-mêmes claires, un fond sombre les découperait comme des vignettes.
    background: "linear-gradient(160deg, #E8F0FC 0%, #F5F8FC 55%, #FFFFFF 100%)",
    headlineColor: "#0F1B2D",
    subheadColor: "#5A6B85",
    fontFamily: '"Montserrat", -apple-system, system-ui, sans-serif',
    copyHeightRatio: 0.24,
    deviceWidthRatio: 0.84,
    layout: "classic",
  },

  store: {
    name: "Fotdelsi",
    subtitle: { "fr-FR": "Votre laverie, sans attendre" },
    developer: "FOT DELSI",
    category: "Style de vie",
    ageRating: "4+",
    price: "Gratuit",
    description: {
      "fr-FR":
        "Scannez la machine, payez avec Wave ou Orange Money, et lancez votre " +
        "cycle. Suivez vos lavages en cours et recevez une notification dès " +
        "que votre linge devrait être prêt.\n\n" +
        "Confiez aussi votre linge au comptoir : pliage et repassage, avec le " +
        "suivi étape par étape depuis l'application.",
    },
  },

  scenes: [
    {
      kind: "screenshot",
      id: "accueil",
      flow: "store-01-accueil",
      headline: { "fr-FR": "Toute la laverie dans votre poche" },
      subhead: { "fr-FR": "Choisissez votre formule, payez avec Wave ou Orange Money." },
    },
    {
      kind: "screenshot",
      id: "scan",
      flow: "store-02-scan",
      // « c'est payé » et non « c'est lancé » : l'application envoie une
      // commande de démarrage, et c'est la personne devant l'appareil qui
      // appuie sur Démarrer. L'écran capturé le dit lui-même.
      headline: { "fr-FR": "Le QR de la machine, et c'est payé" },
      subhead: { "fr-FR": "Ni monnaie, ni file d'attente. Wave ou Orange Money." },
    },
    {
      kind: "screenshot",
      id: "cycle",
      flow: "store-03-cycle",
      // Le décompte a disparu avec le relevé EQLink : plus aucune machine ne
      // sait dire son temps restant. Ces deux lignes le promettaient encore.
      // Ce que l'écran montre vraiment, c'est le temps ÉCOULÉ, et la notif
      // annonce au conditionnel — « votre linge devrait être prêt ».
      headline: { "fr-FR": "Sachez où en est votre linge" },
      subhead: {
        "fr-FR":
          "Le temps écoulé depuis le démarrage, et une notification quand " +
          "votre linge devrait être prêt.",
      },
    },
    {
      kind: "screenshot",
      id: "cycles",
      flow: "store-04-cycles",
      headline: { "fr-FR": "Tous vos lavages au même endroit" },
      // « leur durée » et non « leur durée réelle » : le qualificatif laissait
      // entendre une mesure venue de la machine, qu'on n'a plus.
      subhead: { "fr-FR": "Les cycles en cours et l'historique, chacun avec sa durée." },
    },
    {
      kind: "screenshot",
      id: "finition",
      flow: "store-05-finition",
      headline: { "fr-FR": "Prévenu dès que c'est prêt" },
      subhead: { "fr-FR": "Pliage et repassage suivis étape par étape." },
    },

    /**
     * L'aperçu vidéo suit le parcours dans son ordre réel : on choisit, on
     * scanne, on suit son cycle, on suit sa finition. Les segments s'enchaînent
     * dans une seule session — chacun reprend là où le précédent s'est arrêté,
     * d'où les `executionPrerequisite` à partir du deuxième.
     *
     * Apple impose un enregistrement d'écran nu : ni cadre, ni légende. Les
     * clips sont donc joints tels quels, et la durée totale doit tomber entre
     * 15 et 30 secondes — `goldie preview` refuse en dehors.
     */
    {
      kind: "preview",
      id: "parcours",
      segments: [
        { id: "accueil", flow: "store-preview-01-accueil" },
        { id: "scan", flow: "store-preview-02-scan" },
        { id: "cycle", flow: "store-preview-03-cycle" },
        { id: "finition", flow: "store-preview-04-finition" },
      ],
    },
  ],
};

export default config;
