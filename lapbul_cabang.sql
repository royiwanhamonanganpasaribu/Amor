-- View: public.sisa_amor_acc_deposito

-- DROP VIEW public.sisa_amor_acc_deposito;

CREATE OR REPLACE VIEW public.sisa_amor_acc_deposito AS 
 SELECT deposito.id_dep,
    sisa_amor_acc_deposito(deposito.id_dep, 'D'::bpchar) AS sisa_deposito
   FROM deposito
 WHERE deposito.active_dep AND deposito.maturity_dep > sekarang() AND NOT deposito.gantung_dep;
  

ALTER TABLE public.sisa_amor_acc_deposito
  OWNER TO postgres;

-- View: public.sisa_amor_acc_deposito1

-- DROP VIEW public.sisa_amor_acc_deposito1;

CREATE OR REPLACE VIEW public.sisa_amor_acc_deposito1 AS 
 SELECT sisa_amor_acc_deposito.id_dep,
        CASE 
            WHEN sisa_amor_acc_deposito.id_dep = 600000053 THEN 49998::numeric

            WHEN sisa_amor_acc_deposito.sisa_deposito < 0::numeric OR sisa_amor_acc_deposito.id_dep = 19661 OR sisa_amor_acc_deposito.id_dep = 20259 OR sisa_amor_acc_deposito.id_dep = 19520 OR sisa_amor_acc_deposito.id_dep = 20160 OR sisa_amor_acc_deposito.id_dep = 18514  THEN sisa_amor_acc_deposito.sisa_deposito * (- 1::numeric)
            WHEN sisa_amor_acc_deposito.sisa_deposito = 0::numeric THEN 0::numeric
            ELSE sisa_amor_acc_deposito.sisa_deposito
        END AS sisa_deposito
   FROM sisa_amor_acc_deposito
 sisa_amor_acc_deposito.id_dep ;

ALTER TABLE public.sisa_amor_acc_deposito1
  OWNER TO postgres;



CREATE OR REPLACE VIEW public.sisa_amor_acc_deposito2 AS 
SELECT  *
   FROM sisa_amor_acc_deposito1 
 ORDER BY sisa_deposito asc;

 CREATE OR REPLACE VIEW public.sisa_amor_acc_deposito3 AS 
select id_Dep  , 
case
  when  id_dep = 20437 then 0 
else sisa_Deposito
end as sisa_Deposito

from sisa_amor_acc_deposito2;

-- View: public.v_lapbul19_gen1200

-- DROP VIEW public.v_lapbul19_gen1200;

CREATE OR REPLACE VIEW public.v_lapbul19_gen1200 AS 
 SELECT deposito.id_dep,
    deposito.bilyet_dep,
    deposito.buka_dep,
    deposito.maturity_dep,
    deposito.bunga_dep,
    deposito.nilaiskr,
    deposito.active_dep,
    deposito.blocked_dep,
    cif_nasabah.cif,
    reknas.no_rek,
    nasabah.kaitan_nas,
    nasabah.id_dati,
    nasabah.s_bentuk_nas,
    nasabah.satu_nas,
    nasabah.hub_nas,
    n2.cif2_nas AS cif1,
    COALESCE(nasabah.cif2_nas, n2.cif2_nas) AS "coalesce",
        CASE
            WHEN nasabah.id_dati = '0122'::bpchar THEN '0121'::bpchar
            ELSE nasabah.id_dati
        END AS ubah_dati,
          sisa_deposito,  deposito.nilaiskr - sisa_deposito  AS jumlah
   FROM deposito
     JOIN reknas USING (id_rek)
     JOIN nasabah USING (id_nas)
     JOIN cif_nasabah USING (id_nas)
     JOIN sisa_amor_acc_deposito3 USING (id_dep)
     LEFT JOIN nasabah n2 ON nasabah.satu_nas = n2.id_nas
  WHERE deposito.active_dep AND deposito.maturity_dep > sekarang() AND NOT deposito.gantung_dep
  ORDER BY deposito.bilyet_dep;

ALTER TABLE public.v_lapbul19_gen1200
  OWNER TO bprdba;
