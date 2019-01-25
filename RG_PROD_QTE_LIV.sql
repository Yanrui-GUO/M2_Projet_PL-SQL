create or replace PROCEDURE RG_PROD_QTE_LIV 
(
  p_prodnum IN NUMBER 
, p_bonlivnum IN NUMBER 
, p_qteliv IN NUMBER 
) AS 
v_qterefus NUMBER;
v_comglobnum NUMBER;
v_qtecomglob NUMBER;
v_comnum NUMBER;
v_prodvolume NUMBER;
v_qtecom NUMBER;
v_colvolume NUMBER;
v_autrebonlivnum NUMBER;
v_prodattente NUMBER;
v_bonlivnum NUMBER;
v_prodlivre NUMBER;
v_prodconcerne NUMBER;
v_colnum NUMBER;

-- trouver la quantité de ce produit dans cette commande globale  
cursor c_qtecomglob is select qtecomglob from concernerglob cg 
    where cg.COMGLOBNUM = v_comglobnum and cg.PRODNUM=p_prodnum;
    
-- trouver commande associé avec ce produit et avec cette commande globale pour faire colis
cursor c_commande is select comnum from associer a 
 where a.COMGLOBNUM = v_comglobnum and a.prodnum = p_prodnum; 
 

-- trouver l'existance de bon livraison qui est déjà reçu avant sur ce produit et sur cette commande globale.          
cursor c_autrebonlivraison is  select bon.bonlivnum 
    from livrer l, bonlivraison bon
    where bon.comglobnum = v_comglobnum 
    and l.bonlivnum = bon.bonlivnum 
    and l.prodnum = p_prodnum
    and l.bonlivnum <> p_bonlivnum
    and l.qteliv - l.qterefus = v_qtecomglob;
        
BEGIN
  SYS.DBMS_OUTPUT.PUT_LINE('Bonlivraison ' || p_bonlivnum || ' : produit ' || p_prodnum || ' quantité : ' || p_qteliv);
-- trouver la commande globale concerné de ce produit et de ce bon livraison
  select comglobnum into v_comglobnum from bonlivraison b 
    where b.BONLIVNUM = p_BONLIVNUM;
  open c_qtecomglob;
  fetch c_qtecomglob into v_qtecomglob;
    if c_qtecomglob%notfound then
    SYS.DBMS_OUTPUT.PUT_LINE('produit ne correspond pas');
    -- Cas 1 : le produit ne correspond pas à la commande globale
      v_qterefus := p_QTELIV;
      --insert into bonlivraison values (seq_bonliv.nextval,v_comglobnum,sysdate);
      --insert into livrer values (p_prodnum,v_bonlivnum,null,null);
      --raise_application_error(-20101,'le produit ne correspond pas');
    else
       open c_autrebonlivraison;
       fetch c_autrebonlivraison into v_autrebonlivnum;
       if c_autrebonlivraison%notfound then
          if p_QTELIV < v_qtecomglob then
          SYS.DBMS_OUTPUT.PUT_LINE('quantité insuffisant');
          -- Cas 2 : le produit est livré en quantité insuffisant
               v_qterefus := p_QTELIV;
                --insert into bonlivraison values (seq_bonliv.nextval,v_comglobnum,sysdate);
                --insert into livrer values (p_prodnum,v_bonlivnum,null,null);
                --raise_application_error(-20101,'quantité insuffisant');
          elsif p_QTELIV >= v_qtecomglob then 
          SYS.DBMS_OUTPUT.PUT_LINE('quantité dépassant ou bon');
          -- Cas 3&4 : le produit est livré en bon quantité ou dans une quantité dépassant la quantité commandée, nous pouvons commencer de faire des colis
              v_qterefus := p_QTELIV - v_qtecomglob;
              select count(prodnum) into v_prodconcerne 
                  from concernerglob
                  where comglobnum = v_comglobnum
                  and prodnum <> p_prodnum;
              select count(l.prodnum) into v_prodlivre
                  from livrer l, bonlivraison bon, concernerglob co
                  where bon.comglobnum = co.comglobnum
                  and co.PRODNUM = l.prodnum
                  and bon.bonlivnum = l.bonlivnum
                  and co.comglobnum = v_comglobnum
                  and l.qteliv - l.QTEREFUS = co.qtecomglob
                  and l.prodnum <> p_prodnum;
                if v_prodlivre = v_prodconcerne then
                -- si tous les produit dans cette commande globale sont déjà bien livré, nous pouvons changer l'état de cette commande globale à 'terminé', sinon, nous faison rien.
                  SYS.DBMS_OUTPUT.PUT_LINE('la commande globale ' || v_comglobnum ||' est terminée');
                  update commandeglobale set comglobetat = 'terminée' where comglobnum = v_comglobnum;
                  -- faire des colis des commandes sur ce produit et cette commande globale
                end if;
                for un_commande in c_commande loop
                    select qtecom into v_qtecom from concerner c 
                      where c.COMNUM = un_commande.comnum and c.PRODNUM = p_PRODNUM;
                    select prodvolume into v_prodvolume from produit p 
                      where p.PRODNUM = p_PRODNUM;
                    v_colvolume := v_qtecom*v_prodvolume;
                    v_colnum := SEQ_COLIS.nextval;
                    insert into colis VALUES (v_colnum, null, p_prodnum, un_commande.comnum, 'en cours de préparation', v_colvolume, v_qtecom);
                    SYS.DBMS_OUTPUT.PUT_LINE('Créer le colis '|| v_colnum ||' du produit ' || p_prodnum || ' pour la commande '||un_commande.comnum);
                    RG_TERMINER_COMMANDE (un_commande.comnum, p_prodnum);
                    RG_DISTRIBUTION_COLIS(SEQ_COLIS.currval, v_colvolume);
                end loop;
            end if;
		else 
      SYS.DBMS_OUTPUT.PUT_LINE('Le produit a été déjà reçu');
			v_qterefus := p_QTELIV;
		end if;
	end if; 
	close c_qtecomglob;
  
  -- chaque fois après nous avons réçu un livraison, nous changons la quantité refusée.
  update livrer l set qterefus = v_qterefus where l.BONLIVNUM = p_BONLIVNUM and l.PRODNUM = p_PRODNUM;
  SYS.DBMS_OUTPUT.PUT_LINE('Contole de quantité est fini');

END RG_PROD_QTE_LIV;