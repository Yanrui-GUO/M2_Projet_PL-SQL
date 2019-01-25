-----view_commandeglobale
  CREATE OR REPLACE FORCE VIEW "AEROFRANCE_LIAO"."VIEW_COMMANDEGLOBALE" ("COMGLOBNUM", "FOURNUM", "COMGLOBDATE", "COMGLOBETAT") AS 
  SELECT "COMGLOBNUM","FOURNUM","COMGLOBDATE","COMGLOBETAT"
    
FROM CHEF_GUO.COMMANDEGLOBALE
WHERE FOURNUM = 4;
 

  CREATE OR REPLACE TRIGGER "AEROFRANCE_LIAO"."PREPARATION_COMGLOB" 
INSTEAD OF UPDATE ON VIEW_COMMANDEGLOBALE 
REFERENCING OLD AS A NEW AS N 
FOR EACH ROW
BEGIN
    if :n.comglobetat = 'en cours de préparation' then
        ETAT_PREPARATION(:n.comglobnum);
    end if;
END;
/
ALTER TRIGGER "AEROFRANCE_LIAO"."PREPARATION_COMGLOB" ENABLE;




-----view_produit
  CREATE OR REPLACE FORCE VIEW "AEROFRANCE_LIAO"."VIEW_PRODUIT" ("COMGLOBNUM", "PRODNUM", "QTECOMGLOB") AS 
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
 

 
 ----- une procédure aautonomous transaction
 create or replace PROCEDURE ETAT_PREPARATION
(
  P_COMGLOBNUM IN NUMBER 
) AS 
     pragma AUTONOMOUS_TRANSACTION;
BEGIN
    update CHEF_GUO.commandeglobale SET comglobetat = 'en cours de préparation' where comglobnum = P_COMGLOBNUM;
    commit;
END ETAT_PREPARATION;

-----Déclencheur qui permet modifier l'état de commandeglobale depuis view_commandeglobale
create or replace TRIGGER PREPARATION_COMGLOB 
INSTEAD OF UPDATE ON VIEW_COMMANDEGLOBALE 
REFERENCING OLD AS A NEW AS N 
FOR EACH ROW
BEGIN
    if :n.comglobetat = 'en cours de préparation' then
        ETAT_PREPARATION(:n.comglobnum);
    end if;
END;





CREATE OR REPLACE PROCEDURE MODIFICATION_FOURNIR 
(
  P_PRODNUM IN NUMBER, 
  P_DATE IN DATE,
  P_PRIX IN NUMBER,
  P_SEUIL IN NUMBER  
) AS pragma AUTONOMOUS_TRANSACTION;
BEGIN
    update CHEF_GUO.fournir SET PROPRIX = P_PRIX, SEUIL = P_SEUIL 
    where FOURNUM = 4
    and HISTODATE = P_DATE
    and PRODNUM = P_PRODNUM;
    commit;
END MODIFICATION_FOURNIR;




CREATE OR REPLACE TRIGGER MODIFIER_FOURNIR 
INSTEAD OF UPDATE ON VIEW_FOURNIR 
REFERENCING OLD AS A NEW AS N 
FOR EACH ROW
BEGIN
    if to_char(:n.histodate, 'DD/MM/YY') = to_char(sysdate, 'DD/MM/YY') then
        modification_fournir(:n.prodnum, :n.histodate, :n.proprix, :n.seuil);
    end if;
END;





  CREATE OR REPLACE FORCE VIEW "AEROFRANCE_LIAO"."VIEW_BONLIVRAISON" ("BONLIVNUM", "PRODNUM", "QTELIV", "QTEREFUS") AS 
  SELECT bonlivnum, prodnum, qteliv, qterefus
    
FROM CHEF_GUO.VIEW_BONLIV

WHERE fournum = 4;





  CREATE OR REPLACE FORCE VIEW "AEROFRANCE_LIAO"."VIEW_FOURNIR" ("PRODNUM", "HISTODATE", "PROPRIX", "SEUIL") AS 
  SELECT "PRODNUM","HISTODATE","PROPRIX","SEUIL"
    
FROM CHEF_GUO.FOURNIR
WHERE FOURNUM = 4;