# Compteur d'heures (Flutter)

Application Flutter pour calculer l'heure de fin en fonction d'un objectif en heures decimales, d'une heure de debut et de pauses multiples.

## Demarrage rapide

1. Installer Flutter.
2. Si tu n'as pas encore de dossier `android/`, genere la base Android :
   - `flutter create . --platforms=android --project-name compteur_heures`
   - Si Flutter demande d'ecraser des fichiers, accepte puis remets `lib/main.dart` et `pubspec.yaml` de ce projet.
3. `flutter pub get`
4. `flutter run`

## Notes
- Les pauses sont interpretees dans l'ordre de la liste.
- Les heures sont au format 24h.
