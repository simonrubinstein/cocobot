VariablesDefinissantUnUtilisateur

# Variables définissant un utilisateur #

Voici une liste des variables JavaScript identifiant un utilisateur :

  * **mynickname** : Une chaîne alphanumérique contenant le pseudonyme de l'utilisateur.
  * **mynickID**   : L'identifiant numérique pour la session en cours. Par exemple la valeur « 218454 ».
  * **myage** : L'âge de l'utilisateur.
  * **mysex** : Le sexe de l'utilisateur : 1 pour homme, 2 pour femme
  * **mycityID** : Le code géographique spécifique à Coco.fr. Exemple le code « 30915 » correspond au code postal  « 75001 ».
  * **myXP** :
  * **myStat** :
  * **myver** : Si supérieur à 4 alors l'utilisateur a un abonnement Premium.

# Liste des utilisateurs #

Quand une code « _10_ » est envoyée dans une requête au serveur, celui-ci répond par un code « _34_ » avec la liste des pseudonymes. Les pseudonymes et les informations liées sont contenu dans une seule chaîne comme suit :

```
/#34AASCCCCCIIIIIIXSVPSEUDO1#AASCCCCCIIIIIIXSVPSEUDO2#AASCCCCCIIIIIIXSVPSEUDO3#...
```

Donc un pseudonyme et ses informations sont contenus dans une chaînes du style :
```
AA S CCCCC IIIIII X S V PSEUDO1
```
Où les caractères signifient :
  * **AA** : l'âge.
  * **S** : le sexe ( 1 ou 6 pour un homme, 2 ou 7 pour une femme).
  * **CCCCC** : Le code géographique.
  * **IIIIII** : L'identifiant numérique pour la session en cours.
  * **X** : correspond à _myXP_.
  * **S** : correspond _myStat_.
  * **V** : correspond à _myver_.
  * **PSEUDO1** : Le nom du pseudonyme en lui même.

Exemple pour la chaîne de caractères suivante : « 28230915218969104Simona ».
  * **Âge** : 28 ans.
  * **Sexe** : 2, identifiant une femme.
  * **Le code géographique** : 30915.
  * Identifiant de la session en cours : 220296
  * **myXP** : 1
  * **myStat** : 0
  * **myver** : 4
  * **Pseudonyme** : Simona

La fonction JavaScript _populate()_ éclate la chaîne dans différents tableaux :
  * **resage** : l'âge.
  * **ressex** : le sexe : 1 ou 6 pour un homme, 2 ou 7 pour une femme.
  * **rescity** : le code géographique.
  * **resID** :  m'identifiant de la session en cours.
  * **resnom** : le pseudonyme.
  * **resniv** : myXP
  * **resstat**: myStat
  * **resok** : myver










