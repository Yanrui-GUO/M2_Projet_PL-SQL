CREATE OR REPLACE FORCE VIEW "AEROFRANCE_LIAO"."VIEW_PRODUIT" ("COMGLOBNUM", "PRODNUM", "QTECOMGLOB") AS 
select co.comglobnum, co.prodnum, co.qtecomglob
from CHEF_GUO.concernerglob co, CHEF_GUO.commandeglobale com
where com.comglobnum = co.comglobnum
and com.fournum = 4
and co.prodnum not in (select l.prodnum
						from CHEF_GUO.livrer l, CHEF_GUO.bonlivraison b, CHEF_GUO.concernerglob c
						where l.bonlivnum = b.bonlivnum
						and com.comglobnum = b.comglobnum
						and com.comglobnum = c.comglobnum
						and c.prodnum = l.prodnum
						and com.fournum = 4
						and l.qteliv-l.qterefus = c.qtecomglob );
 
