# Compteur d'heures (Flutter)

Application Flutter pour suivre les heures de travail au jour le jour, estimer l'heure de fin, et cumuler les statistiques.

## Fonctionnalites

- Pointage du jour : heure de debut/fin + pauses, estimation de fin et solde vs objectif.
- Calendrier : saisie des heures par jour, vue mois/semaine, interdiction des dates futures.
- Types de jour : travail, conge, maladie, pont, recup (saisie des heures desactivee hors "Travail").
- Statistiques : cumul global, objectifs, solde, moyenne, meilleurs jours.
- Themes : clair/sombre/auto + couleur principale.
- Image de fond : choix d'un visuel integre (avec un degrade par-dessus).
- Langues : Francais, Anglais, Italien, Allemand (ou systeme).
- Donnees locales : stockage dans un fichier JSON de l'app (pas de cloud).

## Demarrage rapide

1. Installer Flutter.
2. Si tu n'as pas encore de dossier `android/`, genere la base Android :
   - `flutter create . --platforms=android --project-name compteur_heures`
   - Si Flutter demande d'ecraser des fichiers, accepte puis remets `lib/` et `pubspec.yaml` de ce projet.
3. `flutter pub get`
4. `flutter run`
5. `flutter build apk --release`

## Notes

- Les pauses sont interpretees dans l'ordre de la liste.
- Les heures sont au format 24h.
- Les jours "Recup" impactent le solde.
