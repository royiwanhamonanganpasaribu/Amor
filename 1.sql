
DROP VIEW public.perhitungan_sisa_amor_final;
DROP VIEW public.perhitungan_sisa_deposito;

-- View: public.perhitungan_sisa_deposito

-- DROP VIEW public.perhitungan_sisa_deposito;

CREATE OR REPLACE VIEW public.perhitungan_sisa_deposito AS 
 SELECT sum(hitung_komisi_deposito_3.sisa_amor) AS komisi_dep
   FROM hitung_komisi_deposito_3;

ALTER TABLE public.perhitungan_sisa_deposito
  OWNER TO postgres;

 

-- View: public.perhitungan_sisa_amor_final

-- DROP VIEW public.perhitungan_sisa_amor_final;

CREATE OR REPLACE VIEW public.perhitungan_sisa_amor_final AS 
 SELECT sekarang() AS sekarang,
    perhitungan_sisa_pa_mk.pa_mk,
    perhitungan_sisa_mk_mk.mk_mk,
    perhitungan_sisa_pa_inv.pa_inv,
    perhitungan_sisa_mk_inv.mk_inv,
    perhitungan_sisa_pa_ksm.pa_ksm,
    perhitungan_sisa_mk_ksm.mk_ksm,
    coa_13011.coa_13011,
    coa_13012.coa_13012,
    coa_13021.coa_13021,
    coa_13031.coa_13031,
    coa_13022.coa_13022,
    coa_13032.coa_13032,
    coa_16001.coa_16001,
    perhitungan_sisa_deposito.komisi_dep
   FROM perhitungan_sisa_pa_mk,
    perhitungan_sisa_mk_mk,
    perhitungan_sisa_pa_inv,
    perhitungan_sisa_mk_inv,
    perhitungan_sisa_pa_ksm,
    perhitungan_sisa_mk_ksm,
    coa_13011,
    coa_13012,
    coa_13021,
    coa_13031,
    coa_13022,
    coa_13032,
    coa_16001,
    perhitungan_sisa_deposito;

ALTER TABLE public.perhitungan_sisa_amor_final
  OWNER TO postgres;
-- View: public.hitung_komisi_deposito_3

-- DROP VIEW public.hitung_komisi_deposito_3;

CREATE OR REPLACE VIEW public.hitung_komisi_deposito_3 AS 
 SELECT hitung_komisi_deposito_2.id_dep,
    hitung_komisi_deposito_2.amor_per_bln,
    hitung_komisi_deposito_2.amor_terakhir,
    hitung_komisi_deposito_2.awal_dep,
    hitung_komisi_deposito_2.maturity_dep,
    hitung_komisi_deposito_2.sekarang,
    hitung_komisi_deposito_2.bln_dep,
    hitung_komisi_deposito_2.bln_lewat,
    hitung_komisi_deposito_2.sisa_bln,
    hitung_komisi_deposito_2.sisa_amor,
    deposito.komisi_deposito,
    hitung_komisi5.akhir_nilai_amor
   FROM hitung_komisi_deposito_2
     JOIN deposito USING (id_dep)
     JOIN hitung_komisi5 USING (id_dep)
    where deposito.active_Dep;

ALTER TABLE public.hitung_komisi_deposito_3
  OWNER TO postgres;
