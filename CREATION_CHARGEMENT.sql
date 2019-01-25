create or replace PROCEDURE CREATION_CHARGEMENT
(
  P_CHARNUM IN NUMBER
)AS 
  v_secnum NUMBER;
  v_colnum NUMBER;
  v_secnom VARCHAR2(32);
  cursor c_touslescolis is select col.colnum, m.secnum
                    from colis col, commande com, magasin m
                    where col.comnum = com.comnum
                    and com.magnum = m.magnum
                    and coletat = 'en cours de préparation';
  
  cursor c_colissec is select col.colnum
                    from colis col, commande com, magasin m
                    where col.comnum = com.comnum
                    and com.magnum = m.magnum
                    and m.secnum = v_secnum;
  
BEGIN
  open c_touslescolis;
  fetch c_touslescolis into v_colnum, v_secnum;
  if c_touslescolis%found then
    for un_colis in c_colissec loop
      update colis set charnum = P_CHARNUM, coletat = 'prise en charge' where colnum = un_colis.colnum;
    end loop;
    select secquartier into v_secnom from secteur where secnum = v_secnum;
    SYS.DBMS_OUTPUT.PUT_LINE('Tous les colis de ' || v_secnom || ' sont pris en charge');
  end if;
  close c_touslescolis;
END CREATION_CHARGEMENT;