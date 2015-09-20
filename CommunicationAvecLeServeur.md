# Communication avec le serveur #

Le code JavaScript communique avec le serveur en exécutant des requêtes HTTP avec la méthode GET sur une adresse IP et un port donné.

Il existe deux types de requêtes :
  * La requête initiale d'authentification lancée avant toutes les autres.
  * Les autres requêtes.

# La requête initiale #

La requête initiale est la toute première requête lancée c'est la requête qui sert à authentifier l'utilisateur avec son **myavatar** et **mypass**.

_Syntaxe de la requête_ : **40** + **mynickname** + **`*`** + **myage** + **mysex** + **mycityID**  + **myavatar** + **speco** + **mypass** + **?** + **Random**

  * La valeur **speco** est toujours initialisée à zéro.
  * **myavatar** : Identifiant unique de l'utilisateur de neuf chiffres décimaux. Cet identifiant unique, sauvegardé dans le cookie **samedi**, est toujours le même à moins que l'utilisateur efface ses cookies ou utilise la navigation privée.
  * **mypass** : Mot de passe de vingt caractères alphabétiques associé à l'identifiant unique de l'utilisateur précédent. À la première connexion le mot de passe n'existe pas encore, la chaîne de caractères est vide.
  * **Random** est un nombre décimal compris en 0 et 10 000 000.

_Retour de la requête_ : **12** + **mynickID** + **monpass** + **mycrypt** + **mycrypt2** + **0** +  **code-pays**

  * **mynickID** : Identifiant pour la session en cours, susceptible de changer à chaque connexion.
  * **monpass**  : Mot de passe de l'identifiant pour la session en cours modifié à chaque connexion.
  * **mycrypt** et **mycrypt2** semblent ne pas être utilisés.
  * **code-pays** : Semble être le code ISO 3166-1 alpha-2 du pays, c'est à dire **FR** dans la majorité des cas.

Exemple d'une requête :
```
http://46.105.32.143:80/40Simon*371309328813008330?7619933.453716727
```

Qui retourne :
```
process1(#12183616UpzIoL11537742395958620*FR)
```
  * **mynickID** : 183616
  * **monpass** : UpzIoL
  * **mycrypt** : 1153774 (récupéré mais inutilisé)
  * **mycrypt2** : 239595862 (récupéré mais inutilisé)
  * **code-pays** : FR (non récupéré)

## Les autres requêtes ##

Le second type de requête est constitué ainsi :
` http:// adresseIP + : + myport + / + code +  mynickID + monpass + params`

  * **adresseIP** : Toujours l'adresse IP « 46.105.32.143 ».
  * **myport**    : Le numéro de port TCP toujours 80.
  * **code**      : Un code numérique identifié la commande, comme par exemple 10, 89, 48, ...
  * **mynickID**  : l'identificateur numérique unique du pseudonyme pour la session en cours.
  * **monpass**   : le mot de passe de la session en cours.
  * **params**    : les éventuels paramètres.

Exemple d'une requête :
` http://46.105.32.143:80/10327709RObSoa00 `
  * **adresseIP** : 46.105.32.143
  * **myport**    : 80
  * **code**      : 10
  * **mynickID**  : 10327709
  * **monpass**   : RObSoa
  * **params**    : 00

Cette requête recherche et retourne la liste des pseudonymes. Le code « 10 » demande la recherche des pseudonymes.  Les paramètres sont les deux valeurs numériques collées des variables **genru** et **yearu**.

### Liste des requêtes connues ###

##### Requêtes 83 / 33000000 : Retourne informations sur un code vote #####
Syntaxe de la requête : **83** + **mynickID** + **monpass** + **33000000** + **code**

Retour de la requête : **99** + **557** + **mynickID** + **myage** + **mysex** + **mynickname**

Exemple de requête qui demande des informations sur le code vote « MYY »:
```
http://46.105.32.143:80/83201207hwZTEQ733000000MYY
```
Qui retourne :
```
process1('#9955718252999309297Laws'); 
```

  * **mynickname** : Laws
  * **myage**      : 99 (99 ans signifie que l'utilisateur n'est plus connecté actuellement.)
  * **mynickID**   : 182529 (ID de la session en cours ou de la dernière session.)
  * **citydio**    : 30929 (code pour le code postal 75015)
  * **mysex**      : 7 (pseudo femme avec avatar)






## Quelques codes de retour ##

  * 12 : réponse à une commande  « 40 », première authentification avec l'identifiant de l'avatar et le mot de passe réussie.
  * 99555 : information sur un pseudonyme utilisé en pressant le bouton « ? ». Réservé à un abonnement Premium.
  * 99556 : réponse à une commande  « 51 », deuxième authentification avec l'identifiant et le mot de passe de la session réussie.
  * 34 : réponse à une commande « 10 », retourne la liste des pseudos
  * 89 : réponse à une commande « 89 », retourne la liste des salons
  * 48 : réponse à une commande « 48 », retourne la liste des « amiz », c'est à dire les pseudonymes de la liste de contacts.