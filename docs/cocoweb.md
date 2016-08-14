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

#### Action « write » ####

L'action  « write » crée un bot qui va écrire à un utilisateur connecté. L'option « -i » précise le _mynickID_ de l'utilisateur à qui écrire. La valeur _mynickID_ est à récupérer dans la quatrième colonne du résultat donné par l'action « list » précédente.

<pre>
./cocoweb.pl -i 30925 -a write -m "Hello" 
</pre>

On peut répéter le nombre de fois que le message sera écrit avec l'option « -w » et le nombre de bots créés pour envoyer le message avec l'option « -x ». Exemple, cette ligne créera successivement dix bots de femmes de 37 ans qui écriront deux fois la phrase « hello » à l'utilisateur identifié par le  _mynickID_ « 218530 » :
<pre>
./cocoweb.pl -s W -y 37 -i 218530 -a write -m "Hello" -w 2 -x 10
</pre>

#### Action « hello » ####

L'action  « write » crée un bot qui va écrire une salutation aléatoire à un utilisateur connecté. L'option « -i » précise le _mynickID_ de l'utilisateur à qui écrire.

<pre>
./cocoweb.pl -a hello -i 218530 -x 30 -s M
</pre>
