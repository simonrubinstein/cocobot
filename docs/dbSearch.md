# Introduction #

Cette page donne quelques informations sur le script « db-search.pl ». Ce script est un des scripts les plus utiles couplé au [script « save-logged-user-in-database.pl »](saveLoggedUserInDatabase.md).

Le script « db-search.pl » permet de lancer des recherches sur les connexions d'utilisateurs enregistrés dans la bases de données.

Pour que le script « db-search.pl » fonctionne, la base de données doit être constamment mis à jour par le [script « save-logged-user-in-database.pl »](saveLoggedUserInDatabase.md), ce dernier est normalement lancé toutes les minutes et met à jour la base de données dès qu'un nouvel utilisateur se connecte où se déconnecte du site web [Coco.fr](http://www.coco.fr/).

## Options du script ##

```
 db-search.pl [-v -d] [-l logins -c codes -t towns -i ISPs -s sex -y age -O -I -P -F 1 -H -N]
  -l logins   Un pseudonyme ou une suite de pseudonymes séparés par une virgule
              (exemples : -l RomeoKnight or -l RomeoKnight,Delta,UncleTom) 
  -c codes    Un code de vote ou une suite de codes de votes séparés par une virgule
              (exemples : -c cZj ou -c cZj,23m,Wcl,PXd) 
  -t towns    Un ou des points de connexions séparés par une virgule 
              (exemples : -t "FR- Paris" ou -t "FR- Aulnay-sous-bois","FR- Sevran"
  -i ISPs     Un ou des noms de FAI séparés par une virgule
              (exemples : -i "Free SAS" or -i "Orange","Free SAS")
  -s sex      Genre : W : femme ; M : homme ;
                      2 : femme sans avatar ; 7 : femme avec un avatar
                      1 : homme sans avatar ; 6 : homme avec un avatar
  -y age      Âge
  -O          Utilisateurs connectés actuellement.
  -I          Uniquement en Îles-de-France. (basé sur le champ towns)
  -P          Pseudo qui ont rentré un code postal de la ville de Paris uniquement.
  -v          Mode verbeux
  -d          Mode debug
  -f filters  Active un fichier filtre. 
              Le fichier contient des noms de pseudonymes à ignorer.
  -F 1        Active un filtre spécial. 
              Affiche uniquement les pseudonymes commençant par un caractère majuscule.
  -H          Affiche le résultat en HTML
  -N          Retourne uniquement la liste des pseudos uniques
```


## Quelques exemples d'utilisation ##

Affiche les connexions ayant les codes de votes WcL, PXd, uyI, 0fN, rs6 :
```
db-search.pl -c WcL,PXd,uyI,0fN,rs6 
```

Affiche les connexions ayant un pseudonyme commençant par le nom « BetterDays ». Attention les noms sont sensibles à la case.
```
db-search.pl -l BetterDays%
```

Affiche les connexions avec les pseudonymes « BlueVelvet » et « Babycat » :
```
db-search.pl -l BlueVelvet,Babycat
```

Affiche les connexions ayant été faites puis les points « FR- Aulnay-sous-bois » et « FR- Sevran » avec un pseudonyme femme sans avatar et avec le FAI « Free SAS » :
```
db-search.pl -t "FR- Aulnay-sous-bois","FR- Sevran" -s 2 -i "Free SAS"
```

Affiche les connexions avec un code de vote « JiC » et un FAI « Orange » :
```
db-search.pl -c JiC -i "Orange"
```

Affiche les connexions des pseudonymes femmes actuellement connectés sur Coco.fr depuis l'Île de France en ignorant tous les pseudonymes contenu dans le fichier « conf/plain-text/nicknames-to-filter.txt » :
```
db-search.pl -O -I -s 2,7 -f plain-text/nicknames-to-filter.txt
```

Affiche les connexions des pseudonymes femmes actuellement connectés sur Coco.fr depuis l'Île de France et ayant entrés un code postal de Paris en ignorant tous les pseudonymes contenu dans le fichier « conf/plain-text/nicknames-to-filter.txt » et « conf/plain-text/nicknames-to-filter-2.txt », ignorant aussi les pseudonymes commençant par un caractère en minuscule :
```
db-search.pl -P -I -s 2 -f plain-text/nicknames-to-filter.txt,plain-text/nicknames-to-filter-2.txt -y 30 -F 1
```


## Repérer les hommes se faisant passer pour des femmes ##

Sur le site Coco.fr, un nombre important de pseudonymes de femmes sont en fait pilotés par des hommes. Certains hommes homosexuels prennent sciemment un pseudonyme de femme avec un nom sans équivoque sur ce qu'ils sont vraiment. Ainsi par exemple les pseudonymes femmes « Jeunegay », « LolaTravestie » ou « MecChMec » ne laissent que peu de doute sur le sexe de leurs propriétaires.

Cependant, il existe un nombre important de pseudonymes femmes qui sont créés par des hommes dans le but de tromper les autres utilisateurs en se faisant passer pour des femmes.

Le script « db-search.pl » peut aider à débusquer ces hommes malhonnêtes.

### Exemple 1 : Pseudonyme femme « Qwerty » ###

Le pseudonyme femme « Qwerty » avec le code de votre « QVa » était connecté sur [Coco.fr](http://www.coco.fr/). Voilà ce que donne une recherche du code vote « QVa » dans la base de données. La liste a été épurée de plusieurs connexions pour plus de clarté :

```text

./db-search.pl -c QVa
!--------------------------------------------------------------------------------------------------------------------------------!
! nickname   ! nickID ! ISP    ! town        ! age ! sex ! city        ! creation_date  ! logout         ! update_date    ! code !
!--------------------------------------------------------------------------------------------------------------------------------!
! Mec377     ! 201126 ! Orange ! Paris       ! 37  ! 1   ! 75009 Paris ! 06-14 10:28:41 ! 06-14 10:36:03 ! 06-14 10:35:41 ! QVa  !
! LukeSk     ! 317779 ! Orange ! Paris       ! 19  ! 1   ! 75009 Paris ! 06-17 13:26:04 ! 06-17 14:00:41 ! 06-17 13:43:43 ! QVa  !
! SuceBeat   ! 289338 ! Orange ! Paris       ! 19  ! 1   ! 75009 Paris ! 06-22 23:26:43 ! -              ! 06-23 00:08:12 ! QVa  !
! Kimenik    ! 289338 ! Orange ! Paris       ! 19  ! 1   ! 75009 Paris ! 06-23 00:54:41 ! 06-23 01:28:42 ! 06-23 01:28:12 ! QVa  !
! Kimenik    ! 195652 ! Orange ! Paris       ! 19  ! 1   ! 75009 Paris ! 06-24 00:06:41 ! 06-24 00:24:03 ! 06-24 00:21:14 ! QVa  !
! Kimenik    ! 237380 ! Orange ! Ris-orangis ! 19  ! 1   ! 75009 Paris ! 06-24 09:06:40 ! 06-24 09:29:40 ! 06-24 09:29:11 ! QVa  !
! DayOff     ! 237380 ! Orange ! Ris-orangis ! 19  ! 2   ! 75009 Paris ! 06-24 09:31:41 ! 06-24 09:32:41 ! 06-24 09:32:12 ! QVa  !
! SuceBeat   ! 237380 ! Orange ! Ris-orangis ! 19  ! 1   ! 75009 Paris ! 06-24 09:32:41 ! 06-24 10:26:03 ! 06-24 10:25:11 ! QVa  !
! Alive      ! 320648 ! Orange ! Clamart     ! 37  ! 1   ! 75009 Paris ! 07-01 16:45:02 ! 07-01 16:45:41 ! 07-01 16:45:11 ! QVa  !
! SuperNan   ! 320648 ! Orange ! Clamart     ! 19  ! 2   ! 75009 Paris ! 07-01 16:45:41 ! 07-01 17:24:43 ! 07-01 17:24:13 ! QVa  !
! SuperNan   ! 193003 ! Orange ! Clamart     ! 19  ! 2   ! 75010 Paris ! 07-05 17:55:41 ! 07-05 18:33:03 ! 07-05 18:32:41 ! QVa  !
! Republique ! 308339 ! Orange ! Clamart     ! 19  ! 2   ! 75010 Paris ! 07-06 11:08:43 ! 07-06 12:56:41 ! 07-06 12:56:02 ! QVa  !
! OpenMind   ! 308339 ! Orange ! Clamart     ! 19  ! 2   ! 75010 Paris ! 07-06 14:31:41 ! 07-06 14:39:43 ! 07-06 14:39:13 ! QVa  !
! Qwerty     ! 308339 ! Orange ! Clamart     ! 19  ! 2   ! 75009 Paris ! 07-06 14:40:04 ! 07-06 15:32:43 ! 07-06 15:32:12 ! QVa  !
!--------------------------------------------------------------------------------------------------------------------------------!
```

Attention un [code vote](CodeDeVote.md) n'est pas forcément unique pour un pseudonyme, même si c'est souvent le cas. Certains pseudonymes peuvent partager le même code de vote.

Dans notre cas plus indices laissent supposer que c'est un homme :
  * Le FAI est Orange à toutes les connexions.
  * Les points de connexions varient entre Paris, Clamart et Ris-Orangis des villes très proches.
  * Le code postal, entré par l'utilisateur, ne varie pour ainsi pas, c'est toujours 75009 ou 75010.

Ces trois points ne donnent pas une preuve formelle, mais de fortes présomptions.

Cependant si on regarde la valeur nickID « 237380 » du 24 juin elle est identique pour les pseudos hommes « Kimenik » et « SuceBeat » et le pseudo femme « DayOff ». Nous avons la même chose pour le nickID « 320648 » du 1er juillet qui est partagé le pseudo homme « Alive » et le pseudo femme « SuperNan ».

Nous avons de fortes chances que l'internaute soit un homme se faisant passer pour une femme. Ce qui a été confirmé, difficilement, par l'utilisateur après lui avoir fourni son historique de connexion.

### Exemple 2 : Pseudonyme femme « chaude12 » ###


Le pseudonyme femme « chaude12 » avec le code de votre « HgZ  » était connecté sur [Coco.fr](http://www.coco.fr/) :
```text

./db-search.pl -c QVa
!-----------------------------------------------------------------------------------------------------------------------------!
! nickname      ! nickID ! ISP ! town     ! age ! sex ! city        ! creation_date  ! logout         ! update_date    ! code !
!-----------------------------------------------------------------------------------------------------------------------------!
! lala0         ! 373762 ! SFR ! Pontoise ! 21  ! 2   ! 75013 Paris ! 06-21 16:49:42 ! 06-21 18:04:44 ! 06-21 18:04:14 ! HgZ  !
! divieala      ! 196506 ! SFR ! FR-      ! 36  ! 1   ! 75012 Paris ! 07-02 08:09:40 ! 07-02 08:38:40 ! 07-02 08:38:11 ! HgZ  !
! AL12eme       ! 196506 ! SFR ! FR-      ! 34  ! 6   ! 75012 Paris ! 07-02 08:38:40 ! 07-02 09:06:03 ! 07-02 09:05:40 ! HgZ  !
! AL12eme       ! 196506 ! SFR ! FR-      ! 34  ! 6   ! 75012 Paris ! 07-02 09:06:03 ! -              ! 07-02 09:25:02 ! HgZ  !
! AL12eme       ! 196506 ! SFR ! FR-      ! 34  ! 6   ! 75012 Paris ! 07-02 10:27:11 ! 07-02 11:07:04 ! 07-02 10:48:13 ! HgZ  !
! kijepompeds12 ! 196506 ! SFR ! FR-      ! 34  ! 6   ! 75012 Paris ! 07-02 11:14:41 ! 07-02 11:55:42 ! 07-02 11:33:11 ! HgZ  !
! Meccool12     ! 196506 ! SFR ! FR-      ! 34  ! 6   ! 75012 Paris ! 07-02 11:55:42 ! -              ! 07-02 12:14:12 ! HgZ  !
! Meccool12     ! 384144 ! SFR ! FR-      ! 34  ! 6   ! 75012 Paris ! 07-03 08:06:03 ! -              ! 07-03 08:40:40 ! HgZ  !
! Meccool12     ! 275637 ! SFR ! FR-      ! 34  ! 6   ! 75012 Paris ! 07-04 08:39:40 ! 07-04 09:36:04 ! 07-04 09:21:02 ! HgZ  !
! Meccool12     ! 107958 ! SFR ! FR-      ! 34  ! 6   ! 75012 Paris ! 07-04 23:02:42 ! -              ! 07-04 23:17:11 ! HgZ  !
! chaude12      ! 107958 ! SFR ! FR-      ! 34  ! 7   ! 75012 Paris ! 07-05 00:44:04 ! 07-05 01:35:03 ! 07-05 01:34:42 ! HgZ  !
! chaude12      ! 113444 ! SFR ! FR-      ! 34  ! 7   ! 75012 Paris ! 07-05 07:29:11 ! 07-05 09:13:40 ! 07-05 09:13:11 ! HgZ  !
! chaude12      ! 113444 ! SFR ! FR-      ! 34  ! 7   ! 75012 Paris ! 07-05 09:39:04 ! 07-05 09:55:40 ! 07-05 09:55:11 ! HgZ  !
! chaude12      ! 117917 ! SFR ! FR-      ! 34  ! 7   ! 75012 Paris ! 07-07 07:52:02 ! -              ! 07-07 09:58:40 ! HgZ  !
```


La première connexion du pseudo « lala0 » semble être un autre utilisateur.

Par contre pour les connexions suivantes c'est le même utilisateur, le FAI, le point de connexion, le code postal et même l'âge correspondent. Le pseudonyme est toujours suffixé de « 12 » ce qui donne un indice de plus.

Enfin le nickID « 107958 » sert pour le pseudo « Meccool12 » et « chaude12 » ce qui ne laisse aucun doute sur le sexe de l'utilisateur.


### Exemple 3 : Pseudonyme femme « LittleBoat » ###

Le pseudonyme femme « LittleBoat » avec le code de votre « 7FH » était connecté sur [Coco.fr](http://www.coco.fr/). Une seule connexion, celle est en cours, était présente dans la base de données. Mais la commande « ./db-search.pl -l LittleBoat » retournait six connexions avec les codes de votes : « 7FH », « EoF », « ZvF », « Xti » et « fho ».

Voici ce que retourne une recherche de ces cinq codes de votes :
```text

./db-search.pl -c fho,Xti,ZvF,EoF,7FH
!--------------------------------------------------------------------------------------------------------------------------------------!
! nickname   ! nickID ! ISP             ! town     ! age ! sex ! city        ! creation_date  ! logout         ! update_date    ! code !
!--------------------------------------------------------------------------------------------------------------------------------------!
! ThomasMore ! 122704 ! SFR             ! FR-      ! 40  ! 1   ! 75015 Paris ! 06-20 08:08:11 ! 06-20 09:29:40 ! 06-20 09:09:11 ! fho  !
! LittleBoat ! 122704 ! SFR             ! FR-      ! 18  ! 2   ! 75015 Paris ! 06-20 10:22:42 ! -              ! 06-20 11:27:41 ! fho  !
! LittleBoat ! 199368 ! SFR             ! FR-      ! 18  ! 7   ! 75005 Paris ! 06-23 07:39:12 ! 06-23 08:22:40 ! 06-23 08:22:11 ! Xti  !
! LittleBoat ! 199368 ! SFR             ! FR-      ! 18  ! 7   ! 75005 Paris ! 06-23 08:28:41 ! 06-23 08:31:40 ! 06-23 08:31:11 ! Xti  !
! david8     ! 199368 ! SFR             ! FR-      ! 25  ! 6   ! 75009 Paris ! 06-23 11:57:12 ! 06-23 11:57:41 ! 06-23 11:57:12 ! Xti  !
! david3     ! 199368 ! SFR             ! FR-      ! 25  ! 6   ! 75009 Paris ! 06-23 11:57:41 ! 06-23 12:11:11 ! 06-23 12:08:43 ! Xti  !
! david2     ! 199368 ! SFR             ! FR-      ! 25  ! 6   ! 75009 Paris ! 06-23 12:11:11 ! 06-23 12:12:04 ! 06-23 12:11:11 ! Xti  !
! david9     ! 199368 ! SFR             ! FR-      ! 25  ! 6   ! 75009 Paris ! 06-23 12:12:04 ! 06-23 12:13:11 ! 06-23 12:12:43 ! Xti  !
! david5     ! 199368 ! SFR             ! FR-      ! 25  ! 6   ! 75009 Paris ! 06-23 12:13:11 ! -              ! 06-23 12:13:11 ! Xti  !
! LittleBoat ! 107462 ! SFR             ! FR-      ! 18  ! 2   ! 75015 Paris ! 06-23 15:57:44 ! 06-23 16:00:03 ! 06-23 15:59:41 ! ZvF  !
! LittleBoat ! 230918 ! SFR             ! FR-      ! 18  ! 2   ! 75015 Paris ! 06-25 17:56:02 ! 06-25 17:57:41 ! 06-25 17:57:11 ! EoF  !
! LittleBoat ! 126262 ! SFR             ! Paris    ! 18  ! 2   ! 75001 Paris ! 07-07 08:46:03 ! -              ! 07-07 10:11:04 ! 7FH  !
!--------------------------------------------------------------------------------------------------------------------------------------!
```

Nous avons affaire à une personne qui utilise la navigation privée, donc plus difficilement traçable puisque son code de vote change, le cookie « samedi » étant supprimé à la fermeture de son navigateur web.

Cependant le 20 juin le nickID « 122704 » est utilisé pour le pseudo homme « ThomasMore » et le pseudo femme « LittleBoat ». Le 23 juin le nickID « 199368 » est utilisé pour le pseudo femme « LittleBoat » et le pseudo homme « david8 ».

Après avoir contacté l'utilisateur en question ce dernier avoue être un homme bisexuel se faisant passer pour une jeune femme.
