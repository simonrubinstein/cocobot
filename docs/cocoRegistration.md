# Introduction #

Normalement, le site Coco.fr se prétend être un chat sans inscription. C'est à dire que l'entrée d'un pseudo, du sexe, de l'âge et du code postal suffisent à utiliser le chat.

Dans la réalité, même si l'utilisateur n'est pas inscrit, Coco.fr conserve un cookie dans le navigateur web du client pour identifier l'utilisateur à sa prochaine connexion.

De plus Coco.fr propose un abonnement _Premium_ qui donne des informations sur les autres pseudos, comme un « code de vote » , l'origine géographique d'où est connecté le pseudo, le FAI, ... Le « code de vote » est un identifiant composé de trois caractères, plus ou moins unique, du pseudo. Des exemples de « codes de vote » sont : **cZj**, **23m**, **WcL** ou **PXd**. Parois certains pseudos peuvent partager ce « code de vote ». L'origine géographique est une ville, exemple « **FR- Paris** », l'origine géographique n'est pas toujours fiable et peut parfois indiquer un point de connexion de plus de cent kilomètres du point réel de connexion.

Les scripts Cocobot peuvent utiliser un abonnement _Premium_, mais pour cela l'utilisateur doit souscrire un abonnement sur le site Coco.fr.

Cette documentation montre comment souscrire un abonnement _Premium_ et ensuite utiliser cet abonnement dans les scripts _Cocobot_ en ligne de commande.

## Se connecter sur Coco.fr ##

Se rendre sur le site http://www.coco.fr/ et entrer un pseudo, un sexe, un âge et un code postal :

![Connexion sur le site web Coco.fr](images/coco-subscribe/coco-login.png)

Cliquer sur le bouton « Entrée », la fenêtre de chat s'ouvre.

## Authentification e-mail ##

Cette étape n'est pas indispensable, mais utiliser l'authentification e-mail permet d'associer son profil à une adresse e-mail et de pouvoir éventuellement récupérer son profil par e-mail.

Cliquer sur le bouton « Profil » et ensuite sur « Mail Non » :

![Bouton Profil et Mail Non](images/coco-subscribe/coco-profil.png)

Rentrer une adresse e-mail dans la boîte de dialogue venant de s'ouvrir :

![Entrer un adresse électronique](images/coco-subscribe/coco-e-mail-input.png)

Se rendre dans sa messagerie, ouvrir le courriel reçu de « contact@coco.fr » et cliquer sur le lien hypertexte de validation de l'adresse e-mail rentrée :

![Valider l'adresse électronique](images/coco-subscribe/coco-gmail.png)

Après le clic le sur le lien hypertexte de validation, une page web s'affiche informant du succès de la validation :

![Succès de la validation](images/coco-subscribe/coco-success-verification.png)

La validation est terminée, retourner sur la fenêtre de chat Coco.fr.

## Souscrire à l'abonnement Premium ##

De retour dans la fenêtre de chat, cliquer sur le bouton « Premium », une nouvelle fenêtre s'ouvre proposant trois types de packs Premium :
  * 1 mois : 5 €
  * 3 mois : 11 €
  * 1 an : 44 €

Cliquer sur « 1 mois : 5 € » :

![1 mois : 5 €](images/coco-subscribe/coco-pack-premium.png)

Rentrer une adresse e-mail dans le champ correspondant afin de recevoir un reçu de paiement :

![Entrer une adresse électronique](images/coco-subscribe/coco-input-confirmation-email.png)

Rentrer un numéro de carte bancaire, une date de fin de validité et un cryptogramme visuel. Puis cliquer le bouton « Valider » pour valider le paiement :

![Cliiquer le bouton Valider](images/coco-subscribe/coco-payment.png)

Une nouvelle page s'affiche en cas de réussite du paiement :

![Réussite du paiement](images/coco-subscribe/coco-payment-success.png)

Fermer la fenêtre précédente et retourner sur la fenêtre de chat. Sélectionner un pseudo et cliquer sur le bouton _info_ qui est en forme de point d'interrogation. Si trois lignes s'affichent dans la fenêtre de chat cela signifie que la souscription au _pack Premium_ est activé :

![Résultat du bouton info](images/coco-subscribe/coco-info.png)

Si le bouton _info_ ne fonctionne pas, fermer la fenêtre de _tchat_ et reconnectez-vous.

## Récupération des valeurs de « myavatar »  et « mypass » ##

L'utilisateur est authentifié par deux valeurs, appelées « myavatar »  et « mypass », concaténées et contenues dans le cookie portant le nom « samedi ».

Dans Mozilla Firefox, cliquer sur l'icône en forme de point d'interrogation juste à gauche de l'URL dans la barre d'adresse. Une petite boîte de dialogue s'affiche, cliquer ensuite sur le signe « > » à droite de « www.coco.fr » :
![Information site web](images/coco-subscribe/coco-website-info.png)

Le panneau défile, ensuite cliquer en bas sur « Plus d'informations » de cette boîte de dialogue :

![Cliquer bouton Plus d'informations](images/coco-subscribe/coco-more-info.png)

La boîte de dialogue d'informations sur la page s'ouvre. Cliquer sur le bouton « Voir les cookies » :

![Voir les cookies](images/coco-subscribe/coco-view-cookies.png)

Une autre boîte de dialogue « Cookie » s'ouvre. Chercher le cookie « samedi » et cliquer dessus. Dans le champ contenu s'affiche les valeurs concaténées de  « myavatar »  et « mypass ».

![Le cookie samedi](images/coco-subscribe/coco-samedi-cookie.png)

Dans cet exemple, la valeur du cookie est « 786919131WKHBNCONUGADQYKEIOFA » :
  * « myavatar » correspond aux neufs premiers chiffres c'est à dire « 786919131 »
  * « mypass » correspond au vingt derniers caractères alphabétiques c'est à dire « WKHBNCONUGADQYKEIOFA ».


Les valeurs de « myavatar »  et « mypass »  peuvent être passées en argument aux scripts avec respectivement les options « -a » et « -p ».

Exemples d'utilisation des ces deux valeurs avec le script « list-users.pl » :

```
cd ~/cocobot-read-only/scripts/
./list-users.pl -a 786919131 -p WKHBNCONUGADQYKEIOFA
```
Le script « list-users.pl » retourne un nombre d'utilisateurs beaucoup plus important lorsque le compte a souscrit un abonnement _Premium_.
