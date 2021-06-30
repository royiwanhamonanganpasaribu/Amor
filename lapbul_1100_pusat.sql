 select in_log('lapbul_1100.sql', 'Perubahan pada suku bunga pada lapbul');
 
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

-- View: public.v_lapbul19_gen1100_jenis_tab_1_uber

-- DROP VIEW public.v_lapbul19_gen1100_jenis_tab_1_uber;

CREATE OR REPLACE VIEW public.v_lapbul19_gen1100_jenis_tab_1_uber AS 
 SELECT uber.bunga,
    uber.cif,
    uber.cif2_nas,
    uber.kaitan_nas,
    uber.s_bentuk_nas,
    uber.id_dati,
    uber.no_rek,
    uber.jenis_rek,
    uber.aktive_rek,
    uber.jenistab_rek,
    uber.sldtab_rek,
    uber.buka_rek,
    uber.cif1,
    uber."coalesce",
    uber.id_dati_nasabah
   FROM dblink('dbname=uber'::text || npw(), 'select * from v_lapbul19_gen1100_jenis_tab_1 '::text) uber(bunga numeric, cif character(16), cif2_nas character(16), kaitan_nas character(1), s_bentuk_nas character(2), id_dati character(4), no_rek character(13), jenis_rek character(1), aktive_rek boolean, jenistab_rek character(1), sldtab_rek numeric(15,2), buka_rek date, cif1 character(16), "coalesce" character(16), id_dati_nasabah bpchar);

ALTER TABLE public.v_lapbul19_gen1100_jenis_tab_1_uber
  OWNER TO postgres;

-- View: public.v_lapbul19_gen1100_jenis_tab_1_bkr

-- DROP VIEW public.v_lapbul19_gen1100_jenis_tab_1_bkr;

CREATE OR REPLACE VIEW public.v_lapbul19_gen1100_jenis_tab_1_bkr AS 
 SELECT bkr.bunga,
    bkr.cif,
    bkr.cif2_nas,
    bkr.kaitan_nas,
    bkr.s_bentuk_nas,
    bkr.id_dati,
    bkr.no_rek,
    bkr.jenis_rek,
    bkr.aktive_rek,
    bkr.jenistab_rek,
    bkr.sldtab_rek,
    bkr.buka_rek,
    bkr.cif1,
    bkr."coalesce",
    bkr.id_dati_nasabah
   FROM dblink('dbname=bkr'::text || npw(), 'select * from v_lapbul19_gen1100_jenis_tab_1 '::text) bkr(bunga numeric, cif character(16), cif2_nas character(16), kaitan_nas character(1), s_bentuk_nas character(2), id_dati character(4), no_rek character(13), jenis_rek character(1), aktive_rek boolean, jenistab_rek character(1), sldtab_rek numeric(15,2), buka_rek date, cif1 character(16), "coalesce" character(16), id_dati_nasabah bpchar);

ALTER TABLE public.v_lapbul19_gen1100_jenis_tab_1_bkr
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


-- Function: public.lapbul19_gen1100()

-- DROP FUNCTION public.lapbul19_gen1100();

CREATE OR REPLACE FUNCTION public.lapbul19_gen1100()
  RETURNS integer AS
$BODY$------------------------Header------------------
declare
  hasil integer;
  isi text;
  isi_uber text;
  isi_bkr text;
  form  char(4);
  r record;
  c record;
begin
  hasil := 0;

  select into c * from company;
  form := '1100';
  isi :=  'H01|010201|601329|' || sekarang() || '|LBBPRK|' || form || '|0|';

  insert into lapbul19 (form_lb, isi_lb) values (form, isi);
  
  
  
  for r in select 'D01|001|'::text as depan, cif,  kaitan_nas,  s_bentuk_nas,
    id_dati_nasabah,  no_rek,  jenis_rek,  aktive_rek,  jenistab_rek,  sldtab_rek,buka_rek,bunga
  from v_lapbul19_gen1100_jenis_tab_1
  order by no_rek
  loop
    isi := r.depan || r.cif || '|'  || replace(r.no_rek,'.','') || '|10|';
    if r.kaitan_nas = 'T' then
      isi := isi || '20|';
    else
      isi := isi || '12|';
    end if;
 
  if r.s_bentuk_nas = '18' then
   isi := isi || '860|';
  else
  if r.s_bentuk_nas = '02' then
    isi := isi || '860|';
  else
    isi := isi || '875|';
  end if;
  end if;
  isi := isi || r.id_dati_nasabah || '|' || to_char(r.buka_rek,'yyyyMMdd') || '||'  || r.bunga || '||';
 

   isi:=isi || round(r.sldtab_rek) || '|0||'  || '0|' || round(r.sldtab_rek);
    insert into lapbul19 (form_lb, isi_lb) values (form, isi);
  end loop; 
 isi_uber = lapbul19_gen1100_uber();
 isi_bkr = lapbul19_gen1100_bkr();
  return hasil;
end; -- end of lapbul19_gen1$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.lapbul19_gen1100()
  OWNER TO postgres;
COMMENT ON FUNCTION public.lapbul19_gen1100() IS 'fungsi untuk generete lapbul19';
 

-- Function: public.lapbul19_gen1100_uber()

-- DROP FUNCTION public.lapbul19_gen1100_uber();

CREATE OR REPLACE FUNCTION public.lapbul19_gen1100_uber()
  RETURNS integer AS
$BODY$------------------------Header------------------
declare
  hasil integer;
  isi text;
  isi_uber text;
  isi_bkr text;
  form  char(4);
  r record;
  c record;
begin
  hasil := 0;

  select into c * from company;
  form := '1100'; 
 
  
  for r in select 'D01|002|'::text as depan, cif,  kaitan_nas,  s_bentuk_nas,
    id_dati_nasabah,  no_rek,  jenis_rek,  aktive_rek,  jenistab_rek,  sldtab_rek,buka_rek,bunga
  from v_lapbul19_gen1100_jenis_tab_1_uber
  order by no_rek
  loop
    isi := r.depan || r.cif || '|'  || replace(r.no_rek,'.','') || '|10|';
    if r.kaitan_nas = 'T' then
      isi := isi || '20|';
    else
      isi := isi || '12|';
    end if;
 
  if r.s_bentuk_nas = '18' then
   isi := isi || '860|';
  else
  if r.s_bentuk_nas = '02' then
    isi := isi || '860|';
  else
    isi := isi || '875|';
  end if;
  end if;
  isi := isi || r.id_dati_nasabah || '|' || to_char(r.buka_rek,'yyyyMMdd') || '||'  || r.bunga || '||';
 

   isi:=isi || round(r.sldtab_rek) || '|0||'  || '0|' || round(r.sldtab_rek);
    insert into lapbul19 (form_lb, isi_lb) values (form, isi);
  end loop; 
 
  return hasil;
end; -- end of lapbul19_gen1$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.lapbul19_gen1100_uber()
  OWNER TO postgres;
COMMENT ON FUNCTION public.lapbul19_gen1100_uber() IS 'fungsi untuk generete lapbul19';
 

-- Function: public.lapbul19_gen1100_bkr()

-- DROP FUNCTION public.lapbul19_gen1100_bkr();

CREATE OR REPLACE FUNCTION public.lapbul19_gen1100_bkr()
  RETURNS integer AS
$BODY$------------------------Header------------------
declare
  hasil integer;
  isi text;
  isi_uber text;
  isi_bkr text;
  form  char(4);
  r record;
  c record;
begin
  hasil := 0;

  select into c * from company;
  form := '1100';   
  for r in select 'D01|003|'::text as depan, cif,  kaitan_nas,  s_bentuk_nas,
    id_dati_nasabah,  no_rek,  jenis_rek,  aktive_rek,  jenistab_rek,  sldtab_rek,buka_rek,bunga
  from v_lapbul19_gen1100_jenis_tab_1_bkr
  order by no_rek
  loop
    isi := r.depan || r.cif || '|'  || replace(r.no_rek,'.','') || '|10|';
    if r.kaitan_nas = 'T' then
      isi := isi || '20|';
    else
      isi := isi || '12|';
    end if;
 
  if r.s_bentuk_nas = '18' then
   isi := isi || '860|';
  else
  if r.s_bentuk_nas = '02' then
    isi := isi || '860|';
  else
    isi := isi || '875|';
  end if;
  end if;
  isi := isi || r.id_dati_nasabah || '|' || to_char(r.buka_rek,'yyyyMMdd') || '||'  || r.bunga || '||';
 

   isi:=isi || round(r.sldtab_rek) || '|0||'  || '0|' || round(r.sldtab_rek);
    insert into lapbul19 (form_lb, isi_lb) values (form, isi);
  end loop; 
 
  return hasil;
end; -- end of lapbul19_gen1$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.lapbul19_gen1100_bkr()
  OWNER TO postgres;
COMMENT ON FUNCTION public.lapbul19_gen1100_bkr() IS 'fungsi untuk generete lapbul19';
 