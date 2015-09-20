# Introduction #
Cette page documente le formulaire d'authentification du site Web « Coco.fr ».

# Authentification sur le site Web #

## Le formulaire HTML ##
L'authentification se fait sur la page « http://coco.fr/index.htm », qui contient un formulaire assez simple.

Le formulaire demande :
  * Un pseudo : un pseudonyme de 4 à 16 caractères. Variable **nicko**.
  * Le sexe : homme ou femme. Variable **typeo2**.
  * L'âge : un âge de 18 à 89 ans. Variable **ageu**.
  * Le code postal. Variable **zipo**.

La page HTML inclut le JavaScript « http://coco.fr/codinew.js ». Les premières lignes du script vont :
  * Attribuer une valeur aléatoire à la variable **cookav** comprise entre 100 000 000 et 990 000 000.
  * Charger un cookie du de nom de **coda**. Les valeurs récupérées dans la chaîne de caractères du cookie vont permettre d'initialiser les variables du formulaire **niko**, **ageu** et **zipo** ainsi que les variables JavaScript **typum**, **ageuq**, **townzz** et **citydio**.

Par exemple si la chaîne de caractères du cookie **coda** est la suivante : « Simon#1#37#PARIS#30915#0#745976486# », les variables seront initialisées comme suit :
  * **nicko** = "Simon"
  * **typum** = 1
  * **ageu** = 37
  * **zipo** = **townzz** = "PARIS"
  * **citydio** = 30915

## La fonction verifPseudo() qui vérifie le code postal ##
Un évènement **onKeyUp** est associé au champ **zipo** lorsque l'utilisateur entre son code postal. À chaque fois qu'une touche est relâchée, la fonction « verifPseudo() » du script « http://coco.fr/codipos.js ». est appelée.

Comme son nom ne l'indique pas la fonction « verifPseudo() » vérifie le code postal et charge un fichier JavaScript différent suivant le code postal entré.

Par exemple si l'utilisateur entre le code postal « _75001_ » le fichier « http://coco.fr/cocoland/75001.js » sera chargé. Le fichier chargé assigne une chaîne de caractère à la variable **cityco** et appelle la fonction « procecodo() »

Voici l'exemple du script « 75001.js » chargé :

```
var cityco='30915*PARIS*';
procecodo();
```

La fonction « procecodo() » initialise les variables **townzz** et **citydio**. Dans notre exemple ces deux variables sont initialisées comm suit :
  * **townzz** : PARIS
  * **citydio** : 30915

## La fonction validatio() ##

Lorsque le bouton « _Entrée_ » est pressé, la fonction « validatio() » du script « http://coco.fr/codipos.js » est appelée qui :
  * Vérifie que la longueur de la chaîne de caractères **nickidol** , le pseudonyme,  est supérieure à trois caractères.
  * Vérifie que la variable  **ageuq**, l'âge, est supérieure à au nombre quatorze.
  * Vérifie que le code postal a bien été entré en vérifiant la variable **citydio** et fabrique une chaîne de caractères **citygood** en copiant la valeur **citydio** précédée du nombre de caractères zéros nécessaires.
  * Créé la variable **infom** basé sur la concaténation des valeurs suivantes : `nickidol + "#" + typum + "#" + ageuq + "#" + townzz + "#" + citygood + "#0#" + cookav +"#"`. Voici un exemple :
    1. **nickidol** : Simon
    1. **typum** : 1
    1. **ageuq** : 37
    1. **townzz** : PARIS
    1. **citygood** :30915
    1. **cookav** : 186767980
    1. Ce qui donne la variable **infom** suivante : `Simon#1#37#PARIS#30915#0#186767980#`
  * Un cookie du de nom de **coda** est écrit avec une date durée de vie de dix ans. La valeur du cookie est la chaîne de caractères **infom**.

### Ouverture de la fenêtre de chat ###

Le script va ensuite construire l'URL suivante :
```
 urlprinc + "#" + nickidol + "#" + typum + "#" + ageuq + "#" + citygood + "#0#" + sauvy + "#" + referenz +"#" 
```
Où les variables suivantes sont toujours initialiser à :
  * **urlprinc** = "http://www.coco.fr/chat/"
  * **referenz** = "0"
  * **sauvy**    = **cookav**


Dans notre exemple 'URL « http://www.coco.fr/chat/#Simon#1#37#30915#0#186767980#0# » est chargée dans une nouvelle fenêtre du navigateur Web.