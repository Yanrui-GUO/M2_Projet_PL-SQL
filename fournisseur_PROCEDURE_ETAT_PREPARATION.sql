create or replace PROCEDURE ETAT_PREPARATION
(
  P_COMGLOBNUM IN NUMBER 
) AS 
     pragma AUTONOMOUS_TRANSACTION;
BEGIN
    update CHEF_GUO.commandeglobale SET comglobetat = 'en cours de préparation' where comglobnum = P_COMGLOBNUM;
    commit;
END ETAT_PREPARATION;