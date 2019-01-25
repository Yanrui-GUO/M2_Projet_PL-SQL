create or replace TRIGGER BONLIVNUM_AUTO 
BEFORE INSERT ON BONLIVRAISON 
REFERENCING OLD AS A NEW AS N 
FOR EACH ROW
BEGIN
  if :n.bonlivnum is null then
    :n.bonlivnum := seq_bonliv.nextval;
  end if;
END;


create or replace TRIGGER CHARGEMENTNUM_AUTO 
AFTER INSERT ON CHARGEMENT 
REFERENCING OLD AS A NEW AS N 
FOR EACH ROW
BEGIN
  CREATION_CHARGEMENT(:n.charnum);
END;


create or replace TRIGGER CONTROLE_QTE_BONLIV 
INSTEAD OF INSERT ON VIEW_LIVRER 
REFERENCING OLD AS A NEW AS N 
FOR EACH ROW
BEGIN
    insert into livrer values (:n.prodnum, :n.bonlivnum, :n.qteliv, 0);
    RG_PROD_QTE_LIV(:n.prodnum, :n.bonlivnum, :n.qteliv);
END;


create or replace TRIGGER CREATION_COMMANDE
BEFORE INSERT ON COMMANDE 
REFERENCING OLD AS A NEW AS N 
FOR EACH ROW
BEGIN
  :N.comnum := seq_commande.nextval;
  :N.cometat := 'en cours de constitution';
END;


create or replace TRIGGER EXPEDIER_CHARGEMENT 
AFTER UPDATE OF CHARETAT ON CHARGEMENT 
REFERENCING OLD AS A NEW AS N 
FOR EACH ROW
DECLARE 
  cursor c_colis is select colnum from colis where charnum = :n.charnum;
BEGIN
  if :n.charetat = 'expédié'then
    for un_colis in c_colis loop
      update colis set coletat = 'expédié' where colnum = un_colis.colnum;
    end loop;
  end if;
END;


create or replace TRIGGER FACTORISATION_COMMANDE 
INSTEAD OF UPDATE ON VIEW_COMMANDE 
REFERENCING OLD AS A NEW AS N 
FOR EACH ROW
BEGIN
    if :n.cometat = 'en cours' then
        update commande set cometat = 'en cours' where comnum = :n.comnum;
        RG_FACTORISATION_COMMANDE(:n.comnum);
    end if;
END;


create or replace TRIGGER INSERER_LIGNE_COMGLOB 
BEFORE INSERT ON ASSOCIER 
REFERENCING OLD AS A NEW AS N 
FOR EACH ROW
BEGIN
  RG_PREPARATION_COMMANDE(:N.comnum, :N.prodnum);
END;


create or replace TRIGGER INSERER_LIGNE_COMMANDE 
BEFORE INSERT ON CONCERNER 
REFERENCING OLD AS A NEW AS N 
FOR EACH ROW
DECLARE
    v_res_qte boolean;
    v_res_etat VARCHAR2(32);
BEGIN
    select cometat into v_res_etat from commande where comnum = :n.comnum;
    v_res_qte := rg_qte_commande(:n.comnum, :n.prodnum, :n.qtecom);
    if v_res_etat != 'en cours de constitution' then
        raise_application_error(-20101, 'Vous ne pouvez plus modifier cette commande');
    else
        if not v_res_qte then
            raise_application_error(-20101, 'La quantité commandée est hors lmitée');
        end if;
    end if;
END;


create or replace TRIGGER LIVRAISON_COLIS 
INSTEAD OF UPDATE ON VIEW_COLIS 
REFERENCING OLD AS A NEW AS N 
FOR EACH ROW
DECLARE 
    v_dateliv DATE;
BEGIN
    if :n.coletat = 'livré' then
        update colis set COLETAT=:n.coletat
          where colnum = :n.colnum;
        v_dateliv := sysdate;
        COLIS_LIVRE(:n.charnum, :n.colnum, :n.comnum, :n.prodnum, :n.qteliv, v_dateliv);
    else
      null;
    end if;
END;