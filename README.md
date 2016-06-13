Cocobot
=======

Introduction
------------

Cocobot est un ensemble de scripts écrits en langage Perl pour créer des bots sur le site de chat « http://www.coco.fr/ ».

Les scripts ne fonctionnent qu'en ligne de commande et ont été testés et développés sur un système d'exploitation Ubuntu Linux et Debian.

Si vous n'êtes ni à l'aise avec Ubuntu Linux et Debian et ni à l'aise avec la ligne de commande, n'allez pas plus loin.

Installation
------------

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
