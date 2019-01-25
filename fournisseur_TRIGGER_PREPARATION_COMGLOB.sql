create or replace TRIGGER PREPARATION_COMGLOB 
INSTEAD OF UPDATE ON VIEW_COMMANDEGLOBALE 
REFERENCING OLD AS A NEW AS N 
FOR EACH ROW
BEGIN
    if :n.comglobetat = 'en cours de préparation' then
        ETAT_PREPARATION(:n.comglobnum);
    end if;
END;