set SERVEROUTPUT ON;

--
GRANT SELECT ON COMMANDEGLOBALE TO "AEROFRANCE_LIAO" ;
GRANT UPDATE(COMGLOBETAT) ON COMMANDEGLOBALE TO "AEROFRANCE_LIAO" ;
GRANT SELECT ON LIVRER TO "AEROFRANCE_LIAO" ;
GRANT SELECT ON BONLIVRAISON TO "AEROFRANCE_LIAO" ;
GRANT INSERT ON BONLIVRAISON TO "AEROFRANCE_LIAO" ;
GRANT SELECT ON CONCERNERGLOB TO "AEROFRANCE_LIAO" ;
GRANT SELECT ON FOURNIR TO "AEROFRANCE_LIAO" ;
GRANT UPDATE(proprix, seuil) ON FOURNIR TO "AEROFRANCE_LIAO" ;
GRANT SELECT ON view_bonliv TO "AEROFRANCE_LIAO" ;


GRANT create view to "AEROFRANCE_LIAO" ;
GRANT create TRIGGER to "AEROFRANCE_LIAO" ;
GRANT create PROCEDURE to "AEROFRANCE_LIAO" ;
revoke create view from "AEROFRANCE_LIAO" ;
revoke create TRIGGER from "AEROFRANCE_LIAO" ;
revoke create PROCEDURE from "AEROFRANCE_LIAO" ;
revoke INSERT ON view_bonliv FROM "AEROFRANCE_LIAO" ;

--initialiser tous les seq
DROP sequence SEQ_BONLIV;
CREATE SEQUENCE SEQ_BONLIV INCREMENT BY 1 START WITH 1 MAXVALUE 999999999999 MINVALUE 1;
DROP sequence SEQ_CHARGEMENT;
CREATE SEQUENCE SEQ_CHARGEMENT INCREMENT BY 1 START WITH 1 MAXVALUE 999999999999 MINVALUE 1;
DROP sequence SEQ_COLIS;
CREATE SEQUENCE SEQ_COLIS INCREMENT BY 1 START WITH 1 MAXVALUE 999999999999 MINVALUE 1;
DROP sequence SEQ_COMGLOB;
CREATE SEQUENCE SEQ_COMGLOB INCREMENT BY 1 START WITH 1 MAXVALUE 999999999999 MINVALUE 1;
DROP sequence SEQ_COMMANDE;
CREATE SEQUENCE SEQ_COMMANDE INCREMENT BY 1 START WITH 1 MAXVALUE 999999999999 MINVALUE 1;

--supprimer tous les données
delete colis;
delete livrer;
delete bonlivraison;
delete concerner;
delete concernerglob;
delete associer;
delete COMMANDEGLOBALE;
delete commande;
delete chargement;
commit;

--création des chargement expédié
insert into chargement values(1,1,sysdate,'expédié');
insert into chargement values(2,2,sysdate,'expédié');
insert into chargement values(3,3,sysdate,'expédié');
insert into chargement values(4,4,sysdate,'expédié');


--création de commande
insert into commande values(1,2,sysdate,null,'en cours de constitution');
insert into concerner values(1,1,800);
insert into concerner values(1,2,300);
insert into concerner values(1,3,50);

insert into commande values(2,3,sysdate,null,'en cours de constitution');
insert into concerner values(2,1,100);
insert into concerner values(2,2,250);

insert into commande values(3,4,sysdate,null,'en cours de constitution');
insert into concerner values(3,3,170);

--factorisation de commande
update view_commande set cometat = 'en cours' where COMNUM = 1;
update view_commande set cometat = 'en cours' where COMNUM = 2;
update view_commande set cometat = 'en cours' where COMNUM = 3;

commit;

--le fournisseur modifie l'état de commande globale(en view)
update CHEF_GUO.commandeglobale SET comglobetat = 'en cours de préparation' where comglobnum = 1;
commit;

--création des nouvelles commandes
insert into commande values(4,5,sysdate,null,'en cours de constitution');
insert into commande values(5,6,sysdate,null,'en cours de constitution');


insert into concerner values(4,1,800);
insert into concerner values(5,3,800);
insert into concerner values(5,4,200);

--factorisation des nouvelles commandes
update view_commande set cometat = 'en cours' where COMNUM = 4;
update view_commande set cometat = 'en cours' where COMNUM = 5;


--création bonlivraison 1, 2
insert into CHEF_GUO.bonlivraison values(null,1,sysdate);
insert into CHEF_GUO.bonlivraison values(null,1,sysdate);
commit;


--contrôle de la quantité livrée
--recevoir le bonlivraison 1
--cas 1 : produit ne correspande pas, refus = 500
insert into VIEW_LIVRER values (4,1,500);
--cas 2 : quantité insuffisante, refus = 500
insert into VIEW_LIVRER values (1,1,500);
--cas 5 : bonne auqntité
insert into VIEW_LIVRER values (2,1,550);
commit;

--recevoir le bonlivraison 2
insert into VIEW_LIVRER values (3,2,220);
commit;

--le fournisseur peut vérifier leur commandeglobale non terminé, avec les produit en attente de livrer et la quantité
select co.comglobnum, co.prodnum, co.qtecomglob
from CHEF_GUO.concernerglob co, CHEF_GUO.commandeglobale com
where com.comglobnum = co.comglobnum
and com.fournum = 4
and co.prodnum not in (select l.prodnum
						from CHEF_GUO.livrer l, CHEF_GUO.bonlivraison b, CHEF_GUO.concernerglob c
						where l.bonlivnum = b.bonlivnum
						and com.comglobnum = b.comglobnum
						and com.comglobnum = c.comglobnum
						and c.prodnum = l.prodnum
						and com.fournum = 4
						and l.qteliv-l.qterefus = c.qtecomglob );


--création bonlivraison 3,4
insert into CHEF_GUO.bonlivraison values(null,1,sysdate);
insert into CHEF_GUO.bonlivraison values(null,1,sysdate);
commit;

--recevoir le bonlivraison 3
--cas 3 : quantité dépassante, refus = 100
insert into VIEW_LIVRER values (1,3,1000);

--recevoir le bonlivraison 4
--cas 4 : existe bon liv de bonne quantité, refus = 900
insert into VIEW_LIVRER values (1,4,900);
commit;
						


--création des chargement et prendre les colis non chargés
insert into chargement values(5,1,sysdate,'en cours');
insert into chargement values(6,2,sysdate,'en cours');
insert into chargement values(7,3,sysdate,'en cours');
insert into chargement values(8,4,sysdate,'en cours');


--contrôle de quantité et charger les colis automatiquement
insert into bonlivraison values(null,2,sysdate);
insert into VIEW_LIVRER values (1,5,800);

insert into bonlivraison values(null,3,sysdate);
insert into VIEW_LIVRER values (3,6,800);

insert into bonlivraison values(null,4,sysdate);
insert into VIEW_LIVRER values (4,7,200);


--expédier le chargement
update chargement set CHARETAT = 'expédié' where charnum = 1;

--livrer des colis
update view_colis set coletat = 'livré' where colnum in (select co.colnum
                                                    from colis co
                                                    where co.charnum = 5);