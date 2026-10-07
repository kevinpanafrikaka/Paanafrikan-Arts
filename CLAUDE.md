# PaanafrikanArts

App iOS SwiftUI explorant les œuvres de l'**Art Institute of Chicago**
(API publique, sans clé). Projet capstone "Projet 6 — Galerie d'art"
(Orange Digital Center, formation développement mobile).

> Historique : le projet a démarré sur une autre idée (NMAfA/Smithsonian via
> un proxy Cloudflare perso) avant qu'on découvre le vrai brief et qu'on
> pivote entièrement dessus (2026-09-14). Le proxy Smithsonian n'est plus
> utilisé.

## Écrans

1. **Liste des œuvres** : grille d'images, ordre mélangé, scroll infini,
   recherche par mot-clé. Pas de filtre par catégorie : testé sous forme
   d'onglets sous le titre puis retiré à la demande de l'utilisateur
   (2026-09-14, jitter visuel gênant). Le filtrage API par catégorie
   (`query[term][artwork_type_id]`, voir plus bas) fonctionne et reste
   documenté si on veut réessayer avec une autre présentation UI.
2. **Détail** : grande image (zoom/pan), artiste, date, medium, dimensions,
   origine, description (traduisible en français), bouton favori, transition
   animée depuis sa vignette dans la grille
3. **Favoris** : sauvegardés en local (SwiftData), doivent rester
   affichables hors-ligne

## API

Base : `https://api.artic.edu/api/v1` — aucune clé requise, appel **direct**
depuis l'app (pas de proxy).

- `GET /artworks?page=1&fields=id,title,artist_display,image_id,date_display,medium_display,dimensions,place_of_origin,short_description,artwork_type_title`
  → liste paginée. Champs vérifiés en direct (2026-09-14) sur un artwork
  réel, tous existent mais sont **individuellement optionnels** (souvent
  `null`, surtout `place_of_origin`/`short_description`). On utilise
  `short_description` (texte simple) plutôt que `description` (contient du
  HTML `<p>`/`<em>`, pas géré côté client).
- `GET /artworks/search?q=...&page=1&fields=...` → recherche par mot-clé.
  **Important, vérifié en live (2026-09-14)** : le paramètre `&q=` sur
  `/artworks` (suggéré par le brief) ne filtre en réalité rien — mêmes
  résultats avec ou sans. Le vrai filtrage se fait sur `/artworks/search`.
  C'est cet endpoint qu'utilise `ArtInstituteService.searchArtworks`.
- `GET /artworks/search?query[term][artwork_type_id]=<id>&...` → filtre par
  catégorie. **Vérifié en live (2026-09-14)**, deux pièges :
  1. Le paramètre `query` attend la syntaxe à crochets `query[term][champ]=valeur`
     dans l'URL — envoyer un objet JSON sérialisé (`query={"term":{...}}`) est
     silencieusement ignoré (aucune erreur, juste pas de filtrage).
  2. `/artworks` (sans `/search`) ignore complètement ce paramètre, même
     avec la bonne syntaxe — il faut passer par `/artworks/search`, avec ou
     sans `q`.
  Filtrer par `artwork_type_id` (numérique, `/artwork-types`) fonctionne ;
  filtrer par `artwork_type_title` (texte) ne fonctionne pas (`term` fait un
  match exact sur le champ indexé, pas une recherche texte).

### Autres champs "catégorie" disponibles mais non utilisés (vérifiés le 2026-09-14)

`artwork_type_title` (ex: "Painting") est dans le modèle, affiché sur
l'écran détail. L'API expose aussi, si besoin plus tard :
`department_title` (département du musée), `category_titles` (tags
curatoriaux, array), `classification_titles` (classification technique,
array), `subject_titles` (thèmes représentés, array), `style_title`
(mouvement artistique, ex: "Pointillism").

### Forme de la réponse

```json
{
  "pagination": { "total": 132744, "limit": 20, "offset": 0, "total_pages": 6638, "current_page": 1 },
  "data": [
    { "id": 27992, "title": "A Sunday on La Grande Jatte", "date_display": "1884-86",
      "artist_display": "Georges Seurat", "image_id": "2d484387-2509-5e8e-2c43-22f9981972eb" }
  ],
  "config": { "iiif_url": "https://www.artic.edu/iiif/2" }
}
```

- `image_id` est **optionnel** : certaines œuvres n'ont pas d'image
  numérisée → `imageURL(for:)` renvoie `nil` dans ce cas, à gérer côté vue
  (placeholder), jamais de force-unwrap.
- Aucune URL d'image toute faite dans `data` : elle se construit avec
  `config.iiif_url` + `image_id`.

### Construction de l'URL image (IIIF)

Format vérifié sur `api.artic.edu/docs/#images` (ne pas deviner ni changer
sans revérifier la doc) :

```
{iiif_url}/{image_id}/full/843,/0/default.jpg
```

Implémenté dans `Models/IIIFImageURLBuilder.swift`. `iiif_url` ne doit
**jamais** être codé en dur ailleurs dans le code : il vient toujours de
`config.iiif_url` dans la réponse la plus récente.

### ⚠️ Piège : `www.artic.edu` exige un header `Referer`

Découvert le 2026-09-14 en debug (les images restaient en placeholder dans
l'app alors que l'URL s'ouvrait très bien dans Safari) : le CDN d'images
(`www.artic.edu`, différent de `api.artic.edu`) est derrière Cloudflare et
renvoie **403** à toute requête HTTP qui n'a pas de header `Referer` — testé
et confirmé en direct (`curl` sans `Referer` → 403, `curl -H "Referer:
https://www.artic.edu/" ...` → 200). Ce n'est pas un challenge JS
(`AIC-User-Agent` ou un `User-Agent` de navigateur seuls ne suffisent pas),
c'est bien spécifiquement l'absence de `Referer`.

Conséquence : `AsyncImage` est **inutilisable tel quel** ici (pas de moyen
d'ajouter des headers custom à sa requête). `Views/Components/ArtworkThumbnail.swift`
fait donc son propre chargement via `URLSession.shared.data(for:)` avec
`Referer: https://www.artic.edu/` posé manuellement, plutôt que d'utiliser
`AsyncImage`. Si jamais on réintroduit `AsyncImage` quelque part pour les
images IIIF, ce header doit être reproduit, sinon toutes les images
échouent silencieusement (état `.failure`, pas d'erreur visible côté UI
à part le placeholder).

## Architecture : MVVM

```
PaanafrikanArts/
├── Models/                     structs Codable pures, aucune logique
│   ├── Artwork.swift             → Artwork, Pagination, APIConfig, ArtworksResponse
│   └── IIIFImageURLBuilder.swift → fonction pure de construction d'URL image
├── Services/                    seule couche qui touche URLSession
│   ├── ArtInstituteServiceProtocol.swift → abstraction (permet le mock en test)
│   └── ArtInstituteService.swift  → implémentation réelle (struct, conforme au protocole)
├── ViewModels/                  état + logique de présentation, @Observable, jamais d'import SwiftUI
│   ├── ArtworkListViewModel.swift → state idle/loading/loaded/error, load(), search(), loadMore() (pagination)
│   └── FavoritesViewModel.swift   → lit/écrit FavoriteArtwork via un ModelContext passé en paramètre
├── Views/                       déclaratif pur, ne parle jamais au Service/ModelContext directement... sauf pour lire @Environment(\.modelContext) et le transmettre au ViewModel
│   ├── RootTabView.swift          → TabView (Œuvres / Favoris), racine de l'app
│   ├── ArtworkListView.swift      → grille + recherche + @Namespace pour la transition zoom vers Détail
│   ├── ArtworkDetailView.swift    → grande image zoomable (pinch/pan), infos (date/medium/dimensions/origine), description traduisible en français, bouton favori
│   ├── FavoritesView.swift        → grille des favoris, hors-ligne, cliquable vers Détail (via `favorite.asArtwork`), bouton "x" en overlay pour retirer directement
│   └── Components/
│       ├── ArtworkThumbnail.swift → chargement image maison (pas AsyncImage, voir piège Referer ci-dessus). `contentMode: .fill` (défaut, grille) ou `.fit` (détail, œuvre entière visible). Taille de carte imposée via `GeometryReader` : le format natif de l'image (portrait/paysage/carré, variable selon l'œuvre) n'a aucune influence sur la taille de la cellule, seul son contenu est recadré/letterboxé dedans
│       ├── ArtworkGridCell.swift  → cellule de grille générique (title/subtitle/imageURL), réutilisée par liste ET favoris ; hauteur de texte fixe (46pt) pour aligner les cellules d'une même ligne
│       ├── SkeletonGridCell.swift → placeholder animé (pulse) pendant le premier chargement de la grille, à la place d'un spinner plein écran
│       └── FavoriteButton.swift
└── Storage/                     persistance SwiftData, séparée de Models
    └── FavoriteArtwork.swift      → @Model : id (unique), title, artistDisplay, dateDisplay, imageURL, savedAt. `asArtwork` (extension) reconstruit un `Artwork` partiel (medium/dimensions/placeOfOrigin/shortDescription = nil) pour rouvrir ArtworkDetailView depuis un favori
```

Règles :
- **Model** : aucune logique métier, juste la structure des données de l'API.
- **Service** : exposé via un protocole (`ArtInstituteServiceProtocol`) pour
  permettre l'injection d'un mock dans les tests de ViewModel.
- **ViewModel** : `@Observable final class`. `ArtworkListViewModel` reçoit
  le service en paramètre d'init (défaut = `ArtInstituteService.shared`).
  `FavoritesViewModel` reçoit le `ModelContext` par méthode (pas à l'init :
  `@Environment(\.modelContext)` n'est pas fiable dans l'init d'un objet
  créé via `@State`).
- **View** : possède son ViewModel via `@State`. `FavoritesViewModel` est
  partagé entre écrans via `.environment(favoritesViewModel)` posé sur le
  `TabView` de `RootTabView`, lu ensuite avec
  `@Environment(FavoritesViewModel.self)`.
- **Storage** : dossier séparé de `Models`, ne contient que ce qui touche
  SwiftData. `FavoriteArtwork` copie `title`/`artistDisplay`/`dateDisplay`
  et **l'URL image déjà résolue** (pas juste `image_id`) au moment de
  l'ajout aux favoris — hors-ligne, `config.iiif_url` n'est pas disponible
  pour la reconstruire.
- **Pagination** : `fetchArtworks`/`searchArtworks` prennent un `limit`
  explicite (30/page, sinon l'API applique son défaut minimal). **Scroll
  infini** (pas de bouton "Charger plus") : `onAppear` sur la dernière
  cellule de `viewModel.artworks` déclenche `loadMore()`. `loadMore()`
  échoue silencieusement (la liste déjà chargée reste affichée, le
  prochain passage en bas de la liste retente).
- **Ordre mélangé** : `fetchFirstPage`/`loadMore` font `.shuffled()` sur
  les résultats reçus avant de les afficher, pour ne pas toujours montrer
  les œuvres dans le même ordre. Le mélange ne porte que sur le lot
  nouvellement chargé (pas sur tout `artworks`), pour que les œuvres déjà
  affichées ne changent pas de position pendant le scroll infini.
- **Traduction (Détail)** : framework `Translation` d'Apple, **on-device**,
  déclenché à la demande via `TranslationSession.Configuration` +
  `.translationTask(...)` (pas de clé API, cohérent avec le reste du
  projet). Traduit `shortDescription` (EN → FR). ⚠️ Ne fonctionne pas dans
  le Simulateur iOS — le modèle de langue doit être téléchargé sur
  l'appareil, à tester sur un vrai iPhone.
- **Transition grille → Détail** : `matchedTransitionSource(id:in:)` sur la
  `NavigationLink` de la grille + `.navigationTransition(.zoom(sourceID:in:))`
  sur la destination (API iOS 18, `@Namespace` partagé dans `ArtworkListView`).

Tests : `PaanafrikanArtsTests/` utilise le framework **Swift Testing**
(`import Testing`, `@Test`, `#expect`, pas XCTest). `Mocks/MockArtInstituteService.swift`
permet de tester `ArtworkListViewModel` sans réseau ;
`FavoritesViewModelTests.swift` utilise un `ModelContainer` SwiftData en
mémoire pour tester `FavoritesViewModel` sans toucher au disque.

## Conventions de code

- SwiftUI + async/await + `URLSession` natif (pas de dépendance réseau
  tierce).
- Projet Xcode 16 à groupes synchronisés (`PBXFileSystemSynchronizedRootGroup`,
  y compris pour la target de tests) : tout fichier déposé dans les dossiers
  du projet est détecté automatiquement, pas besoin d'éditer `project.pbxproj`.
- Bundle : Organization Identifier `com.paanahub`, Product Name
  `PaanafrikanArts`. Deployment target iOS 18.2.
