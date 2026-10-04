# Evolve Staff

Application Flutter pour les formateurs et les administrateurs Evolve Academy.
Elle permet de gérer les cours, les leçons, les formations, les devoirs, le suivi
des étudiants et les messages envoyés depuis le site Evolve School.

## Démarrage rapide

### Prérequis

- Flutter et Dart installés (`flutter doctor` doit être sans erreur bloquante)
- Git
- Un compte Evolve Staff autorisé (`teacher` ou `admin`)

### Installer et lancer

Depuis le dossier du projet :

```bash
flutter pub get
flutter run -d windows
```

Pour lancer sur une autre plateforme, remplacez `windows` par un appareil
disponible dans `flutter devices`. Si les dépendances sont déjà installées, vous
pouvez aussi lancer `flutter run`.

L’application est préconfigurée pour le projet Supabase partagé avec Evolve
School. Si vous utilisez un autre environnement, adaptez la configuration
publique Supabase dans `lib/main.dart`. **N’ajoutez jamais de clé `service_role`
ou de secret Chargily à l’application Flutter.**

## Se connecter

1. Connectez-vous avec l’adresse e-mail et le mot de passe du compte.
2. Le compte doit exister dans Supabase Auth et son profil doit avoir le rôle
   `teacher` ou `admin`.
3. Si l’accès est refusé, demandez à un administrateur de vérifier le rôle dans
   le profil du compte.

Les champs de connexion acceptent la touche Entrée, vérifient le format de
l’adresse e-mail et permettent d’afficher temporairement le mot de passe.

## Utiliser le tableau de bord

Le menu latéral donne accès aux espaces suivants :

| Espace | Utilisation |
| --- | --- |
| **Dashboard** | Vue d’ensemble et raccourcis vers les tâches courantes |
| **My Courses** | Rechercher, filtrer, créer, modifier et gérer les cours |
| **Lessons** | Parcourir les leçons |
| **Formations** | Organiser les cours en parcours |
| **Assignments** | Examiner et noter les travaux remis |
| **Students Progress** | Consulter la progression des étudiants |
| **Student Messages** | Répondre aux étudiants qui écrivent depuis le site |
| **Statistics** | Voir les compteurs de la plateforme |
| **Users & Roles** | Gérer les rôles et inviter des administrateurs |
| **Revenue** | Consulter les revenus enregistrés, leur répartition par cours et les paiements historiques sans montant |

Les cartes de statistiques et les raccourcis du tableau de bord sont
cliquables. Utilisez l’icône d’actualisation pour recharger les données.

Les administrateurs disposent aussi d’un aperçu des enseignants, des nouveaux
comptes, des cours publiés, des paiements en attente et des inscriptions payées,
ainsi que des dernières inscriptions de comptes. Les actions ouvrent directement
la gestion des utilisateurs, des cours ou des paiements.

L’invitation d’un administrateur nécessite le déploiement de la fonction
Supabase `invite-admin` et la configuration de l’envoi d’e-mails dans Supabase
Auth. Les revenus affichés proviennent des montants enregistrés au paiement ;
les anciens paiements sans montant conservé ou enregistrés à zéro sur un cours
payant sont signalés séparément. Le prix actuel du cours n’est pas utilisé pour
estimer un ancien paiement.
Les changements de rôle passent par un service réservé aux administrateurs ;
le dernier administrateur et le rôle de son propre compte sont protégés.
La liste des utilisateurs est chargée par la fonction Supabase réservée aux
administrateurs `admin-users`, afin de respecter les politiques RLS des profils.
Les administrateurs peuvent filtrer les cours à vérifier et publier ou
dépublier un cours après confirmation. La carte **Courses needing review**
ouvre directement les brouillons.
La page **Statistics** des administrateurs présente un graphique de tendance
mensuelle des inscriptions et des comptes, un graphique circulaire des statuts
de paiement, les cours les plus demandés, les revenus associés et les travaux
à corriger. Son rapport financier permet de sélectionner un mois, de comparer
les revenus enregistrés avec le mois précédent, de consulter les revenus par
cours et de télécharger le rapport au format CSV. Les webhooks de paiement
enregistrent la date réelle de réception pour les paiements futurs ; les
anciennes lignes sans date restent exclues des totaux mensuels et sont
signalées. Les administrateurs peuvent aussi saisir des dépenses ponctuelles
et des remboursements liés à une inscription payée. Le rapport présente le
mouvement net enregistré et des alertes de baisse des paiements, d’augmentation
des inscriptions en attente et de baisse des inscriptions par cours. Ces
chiffres ne représentent pas un bénéfice comptable : les frais de paiement et
les mouvements non saisis ne sont pas inclus.

### Messages étudiant-formateur

La messagerie utilise les tables partagées avec le site :

- `public.conversations`
- `public.direct_messages`

Une discussion apparaît dans **Student Messages** lorsque l’étudiant envoie le
premier message depuis Evolve School. Ouvrez la discussion, saisissez votre
réponse et envoyez-la ; elle apparaîtra dans la conversation de l’étudiant sur le
site. La boîte de réception permet de rechercher un étudiant, d’afficher les
messages non lus uniquement et de rafraîchir la liste. Les nouveaux messages
sont synchronisés en temps réel.

### Si un écran ne charge pas

1. Vérifiez votre connexion Internet et votre session.
2. Utilisez **Refresh** ou **Try again** sur l’écran.
3. Vérifiez que le rôle du compte et les données existent dans Supabase.
4. Si l’erreur persiste, transmettez son texte à l’administrateur ; ne collez
   jamais de clé secrète ou de jeton d’authentification dans un ticket.

## Développement et vérifications

Avant de proposer des changements :

```bash
dart format lib test
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub
```

Le même ensemble de contrôles est disponible via :

```bash
scripts/check.sh
```

GitHub Actions exécute ces vérifications lors des changements de code.
