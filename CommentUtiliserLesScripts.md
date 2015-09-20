# Introduction #

Les scripts ne fonctionnent qu'en ligne de commande et ont été testés et développés sur un système d'exploitation Ubuntu Linux et Debian.

Si vous n'êtes ni à l'aise avec  Ubuntu Linux et Debian et ni à l'aise avec la ligne de commande, n'allez pas plus loin.

# Installation #

## Installation des dépendances ##

Ouvrir un GNOME Terminal et installer les paquets nécessaires, Subversion et quelques modules Perl en tapant la ligne suivante :

```
  sudo aptitude install subversion libconfig-general-perl libwww-perl libdbd-sqlite3-perl

```

## Récupération des sources sur Subversion ##

Les scripts sont en cours de développement, et ne seront peut-être, jamais finalisés. Pour télécharger les scripts récupérer les sources directement sur le dépôt Subversion avec la commande suivante :

```
  svn checkout http://cocobot.googlecode.com/svn/trunk/ cocobot-read-only
```


## Utilisation des scripts ##

Il existe deux versions des scripts.

La première version ne se compose que d'un seul script monolithique, le script « cocoweb.pl », avec son fichier de configuration « cocoweb.conf ».

La deuxième version se compose d'une suite de scripts réécrites pour être plus modulaires. Les scripts se trouvent dans les répertoires « scripts » et « tools ». Les modules Perl, les bibliothèques utilisées dans le répertoire « lib » et les fichiers de configuration dans le répertoire « conf ».

### Première version du script « cocoweb.pl » ###

Cette première version du script est une commande prenant une multitude d'options en paramètres.


```bash

./cocoweb.pl
Usage:
cocobot.pl -a action [-u searchUser -i searchId -m message
-x writeLoop -w writeRepeat -z zipCode -y old -l loginName -d -v -n
-f customNickname]
-m message        Un message
-a action         Actions : alert, search, idiot, string, pb, login, hello, list ou write
-u searchUser     Un nom utilisateur.
-i searchId       Un identifiant numérique du pseudo.
-x writeLoop      Nombre de boucles.
-w writeRepeat    Nombre de répétions.
-s sex            M pour homme et W pour femme.
-z zipCode        Un code postal, par exemple 75001.
-y old            Un âge, exemple 37 ans.
-l loginName      Le nom écrit dans les messages.
-v                Mode verbeux.
-d                Mode debug.
-n                Mode test.
-f customNickname Une liste de pseudo.
```


Le script doit toujours être lancé avec une option -a qui correspond à une action.

#### Action « list » ####

L'action « list » énumère les pseudos présents sur le chat. Les résultats peuvent-être filtrés, par exemple cette commande énumère les pseudos femmes :
```
./cocoweb.pl -s W -a list 
0
! missmoi          ! 7 ! 18 ! 30925 ! 187979 ! 0 ! 0 ! 0 !
! titeprincesse    ! 7 ! 49 ! 30923 ! 169086 ! 2 ! 7 ! 0 !
! typh             ! 2 ! 19 ! 30926 ! 188376 ! 0 ! 0 ! 0 !
! adoredouchedoree ! 2 ! 26 ! 30916 ! 201736 ! 0 ! 0 ! 0 !
! friandise        ! 2 ! 40 ! 30915 ! 168651 ! 0 ! 0 ! 0 !
```

### Deuxième version modulaires des script ###

#### Les scripts du répertoire « scripts » ####

  * **bot-test.pl** : crée juste un bot connecté.
  * **checks-if-nickname-is-offline.pl** : crée un bot et vérifie qu'un pseudo donné est hors-ligne.
  * **db-search.pl** : recherche dans la base de données enregistrés par le script « save-logged-user-in-database.pl ».
  * **get-amiz.pl** : crée un bot et affiche la liste des amis de ce bot.
  * **list-users.pl** : créé un bot et afficher la liste des utilisateurs connectés sur le tchat.
  * **loop-requests-report-abuse.pl** : crée des bots en boucle qui lancent des rapports d'abus sur un utilisateur connecté.
  * **loop-requests-to-be-a-friend.pl** : crée des bots en boucle qui font des demandes à un utilisateur connecté de faire parti de sa liste d'amis.
  * **save-logged-user-in-database.pl** : crée un bot et enregistre toutes les connexions et déconnexions dans une base de données. Ce script requiert un abonnement Premium.
  * **search-code.pl** : Crée un bot et cherche un pseudo d'après son code de vode. Ce script requiert un abonnement Premium.
  * **user-info.pl** : Crée un bot et donne des information sur le compte utilisé par le bot.
  * **write.pl** : Crée un bot et écrit un message à un utilisateur connecté.

#### Les scripts du répertoire « tools » ####
  * **initializes-database.pl** : crée et peuple les tables de la base de données utilisés par le script « save-logged-user-in-database.pl » pour enregistrer toutes les connexions et déconnexions des utilisateurs sur Coco.fr.
  * **get-town-code-from-coco.pl** :
  * **check-xmpp.pl** : vérifie que l'envoi d'un message XMPP utilisé par les alertes fonctionne.
  * **get-zip-citydio.pl** : récupère tous les codes spécifiques utilisés par Coco.fr pour les codes postaux. Ce script est utilisé pour générer le fichier « conf/zip-codes.txt ».
  * **check-town-dump-file.pl** : Affiche la liste des _towns_ et _ISPs_ existants dans la base de données et n'existant pas dans les fichiers de configuration.
  * **get-zip-from-wikipedia.pl** :
  * **sort-conf-plain-text-file.pl** : trie supprime les doublons des fichiers de configuration contenant une information par ligne, comme une liste de pseudos ou de citations.
  * **read-messages.pl** : affiche les réponses envoyés au bot créé par le script « save-logged-user-in-database.pl ».

#### Exemple d'utilisation ####

##### Le script user-info.pl #####

Ce script créé un bot et affiche certaines informations du bot créé. En passant les les valeurs « myavatar » et « mypass » d'un compte Premium, le script retourne le nombre de jours avant l'expiration de l'abonnement :

```
./user-info.pl -a 175874896 -p XYJSMECJOFDITYYDAXST  -s M -y 37 -u Simon
mynickname: Simon
myage:      37  
mysex:      1   
zip:        75017
mynickID:   100098
monpass:    XpcKLD
myavatar:   175874896
mypass:     XYJSMECJOFDITYYDAXST
townzz:     PARIS
citydio:    30931
mystat:     0   
myXP:       0
myver:      4   
code:       ZJ8
ISP:        Free SAS 
status:     0   
premium:    1   
level:      6   
since:      0   
town:       FR- Paris
Il vous reste 7 jours avant expiration de votre abonnement premium
execution time: 1 seconds
```









