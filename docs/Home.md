# Cocobot

## Introduction

Cocobot est un ensemble de scripts écrits en [langage Perl](https://fr.wikipedia.org/wiki/Perl_(langage)) pour créer des bots sur le site de chat [Coco.fr](http://www.coco.fr/).

Les scripts ne fonctionnent qu'en ligne de commande et ont été testés et développés sur un système d'exploitation [Ubuntu Linux](https://fr.wikipedia.org/wiki/Ubuntu) et peuvent fonctionner également sous Debian Linux ou sur d'autres variantes de GNU/Linux, comme Fedora, OpenSuse,  Archlinux, ... 

Si vous n'êtes ni à l'aise avec Ubuntu Linux ou Debian et ni à l'aise avec la ligne de commande, n'allez pas plus loin.

## Installation

### Installation des dépendances

Ouvrir un GNOME Terminal et installer les paquets nécessaires, Git et quelques modules Perl en tapant la ligne suivante :

  sudo apt-get install git libconfig-general-perl libwww-perl libdbd-sqlite3-perl libnet-xmpp-perl


### Récupération des sources sur GitHub

Les scripts ne sont disponibles que récupérant les sources depuis GitHub :

  git clone https://github.com/simonrubinstein/cocobot.git


Utilisation des scripts
-----------------------

Il existe deux versions des scripts.

La première version ne se compose que d'un seul script monolithique, le script « cocoweb.pl », avec son fichier de configuration « cocoweb.conf ».

La deuxième version se compose d'une suite de scripts réécrites pour être plus modulaires. Les scripts se trouvent dans les répertoires « scripts » et « tools ». Les modules Perl, les bibliothèques utilisées dans le répertoire « lib » et les fichiers de configuration dans le répertoire « conf ».

### Première version du script « cocoweb.pl » ###

Le script « [cocoweb.pl](cocoweb.md) » est la première version développée est une commande autonome, sans bibliothèques externes, prenant une multitude d'options en paramètres. 

### Deuxième version modulaires des scripts ###

#### Les scripts du répertoire « scripts » ####

  * **bot-test.pl** : crée juste un bot connecté.
  * **checks-if-nickname-is-offline.pl** : crée un bot et vérifie qu'un pseudo donné est hors-ligne.
  * **create-myavatars.pl** : crée un bot et stocke l'avatar son mot de passe dans le répertoire « var/myavatar/new ».
  * **[db-search.pl](dbSearch.md)** : recherche dans la base de données enregistrés par le script « save-logged-user-in-database.pl ».
  * **get-amiz.pl** : crée un bot et affiche la liste des amis de ce bot.
  * **list-users.pl** : créé un bot et afficher la liste des utilisateurs connectés sur le tchat.
  * **loop-requests-report-abuse.pl** : crée des bots en boucle qui lancent des rapports d'abus sur un utilisateur connecté.
  * **loop-requests-to-be-a-friend.pl** : crée des bots en boucle qui font des demandes à un utilisateur connecté de faire parti de sa liste d'amis.
  * **[save-logged-user-in-database.pl](saveLoggedUserInDatabase.md)** : crée un bot et enregistre toutes les connexions et déconnexions dans une base de données. Ce script requiert un abonnement Premium.
  * **search-code.pl** : Crée un bot et cherche un pseudo d'après son code de vode. Ce script requiert un abonnement Premium.
  * **search-nickname.pl** : Crée un bot qui va rechercher un pseudo dans la liste des connectés.
  * **user-info.pl** : Crée un bot et donne des information sur le compte utilisé par le bot.
  * **write.pl** : Crée un bot et écrit un message à un utilisateur connecté.
  * **x-requests-to-be-a-friend.pl** : crée des bots en boucle qui lancent des demandes à des utilisateurs connectés de faire parti de sa liste d'amis.

#### Les scripts du répertoire « tools » ####
  * **check-alerts.pl** : vérifie que les alertes fonctionnent.
  * **check-cocoweb-user-list-data.pl** : vérifie le fichier « var/cocoweb-user-list.data »
  * **check-town-dump-file.pl** : Affiche la liste des _towns_ et _ISPs_ existants dans la base de données et n'existant pas dans les fichiers de configuration « conf/towns.txt » et « conf/ISPs.txt ».
  * **check-xmpp.pl** : vérifie que l'envoi d'un message XMPP utilisé par les alertes fonctionne.
  * **create-myavatars-list.pl** :
  * **get-town-code-from-coco.pl** :
  * **get-zip-citydio.pl** : récupère tous les codes spécifiques utilisés par Coco.fr pour les codes postaux. Ce script est utilisé pour générer le fichier « conf/zip-codes.txt ».
  * **get-zip-from-wikipedia.pl** :
  * **initializes-database.pl** : crée et peuple les tables de la base de données utilisés par le script « save-logged-user-in-database.pl » pour enregistrer toutes les connexions et déconnexions des utilisateurs sur Coco.fr.
  * **read-messages.pl** : affiche les réponses envoyés au bot créé par le script « save-logged-user-in-database.pl ».
  * **rivescript.pl** : Test RiveScript.
  * **sort-conf-plain-text-file.pl** : trie supprime les doublons des fichiers de configuration contenant une information par ligne, comme une liste de pseudos ou de citations.

