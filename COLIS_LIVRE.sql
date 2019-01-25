create or replace PROCEDURE COLIS_LIVRE 
(
  P_CHARNUM IN NUMBER,
  P_COLNUM IN NUMBER,
  P_COMNUM IN NUMBER,
  P_PRODNUM IN NUMBER,
  P_QTELIV IN NUMBER,
  P_DATELIV IN DATE
) AS 
    v_prodlivre NUMBER;
    v_magnum NUMBER;
    v_colnum NUMBER;
    
                            
    cursor c_prodlivre is select co.prodnum
                            from concerner co
                            where co.comnum = p_comnum
                            and co.prodnum <> p_prodnum
                            and co.prodnum not in (select colis.prodnum
                                                    from colis
                                                    where colis.comnum = p_comnum
                                                    and colis.coletat = 'livré'); 
    
    cursor c_chargement is select colnum
                            from colis
                            where colnum <> p_colnum
                            and charnum = p_charnum
                            and coletat <> 'livré';
                        
BEGIN
       
    --modifier qtestock
    select magnum into v_magnum from commande where comnum = p_comnum;
    update stocker set qtestock = qtestock + p_qteliv where magnum = v_magnum and prodnum = p_prodnum;
    
    --vérifier les colis reçus, si tous les colis de la commande sont bien reçus, modifier l'état de la commande
    open c_prodlivre;
    fetch c_prodlivre into v_prodlivre;
    if c_prodlivre%rowcount = 0 then
        update commande set cometat = 'livré', comdateliv = p_dateliv where comnum = p_comnum;
    end if;
    
    --vérifier l'état du chargement, si tous les colis du chargement sont bien livrés, modifier l'état du chargement
    open c_chargement;
    fetch c_chargement into v_colnum;
    if c_chargement%rowcount = 0 then
        update chargement set charetat = 'livré' where charnum = p_charnum;
    end if;
    
END COLIS_LIVRE;