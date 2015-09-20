# Introduction #

Cette page documente le processus d'initialisation et authentification de l'utilisateur.

## Initialisation de la page ##


Quand la page «  http://www.coco.fr/chat/index.html#nickidol#typum#ageuq#citygood#0#sauvy#0# » est appelée et chargée les trois fonctions suivants sont exécutées séquentiellement :
  * **primo()** à la ligne 927 du fichier « initio.js ».
  * **initial()** à la ligne 1 251 du fichier « initio.js ».
  * **resinit()** à la ligne 551 du fichier « onglet.js ».

### Cookie Flash ###

La page « http://www.coco.fr/chat/index.html » comporte une animation [Abobe Flash](http://fr.wikipedia.org/wiki/Adobe_Flash_Player) invisible « http://www.coco.fr/chat/chat.swf » utilisée uniquement pour disposer des _cookies Flash_, appelé les [objets locaux partagés (en anglais Local Shared Objects ou LSO](http://fr.wikipedia.org/wiki/Local_Shared_Object)).
```html

<object classid='clsid:d27cdb6e-ae6d-11cf-96b8-444553540000' id='flash' width='1' height='1'>
<param name='movie' value='chat.swf' />
<embed src='chat.swf' name='flash' width='1' height='1' type='application/x-shockwave-flash' />


Unknown end tag for &lt;/object&gt;


```

La valeur du _cookie Flash_ est lue par la fonction « crocu() ».

### Fonction « primo() » ###

La fonction « primo() » déclarée à la ligne 927 du fichier « http://www.coco.fr/chat/initio.js » est la première fonction appelée déclarée dans l'attribut `onload()` de la balise `<body>`.

La fonction « primo()» va lire le contenu de la barre d'adresse. Dans notre exemple la barre d'adresse est égale à «  http://www.coco.fr/chat/#Simon#1#37#30915#0#186767980#0# ».

Les paramètres passées dans l'URL sont éclatés dans le tableau de la variable **parami** :
```
parami = [
    "Simon",
    "1",
    "37",
    "30915",
    "0",
    "186767980" ];
```

Certaines variables sont initialisées à partir de ce tableau :

  * **mynickname** = "Simon"
  * **mylownick** = "simon"
  * **mygender**  = "1"
  * **mysex**     = 1
  * **myage**     = 37
  * **mycityID**   = 30915


La chaîne de l'agent utilisateur du navigateur Web est transformé par la fonction « writo() » et assigné dans la variable **agento**. Cette variable sera par la suite envoyée au serveur.

Dans notre exemple notre agent utilisateur est « Mozilla/5.0 (Ubuntu; X11; Linux x86\_64; rv:8.0) Gecko/20100101 Firefox/8.0 » ce qui donnera la chaîne de caractères suivante :
  * **agento**     = "Mozilla/5.0~(Ubuntu;~X11;~Linux~x86\*064;~rv:8.0)~Gecko/20100101~Firefox/8.0"

La variable **myport** est initialisée avec la valeur « 80 »
  * **myport** = 80

La variable **url1** est initialisée par l'appel de la méthode « chang(nmh) » où **mnh** correspond au numéro de port (toujours 80).

  * **url1** = "http://46.105.32.143:80/"

Cette URL est l'URL utilisée pour communiquer avec le serveur. Toute communication avec le serveur se fera par une commande `HTTP GET` sur cette URL.

### Fonction « initial() » ###

La fonction « initial() » est déclarée à la ligne 1 251 du fichier « http://www.coco.fr/chat/initio.js ».

La fonction « initial() » va lire le cookie « samedi » et l'assigner dans la variable **infor**.

Dans notre exemple :
infor**= "570685428"**

La variable **myavatar** est initialisée avec les les caractères 0 à 9 de la chaîne de caractères **infor** :
  * **myavatar** = "570685428"

La **mypass** est initialisée avec les caractères 9 à 29 de **infor** :
  * **mypass** = ""

Une minuterie est initialisée de 200 millisecondes avant d'appeler la fonction « quasi() ».

### Fonction « quasi() » ###

La fonction « quasi() » est déclarée à la ligne 1 309 du fichier « http://www.coco.fr/chat/initio.js ».

### Fonction « presk() » ###

La fonction « presk() » est déclarée à la ligne 1 320 du fichier « http://www.coco.fr/chat/initio.js ».

La fonction « presk() » appelle la fonction « croco() » qui essaie de lire le _cookie Flash_.

Les variables JavaScript suivantes sont initialisées :

  * **myavatar** avec les caractères 0 à 9 de la variable **infor** ou avec un valeur de aléatoire 890 000 000 à 900 000 000 si **infor** est initialisée à « "null" ». Si **myavatar** est générée aléatoirement la chaîne « zx » est inséré dans une balise HTML `<div>` possédant l'ID « zerob ».

  * **mypass** avec les caractères 9 à 29 de la variable **infor** ou à « "" » si  si **infor** est initialisée à « "null" ». Si **mypass** est gune chaîne vide  la chaîne « fw » est insérée dans une balise HTML `<div>` possédant l'ID « zerob ».

Le cookie « samedi » est réécrit avec la chaînes de caractère **infor**.

La fonction « crocu() est appelée pour relire le cookie flash ?

Deux minuteries sont initialisée avec la fonction JavaScript « setTimeout() » :
  * Pour appeler la méthode « firsty() » au bout de 200 millisecondes.
  * Pour appeler la méthode « pret() » au bout de 300 millisecondes.

### Fonction « firsty() » ###

La fonction « firsty() » est déclarée à la ligne 1 388 du fichier « http://www.coco.fr/chat/initio.js ».

La fonction « firsty() » ne contient qu'une ligne l'appel à la fonction « agix() » :
```
 agix( url1 + "40" + mynickname + "*" + myage + mysex + parami[3] + myavatar + speco + mypass + "?" + (Math.random() * 10000000) ,4);
```

  * La valeur **`parami[3]`**  correspond à la valeur de **mycityID** qui est le code identifiant la ville. Dans notre exemple la valeur 30 915.
  * La valeur **speco** est toujours initialisée à zéro.

Dans notre cas :
```
 agix( "http://46.105.32.143:80/40Simon*371309157636446650?7619933.453716727", 4);
```


### Fonction « agix() » ###

La fonction « agix() » est la base de la communication de type _Ajax_ entre le client et le serveur et est déclarée à la ligne 346 du fichier « recherche.js ».

Cette fonction crée un nouvelle balise « `<script>` » pour l'arborescence avec comme valeur de l'attribut « src » l'URL « http://46.105.32.143:80/40Simon*371309157636446650?7619933.453716727 ».

L'URL précédente charge le fichier suivant qui sera exécuté en JavaScript :

```
process1('/#12106177BVgfBQ75738949435055320*FR');
```

La fonction « process1(urlu) » déclarée à la ligne 586 du fichier « rasmus.js » sera exécutée.

### Fonction « process1(urlu) » ###

La fonction « process1(urlu) » exécute toutes les réponses du serveur.

La chaîne de caractères **urlu** contient la réponse du serveur.

Les deux premiers caractères contiennent le code de la réponse qui est un entier naturel à deux chiffres. Dans notre cas le code de la réponse est « 12 », qui correspond au succès de l'authentification. Le serveur retourne les valeurs **mynickID** et **monpass** qui sont respectivement l'identifiant et le mot de passe de la session courante :

  * **olko** = 12
  * **mynickID** = 106177
  * **monpass** = BVgfBQ
  * **mycrypt** = 7573894
  * **mycrypt2** = 943505532

Les valeurs **mycrypt** et **mycrypt2** semblent être inutilisées.