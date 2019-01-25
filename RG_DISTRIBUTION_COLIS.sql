create or replace PROCEDURE RG_DISTRIBUTION_COLIS 
(
  P_COLNUM IN NUMBER 
, P_COLVOLUME IN NUMBER 
) AS 

v_secteur_nouveau_colis NUMBER;
v_charnum NUMBER;
v_secteur_chargement NUMBER;
v_colis_chargement NUMBER;
v_colvolume_chargement NUMBER;
v_somme_volume_chargement NUMBER;
v_capacite_chargement NUMBER;
v_charger BOOLEAN;

-- au debut de chaque jour, on va mettre à jour des état des chargements
-- chaque jour on crée des chargements manuellement, chaque chargement concerne qu'un seul secteur
-- chaque jour un camion est affecté sur un seul chargement 
-- tous les chargements du jour qui ne atteignent pas sa capacité sont en l'état de 'en cours', les autres sont en l'état de 'expédié'
-- tous les chargements précédents passent en l'état de 'expédié' :  on fait les livraison par jour


-- trouver tous les chargements 
cursor c_chargement is select charnum from chargement
    where CHARETAT = 'en cours';

-- trouver des colis qui sont déjà dans le chargement
cursor c_colis_chargement is select colnum, colvolume, secnum from colis col, commande com, magasin m
    where col.comnum = com.comnum and com.magnum = m.magnum and col.charnum = v_charnum;

-- trouver des chargements vide
cursor c_chargement_vide is select cha.charnum from chargement cha
                            where cha.charetat = 'en cours'
                            and cha.charnum not in (select co.charnum from colis co
                                                      where co.charnum is not null);
  
BEGIN
  v_charger := false;
  v_somme_volume_chargement :=0;
  select secnum into v_secteur_nouveau_colis from colis col1, commande com1, magasin m1
    where col1.colnum = p_colnum and col1.comnum = com1.comnum and com1.magnum = m1.magnum;

    for un_chargement in c_chargement loop
    v_charnum := un_chargement.charnum;
      -- trouver la somme de volume des colis qui sont déjà dans ce chargement 
      open c_colis_chargement;
      fetch c_colis_chargement into v_colis_chargement,v_colvolume_chargement,v_secteur_chargement;
      if v_secteur_chargement = v_secteur_nouveau_colis then
        v_charger := true;
        while c_colis_chargement%found loop
        v_somme_volume_chargement := v_somme_volume_chargement + v_colvolume_chargement;
        fetch c_colis_chargement into v_colis_chargement,v_colvolume_chargement,v_secteur_chargement;
        end loop;
        close c_colis_chargement;
       -- trouver la capacité de camion affecté sur ce chargement
        select modcapacite into v_capacite_chargement from chargement ch, camion cam,modele mo
          where ch.charnum = un_chargement.charnum and ch.camnum = cam.camnum and cam.modnum = mo.modnum;
            -- vérifier s'il y a d'espace suffisant pour ce colis
            if v_capacite_chargement - v_somme_volume_chargement >= p_colvolume then
            -- Cas 1 : exist le chargement avec le même secteur avec d'espace suffisant, on ajoute ce colis dans ce chargement
              update colis set charnum = un_chargement.charnum, coletat = 'prise en charge' where colnum = p_colnum;
              sys.dbms_output.put_line('colis '|| p_colnum ||' bien prise en charge');
              exit;
            else
            -- Cas 2 : exist le chargement avec le même secteur sans d'espace suffisant, il faut attendre
              sys.dbms_output.put_line(p_colnum||'  pas d''espace suffisant, il faut attendre');
              exit;
            end if;     
       end if;
       close c_colis_chargement;
       end loop;     
       
       if v_charger = false then
          -- pas de chargement avec le même secteur
            for un_chargement_vide in c_chargement_vide loop
              -- Cas 3 : n'exist pas de chargement pour ce secteur mais il exist de chargement vide(sans colis), on ajoute ce colis sur ce chargement vide
                update colis set charnum = un_chargement_vide.charnum, coletat = 'prise en charge' where colnum = p_colnum;
                sys.dbms_output.put_line('colis '|| p_colnum ||' bien prise en charge dans un chargement vide');
                v_charger := true;
                exit;  
            end loop;
        end if;
        
END RG_DISTRIBUTION_COLIS;

-- chaque jour on créer des chargement manuellement
-- chaque jour un camion est affecté à un seul chargement
-- chaque chargement est pour qu'un seul secteur
-- ici on ne considère pas l'ajustement des camions avec differente capacité selon la somme de volume des colis