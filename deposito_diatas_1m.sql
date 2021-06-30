DROP VIEW public.deposito_diatas_1m_2;
DROP VIEW public.deposito_diatas_1m_1;
 DROP VIEW public.deposito_diatas_1m;
-- View: public.deposito_diatas_1m

-- DROP VIEW public.deposito_diatas_1m;

CREATE OR REPLACE VIEW public.deposito_diatas_1m AS 
 SELECT reknas.id_nas,nasabah.nama_nas,
    reknas.id_rek,
        CASE
            WHEN substr(reknas.no_rek::text, 1, 6) = '4.456.'::text THEN sum(reknas.sldtab_rek)
            WHEN substr(reknas.no_rek::text, 1, 6) <> '4.456.'::text THEN 0::numeric
            ELSE NULL::numeric
        END AS saldo_tabungan,
    sum(deposito.nilaiskr) AS saldo_deposito
   FROM deposito
     JOIN reknas USING (id_rek)
     JOIN nasabah USING (id_nas)
  WHERE deposito.active_dep  and   bktcair_dep is   null
  GROUP BY reknas.id_nas, nasabah.nama_nas,reknas.id_rek;

ALTER TABLE public.deposito_diatas_1m
  OWNER TO postgres;
-- View: public.deposito_diatas_1m_1

-- DROP VIEW public.deposito_diatas_1m_1;

CREATE OR REPLACE VIEW public.deposito_diatas_1m_1 AS 
 SELECT deposito_diatas_1m.id_nas,deposito_diatas_1m.nama_nas,
    sum(deposito_diatas_1m.saldo_deposito) AS saldo_deposito,
    sum(deposito_diatas_1m.saldo_tabungan) + sum(deposito_diatas_1m.saldo_deposito) AS semua_tabungan
   FROM deposito_diatas_1m
  GROUP BY deposito_diatas_1m.nama_nas,deposito_diatas_1m.id_nas
  ORDER BY deposito_diatas_1m.id_nas;

ALTER TABLE public.deposito_diatas_1m_1
  OWNER TO postgres;

  -- View: public.deposito_diatas_1m_2

-- DROP VIEW public.deposito_diatas_1m_2;

CREATE OR REPLACE VIEW public.deposito_diatas_1m_2 AS 
 SELECT deposito.id_dep,
    nasabah.id_nas,
    nasabah.nama_nas,
    nasabah.ktp_nas,
    nasabah.alamat_nas,
    nasabah.tmp_nas,
    nasabah.lahir_nas,
    nasabah.npwp_nas,
    nasabah.npwp2_nas,
    deposito.bilyet_dep,
    COALESCE(nasabah.cif2_nas, n2.cif2_nas) AS cif,
    deposito.nilaiskr
   FROM deposito_diatas_1m_1
     JOIN nasabah USING (id_nas)
     JOIN reknas USING (id_nas)
     JOIN cif_nasabah USING (id_nas)
     LEFT JOIN nasabah n2 ON nasabah.satu_nas = n2.id_nas
     JOIN deposito USING (id_rek)
  WHERE deposito_diatas_1m_1.saldo_deposito >= 1000000000::numeric AND deposito.active_dep and   bktcair_dep is   null ;

ALTER TABLE public.deposito_diatas_1m_2
  OWNER TO postgres;


-- View: public.deposito_diatas_1m_3

-- DROP VIEW public.deposito_diatas_1m_3;

CREATE OR REPLACE VIEW public.deposito_diatas_1m_3 AS 
 SELECT reknas.id_nas,
    nasabah.nama_nas,
    reknas.no_rek,
    reknas.id_rek,
    sum(reknas.sldtab_rek) AS saldo_tabungan
   FROM reknas
     JOIN nasabah USING (id_nas)
     JOIN cif_nasabah USING (id_nas)
     LEFT JOIN nasabah n2 ON nasabah.satu_nas = n2.id_nas
  WHERE substr(reknas.no_rek::text, 1, 6) = '4.456.'::text
  GROUP BY reknas.id_nas, nasabah.nama_nas, reknas.id_rek
  ORDER BY (substr(reknas.no_rek::text, 1, 6));

ALTER TABLE public.deposito_diatas_1m_3
  OWNER TO postgres;

-- View: public.deposito_diatas_1m_4

-- DROP VIEW public.deposito_diatas_1m_4;

CREATE OR REPLACE VIEW public.deposito_diatas_1m_4 AS 
 SELECT DISTINCT deposito_diatas_1m_2.id_dep,
    deposito_diatas_1m_2.id_nas,
    deposito_diatas_1m_2.nama_nas,
    deposito_diatas_1m_2.ktp_nas,
    deposito_diatas_1m_2.alamat_nas,
    deposito_diatas_1m_2.tmp_nas,
    deposito_diatas_1m_2.lahir_nas,
    deposito_diatas_1m_2.npwp_nas,
    deposito_diatas_1m_2.npwp2_nas,
    deposito_diatas_1m_2.bilyet_dep,
    deposito_diatas_1m_2.cif,
    deposito_diatas_1m_2.nilaiskr,
    deposito_diatas_1m_3.saldo_tabungan
   FROM deposito_diatas_1m_2
     FULL JOIN deposito_diatas_1m_3 ON deposito_diatas_1m_2.id_nas = deposito_diatas_1m_3.id_nas
  WHERE deposito_diatas_1m_2.id_dep IS NOT NULL
  ORDER BY deposito_diatas_1m_2.nama_nas;

ALTER TABLE public.deposito_diatas_1m_4
  OWNER TO postgres;
