create or replace PROCEDURE RG_PREPARATION_COMMANDE 
(
  P_COMNUM IN NUMBER,
  P_PRODNUM IN NUMBER
) AS 
    v_prodnum number;
    cursor c_produit is select prodnum 
                        from concerner c
                        where c.comnum = P_COMNUM 
                        and c.prodnum <> p_prodnum
                        and c.prodnum not in (select asso.prodnum   
                                                from associer asso 
                                                where asso.comnum = P_COMNUM);
    
BEGIN
    open c_produit;
    fetch c_produit into v_prodnum;
    if c_produit%notfound then
        update commande set cometat = 'en cours de préparation' where comnum = P_COMNUM;
        SYS.DBMS_OUTPUT.PUT_LINE('Tous les produit de la commande ' || p_comnum || ' sont factorisé. L''état de commande passe en ''en cours de préparation''.');
    end if;
    close c_produit;
    
END RG_PREPARATION_COMMANDE;