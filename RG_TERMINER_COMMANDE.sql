create or replace PROCEDURE RG_TERMINER_COMMANDE  
(
p_comnum IN NUMBER,
p_prodnum IN NUMBER
)
AS
v_produit NUMBER;

cursor c_produit is select prodnum from concerner c
  where c.comnum = p_comnum and c.prodnum <> p_prodnum and prodnum not in (select prodnum from colis co
                                                                            where co.comnum = p_comnum and co.prodnum <>p_prodnum); 

BEGIN
  open c_produit;
  fetch c_produit into v_produit;
  
  if c_produit%notfound then
    SYS.DBMS_OUTPUT.PUT_LINE('Tous les produit de la commande ' || p_prodnum || ' sont placés dans colis');
    update commande set cometat = 'terminée'
      where comnum = p_comnum;
  end if;
  
  close c_produit;
  
END RG_TERMINER_COMMANDE;