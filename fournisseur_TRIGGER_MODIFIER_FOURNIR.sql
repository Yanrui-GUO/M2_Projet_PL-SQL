create or replace TRIGGER MODIFIER_FOURNIR 
INSTEAD OF UPDATE ON VIEW_FOURNIR 
REFERENCING OLD AS A NEW AS N 
FOR EACH ROW
BEGIN
    if to_char(:n.histodate, 'DD/MM/YY') = to_char(sysdate, 'DD/MM/YY') then
        modification_fournir(:n.prodnum, :n.histodate, :n.proprix, :n.seuil);
    end if;
END;