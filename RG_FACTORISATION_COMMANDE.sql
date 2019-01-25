create or replace PROCEDURE RG_FACTORISATION_COMMANDE 
(
  P_COMNUM IN NUMBER 
) AS 
  v_comglobnum NUMBER;
  v_qtecomglob NUMBER;
  v_qtestock NUMBER;
  v_qtealerte NUMBER;
  v_prodnum NUMBER;
  v_qteattente NUMBER;
  v_fournum NUMBER;
  v_seuil NUMBER;
  v_inserer BOOLEAN;
                        
  cursor c_produit is select prodnum, qtecom
                      from concerner
                      where comnum = P_COMNUM;
   
  cursor c_prodattente is select co.comnum, co.qtecom 
                            from commande com, concerner co
                            where com.comnum = co.comnum
                            and com.comnum <> p_comnum
                            and prodnum = v_prodnum
                            and com.cometat = 'en cours'
                            and prodnum not in (select asso.prodnum
                                                from associer asso
                                                where asso.comnum = com.comnum);
    
  cursor c_fournisseur is select f1.fournum, f1.seuil
                            from fournir f1
                            where f1.prodnum = v_prodnum
                            and to_char(f1.histodate, 'DD/MM/YY') = to_char(sysdate,'DD/MM/YY')
                            and f1.proprix = (select min(proprix)
                                            from fournir f2
                                            where f2.prodnum = v_prodnum
                                            and to_char(f2.histodate, 'DD/MM/YY') = to_char(sysdate,'DD/MM/YY'));
                                            
  cursor c_comglob_produit is select comglob.comglobnum
                                from CONCERNERGLOB co, commandeglobale comglob
                                where comglob.COMGLOBNUM = co.comglobnum 
                                and co.PRODNUM = v_prodnum
                                and comglob.COMGLOBETAT = 'en cours de constitution';
                        
  cursor c_comglob is select comglobnum
                        from COMMANDEGLOBALE
                        where comglobetat = 'en cours de constitution' 
                        and fournum = v_fournum;
                        
  cursor c_four_alerte is select f1.fournum
                          from fournir f1
                          where f1.prodnum = v_prodnum
                          and f1.seuil <= v_qtecomglob
                          and to_char(f1.histodate, 'DD/MM/YY') = to_char(sysdate,'DD/MM/YY')
                          and f1.proprix = (select min(proprix)
                                          from fournir f2
                                          where f2.prodnum = v_prodnum
                                          and f2.seuil <= v_qtecomglob
                                          and to_char(f2.histodate, 'DD/MM/YY') = to_char(sysdate,'DD/MM/YY'));
                                          
    
BEGIN
    SYS.DBMS_OUTPUT.PUT_LINE('Commande ' || p_comnum);
    for un_produit in c_produit loop
      SYS.DBMS_OUTPUT.PUT_LINE('Produit' || un_produit.prodnum);
      v_prodnum := un_produit.prodnum;
      v_inserer := false;
      --chercher une commande globale concernée à ce produit
      open c_comglob_produit;
      fetch c_comglob_produit into v_comglobnum;
            
      if c_comglob_produit%found then
        --s'il existe une commande globale concerné
        update concernerglob set qtecomglob = qtecomglob + un_produit.qtecom 
        where comglobnum = v_comglobnum and prodnum = un_produit.prodnum;
        
        insert into associer values(P_COMNUM, v_comglobnum, un_produit.prodnum);
        
        SYS.DBMS_OUTPUT.PUT_LINE('produit ' || un_produit.prodnum || ' --existe une commande globale, augmenter la qtecomglob');
        close c_comglob_produit;
      else
        close c_comglob_produit;
        --sinon, calculer la somme de la quantitée à commander
        v_qtecomglob := un_produit.qtecom;
        for un_prodattente in c_prodattente loop
          v_qtecomglob := v_qtecomglob + un_prodattente.qtecom;
        end loop;
        
        --chercher le fournisseur le moins cher concernant le même produit
        open c_fournisseur;
        fetch c_fournisseur into v_fournum, v_seuil;
        while c_fournisseur%found and v_inserer = false loop
          SYS.DBMS_OUTPUT.PUT_LINE('Le fournisseur ' || v_fournum || ' est le moins cher');
          --s'il existe, vérifier le seuil
          if v_seuil <= v_qtecomglob then
            SYS.DBMS_OUTPUT.PUT_LINE('On atteint le seuil');
            --si le seuil est inférieur ou égale à la quantité à commonder, chercher la commande globale de ce fournisseur
            open c_comglob;
            fetch c_comglob into v_comglobnum;
            
            if c_comglob%notfound then
              --s'il n'existe pas de commande globale, créer une commande globale
              insert into commandeglobale values(seq_comglob.nextval,v_fournum,sysdate,'en cours de constitution');
              v_comglobnum := seq_comglob.currval;
              SYS.DBMS_OUTPUT.PUT_LINE('Commande n''existe pas, créer une commande globale');
            end if;
            close c_comglob;
            
            --insérer une ligne dans commandeglobale avec la somme des quantité
            insert into concernerglob values (un_produit.prodnum,v_comglobnum,v_qtecomglob);
            SYS.DBMS_OUTPUT.PUT_LINE('Insérer une ligne de commande globale du produit ' || un_produit.prodnum);
            --insérer les lignes dans le table associer
            insert into associer values(P_comnum, v_comglobnum, un_produit.prodnum);
            for un_prodattente in c_prodattente loop
              insert into associer values(un_prodattente.comnum, v_comglobnum, un_produit.prodnum);
            end loop;
            SYS.DBMS_OUTPUT.PUT_LINE('Insérer tous les commande concerné du produit ' || un_produit.prodnum || ' dans le table associer');
            v_inserer := true;
          else
            fetch c_fournisseur into v_fournum, v_seuil;
          end if;
        end loop;
        close c_fournisseur;
        
        if v_inserer = false then
        SYS.DBMS_OUTPUT.PUT_LINE('On n''atteint pas le seuil');
          --vérifier cas alerte
          select qtestock, qtealerte into v_qtestock, v_qtealerte
          from commande c, stocker s
          where c.comnum = P_COMNUM
          and c.magnum = s.magnum
          and s.prodnum = un_produit.prodnum;
        
          if v_qtestock <= v_qtealerte then
            SYS.DBMS_OUTPUT.PUT_LINE('stock alerte du produit ' || un_produit.prodnum);
            --cas stock alerte        
            --chercher le fournisseur le moins cher concernant le même produit avec un seuil inférieur à la quantité totale à commander
            open c_four_alerte;
            fetch c_four_alerte into v_fournum;
            
            if c_four_alerte%found then
              --s'il existe, chercher la commande globale de ce fournisseur
              SYS.DBMS_OUTPUT.PUT_LINE('Le fournisseur ' || v_fournum || ' est le moins cher avec bon seuil du produit ' || un_produit.prodnum);
              open c_comglob;
              fetch c_comglob into v_comglobnum;
              
              
              if c_comglob%notfound then
                --s'il n'existe pas de commande globale, créer une commande globale
                insert into commandeglobale values(seq_comglob.nextval,v_fournum,sysdate,'en cours de constitution');
                v_comglobnum := seq_comglob.currval;
                SYS.DBMS_OUTPUT.PUT_LINE('Commande n''existe pas, créer une commande globale');
              end if;
              
              --insérer une ligne dans commandeglobale avec la somme des quantité
              insert into concernerglob values (un_produit.prodnum,v_comglobnum,v_qtecomglob);
              SYS.DBMS_OUTPUT.PUT_LINE('Insérer une ligne de commande globale du produit ' || un_produit.prodnum);
              
              --insérer les lignes dans le table associer
              insert into associer values(P_comnum, v_comglobnum, un_produit.prodnum);
              for un_prodattente in c_prodattente loop
                insert into associer values(un_prodattente.comnum, v_comglobnum, un_produit.prodnum);
              end loop;
              SYS.DBMS_OUTPUT.PUT_LINE('Insérer tous les commande concerné du produit ' || un_produit.prodnum || ' dans le table associer');
              close c_comglob;
            end if;
            close c_four_alerte;
          end if;
        end if;
      end if;
    end loop;
    SYS.DBMS_OUTPUT.PUT_LINE('Factorisation de la commande ' || p_comnum || ' est finie');
END RG_FACTORISATION_COMMANDE;