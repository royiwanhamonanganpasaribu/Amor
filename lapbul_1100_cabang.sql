-- View: public.v_lapbul19_gen1100_jenis_tab

-- DROP VIEW public.v_lapbul19_gen1100_jenis_tab;

CREATE OR REPLACE VIEW public.v_lapbul19_gen1100_jenis_tab AS 
 SELECT substr(v_lapbul19_gen1100.no_rek::text, 1, 1) AS substr,
        CASE
            WHEN substr(v_lapbul19_gen1100.no_rek::text, 1, 1) = '1'::text THEN 'Perdana'::text
            WHEN substr(v_lapbul19_gen1100.no_rek::text, 1, 1) = '4'::text THEN 'Prestasi'::text
            ELSE NULL::text
        END AS jenis_tab,
    company.tabplus3,
    company.tabplus2,
    company.batasplus2,
    company.tabplus1,
    company.batasplus1,
    company.bunga_tabungan,
    company.batasbunga,
    v_lapbul19_gen1100.cif,
    v_lapbul19_gen1100.cif2_nas,
    v_lapbul19_gen1100.kaitan_nas,
    v_lapbul19_gen1100.s_bentuk_nas,
    v_lapbul19_gen1100.id_dati,
    v_lapbul19_gen1100.no_rek,
    v_lapbul19_gen1100.jenis_rek,
    v_lapbul19_gen1100.aktive_rek,
    v_lapbul19_gen1100.jenistab_rek,
    v_lapbul19_gen1100.sldtab_rek,
    v_lapbul19_gen1100.buka_rek,
    v_lapbul19_gen1100.cif1,
    v_lapbul19_gen1100."coalesce",
    v_lapbul19_gen1100.id_dati_nasabah
   FROM v_lapbul19_gen1100,
    company;

ALTER TABLE public.v_lapbul19_gen1100_jenis_tab
  OWNER TO postgres;

-- View: public.v_lapbul19_gen1100_jenis_tab_1

-- DROP VIEW public.v_lapbul19_gen1100_jenis_tab_1;

CREATE OR REPLACE VIEW public.v_lapbul19_gen1100_jenis_tab_1 AS 
 SELECT
        CASE
            WHEN v_lapbul19_gen1100_jenis_tab.jenis_tab = 'Perdana'::text AND v_lapbul19_gen1100_jenis_tab.sldtab_rek >= v_lapbul19_gen1100_jenis_tab.batasbunga THEN round(v_lapbul19_gen1100_jenis_tab.bunga_tabungan, 2)
            WHEN (v_lapbul19_gen1100_jenis_tab.jenis_tab = 'Prestasi'::text OR v_lapbul19_gen1100_jenis_tab.jenis_tab = 'Perdana'::text) AND v_lapbul19_gen1100_jenis_tab.sldtab_rek < v_lapbul19_gen1100_jenis_tab.batasbunga THEN round(0::numeric, 2)
            WHEN v_lapbul19_gen1100_jenis_tab.jenis_tab = 'Prestasi'::text AND v_lapbul19_gen1100_jenis_tab.sldtab_rek >= v_lapbul19_gen1100_jenis_tab.batasbunga AND v_lapbul19_gen1100_jenis_tab.sldtab_rek <= v_lapbul19_gen1100_jenis_tab.batasplus1 THEN round(v_lapbul19_gen1100_jenis_tab.tabplus1, 2)
            WHEN v_lapbul19_gen1100_jenis_tab.jenis_tab = 'Prestasi'::text AND v_lapbul19_gen1100_jenis_tab.sldtab_rek > v_lapbul19_gen1100_jenis_tab.batasplus1 AND v_lapbul19_gen1100_jenis_tab.sldtab_rek <= v_lapbul19_gen1100_jenis_tab.batasplus2 THEN round(v_lapbul19_gen1100_jenis_tab.tabplus2, 2)
            WHEN v_lapbul19_gen1100_jenis_tab.jenis_tab = 'Prestasi'::text AND v_lapbul19_gen1100_jenis_tab.sldtab_rek > v_lapbul19_gen1100_jenis_tab.batasplus2 THEN round(v_lapbul19_gen1100_jenis_tab.tabplus3, 2)
            ELSE NULL::numeric
        END AS bunga,
    v_lapbul19_gen1100_jenis_tab.cif,
    v_lapbul19_gen1100_jenis_tab.cif2_nas,
    v_lapbul19_gen1100_jenis_tab.kaitan_nas,
    v_lapbul19_gen1100_jenis_tab.s_bentuk_nas,
    v_lapbul19_gen1100_jenis_tab.id_dati,
    v_lapbul19_gen1100_jenis_tab.no_rek,
    v_lapbul19_gen1100_jenis_tab.jenis_rek,
    v_lapbul19_gen1100_jenis_tab.aktive_rek,
    v_lapbul19_gen1100_jenis_tab.jenistab_rek,
    v_lapbul19_gen1100_jenis_tab.sldtab_rek,
    v_lapbul19_gen1100_jenis_tab.buka_rek,
    v_lapbul19_gen1100_jenis_tab.cif1,
    v_lapbul19_gen1100_jenis_tab."coalesce",
    v_lapbul19_gen1100_jenis_tab.id_dati_nasabah
   FROM v_lapbul19_gen1100_jenis_tab;

ALTER TABLE public.v_lapbul19_gen1100_jenis_tab_1
  OWNER TO postgres;
