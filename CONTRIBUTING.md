# Guide de contribution

Ce document decrit les conventions a respecter pour contribuer a ce projet.

## Branches

- Jamais de commit direct sur `main` (ou `master`).
- Nomme les branches selon ce schema : `<type>/<description-courte-en-kebab-case>`
  - `feature/ajout-exercice-ecoute`
  - `fix/bug-streak-reset`
  - `chore/maj-dependances`
  - `refactor/nettoyage-composant-lesson`
  - `docs/readme-installation`
- Cree une nouvelle branche avant toute modification de code.

## Commits (Conventional Commits)

Format : `<type>(<scope>): <description au present, en minuscules, sans point final>`

Types autorises : `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`

Exemples :

```
feat(lesson): ajoute le mode revision espacee
fix(storage): corrige la perte de progression au refresh
ci(github-actions): ajoute le workflow de deploiement
```

- Un commit = un changement logique coherent, pas un fourre-tout.
- Jamais de message vague ("update", "fix stuff", "wip").
- Corps du commit (optionnel) : explique le "pourquoi", pas le "quoi" (le diff montre deja le quoi).

## Pull Requests

- Titre = meme format que les commits.
- Description structuree avec sections : `## Contexte` / `## Changements` / `## Tests effectues`.
- Toujours lier l'issue concernee si elle existe (`Closes #12`).
- Ne jamais merger automatiquement sans confirmation explicite du mainteneur.

## Versioning (SemVer)

- `MAJOR.MINOR.PATCH` (ex: `1.4.2`)
  - **MAJOR** : changement incompatible avec les versions precedentes
  - **MINOR** : nouvelle fonctionnalite retrocompatible
  - **PATCH** : correction de bug retrocompatible
- Mets a jour le `CHANGELOG.md` a chaque version taguee.
- Tag Git au format `vX.Y.Z` (ex: `v1.4.2`).

## CI/CD (GitHub Actions)

- Fichiers de workflow dans `.github/workflows/`, nommes en kebab-case : `ci.yml`, `deploy-prod.yml`, `lint-and-test.yml`.
- Noms de jobs explicites en anglais : `lint`, `test`, `build`, `deploy`.
- Separe toujours lint/test/build en jobs distincts plutot qu'un seul job monolithique.
- N'ajoute ou ne modifie jamais un secret/credential dans un workflow sans le signaler clairement dans la PR.

## Comportement general

- Avant toute modification, precise sur quelle branche le travail est effectue.
- Propose le message de commit avant de committer, sauf instruction deja validee.
- Ne pousse jamais (`git push`) sans confirmation explicite du mainteneur.
- Si une convention deja en place dans le repo differe de ce document, suivre les conventions existantes du repo plutot que ce guide.
