create or replace FUNCTION RG_QTE_COMMANDE 
(P_COMNUM IN NUMBER 
, P_PRODNUM IN NUMBER 
, P_QTECOM IN NUMBER 
) RETURN boolean AS 
res boolean;
p_magnum number;
p_qtestock number;
p_qtemax number;
BEGIN
    select qtestock, qtemax into p_qtestock, p_qtemax from stocker s, commande c
        where s.magnum = c.magnum
        and s.prodnum = p_prodnum
        and c.comnum = p_comnum;
    
    if p_qtecom <= p_qtemax - p_qtestock then
        return true;
    else
        return false;
    end if;
END RG_QTE_COMMANDE;