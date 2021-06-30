 
CREATE OR REPLACE VIEW public.hitung_komisi AS 
SELECT distinct id_Dep,awal_Dep,to_char(awal_Dep, '2021-1-DD')::DATE AS bln_1,bln_Dep,komisi_Deposito,tgl_komisi_dep,bilyet_dep 
FROM deposito
     JOIN reknas USING (id_rek)
     JOIN nasabah USING (id_nas)
     JOIN cif_nasabah USING (id_nas) 
     LEFT JOIN nasabah n2 ON nasabah.satu_nas = n2.id_nas
 --  WHERE deposito.active_dep AND deposito.maturity_dep >= sekarang() AND NOT deposito.gantung_dep
  ORDER BY komisi_Deposito;

-- Function: public.sisa_amor_acc_deposito_lewat(integer, character)

-- DROP FUNCTION public.sisa_amor_acc_deposito_lewat(integer, character);

CREATE OR REPLACE FUNCTION public.sisa_amor_acc_deposito_lewat(
    dep integer,
    jenis character)
  RETURNS numeric AS
$BODY$-- menghasilkan sisa amor untuk dep (id_dep) dan jenis (id_je) yang dimasukan
-- ditentukan menurut penelusuran di jurnal_detil
declare
  r record;
  hasil numeric(15,2);
begin
  hasil := 0;
  if jenis = 'D' then
    select into hasil 
      sum(debet_xa)  -  sum(kredit_xa)
      from trans_amor 
      join amor_etap using (id_ae)
      join deposito using (id_dep);
  end if;
  return nonul(hasil);
end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.sisa_amor_acc_deposito_lewat(integer, character)
  OWNER TO postgres;
COMMENT ON FUNCTION public.sisa_amor_acc_deposito_lewat(integer, character) IS 'Menghasilkan sisa amor untuk id_dep, id_je yang dimasukan.';



CREATE OR REPLACE VIEW public.sisa_amor_acc_deposito_lewat AS 

 SELECT id_Dep,
sisa_amor_acc_deposito_lewat(deposito.id_dep, 'D'::bpchar)

   FROM deposito
where tgl_komisi_Dep >= '2021-2-1'
order by 
sisa_amor_acc_deposito_lewat(deposito.id_dep, 'D'::bpchar);

 
 
CREATE OR REPLACE VIEW public.hitung_komisi AS 
SELECT distinct id_Dep,awal_Dep,to_char(awal_Dep, '2021-1-DD')::DATE AS bln_1,bln_Dep,komisi_Deposito,tgl_komisi_dep,bilyet_dep 
FROM deposito
     JOIN reknas USING (id_rek)
     JOIN nasabah USING (id_nas)
     JOIN cif_nasabah USING (id_nas) 
     LEFT JOIN nasabah n2 ON nasabah.satu_nas = n2.id_nas
 --  WHERE deposito.active_dep AND deposito.maturity_dep >= sekarang() AND NOT deposito.gantung_dep
  ORDER BY komisi_Deposito;

-- View: public.hitung_komisi1

-- DROP VIEW public.hitung_komisi1;

CREATE OR REPLACE VIEW public.hitung_komisi1 AS 
 SELECT hitung_komisi.id_dep,
    hitung_komisi.bln_1,
    hitung_komisi.awal_dep,
    hitung_komisi.tgl_komisi_dep,
    hitung_komisi.bln_dep,
        CASE
            WHEN hitung_komisi.awal_dep <= '2020-12-31'::date THEN hitung_komisi.bln_dep::double precision - round(((hitung_komisi.bln_1 - hitung_komisi.awal_dep) / 30)::double precision)
            WHEN hitung_komisi.awal_dep >= '2021-01-01'::date THEN hitung_komisi.bln_dep::double precision
            ELSE NULL::double precision
        END AS sdh_dilewati,
    hitung_komisi.komisi_deposito,
    hitung_komisi.bilyet_dep
   FROM hitung_komisi
  ORDER BY hitung_komisi.bln_dep;

ALTER TABLE public.hitung_komisi1
  OWNER TO postgres;


CREATE OR REPLACE VIEW public.hitung_komisi2 AS 
SELECT maturity_Dep,hitung_komisi1.* , 
CASE
  WHEN hitung_komisi1.awal_dep <= '2021-12-31'::date THEN round(hitung_komisi1.komisi_deposito/sdh_dilewati)
  WHEN hitung_komisi1.awal_dep >= '2021-01-01'::date THEN round(hitung_komisi1.komisi_deposito/hitung_komisi1.bln_dep)

  end as amor_bln
FROM hitung_komisi1 
JOIN DEPOSITO USING(bilyet_dep)   
order by komisi_Deposito asc;
 
-- View: public.hitung_komisi3

-- DROP VIEW public.hitung_komisi3;

CREATE OR REPLACE VIEW public.hitung_komisi3 AS 
 SELECT hitung_komisi2.maturity_dep,
    hitung_komisi2.id_dep,
    hitung_komisi2.bln_1,
    hitung_komisi2.awal_dep,
    hitung_komisi2.tgl_komisi_dep,
    hitung_komisi2.bln_dep,
    hitung_komisi2.sdh_dilewati,
    hitung_komisi2.komisi_deposito,
    hitung_komisi2.bilyet_dep,
    hitung_komisi2.amor_bln,
    hitung_komisi2.komisi_deposito::numeric(15,2) - hitung_komisi2.amor_bln * (hitung_komisi2.sdh_dilewati - 1::numeric(15,2)) AS amor_akhir,
    Round(hitung_komisi2.amor_bln * (hitung_komisi2.bln_dep - 1)::numeric(15,2) + hitung_komisi2.komisi_deposito::numeric(15,2) - 
    hitung_komisi2.amor_bln * (hitung_komisi2.sdh_dilewati - 1::numeric(15,2)) ::numeric(15,2))::numeric(15,2) AS nilai_amor
   FROM hitung_komisi2
  ORDER BY hitung_komisi2.komisi_deposito;

ALTER TABLE public.hitung_komisi3
  OWNER TO postgres;

-- View: public.hitung_komisi4

-- DROP VIEW public.hitung_komisi4;

CREATE OR REPLACE VIEW public.hitung_komisi4 AS 
 SELECT hitung_komisi3.maturity_dep,
    hitung_komisi3.id_dep,
    hitung_komisi3.bln_1,
    hitung_komisi3.awal_dep,
    hitung_komisi3.tgl_komisi_dep,
    hitung_komisi3.bln_dep,
    hitung_komisi3.sdh_dilewati,
    hitung_komisi3.komisi_deposito,
    hitung_komisi3.bilyet_dep,
    hitung_komisi3.amor_bln,
    hitung_komisi3.amor_akhir,
    hitung_komisi3.nilai_amor,
        CASE
            WHEN hitung_komisi3.nilai_amor >= 4999::numeric AND hitung_komisi3.nilai_amor <= 5003::numeric THEN 5000::numeric
            WHEN hitung_komisi3.nilai_amor >= 9997::numeric AND hitung_komisi3.nilai_amor <= 10001::numeric THEN 10000::numeric
            ELSE hitung_komisi3.nilai_amor
        END AS akhir_nilai_amor
   FROM hitung_komisi3 
  ORDER BY hitung_komisi3.nilai_amor;

ALTER TABLE public.hitung_komisi4
  OWNER TO postgres;

-- View: public.hitung_komisi5

-- DROP VIEW public.hitung_komisi5;

CREATE OR REPLACE VIEW public.hitung_komisi5 AS 
 SELECT hitung_komisi4.maturity_dep,
    hitung_komisi4.id_dep,
    hitung_komisi4.bln_1,
    hitung_komisi4.awal_dep,
    hitung_komisi4.tgl_komisi_dep,
    hitung_komisi4.bln_dep,
    hitung_komisi4.sdh_dilewati,
    hitung_komisi4.komisi_deposito,
    hitung_komisi4.bilyet_dep,
    hitung_komisi4.amor_bln,
    hitung_komisi4.amor_akhir,
    hitung_komisi4.nilai_amor,
    hitung_komisi4.akhir_nilai_amor,
    round(hitung_komisi4.akhir_nilai_amor / hitung_komisi4.bln_dep::numeric) AS amor_per_bln,
    hitung_komisi4.akhir_nilai_amor - round(hitung_komisi4.akhir_nilai_amor / hitung_komisi4.bln_dep::numeric) * (hitung_komisi4.bln_dep - 1)::numeric AS amor_terakhir
   FROM hitung_komisi4;

ALTER TABLE public.hitung_komisi5
  OWNER TO postgres;

-- View: public.hitung_komisi_deposito

-- DROP VIEW public.hitung_komisi_deposito;

CREATE OR REPLACE VIEW public.hitung_komisi_deposito AS 
 
 SELECT hitung_komisi5.id_dep,
        CASE
            WHEN hitung_komisi5.amor_per_bln IS NOT NULL THEN hitung_komisi5.amor_per_bln
            WHEN hitung_komisi5.amor_per_bln IS NULL THEN 0::numeric
            ELSE NULL::numeric
        END AS amor_per_bln,
        CASE
            WHEN hitung_komisi5.amor_per_bln IS NOT NULL THEN hitung_komisi5.amor_terakhir
            WHEN hitung_komisi5.amor_per_bln IS NULL THEN 0::numeric
            ELSE NULL::numeric
        END AS amor_terakhir,
        CASE
            WHEN hitung_komisi5.amor_per_bln IS NOT NULL AND hitung_komisi5.bln_dep::double precision <> hitung_komisi5.sdh_dilewati AND hitung_komisi5.sdh_dilewati = 1::double precision THEN hitung_komisi5.amor_terakhir::double precision
            WHEN hitung_komisi5.amor_per_bln IS NOT NULL AND hitung_komisi5.bln_dep::double precision <> hitung_komisi5.sdh_dilewati AND hitung_komisi5.sdh_dilewati >= 2::double precision THEN (hitung_komisi5.bln_Dep - hitung_komisi5.sdh_dilewati) * hitung_komisi5.amor_per_bln::double precision
            WHEN hitung_komisi5.amor_per_bln IS NOT NULL AND hitung_komisi5.bln_dep::double precision = hitung_komisi5.sdh_dilewati THEN hitung_komisi5.nilai_amor::double precision
            WHEN hitung_komisi5.amor_per_bln IS NULL THEN 0::numeric::double precision
            ELSE NULL::double precision
        END AS sisa_amor 
,nilai_amor, bln_dep, sdh_dilewati,awal_dep,maturitY_dep,tgl_komisi_dep  
   FROM hitung_komisi5
 
  ORDER BY (
        CASE
            WHEN hitung_komisi5.amor_per_bln IS NOT NULL THEN hitung_komisi5.amor_per_bln
            WHEN hitung_komisi5.amor_per_bln IS NULL THEN 0::numeric
            ELSE NULL::numeric
        END);
 
ALTER TABLE public.hitung_komisi_deposito
  OWNER TO postgres;

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
        CASE
            WHEN deposito.maturity_dep = sekarang()  THEN amor_terakhir 
            WHEN deposito.maturity_dep <> sekarang()  THEN amor_per_bln 
             
        END AS sisa_deposito,
         CASE
            WHEN deposito.maturity_dep = sekarang()  THEN deposito.nilaiskr - amor_terakhir 
            WHEN deposito.maturity_dep <> sekarang()  THEN deposito.nilaiskr - amor_per_bln 
             
        END AS jumlah
   FROM deposito
     JOIN reknas USING (id_rek)
     JOIN nasabah USING (id_nas)
     JOIN cif_nasabah USING (id_nas)
     JOIN hitung_komisi_deposito USING (id_dep)
     LEFT JOIN nasabah n2 ON nasabah.satu_nas = n2.id_nas
  WHERE deposito.active_dep AND deposito.maturity_dep > sekarang() AND NOT deposito.gantung_dep
  ORDER BY deposito.bilyet_dep;

ALTER TABLE public.v_lapbul19_gen1200
  OWNER TO postgres;
