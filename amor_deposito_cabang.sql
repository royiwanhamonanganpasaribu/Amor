 
 select in_log('bpr.sql', 'Revisi pada amortisasi BPR public.amor_etap ADD COLUMN tgl_dep_ae,  public.amor_etap ADD COLUMN id_dk,ubah2dep,komisi_deposito_hit1,komisi_deposito_daily_amor,komisi_deposito_daily_amor1,ubah2dep,ubah_dep,sisa_amor_acc_deposito');

ALTER TABLE public.amor_etap ADD COLUMN tgl_dep_ae date;
ALTER TABLE public.amor_etap ADD COLUMN id_dk integer;
ALTER TABLE public.deposito ADD COLUMN id_dk integer;

 
CREATE OR REPLACE VIEW public.hitung_komisi AS 
 SELECT DISTINCT deposito.id_Dk,deposito.id_dep,
    deposito.awal_dep,
    to_char(deposito.awal_dep::timestamp with time zone, '2021-1-DD'::text)::date AS bln_1,
    deposito.bln_dep,
    deposito.komisi_deposito,
    deposito.tgl_komisi_dep,
    deposito.bilyet_dep
   FROM deposito
     JOIN reknas USING (id_rek)
     JOIN nasabah USING (id_nas)
     JOIN cif_nasabah USING (id_nas)
     LEFT JOIN nasabah n2 ON nasabah.satu_nas = n2.id_nas
  WHERE deposito.active_dep
  ORDER BY deposito.komisi_deposito;

ALTER TABLE public.hitung_komisi
  OWNER TO postgres;

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
SELECT distinct deposito.id_Dk,id_Dep,awal_Dep,to_char(awal_Dep, '2021-1-DD')::DATE AS bln_1,bln_Dep,komisi_Deposito,tgl_komisi_dep,bilyet_dep 
FROM deposito
     JOIN reknas USING (id_rek)
     JOIN nasabah USING (id_nas)
     JOIN cif_nasabah USING (id_nas) 
     LEFT JOIN nasabah n2 ON nasabah.satu_nas = n2.id_nas
  WHERE deposito.active_dep --  WHERE deposito.active_dep AND deposito.maturity_dep >= sekarang() AND NOT deposito.gantung_dep
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
            WHEN hitung_komisi3.nilai_amor >= 4992::numeric AND hitung_komisi3.nilai_amor <= 5003::numeric THEN 5000::numeric
            WHEN hitung_komisi3.nilai_amor >= 9000::numeric AND hitung_komisi3.nilai_amor <= 10001::numeric THEN 10000::numeric
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
 SELECT hitung_komisi5.id_dep,deposito.id_dk,
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
    hitung_komisi5.nilai_amor,
    hitung_komisi5.bln_dep,
    hitung_komisi5.sdh_dilewati,
    hitung_komisi5.awal_dep,
    hitung_komisi5.maturity_dep,
    hitung_komisi5.tgl_komisi_dep
   FROM hitung_komisi5
     JOIN deposito USING (id_dep)
  WHERE deposito.active_dep AND deposito.tgl_komisi_dep IS NOT NULL
  ORDER BY (
        CASE
            WHEN hitung_komisi5.amor_per_bln IS NOT NULL THEN hitung_komisi5.amor_per_bln
            WHEN hitung_komisi5.amor_per_bln IS NULL THEN 0::numeric
            ELSE NULL::numeric
        END);

ALTER TABLE public.hitung_komisi_deposito
  OWNER TO postgres;


-- View: public.hitung_komisi_deposito_1

-- DROP VIEW public.hitung_komisi_deposito_1;

CREATE OR REPLACE VIEW public.hitung_komisi_deposito_1 AS 
 SELECT hitung_komisi_deposito.id_dep,
    hitung_komisi_deposito.amor_per_bln,
    hitung_komisi_deposito.amor_terakhir,
    hitung_komisi_deposito.awal_dep,
    hitung_komisi_deposito.maturity_dep,
    sekarang() AS sekarang,
    deposito.bln_dep,
    round(((sekarang() - deposito.awal_dep) / 30)::double precision) AS bln_lewat,
    deposito.bln_dep::double precision - round(((sekarang() - deposito.awal_dep) / 30)::double precision) AS sisa_bln
   FROM hitung_komisi_deposito
     JOIN deposito USING (id_dep)
  WHERE deposito.active_dep AND deposito.tgl_komisi_dep IS NOT NULL
  ORDER BY deposito.awal_dep;

ALTER TABLE public.hitung_komisi_deposito_1
  OWNER TO postgres;

-- View: public.hitung_komisi_deposito_2

-- DROP VIEW public.hitung_komisi_deposito_2;

CREATE OR REPLACE VIEW public.hitung_komisi_deposito_2 AS 
 SELECT hitung_komisi_deposito_1.id_dep,
    hitung_komisi_deposito_1.amor_per_bln,
    hitung_komisi_deposito_1.amor_terakhir,
    hitung_komisi_deposito_1.awal_dep,
    hitung_komisi_deposito_1.maturity_dep,
    hitung_komisi_deposito_1.sekarang,
    hitung_komisi_deposito_1.bln_dep,
    hitung_komisi_deposito_1.bln_lewat,
    hitung_komisi_deposito_1.sisa_bln,
        CASE
            WHEN hitung_komisi_deposito_1.sisa_bln = 0::double precision THEN 0::double precision
            WHEN hitung_komisi_deposito_1.sisa_bln = 1::double precision THEN hitung_komisi_deposito_1.amor_terakhir::double precision
            WHEN hitung_komisi_deposito_1.sisa_bln > 1::double precision THEN hitung_komisi_deposito_1.amor_per_bln::double precision * (hitung_komisi_deposito_1.sisa_bln - 1::double precision) + hitung_komisi_deposito_1.amor_terakhir::double precision
            ELSE NULL::double precision
        END AS sisa_amor
   FROM hitung_komisi_deposito_1;

ALTER TABLE public.hitung_komisi_deposito_2
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
        sisa_amor_acc_deposito(deposito.id_dep, 'D'::bpchar) AS sisa_deposito,
        
         CASE
            WHEN deposito.maturity_dep = sekarang()  THEN deposito.nilaiskr - sisa_amor_acc_deposito(deposito.id_dep, 'D'::bpchar) 
            WHEN deposito.maturity_dep <> sekarang()  THEN deposito.nilaiskr -sisa_amor_acc_deposito(deposito.id_dep, 'D'::bpchar) 
             
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


  -- Function: public.ubah2dep()

-- DROP FUNCTION public.ubah2dep();

CREATE OR REPLACE FUNCTION public.ubah2dep()
  RETURNS trigger AS
$BODY$declare
  j record;
  a record;
  nas text;
  skr date;
  iddebet integer;
  iddebet2 integer;
  iddk integer;
  idae integer;
  jedbt integer;
  jekrd integer;
  idjr integer;
  no_coa integer;
  id_coa integer;
  id_coa2 integer;
  jr record;
  ket text;
  ref3 text;
  ref2 text;
  
begin
  skr := sekarang();
  idjr := 0;
  new.id_rek := old.id_rek;
  id_coa :=984; -- "BEBAN YG DITANGGUHKAN - KOMISI DEPOSITO           "
  id_coa2 :=1040; -- "KEWAJIBAN LAINNYA - KOMISI                        "
  ref3 := '160.01';  -- "BEBAN YG DITANGGUHKAN - KOMISI DEPOSITO           "
  ref2 := '250.12';  -- "KEWAJIBAN LAINNYA - KOMISI                        "
   


    if old.komisi_deposito is null and new.komisi_deposito is not null then
      select into j * from jenis_etap where id_je = 'D';

     
      select into jr * from transjr where id_jr = new.temp_idjr_dep; -- cari apakah transjr sudah ada
      if jr is null then
        insert into transjr (
            id_jr,id_com,entryop_jr,tglbuku_jr,ket_jr,
            posted_jr
            ) values (
            new.temp_idjr_dep,'1','System',skr,'Jurnal Komisi Deposito',
            skr
          );
      end if;

      if new.bln_dep > j.batas_je then
    ---- dari atas insert ke transj

        iddebet := nextval('jurnal_detil_id_djr_seq'); 
        iddebet2 := nextval('jurnal_detil_id_djr_seq'); 

  iddk := nextval('deposito_komisi_id_dk_seq');
        select into nas nama_nas from nasabah join reknas using (id_nas)  where id_rek = new.id_rek;
        ket = 'Komisi Deposito ' || nas || '/' ||new.bilyet_dep;

   insert into deposito_komisi
          (id_dk,id_dep,tgl_deposito_komisi,komisi_deposito,temp_idjr_dep,maturity_dep,buka_dep,awal_dep)
          values
          (iddk,old.id_dep,skr,new.komisi_deposito,new.temp_idjr_dep,old.maturity_dep,old.buka_dep,old.awal_dep); 

        insert into jurnal_detil
          (id_jr,tgl_djr,id_djr,id_coa,debet_djr, kredit_djr, posted_djr,ref,ket_djr)
          values
          (new.temp_idjr_dep,skr,iddebet,j.d_je,new.komisi_deposito,0,true,'250.12',ket); 
      
        insert into jurnal_detil
          (id_jr,tgl_djr,id_djr,id_coa,debet_djr, kredit_djr, posted_djr,ref,ket_djr)
          values
          (new.temp_idjr_dep,skr,iddebet2,j.k_je,0,new.komisi_deposito,true,'160.01',ket); 

        idae := nextval('amor_etap_id_ae_seq'); 
        insert into amor_etap
          (id_ae,id_je,id_dep,nilai_ae,reset,sisa_ae,tgl_dep_ae,id_dk)
          values
          (idae,'D',new.id_dep,new.komisi_deposito,false,new.komisi_deposito,skr,iddk);
        insert into trans_amor
          (id_ae,id_djr,debet_xa) values (idae,iddebet,new.komisi_deposito);
        update amor_etap set reset = true where id_dep = new.id_dep and id_je = 'D'; 
        update deposito set id_Dk = iddk where id_dep = old.id_dep;  
     else
        -- insert jurnal detil untuk komisi yang langsung di biayakan
        iddebet := nextval('jurnal_detil_id_djr_seq'); 
        iddebet2 := nextval('jurnal_detil_id_djr_seq'); 
        select into nas nama_nas from nasabah join reknas using (id_nas)  where id_rek = new.id_rek;
        ket = 'Komisi Deposito ' || nas || '/' ||new.bilyet_dep;

        insert into jurnal_detil
          (id_jr,tgl_djr,id_djr,id_coa,debet_djr, kredit_djr, posted_djr,ref,ket_djr)
          values
          (new.temp_idjr_dep,skr,iddebet,j.dkecil_je,new.komisi_deposito,0,true,'250.12',ket); 
      
        insert into jurnal_detil
          (id_jr,tgl_djr,id_djr,id_coa,debet_djr, kredit_djr, posted_djr,ref,ket_djr)
          values
          (new.temp_idjr_dep,skr,iddebet2,j.kkecil_je,0,new.komisi_deposito,true,'450.05',ket); 

        update deposito set id_Dk = iddk where id_dep = old.id_dep;  

     end if; -- new.bln_dep

  end if; -- old.komisi_deposito
  return new;
end; -- end of ubah2dep$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.ubah2dep()
  OWNER TO postgres;
COMMENT ON FUNCTION public.ubah2dep() IS 'after ubah deposito';



ALTER TABLE public.trans_deposito
  ADD COLUMN status_xdep text;
  

ALTER TABLE public.deposito_komisi
  ADD COLUMN status_dk text;


-- View: public.transsisabln_komisi

-- DROP VIEW public.transsisabln_komisi;

CREATE OR REPLACE VIEW public.transsisabln_komisi AS 
 SELECT deposito.id_dep,
    trans_deposito.id_xdep,
    deposito_komisi.id_dk,
    trans_deposito.tgl_xdep,
    deposito.awal_dep,
    deposito.bln_dep,
    (trans_deposito.tgl_xdep - deposito.awal_dep) / 30 AS sisabln_komisi
   FROM deposito
     JOIN trans_deposito USING (id_dep)
     JOIN deposito_komisi USING (id_dep)
  WHERE   deposito.active_dep
  ORDER BY ((trans_deposito.tgl_xdep - deposito.awal_dep) / 30);

ALTER TABLE public.transsisabln_komisi
  OWNER TO postgres;

-- View: public.trans_sisa_bln_kom

-- DROP VIEW public.trans_sisa_bln_kom;

CREATE OR REPLACE VIEW public.trans_sisa_bln_kom AS 
 SELECT transsisabln_komisi.id_dep,
    transsisabln_komisi.id_xdep,
    transsisabln_komisi.id_dk,
    transsisabln_komisi.tgl_xdep,
    transsisabln_komisi.awal_dep,
    transsisabln_komisi.bln_dep,
    transsisabln_komisi.sisabln_komisi,
        CASE
            WHEN transsisabln_komisi.sisabln_komisi = '-1'::integer THEN transsisabln_komisi.sisabln_komisi * '-1'::integer
            WHEN transsisabln_komisi.sisabln_komisi >= 1 THEN transsisabln_komisi.sisabln_komisi * 1
            WHEN transsisabln_komisi.sisabln_komisi = 0 THEN 0
            ELSE NULL::integer
        END AS sisa_bln_kom
   FROM transsisabln_komisi
  ORDER BY transsisabln_komisi.id_dep;

ALTER TABLE public.trans_sisa_bln_kom
  OWNER TO postgres;


 -- Column: mulai_bln_dk

-- ALTER TABLE public.deposito_komisi DROP COLUMN mulai_bln_dk;

ALTER TABLE public.deposito_komisi ADD COLUMN mulai_bln_dk integer;
-- View: public.trans_sisa_bln_kom

-- DROP VIEW public.trans_sisa_bln_kom;

CREATE OR REPLACE VIEW public.trans_sisa_bln_kom AS 
 SELECT transsisabln_komisi.id_dep,
    transsisabln_komisi.id_xdep,
    transsisabln_komisi.id_dk,
    transsisabln_komisi.tgl_xdep,
    transsisabln_komisi.awal_dep,
    transsisabln_komisi.bln_dep,
    transsisabln_komisi.sisabln_komisi,
        CASE
            WHEN transsisabln_komisi.sisabln_komisi = '-1'::integer THEN transsisabln_komisi.sisabln_komisi * '-1'::integer
            WHEN transsisabln_komisi.sisabln_komisi >= 1 THEN transsisabln_komisi.sisabln_komisi * 1
            WHEN transsisabln_komisi.sisabln_komisi = 0 THEN 0
            ELSE NULL::integer
        END AS sisa_bln_kom,
        CASE
            WHEN transsisabln_komisi.awal_dep <= '2020-12-31'::date AND date_part('month'::text, transsisabln_komisi.tgl_xdep) = 1::double precision THEN 'satu'::text
            ELSE NULL::text
        END AS bln_1
   FROM transsisabln_komisi
  ORDER BY transsisabln_komisi.id_dep;

ALTER TABLE public.trans_sisa_bln_kom
  OWNER TO postgres;


DROP VIEW public.komisi_deposito_daily_amor1;
 DROP VIEW public.komisi_deposito_daily_amor;
 DROP VIEW public.komisi_deposito_hit1;

 -- View: public.komisi_deposito_hit1

-- DROP VIEW public.komisi_deposito_hit1;

CREATE OR REPLACE VIEW public.komisi_deposito_hit1 AS 
 SELECT DISTINCT trans_deposito.id_sandi,
    bulan_amr_deposito(sekarang(), deposito_komisi.awal_dep, deposito.bln_dep::integer) AS sisabulan,
    round(deposito_komisi.komisi_deposito / deposito.bln_dep::numeric) AS amor,
    total_bln_deposito(trans_deposito.id_dep) AS tb,
    trans_deposito.id_xdep,
    trans_deposito.tgl_xdep,
    trans_deposito.ke_xdep,
    trans_deposito.status_xdep,
    deposito_komisi.id_dep,
    deposito_komisi.awal_dep,
    deposito_komisi.buka_dep,
    deposito_komisi.active_dep,
    deposito.bln_dep,
    deposito.bilyet_dep,
    deposito_komisi.tgl_deposito_komisi AS tgl_komisi_dep,
    deposito_komisi.komisi_deposito,
    deposito_komisi.maturity_dep,
    deposito_komisi.status_dk,
    deposito_komisi.mulai_bln_dk,
     trans_sisa_bln_kom.sisa_bln_kom::numeric,
    mod(deposito_komisi.komisi_deposito, bulan_amr_deposito(sekarang(), deposito_komisi.awal_dep, deposito.bln_dep::integer)::numeric) AS sisa_kom,
    deposito.komisi_deposito AS komisi_deposito_t
   FROM trans_deposito
     JOIN deposito USING (id_dep)
     JOIN deposito_komisi USING (id_Dk)
     JOIN trans_sisa_bln_kom USING (id_xdep)
  WHERE trans_deposito.tgl_xdep = sekarang() AND trans_deposito.id_sandi = '62'::bpchar AND (deposito_komisi.maturity_dep = sekarang() OR trans_deposito.id_sandi = '62'::bpchar AND trans_deposito.ke_xdep = deposito_komisi.bln_dep OR (deposito.active_dep = true OR deposito.active_dep = false AND sekarang() <= deposito.maturity_dep) AND deposito_komisi.buka_dep >= '2006-01-01'::date AND trans_deposito.id_sandi::text = 62::text) AND bulan_amr_deposito(sekarang(), deposito_komisi.awal_dep, deposito.bln_dep::integer) >= 1 AND bulan_amr_deposito(sekarang(), deposito_komisi.awal_dep, deposito.bln_dep::integer) <= deposito.bln_dep AND (trans_deposito.tgl_xdep = sekarang() OR trans_deposito.tgl_xdep <> sekarang())
  ORDER BY deposito.bilyet_dep;

ALTER TABLE public.komisi_deposito_hit1
  OWNER TO postgres;
COMMENT ON VIEW public.komisi_deposito_hit1
  IS 'perhitungan awal komisi marketing deposito';

-- View: public.komisi_deposito_daily_amor

-- DROP VIEW public.komisi_deposito_daily_amor;

CREATE OR REPLACE VIEW public.komisi_deposito_daily_amor AS 
  SELECT DISTINCT  
        CASE
           when komisi_deposito_hit1.maturity_dep = sekarang() then  sisa_amor_acc_deposito(komisi_deposito_hit1.id_dep, 'D'::bpchar)
           when komisi_deposito_hit1.maturity_dep <> sekarang() then amor_per_bln
        END AS amor_bulanini,
    komisi_deposito_hit1.id_sandi,
    komisi_deposito_hit1.sisabulan,
    komisi_deposito_hit1.amor,
    komisi_deposito_hit1.tb,
    komisi_deposito_hit1.id_xdep,
    komisi_deposito_hit1.tgl_xdep,
    komisi_deposito_hit1.ke_xdep,
    komisi_deposito_hit1.id_dep,
    komisi_deposito_hit1.bilyet_dep,
    komisi_deposito_hit1.awal_dep,
    komisi_deposito_hit1.buka_dep,
    komisi_deposito_hit1.active_dep,
    komisi_deposito_hit1.bln_dep,
    komisi_deposito_hit1.komisi_deposito,
    komisi_deposito_hit1.status_dk,
    komisi_deposito_hit1.tgl_komisi_dep
   FROM komisi_deposito_hit1
   join hitung_komisi_deposito using(id_Dep)
  WHERE  komisi_deposito_hit1.sisabulan >= 1 AND (komisi_deposito_hit1.tgl_xdep = sekarang() OR komisi_deposito_hit1.tgl_xdep <> sekarang())
  ORDER BY komisi_deposito_hit1.sisabulan;

ALTER TABLE public.komisi_deposito_daily_amor
  OWNER TO postgres;
COMMENT ON VIEW public.komisi_deposito_daily_amor
  IS 'Amortisasi harian untuk amor komisi deposito kedua dst';


-- View: public.komisi_deposito_daily_amor1

-- DROP VIEW public.komisi_deposito_daily_amor1;

CREATE OR REPLACE VIEW public.komisi_deposito_daily_amor1 AS 
 SELECT DISTINCT komisi_deposito_daily_amor.amor_bulanini,
    nasabah.nama_nas,
    komisi_deposito_daily_amor.bilyet_dep,
    komisi_deposito_daily_amor.id_dep,
    komisi_deposito_daily_amor.awal_dep,
    (komisi_deposito_daily_amor.awal_dep + '1 mon'::interval)::date AS awal_dep1,
    komisi_deposito_daily_amor.sisabulan,
    komisi_deposito_daily_amor.bln_dep,
    komisi_deposito_daily_amor.tgl_komisi_dep
   FROM komisi_deposito_daily_amor
     JOIN deposito USING (id_dep)
     JOIN deposito_komisi USING (id_dep)
     JOIN reknas USING (id_rek)
     JOIN nasabah USING (id_nas)
     JOIN amor3_age_deposito USING (id_dep)
  ORDER BY komisi_deposito_daily_amor.id_dep;

ALTER TABLE public.komisi_deposito_daily_amor1
  OWNER TO postgres; 
  -- View: public.perpanjangan_deposito

-- DROP VIEW public.perpanjangan_deposito;

CREATE OR REPLACE VIEW public.perpanjangan_deposito AS 
 SELECT komisi_deposito_daily_amor1.amor_bulanini,
    komisi_deposito_daily_amor1.tgl_komisi_dep,
    amor_etap.entry_date_ae,
    komisi_deposito_daily_amor1.nama_nas,
    komisi_deposito_daily_amor1.bilyet_dep,
    amor_etap.id_ae,
    komisi_deposito_daily_amor1.id_dep,
    hitung_komisi5.amor_terakhir
   FROM komisi_deposito_daily_amor1
     JOIN deposito USING (id_dep)
     JOIN komisi_deposito_hit1 USING (id_dep)
     JOIN hitung_komisi5 USING (id_dep)
     JOIN amor_etap USING (id_dk)
  WHERE deposito.active_dep AND deposito.tgl_komisi_dep IS NOT NULL AND deposito.maturity_dep = sekarang();

ALTER TABLE public.perpanjangan_deposito
  OWNER TO postgres;
 


-- View: public.perpanjangan_deposito_1

-- DROP VIEW public.perpanjangan_deposito_1;

CREATE OR REPLACE VIEW public.perpanjangan_deposito_1 AS 
 SELECT perpanjangan_deposito.amor_bulanini,
    perpanjangan_deposito.tgl_komisi_dep,
    perpanjangan_deposito.entry_date_ae,
    perpanjangan_deposito.nama_nas,
    perpanjangan_deposito.bilyet_dep,
    perpanjangan_deposito.id_ae,
    perpanjangan_deposito.id_dep,
    sisa_amor_acc_deposito(deposito.id_dep, 'D'::bpchar) AS amor_terakhir
   FROM perpanjangan_deposito
     JOIN deposito USING (id_dep)
  ORDER BY perpanjangan_deposito.id_dep;

ALTER TABLE public.perpanjangan_deposito_1
  OWNER TO postgres;

-- Function: public.ubah_dep()

-- DROP FUNCTION public.ubah_dep();

CREATE OR REPLACE FUNCTION public.ubah_dep()
  RETURNS trigger AS
$BODY$declare 

  sisa record;

  b numeric(7,4);

  batas numeric(15,2);

  acr numeric(15,2);

  xid int4;
 
  xjr int4;
  xjr1 int4;
  abc text;

  p record;

  d numeric(15,0);

  k numeric(15,0);

  kode text;

  aw date;

  cu date;

  bu numeric(15,2);

  nama text;
  skr date; 
begin
  skr := sekarang();
  select into nama nama_nas from nasabah join reknas using(id_nas) 

                                         join deposito using(id_rek) 

          where id_dep = new.id_dep;

-- perpanjangan deposito biasa

   select into batas bataspajakdep from company where id_com='1';

  if new.jenis_dep = 'K' and old.awal_dep <> new.awal_dep then

--    new.nilaibunga_dep := new.nilaiskr*new.bunga_dep/1200 * new.bln_dep;

--    new.bngperbulan := new.nilaiskr*new.bunga_dep/1200;

  -- generate perpanjangan di trans dep

--    new.ke_dep := new.ke_dep+1;

--    new.maturity_dep := new.awal_dep + (new.bln_dep::text||' mon')::interval;

    select into xid nextval('public.trans_deposito_id_xdep_seq');

    INSERT INTO trans_deposito 

     (id_dep, id_sandi,tgl_xdep,proses_xdep,del_xdep,

      bkt_xdep, nilai_xdep, bunga_xdep, id_bng,

      nilaibunga_xdep, trfbngke_xdep, maturity_xdep,

      tglvaluta_xdep, ket_xdep,ke_xdep, bln_xdep, 

      bngperbulan_xdep, id_xdep

     )    

   VALUES 

     (new.id_dep,'64',new.awal_dep,true,false,

      'D '||kanan(6::int2,new.bilyet_dep), new.nilaiskr,new.bunga_dep, new.id_bng,

      new.nilaiskr, new.trfbngke_dep, new.maturity_dep,

      new.tglvaluta_dep, 'Penempatan ke '||new.ke_dep::text, new.ke_dep-1, new.bln_dep, 

      new.bngperbulan, xid

     );

  -- generate bunga di transdep

    b := 0;

    if new.nilaiskr > batas then

      select into b pajakdep from company where id_com='1';

    end if;

    aw := sekarang();

    cu := aw;

--    acr := round(lastday(sekarang())::float*new.bngperbulan/extract(day from akhirbulan(sekarang())));

    for i in 1 .. new.bln_dep loop

      cu := cu + '1 mon'::interval;

      bu := (cu - aw)*new.bunga_dep*new.nilaiskr/36500;

      acr := round(lastday(cu)::float*bu/extract(day from akhirbulan(cu)));

--      INSERT INTO trans_deposito /*accrue*/

--       (id_dep, id_sandi,tgl_xdep, proses_xdep, del_xdep,

--        bkt_xdep, nilai_xdep, bunga_xdep,

--        id_bng,trfbngke_xdep, pajak_xdep,

--        ket_xdep,ke_xdep, nilaibunga_xdep

--       )    

--      VALUES 

--      (new.id_dep,'67',akhirbulan((new.awal_dep+((i-1)::text||' mon')::interval)::date),false,false,

--       'D '||kanan(6::int2,new.bilyet_dep), acr, new.bunga_dep,

--       new.id_bng, new.trfbngke_dep, acr*b/100,

--      'Accrue Bunga Deposito', i, bu

--      );

      INSERT INTO trans_deposito /*bunga */

       (id_dep, id_sandi,tgl_xdep, proses_xdep, del_xdep,

        nilai_xdep, bunga_xdep,

        id_bng,trfbngke_xdep, pajak_xdep,

        ket_xdep,ke_xdep

       )    

      VALUES 

      (new.id_dep,'62',new.awal_dep+(i::text||' mon')::interval,false,false,

       bu-acr, new.bunga_dep,

       new.id_bng, new.trfbngke_dep, (bu-acr)*b/100,

      'Bunga Deposito', i

      );

      aw := aw + '1 mon'::interval;

    end loop;

-- transaksi keuangan perpanjangan deposito

    kode:='64';

    select into xjr nextval('public.transjr_id_jr_seq');

    insert into transjr

      (id_com,tglbuku_jr,ket_jr,bukti_jr,

       asal_jr,kegiatan_id,acc_jr,id_jr

      )

     values

     ('1',sekarang()::date,'Perpanjangan Deposito '||new.bilyet_dep::text ||'   ' , 'D '||kanan(6::int2,new.bilyet_dep),

       'D',xid,true,xjr
 

      );
       
     

       
 
   if old.tgl_komisi_Dep is not null then 
      select into sisa    amor_bulanini, tgl_komisi_dep, entry_date_ae, nama_nas, bilyet_dep,
     id_ae, id_dep,amor_terakhir
   from perpanjangan_deposito_1
   where id_dep = new.id_dep ;
 
 
    select into xjr1 nextval('public.transjr_id_jr_seq');
       abc := no_ledger('77');

       insert into transjr

      (id_com,tglbuku_jr,ket_jr,bukti_jr, asal_jr,kegiatan_id,acc_jr,id_jr)

     values ('1',sekarang()::date,'Amortisasi Deposito ' ||  sisa.nama_nas || '/' || sisa.bilyet_dep::text || '   '  , abc,'D',xid,true,xjr1);

      
            insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
            values (xjr1,skr,1036,sisa.amor_terakhir,0,'System',true,'Amortisasi Deposito ' || 
            sisa.nama_nas || '/' || sisa.bilyet_dep ); 

            insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
            values (xjr1,skr,984,0,sisa.amor_terakhir,'System',true,'Amortisasi Deposito ' || 
            sisa.nama_nas || '/' || sisa.bilyet_dep ); 
        
end if; 

     FOR p IN select id_coa,tab_prs,dk_prs,field_prs,ref_prs from proses where id_sandi = kode order by dk_prs LOOP

        k :=0;

        d :=0;

        if p.dk_prs = 'K' then

          k:= hitisi('D'::text,xid::int4,1::int2);

        else

          d:= hitisi('D'::text,xid::int4,1::int2);

        end if;

        insert into jurnal_detil

         (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,ket_djr,posted_djr,ref

         )

         values

         (xjr,sekarang(),p.id_coa,d,k,'Perpanjangan '||new.bln_dep::text||' Bln/ '||nama,true,p.ref_prs

         );

     END LOOP;

-- selesai transaksi keuangan perpanjangan deposito

  end if;

-- perpanjangan aro, awal_dep (saja) diubah oleh tutup hari secara otomatis

  if new.jenis_dep = 'A' and old.awal_dep <> new.awal_dep then

   if new.bln_dep > 1 then

      raise exception 'Untuk ARO jangka waktu harus 1 Bln';

    end if;

  -- ubah data di dep

    b := 0;

    if new.nilaiskr > batas then

      select into b pajakdep from company where id_com='1';

    end if;

--**    new.nilaiskr := old.nilaiskr+old.nilaibunga_dep*(1-b/100); /* dikurangi pajak */

--**    new.maturity_dep := new.awal_dep + (new.bln_dep::text||' mon')::interval;

--**    b:=bungadepo(old.nilaiskr,old.bln_dep);

 --   select into b bngdepo1_com from company where id_com='1';

--**    new.bunga_dep := b;

--**    new.nilaibunga_dep := round(new.nilaiskr*new.bunga_dep/1200*new.bln_dep);

--**    new.bngperbulan := round(new.nilaiskr*new.bunga_dep/1200);

--**    new.tglvaluta_dep := new.awal_dep;

--    new.ke_dep := new.ke_dep +1;

  -- generate transaksi penutupan di transdep (historis) --> tidak perlu 20 nov 06

--*    kode='66';

--*    select into xid nextval('public.trans_deposito_id_xdep_seq');

--*    INSERT INTO trans_deposito 

--*     (id_dep, id_sandi,tgl_xdep,proses_xdep,del_xdep,

--*      bkt_xdep, nilai_xdep,

--*      tglvaluta_xdep, ket_xdep,ke_xdep,

--*      id_xdep

--*     )    

--*   VALUES 

--*     (new.id_dep,kode,new.awal_dep,true,false,

--*      no_bukti(kode), old.nilaiskr,

--*      new.tglvaluta_dep, 'Jatuh Tempo ', new.ke_dep-1, 

--*      xid

--*     );

  -- transaksi keuangan tutup aro

--*    kode:='66';

--*    select into xjr nextval('public.transjr_id_jr_seq');

--*    insert into transjr

--*      (id_com,tglbuku_jr,ket_jr,bukti_jr,

--*       asal_jr,kegiatan_id,acc_jr,id_jr

--*      )

--*     values

--*      ('1',sekarang()::date,'Penutupan untuk perpanjangan ARO Bilyet : '||new.bilyet_dep, no_ledger(kode),

--*       'D',xid,true,xjr

--*      );

 --*    FOR p IN select id_coa,tab_prs,dk_prs,field_prs from proses where id_sandi = kode order by dk_prs LOOP

--*        k :=0;

--*        d :=0;

--*        if p.dk_prs = 'K' then

--*          k:= hitisi('D'::text,xid::int4,1::int2);

--*        else

--*          d:= hitisi('D'::text,xid::int4,1::int2);

--*        end if;

--*        insert into jurnal_detil

--*         (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr

--*         )

--*         values

--*         (xjr,sekarang(),p.id_coa,d,k

--*         );

--*     END LOOP;

  -- generate transaksi perpanjangan di transdep (historis)

    kode ='68';

    select into xid nextval('public.trans_deposito_id_xdep_seq');

    INSERT INTO trans_deposito 

     (id_dep, id_sandi,tgl_xdep,proses_xdep,del_xdep,

      bkt_xdep, nilai_xdep, bunga_xdep, id_bng,

      nilaibunga_xdep, trfbngke_xdep, maturity_xdep,

      tglvaluta_xdep, ket_xdep,ke_xdep, bln_xdep, 

      bngperbulan_xdep, id_xdep

     )    

   VALUES 

     (new.id_dep,kode,new.awal_dep,true,false,

      no_bukti(kode), new.nilaiskr,new.bunga_dep, new.id_bng,

      new.nilaiskr, new.trfbngke_dep, new.maturity_dep,

      new.tglvaluta_dep, 'Perpanjangan ARO ke '||new.ke_dep::text, new.ke_dep-1, new.bln_dep, 

      new.bngperbulan, xid

     );

  -- transaksi keuangan perpanjangan aro

    kode:='68';

    select into xjr nextval('public.transjr_id_jr_seq');

    insert into transjr

      (id_com,tglbuku_jr,ket_jr,bukti_jr,

      asal_jr,kegiatan_id,acc_jr,id_jr

      )

     values

      ('1',sekarang()::date,'Perpanjangan Deposito Bilyet : '||kanan(6::int2,new.bilyet_dep), 

       'D '||kanan(6::int2,new.bilyet_dep),

       'D',xid,true,xjr

      );

     FOR p IN select id_coa,tab_prs,dk_prs,field_prs,ref_prs from proses where id_sandi = kode order by urut_prs LOOP

        k :=0;

        d :=0;

        if p.dk_prs = 'K' then

          if p.field_prs = 5 then /* keadaan khusus untuk perpanjangan aro, perlu data dari

                                 bunga yang lalu, karena akan digabungkan dengan saldo lama

                                 menjadi saldo baru ( nilaiskr) */

--            k:= old.nilaibunga_dep*(1-b/100); /* dikurangi bunga */

            k:= new.nilaiskr - old.nilaiskr; /* net setelah dikurangi pajak */

          elsif p.field_prs = 6 then /*saldo lalu*/

            k:= old.nilaiskr;

          elsif p.field_prs = 7 then /* Bunga+Saldo Lalu*/

            k:= new.nilaiskr ;

--            k:= old.nilaiskr + old.nilaibunga_dep*(1-b/100);

          else

            k:= hitisi('D'::text,xid::int4,p.field_prs::int2);

          end if;

        else

          if p.field_prs = 5 then /* keadaan khusus untuk perpanjangan aro, perlu data dari

                                 bunga yang lalu, karena akan digabungkan dengan saldo lama

                                 menjadi saldo baru ( nilaiskr) */

--            d:= old.nilaibunga_dep*(1-b/100);

            d:= new.nilaiskr - old.nilaiskr;

          elsif p.field_prs = 6 then /*saldo lalu*/

            d:= old.nilaiskr;

          elsif p.field_prs = 7 then /* Bunga+Saldo Lalu*/

            d:= new.nilaiskr ;

--            d:= old.nilaiskr + old.nilaibunga_dep*(1-b/100);

          else

            d:= hitisi('D'::text,xid::int4,p.field_prs::int2);

          end if;

        end if;

        insert into jurnal_detil

         (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,ket_djr,posted_djr,ref

         )

         values

         (xjr,sekarang(),p.id_coa,d,k,'Perpanjangan (A) 1 Bln/ '||nama,true,p.ref_prs

         );

     END LOOP;

  -- generate 1 bunga di transdep

    acr := round(lastday(sekarang())::float/extract(day from akhirbulan(sekarang()))*new.bngperbulan);

    for i in 1 .. new.bln_dep loop

--      INSERT INTO trans_deposito /* accrue */

--       (id_dep, id_sandi,tgl_xdep, proses_xdep, del_xdep,

--        bkt_xdep, nilai_xdep, bunga_xdep,

--        id_bng,trfbngke_xdep, pajak_xdep,

--        ket_xdep,ke_xdep,nilaibunga_xdep

--       )    

--      VALUES 

--      (new.id_dep,'67',akhirbulan((new.awal_dep+((i-1)::text||' mon')::interval)::date),false,false,

--       no_bukti('67'), acr, new.bunga_dep,

--       new.id_bng, new.trfbngke_dep, acr*b/100,

--      'Bunga Deposito ARO', i, new.bngperbulan

--      );

      INSERT INTO trans_deposito /*bunga */

       (id_dep, id_sandi,tgl_xdep, proses_xdep, del_xdep,

        nilai_xdep, bunga_xdep,

        id_bng,trfbngke_xdep, 

        ket_xdep,ke_xdep

       )    

     VALUES 

      (new.id_dep,'65',new.awal_dep+(i::text||' mon')::interval,false,false,

       new.bngperbulan-acr, new.bunga_dep,

       new.id_bng, new.trfbngke_dep, 

      'Bunga Deposito ARO', i

      );

/*

      INSERT INTO trans_deposito

       (id_dep, id_sandi,tgl_xdep, proses_xdep, del_xdep,

        bkt_xdep, nilai_xdep, bunga_xdep,

        id_bng,trfbngke_xdep, pajak_xdep,

        ket_xdep,ke_xdep

       )    

      VALUES 

      (new.id_dep,'65',new.awal_dep+(i::text||' mon')::interval,false,false,

       no_bukti('DA'), new.bngperbulan, new.bunga_dep,

       new.id_bng, new.trfbngke_dep, new.bngperbulan*b/100,

      'Bunga Deposito ARO', i

      );

*/

    end loop;

  end if;

-- penutupan hanya untuk penutupan aro karena aro sebenarnya  ditutup dan diperpanjang

-- dengan nilai yang baru.

-- aro ditutup dengan cara active_dep -> false. maka tutup hari tidak akan mengubah

-- awal_dep baru. jadi aro tidak diperpanjang lagi. Ini transaksi masa depan untuk 

-- penutupannya (pada maturit date).

-- yang diatas tidak berlaku lagi, jadi ini adalah transaksi jika terjadi perubahan active dari true ke false untuk

-- semua deposito

--  if new.jenis_dep = 'A' and new.active_dep = false and old.active_dep = true then

  if new.active_dep = false and old.active_dep = true then

     update trans_deposito set del_xdep = true where id_dep = new.id_dep and tgl_xdep >= sekarang();

--    kode = '66';

--    INSERT INTO trans_deposito

--     (id_dep, id_sandi,tgl_xdep,proses_xdep,del_xdep,

--      bkt_xdep, ket_xdep,ke_xdep, nilai_xdep

--     )    

--    VALUES 

--     (new.id_dep,kode,new.maturity_dep,false,false,

--      no_bukti(kode), 'Pencairan Deposito', new.ke_dep, new.nilaiskr+new.bngperbulan

--     );

  end if;

  update reknas set sldtab_rek = new.nilaiskr where id_rek = new.id_rek;

  if old.active_dep = true and new.active_dep = false then

    new.tglbreak_dep = now(); 

  end if;
  if old.komisi_deposito is null and new.komisi_deposito is not null then
    new.tgl_komisi_dep := skr;
  end if;
  return new;

end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.ubah_dep()
  OWNER TO bprdba;
COMMENT ON FUNCTION public.ubah_dep() IS 'untuk ubah deposiso (perpanjangan dan penutupan ARO)';


-- View: public.amor_dep_ae

-- DROP VIEW public.amor_dep_ae;

CREATE OR REPLACE VIEW public.amor_dep_ae AS 
 SELECT amor_etap.id_ae,
    amor_etap.id_je,
    amor_etap.id_krd,
    amor_etap.id_dep,
    amor_etap.tgl_ae,
    amor_etap.nilai_ae,
    amor_etap.amor_ae,
    amor_etap.sisa_ae,
    amor_etap.id_jr,
    amor_etap.entry_date_ae,
    amor_etap.reset,
    date(amor_etap.entry_date_ae) AS tgl_dep_ae,
    deposito_komisi.tgl_deposito_komisi,
    deposito_komisi.id_dk
   FROM amor_etap
     JOIN deposito_komisi USING (id_dep)
  WHERE amor_etap.id_dep IS NOT NULL and date(amor_etap.entry_date_ae) =  deposito_komisi.tgl_deposito_komisi;

ALTER TABLE public.amor_dep_ae
  OWNER TO postgres;
   
  
-- View: public.tgl_komisi_depo

-- DROP VIEW public.tgl_komisi_depo;

CREATE OR REPLACE VIEW public.tgl_komisi_depo AS 
 SELECT amor_etap.id_ae,
    amor_etap.id_dep,
    to_date(to_char(amor_etap.entry_date_ae, 'YYYY/MM/DD'::text), 'YYYY/MM/DD'::text) AS tgl_komisi_depo
   FROM amor_etap
     JOIN deposito USING (id_dep)
  WHERE amor_etap.id_dep IS NOT NULL
  ORDER BY amor_etap.entry_date_ae;

ALTER TABLE public.tgl_komisi_depo
  OWNER TO postgres;


-- Function: public.tanggal_amor()

-- DROP FUNCTION public.tanggal_amor();

CREATE OR REPLACE FUNCTION public.tanggal_amor()
  RETURNS integer AS
$BODY$declare
 
  acr record;
  acr_des record;
  acr_trans record;
  acr_jan record;
  acr_trans_sisa_bln_kom record;
  je record; 
  skr date; 
  idae int4;

begin 
 
  select into je * from jenis_etap where id_je = 'D';
    for acr in select id_ae,id_Dep,tgl_komisi_depo  from tgl_komisi_depo
  
  loop  
    update amor_etap set  tgl_dep_ae = acr.tgl_komisi_depo where id_ae =acr.id_ae;
  end loop;

for acr_des in select  id_Dk,awal_Dep,status_dk
     from deposito_komisi    
where awal_Dep <= '2020-12-31'
 
 order by  id_Dk 
  loop  
    update deposito_komisi set  status_dk = 'Desember Ke Bawah' where   id_Dk =acr_des.id_Dk;
  end loop;

  for acr_jan in select  id_Dk,awal_Dep,status_dk
     from deposito_komisi    
where awal_Dep >= '2021-01-01'
 
 order by  id_Dk 
  loop  
    update deposito_komisi set  status_dk = 'Januari Ke Atas' where   id_Dk =acr_jan.id_Dk;
  end loop;

  
  for acr_trans in select id_xdep, status_xdep
  from deposito
    join trans_Deposito using(id_Dep)
    join deposito_komisi using(id_Dep)
    WHERE tgl_xdep >= '2021-1-1' and  status_dk = 'Desember Ke Bawah' 
    order by id_xdep
  loop  
    update trans_Deposito set  status_xdep = 'Januari' where   id_xdep =acr_trans.id_xdep;
  end loop;
  
  for acr_trans_sisa_bln_kom in select   id_dk,sisa_bln_kom 
 From trans_sisa_bln_kom 
where bln_1 = 'satu' and sisa_bln_kom is not null 

loop
  update deposito_komisi set mulai_bln_dk = acr_trans_sisa_bln_kom.sisa_bln_kom  where id_dk = acr_trans_sisa_bln_kom.id_Dk;
end loop;
  return 1;

end; -- end of tanggal_amor()

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.tanggal_amor()
  OWNER TO postgres;


CREATE OR REPLACE VIEW public.deposito_id_dk_null AS 
select id_ae,deposito.id_dk,
case
  when tgl_komisi_Dep = tgl_dep_ae then deposito.id_dk
   when tgl_komisi_Dep <> tgl_dep_ae then null
end as amor_id_dk
from amor_etap  
      join deposito using (id_dep) ;
-- View: public.id_dk_id_dep_id_ae

-- DROP VIEW public.id_dk_id_dep_id_ae;

CREATE OR REPLACE VIEW public.id_dk_id_dep_id_ae AS 
 SELECT DISTINCT deposito_komisi.id_dk,
    deposito_komisi.id_dep,
    amor_etap.id_ae,
    deposito.awal_dep
   FROM deposito_komisi
     JOIN deposito USING (id_dep)
     JOIN amor_etap USING (id_dep)
  WHERE deposito.tgl_komisi_dep IS NOT NULL AND deposito.active_dep AND deposito.tgl_komisi_dep = amor_etap.tgl_dep_ae AND deposito.awal_dep = deposito_komisi.awal_dep
  ORDER BY deposito_komisi.id_dep;

ALTER TABLE public.id_dk_id_dep_id_ae
  OWNER TO postgres;

-- Function: public.amor_id_dk()

-- DROP FUNCTION public.amor_id_dk();

CREATE OR REPLACE FUNCTION public.amor_id_dk()
  RETURNS integer AS
$BODY$declare
 
  acr record;
acr1  record;
acr2 record;
  je record; 
  skr date; 
  idae int4;

begin 
 
  select into je * from jenis_etap where id_je = 'D';
 
 for acr1 in select id_djr1,id_Djr from update_id_djr
    loop  
      update trans_amor set  id_Djr = acr1.id_djr1  where id_Djr = acr1.id_Djr; 
 end loop;

  for acr1 in select id_Dk,id_Dep, id_ae
  from id_dk_id_dep_id_ae
  loop  
    update amor_etap set  id_dk = acr1.id_Dk  where id_ae = acr1.id_ae; 
    update deposito set  id_dk = acr1.id_Dk  where id_Dep = acr1.id_Dep; 
  end loop;
 
  for acr2 in select  deposito_komisi.id_Dk, deposito.id_Dep,id_ae,tgl_komisi_dep
  from deposito 
    join deposito_komisi using(id_Dep)
    join amor_etap using(id_Dep)
    where tgl_komisi_dep is not null and deposito.id_dk is null 
    and deposito.active_Dep and nilai_ae = deposito.komisi_deposito
  loop  
    update amor_etap set  id_dk = acr2.id_Dk  where id_ae = acr2.id_ae; 
    update amor_etap set  tgl_dep_ae = acr2.tgl_komisi_dep  where id_ae = acr2.id_ae; 
    update deposito set  id_dk = acr2.id_Dk  where id_Dep = acr2.id_Dep; 
  end loop;
 
  return 1;

end; -- end of amor_id_dk()

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.amor_id_dk()
  OWNER TO postgres;


 DROP VIEW public.perhitungan_sisa_amor_final;
DROP VIEW public.perhitungan_sisa_deposito;
 
   

-- View: public.hitung_komisi_deposito_4

-- DROP VIEW public.hitung_komisi_deposito_4;

CREATE OR REPLACE VIEW public.hitung_komisi_deposito_4 AS 
 SELECT deposito.id_dk,
    deposito.id_dep,
    deposito.komisi_deposito,
    amor_etap.id_je
   FROM trans_amor
     JOIN amor_etap USING (id_ae)
     JOIN deposito USING (id_dk)
  WHERE deposito.tgl_komisi_dep IS NOT NULL AND deposito.active_dep   AND NOT deposito.gantung_dep
  GROUP BY deposito.id_dk, deposito.id_dep, amor_etap.id_je
  ORDER BY (deposito.komisi_deposito - sum(trans_amor.kredit_xa));

ALTER TABLE public.hitung_komisi_deposito_4
  OWNER TO postgres;



-- View: public.hitung_komisi_deposito_5

-- DROP VIEW public.hitung_komisi_deposito_5;

CREATE OR REPLACE VIEW public.hitung_komisi_deposito_5 AS 
 SELECT deposito.id_dep,
    trans_amor.id_ae,
    amor_etap.id_je,
    deposito.komisi_deposito,
    sum(trans_amor.kredit_xa) AS sum_kredit_xa
   FROM trans_amor
     JOIN amor_etap USING (id_ae)
     JOIN deposito USING (id_dk)
     JOIN jurnal_detil USING (id_djr)
  WHERE deposito.tgl_komisi_dep IS NOT NULL AND deposito.active_dep   AND NOT deposito.gantung_dep AND deposito.awal_dep < jurnal_detil.tgl_djr AND trans_amor.kredit_xa < deposito.komisi_deposito
  GROUP BY deposito.id_dep, trans_amor.id_ae, amor_etap.id_je
  ORDER BY (sum(trans_amor.kredit_xa));

ALTER TABLE public.hitung_komisi_deposito_5
  OWNER TO postgres;


-- View: public.hitung_komisi_deposito_6

-- DROP VIEW public.hitung_komisi_deposito_6;

CREATE OR REPLACE VIEW public.hitung_komisi_deposito_6 AS 
 SELECT hitung_komisi_deposito_4.id_dep,
    hitung_komisi_deposito_4.komisi_deposito AS debet,
    hitung_komisi_deposito_5.id_je,
        CASE
            WHEN hitung_komisi_deposito_5.sum_kredit_xa IS NULL THEN 0::numeric
            WHEN hitung_komisi_deposito_5.sum_kredit_xa IS NOT NULL THEN hitung_komisi_deposito_5.sum_kredit_xa
            ELSE NULL::numeric
        END AS kredit
   FROM hitung_komisi_deposito_4
     LEFT JOIN hitung_komisi_deposito_5 USING (id_dep);

ALTER TABLE public.hitung_komisi_deposito_6
  OWNER TO postgres;


-- View: public.hitung_komisi_deposito_7

-- DROP VIEW public.hitung_komisi_deposito_7;

CREATE OR REPLACE VIEW public.hitung_komisi_deposito_7 AS 
 SELECT hitung_komisi_deposito_6.id_dep,
  hitung_komisi_deposito_6.id_je,
    hitung_komisi_deposito_6.debet,
    hitung_komisi_deposito_6.kredit,
    hitung_komisi_deposito_6.debet - hitung_komisi_deposito_6.kredit AS sisa
   FROM hitung_komisi_deposito_6
  ORDER BY hitung_komisi_deposito_6.kredit;

ALTER TABLE public.hitung_komisi_deposito_7
  OWNER TO postgres;
 

-- View: public.perhitungan_sisa_deposito

-- DROP VIEW public.perhitungan_sisa_deposito;

CREATE OR REPLACE VIEW public.perhitungan_sisa_deposito AS 
 SELECT sum(hitung_komisi_deposito_7.sisa) AS komisi_dep
   FROM hitung_komisi_deposito_7;

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





insert into deposito_komisi (id_dk,id_dep,tgl_deposito_komisi,komisi_deposito,temp_idjr_dep,maturity_dep,buka_dep,awal_dep,bln_dep)
values (114,19661,'2021-02-01',1667,861982,'2021-05-01','2021-02-01','2019-11-01',3);

 
 

CREATE OR REPLACE VIEW public.update_id_djr AS 
select deposito_komisi.id_dk,id_ae,id_xa,debet_xa,kredit_xa ,trans_amor.id_Djr, trans_amor.id_Djr+1 as id_Djr1 ,debet_djr,kredit_djr,jurnal_detil.id_jr,ket_Djr
  from deposito_komisi
  join amor_etap using(id_dep)
  join trans_amor using(id_ae)
  join jurnal_detil using(id_djr);

 -- Function: public.sisa_amor_acc_deposito(integer, character)

-- DROP FUNCTION public.sisa_amor_acc_deposito(integer, character);

CREATE OR REPLACE FUNCTION public.sisa_amor_acc_deposito(
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
    select  into hasil 
    distinct  sisa
       from sisa_komisi_order5_amor_full_sisa 
       join deposito using(id_dk)
        where  deposito.active_Dep and tgl_komisi_Dep is not null and  deposito.id_dep = dep and id_je=jenis and deposito.maturity_dep = sisa_komisi_order5_amor_full_sisa.maturity_dep ;
   end if;
  return nonul(hasil);
end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.sisa_amor_acc_deposito(integer, character)
  OWNER TO postgres;
COMMENT ON FUNCTION public.sisa_amor_acc_deposito(integer, character) IS 'Menghasilkan sisa amor untuk id_dep, id_je yang dimasukan.';

  -- View: public.trans_amor_sisa_dep

-- DROP VIEW public.trans_amor_sisa_dep;

CREATE OR REPLACE VIEW public.trans_amor_sisa_dep AS 
 SELECT distinct amor_etap.id_Dep,
    amor_etap.id_je,
    sisa_amor_acc_deposito(amor_etap.id_Dep, amor_etap.id_je::bpchar) AS sisa_Dep
   FROM amor_etap
     JOIN deposito USING (id_Dep)
 
order by id_Dep;

ALTER TABLE public.trans_amor_sisa_dep
  OWNER TO postgres;



-- View: public.hitung_komisi_deposito_break

-- DROP VIEW public.hitung_komisi_deposito_break;

CREATE OR REPLACE VIEW public.hitung_komisi_deposito_break AS 
 SELECT deposito.id_dep,
    amor_etap.id_je,
    trans_amor.id_ae  ,
      sum(trans_amor.debet_xa) AS sum_debet_xa,
 sum(trans_amor.kredit_xa) AS sum_kredit_xa
   FROM trans_amor
     JOIN amor_etap USING (id_ae)
     JOIN deposito USING (id_Dep)
     JOIN hitung_komisi_deposito USING (id_Dep)
  WHERE amor_etap.id_je::text = 'D'::text AND amor_etap.id_dk IS NOT NULL AND trans_amor.kredit_xa IS NOT NULL AND 
(trans_amor.kredit_xa = hitung_komisi_deposito.amor_per_bln OR trans_amor.kredit_xa = hitung_komisi_deposito.amor_terakhir 
OR hitung_komisi_deposito.nilai_amor = trans_amor.debet_xa OR deposito.komisi_deposito = trans_amor.debet_xa)
 
  GROUP BY deposito.id_dep, amor_etap.id_je, trans_amor.id_ae, trans_amor.debet_xa, trans_amor.kredit_xa;

ALTER TABLE public.hitung_komisi_deposito_break
  OWNER TO postgres;


-- View: public.hitung_komisi_deposito_break_1

-- DROP VIEW public.hitung_komisi_deposito_break_1;

CREATE OR REPLACE VIEW public.hitung_komisi_deposito_break_1 AS 
 SELECT hitung_komisi_deposito_break.id_dep,
    hitung_komisi_deposito_break.id_je,
    hitung_komisi_deposito_break.id_ae,
    sum(hitung_komisi_deposito_break.sum_debet_xa) AS sum_debet_xa
   FROM hitung_komisi_deposito_break
  GROUP BY hitung_komisi_deposito_break.id_dep, hitung_komisi_deposito_break.id_je, hitung_komisi_deposito_break.id_ae;

ALTER TABLE public.hitung_komisi_deposito_break_1
  OWNER TO postgres;


-- View: public.hitung_komisi_deposito_break_2

-- DROP VIEW public.hitung_komisi_deposito_break_2;

CREATE OR REPLACE VIEW public.hitung_komisi_deposito_break_2 AS 
 SELECT hitung_komisi_deposito_break.id_dep,
    hitung_komisi_deposito_break.id_je,
    hitung_komisi_deposito_break.id_ae,
    hitung_komisi_deposito_break_1.sum_debet_xa,
    hitung_komisi_deposito_break.sum_kredit_xa
   FROM hitung_komisi_deposito_break
     JOIN hitung_komisi_deposito_break_1 USING (id_dep)
  WHERE hitung_komisi_deposito_break.sum_kredit_xa < hitung_komisi_deposito_break_1.sum_debet_xa;

ALTER TABLE public.hitung_komisi_deposito_break_2
  OWNER TO postgres;



  
-- View: public.break

-- DROP VIEW public.break;

CREATE OR REPLACE VIEW public.break AS 
 SELECT deposito.id_dk,
    deposito.id_dep,
    deposito.komisi_deposito AS sum_debet_xa,
    sum(trans_amor.kredit_xa) AS sum_kredit_xa,
    deposito.komisi_deposito - sum(trans_amor.kredit_xa) AS sisa,
    amor_etap.id_je
   FROM trans_amor
     JOIN amor_etap USING (id_ae)
     JOIN deposito USING (id_dk)
  WHERE amor_etap.id_je::text = 'D'::text AND amor_etap.id_dk IS NOT NULL AND trans_amor.kredit_xa IS NOT NULL
  GROUP BY deposito.id_dk, deposito.id_dep, amor_etap.id_je;

ALTER TABLE public.break
  OWNER TO postgres;
 
-- Function: public.sisa_amor_acc_deposito_break(integer, character)

-- DROP FUNCTION public.sisa_amor_acc_deposito_break(integer, character);

CREATE OR REPLACE FUNCTION public.sisa_amor_acc_deposito_break(
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
       sisa
      from sisa_komisi_order5_amor_full_sisa 
 
      where   sisa_komisi_order5_amor_full_sisa.id_dep = dep and sisa_komisi_order5_amor_full_sisa.id_je=jenis ;
 end if;
  return nonul(hasil);
end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.sisa_amor_acc_deposito_break(integer, character)
  OWNER TO postgres;
COMMENT ON FUNCTION public.sisa_amor_acc_deposito_break(integer, character) IS 'Menghasilkan sisa amor untuk id_dep, id_je yang dimasukan.';


DROP VIEW public.bilangdepo; 

-- View: public.bilangdepo

-- DROP VIEW public.bilangdepo;

CREATE OR REPLACE VIEW public.bilangdepo AS 
 SELECT sisa_amor_acc_deposito_break(deposito.id_dep, 'D'::bpchar) AS sisa_amor_acc_deposito,
    age(sekarang()::timestamp with time zone, deposito.awal_dep::timestamp with time zone) AS umur,
    date_part('year'::text, age(sekarang()::timestamp with time zone, deposito.awal_dep::timestamp with time zone))::integer AS tahun,
    date_part('month'::text, age(sekarang()::timestamp with time zone, deposito.awal_dep::timestamp with time zone))::integer AS bulan,
    date_part('days'::text, age(sekarang()::timestamp with time zone, deposito.awal_dep::timestamp with time zone))::integer AS sisa_hari,
    deposito.maturity_dep - deposito.awal_dep AS jml_hari,
    deposito.maturity_dep - deposito.awal_dep - date_part('days'::text, age(sekarang()::timestamp with time zone, deposito.awal_dep::timestamp with time zone))::integer AS hari_yg_dilwti,
    reknas.id_rek,
    reknas.jenis_rek,
    reknas.no_rek,
    nasabah.nama_nas,
    deposito.blocked_dep,
    deposito.active_dep,
    deposito.id_dep,
    deposito.nilaiskr,
    terbilang(deposito.nilaiskr::integer::numeric) AS terbilang,
    deposito.bilyet_dep,
    deposito.komisi_deposito,
    deposito.maturity_dep,
    company.penaltydep_com,
    round(deposito.nilaiskr * (100::numeric - company.penaltydep_com) / 100::numeric) AS nilaib,
    terbilang(round(deposito.nilaiskr * (100::numeric - company.penaltydep_com) / 100::numeric)) AS bilangb,
    round(deposito.nilaiskr - round(deposito.nilaiskr * (100::numeric - company.penaltydep_com) / 100::numeric)) AS b_pinalti,
    round(deposito.nilaiskr * deposito.bunga_dep / 100::numeric * date_part('days'::text, age(sekarang()::timestamp with time zone, deposito.awal_dep::timestamp with time zone))::integer::numeric / 365::numeric) AS beban_yg_msh_hrs_dibayar,
    round(deposito.nilaiskr * deposito.bunga_dep / 100::numeric * (deposito.maturity_dep - deposito.awal_dep - date_part('days'::text, age(sekarang()::timestamp with time zone, deposito.awal_dep::timestamp with time zone))::integer)::numeric / 365::numeric) AS by_bunga_deposito,
    round(deposito.nilaiskr * deposito.bunga_dep / 100::numeric * date_part('days'::text, age(sekarang()::timestamp with time zone, deposito.awal_dep::timestamp with time zone))::integer::numeric / 365::numeric + round(deposito.nilaiskr * deposito.bunga_dep / 100::numeric * (deposito.maturity_dep - deposito.awal_dep - date_part('days'::text, age(sekarang()::timestamp with time zone, deposito.awal_dep::timestamp with time zone))::integer)::numeric / 365::numeric)) * 0.8 AS budep,
    round(deposito.nilaiskr * deposito.bunga_dep / 100::numeric * date_part('days'::text, age(sekarang()::timestamp with time zone, deposito.awal_dep::timestamp with time zone))::integer::numeric / 365::numeric + round(deposito.nilaiskr * deposito.bunga_dep / 100::numeric * (deposito.maturity_dep - deposito.awal_dep - date_part('days'::text, age(sekarang()::timestamp with time zone, deposito.awal_dep::timestamp with time zone))::integer)::numeric / 365::numeric)) * 0.2 AS pajak_budep,
    sekarang() AS tgl_sekarang
   FROM deposito
     JOIN reknas USING (id_rek)
     JOIN nasabah USING (id_nas),
    company
  ORDER BY deposito.id_dep;

ALTER TABLE public.bilangdepo
  OWNER TO postgres;

-- Function: public.tambah_xdep()

-- DROP FUNCTION public.tambah_xdep();

CREATE OR REPLACE FUNCTION public.tambah_xdep()
  RETURNS trigger AS
$BODY$declare
 
  nojur int4;
  nojur1 int4;
  acr record;
  acr_sisa record;
  bilyet text;
  rk record;
  skr date;
  kt character(100);
  kode char(2); 
  bt text;
begin
  skr := sekarang(); 
    if new.id_sandi = '69' then /* pelunasan deposito */
      update deposito set active_dep = false , tgl_cair_dep = skr where id_dep = new.id_dep;
      select into rk * from deposito join reknas using (id_rek)
                                   join nasabah using (id_nas)
                                   join (select id_dep, max(tgl_xdep) as maxdate from trans_deposito
                                            where id_sandi = '69'  
                                           group by id_dep) as xdep
                                      using (id_dep)
                       where id_dep = new.id_dep;

      kt:=rk.bilyet_dep;
      select bilyet_dep into bilyet  from deposito where id_dep = new.id_dep;

      if bilyet is null then
        bilyet := ' ';
      end if;
      kode:=new.id_sandi; 
        bt := no_ledger('77');

      select into nojur nextval('public.transjr_id_jr_seq');
      insert into transjr(id_jr,id_com,tglbuku_jr,ket_jr,asal_jr,kegiatan_id,acc_jr,bukti_jr)
      values(nojur,'1',skr::date,'Pencairan Deposito ' || bilyet ,'D',new.id_xdep,true,bt);

      select into acr * from bilangdepo join trans_deposito using (id_dep)  where id_dep = new.id_dep;
        if new.Penalty_xdep = true then
        --  bt := no_ledger('77');

          insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr, entry_op_xdep, posted_djr,ket_djr,ref) 
          values (nojur,skr, 844,acr.nilaiskr,0,'System',true,acr.no_rek || ' Break Deposito Sblm Jth Tempo an ' || 
          acr.nama_nas,'210.10');

          insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr,ref) 
          values (nojur,skr,917,0,acr.nilaib,'System',true, 'Break Deposito Sblm Jth Tempo an ' || acr.nama_nas,'210.01');

          insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
          values (nojur,skr,868,0,acr.b_pinalti,'System',true,'Penalty Deposito Sebelum Jatuh Tempo an ' || 
          acr.nama_nas); 

          insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
          values (nojur,skr,845,acr.beban_yg_msh_hrs_dibayar,0,'System',true,'Beban Yang Masih Harus Dibayar Budep No. ' || 
          acr.bilyet_dep); 

          insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
          values (nojur,skr,873,acr.by_bunga_deposito,0,'System',true,'By Bunga Deposito No. ' || 
          acr.bilyet_dep); 

          insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
          values (nojur,skr,848,0,acr.budep,'System',true,'Budep No. ' || 
          acr.bilyet_dep || '/' || acr.nama_nas ); 

          insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
          values (nojur,skr,932,0,acr.pajak_budep,'System',true,'Pajak Budep No. ' || 
          acr.bilyet_dep); 

select into acr_sisa *  from bilangdepo 
          join trans_deposito using (id_dep)  
          join deposito using(id_Dep)
          join amor_etap using(id_Dk)
          where bilangdepo.id_dep = new.id_dep;

         if acr_sisa.sisa_amor_acc_deposito >= 1 then
 
            insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
            values (nojur,skr,1036,acr_sisa.sisa_amor_acc_deposito,0,'System',true,'Amortisasi Deposito ' || 
            acr_sisa.nama_nas || '/' || acr_sisa.bilyet_dep ); 

      select into nojur1 nextval('public.jurnal_detil_id_djr_seq');
          insert into jurnal_detil (id_Djr,id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
            values (nojur1,nojur,skr,984,0,acr_sisa.sisa_amor_acc_deposito,'System',true,'Amortisasi Deposito ' || 
            acr_sisa.nama_nas || '/' || acr_sisa.bilyet_dep ); 

            insert into trans_amor(id_ae,id_Djr,kredit_xa) values (acr_sisa.id_ae,nojur1,acr_sisa.sisa_amor_acc_deposito);
         end if;
           
        else if new.Penalty_xdep = false and  skr <    acr.maturity_dep then
        --  bt := no_ledger('77');

          insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr, entry_op_xdep, posted_djr,ket_djr,ref) 
          values (nojur,skr, 844,acr.nilaiskr,0,'System',true,acr.no_rek || ' Breaks Deposito Sblm Jth Tempo an ' || 
          acr.nama_nas,'210.10');

          insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr,ref) 
          values (nojur,skr,917,0,acr.nilaiskr,'System',true, 'Break Deposito Sblm Jth Tempo an ' || acr.nama_nas,'210.01');

          insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
          values (nojur,skr,845,acr.beban_yg_msh_hrs_dibayar,0,'System',true,'Beban Yang Masih Harus Dibayar Budep No. ' || 
          acr.bilyet_dep); 

          insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
          values (nojur,skr,873,acr.by_bunga_deposito,0,'System',true,'By Bunga Deposito No. ' || 
          acr.bilyet_dep); 

          insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
          values (nojur,skr,848,0,acr.budep,'System',true,'Budep No. ' || 
          acr.bilyet_dep || '/' || acr.nama_nas ); 

          insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
          values (nojur,skr,932,0,acr.pajak_budep,'System',true,'Pajak Budep No. ' || 
          acr.bilyet_dep); 

select into acr_sisa *  from bilangdepo 
          join trans_deposito using (id_dep)  
          join deposito using(id_Dep)
          join amor_etap using(id_Dk)
          where bilangdepo.id_dep = new.id_dep;

         if acr_sisa.sisa_amor_acc_deposito >= 1 then
 
            insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
            values (nojur,skr,1036,acr_sisa.sisa_amor_acc_deposito,0,'System',true,'Amortisasi Deposito ' || 
            acr_sisa.nama_nas || '/' || acr_sisa.bilyet_dep ); 

      select into nojur1 nextval('public.jurnal_detil_id_djr_seq');
          insert into jurnal_detil (id_Djr,id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
            values (nojur1,nojur,skr,984,0,acr_sisa.sisa_amor_acc_deposito,'System',true,'Amortisasi Deposito ' || 
            acr_sisa.nama_nas || '/' || acr_sisa.bilyet_dep ); 

            insert into trans_amor(id_ae,id_Djr,kredit_xa) values (acr_sisa.id_ae,nojur1,acr_sisa.sisa_amor_acc_deposito);
         end if;
        else if new.Penalty_xdep = false and  skr =    acr.maturity_dep then

  select into acr_sisa *  from bilangdepo 
          join trans_deposito using (id_dep)  
          join deposito using(id_Dep)
          join amor_etap using(id_Dk)
          where bilangdepo.id_dep = new.id_dep;

         if acr_sisa.sisa_amor_acc_deposito >= 1 then
 
            insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
            values (nojur,skr,1036,acr_sisa.sisa_amor_acc_deposito,0,'System',true,'Amortisasi Deposito ' || 
            acr_sisa.nama_nas || '/' || acr_sisa.bilyet_dep ); 

      select into nojur1 nextval('public.jurnal_detil_id_djr_seq');
          insert into jurnal_detil (id_Djr,id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
            values (nojur1,nojur,skr,984,0,acr_sisa.sisa_amor_acc_deposito,'System',true,'Amortisasi Deposito ' || 
            acr_sisa.nama_nas || '/' || acr_sisa.bilyet_dep ); 

            insert into trans_amor(id_ae,id_Djr,kredit_xa) values (acr_sisa.id_ae,nojur1,acr_sisa.sisa_amor_acc_deposito);
         end if;


         end if;
      
         end if;

       end if;
     end if;

 return new;
end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.tambah_xdep()
  OWNER TO bprdba;


-- View: public.hitung_komisi_deposito_3_id_dk

-- DROP VIEW public.hitung_komisi_deposito_3_id_dk;

CREATE OR REPLACE VIEW public.hitung_komisi_deposito_3_id_dk AS 
 SELECT deposito.id_dk,
    deposito.id_dep,
    amor_etap.entry_date_ae,
    amor_etap.id_ae,
    amor_etap.id_je
   FROM trans_amor
     JOIN amor_etap USING (id_ae)
     JOIN hitung_komisi_deposito USING (id_dep)
     JOIN deposito USING (id_Dep)
  WHERE deposito.active_dep = true AND amor_etap.id_je::text = 'D'::text AND amor_etap.id_dk IS NOT NULL AND trans_amor.kredit_xa IS NOT NULL AND (trans_amor.kredit_xa = hitung_komisi_deposito.amor_per_bln OR trans_amor.kredit_xa = hitung_komisi_deposito.amor_terakhir OR hitung_komisi_deposito.nilai_amor = trans_amor.debet_xa OR deposito.komisi_deposito = trans_amor.debet_xa)
  GROUP BY amor_etap.id_ae, deposito.id_dk, deposito.id_dep, amor_etap.id_je;

ALTER TABLE public.hitung_komisi_deposito_3_id_dk
  OWNER TO postgres;


-- Function: public.amor_etap()

-- DROP FUNCTION public.amor_etap();

CREATE OR REPLACE FUNCTION public.amor_etap()
  RETURNS integer AS
$BODY$declare

  ae int4;
  nojur int4;
  acr record;
  je record;
  jem record;
  jed int4;
  jek int4;
  nocoa int4;
  skr date;
  bt text;
  keter text;
  amorbini numeric(15,0);
  jedbt int4;
  jekrd int4;
  iddebet int4;
  idkredit int4;

begin 

 skr := sekarang();
  nojur := 0;

-- P R O V I S I 
  select into je * from jenis_etap where id_je = 'P';
  for acr in select prov_daily_amor.*, nama_nas, akta_krd
      from prov_daily_amor
        join kredit using (id_krd)
        join reknas using (id_rek)
        join nasabah using (id_nas)
      where amor_bulanini > 0  
      order by kredit.id_krd
  loop
    if nojur = 0 then
      nojur := nextval('transjr_id_jr_seq');
      bt := no_ledger('77');
      insert into transjr (
        id_jr,id_com,entryop_jr,tglbuku_jr,ket_jr,
        posted_jr, bukti_jr
        ) values (
        nojur,'1','System',skr,'Jurnal Amortisasi Etap',
        skr, bt
      );
    end if;

    if substr(acr.akta_krd,7,1) ='1' then
      jedbt := je.d1_je;
      jekrd := je.k1_je;
    elseif substr(acr.akta_krd,7,1) ='2' then
      jedbt := je.d2_je;
      jekrd := je.k2_je;   
    else
      jedbt := je.d3_je;
      jekrd := je.k3_je;
    end if;

    iddebet := nextval('jurnal_detil_id_djr_seq'); 
    insert into jurnal_detil (
        id_jr,id_djr,tgl_djr,id_coa,debet_djr,kredit_djr,
        entry_op_xdep, posted_djr,ket_djr
         ) values (
           nojur,iddebet,skr, jedbt,acr.amor_bulanini,0,
           'System',true,'Amortisasi Provisi '|| acr.nama_nas||'/'||acr.akta_krd
         );
    insert into jurnal_detil (
        id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,
        entry_op_xdep, posted_djr,ket_djr
         ) values (
           nojur,skr, jekrd,0,acr.amor_bulanini,
           'System',true,'Amortisasi Provisi '|| acr.nama_nas||'/'||acr.akta_krd
         );
     insert into trans_amor (id_ae,id_djr,debet_xa) values(acr.id_ae,iddebet,acr.amor_bulanini);
      
     update amor_etap
       set  sisa_ae = sisa_ae - acr.amor_bulanini
       where id_krd = acr.id_krd and id_je = 'P' ;
  end loop;
  
  -- A D M

  select into je * from jenis_etap where id_je = 'A';
  for acr in select adm_daily_amor.*, nama_nas, akta_krd
      from adm_daily_amor
        join kredit using (id_krd)
        join reknas using (id_rek)
        join nasabah using (id_nas)
      where amor_bulanini > 0  
      order by kredit.id_krd
  loop
    if nojur = 0 then
      nojur := nextval('transjr_id_jr_seq');
      bt := no_ledger('77');
      insert into transjr (
        id_jr,id_com,entryop_jr,tglbuku_jr,ket_jr,
        posted_jr, bukti_jr
        ) values (
        nojur,'1','System',skr,'Jurnal Amortisasi Etap',
        skr, bt
      );
    end if;

    if substr(acr.akta_krd,7,1) ='1' then
      jedbt := je.d1_je;
      jekrd := je.k1_je;
    elseif substr(acr.akta_krd,7,1) ='2' then
      jedbt := je.d2_je;
      jekrd := je.k2_je;   
    else
      jedbt := je.d3_je;
      jekrd := je.k3_je;
    end if;


    iddebet := nextval('jurnal_detil_id_djr_seq'); 
    insert into jurnal_detil (
        id_jr,id_djr,tgl_djr,id_coa,debet_djr,kredit_djr,
        entry_op_xdep, posted_djr,ket_djr
         ) values (
           nojur,iddebet,skr, jedbt,acr.amor_bulanini,0,
           'System',true,'Amortisasi Adm '|| acr.nama_nas||'/'||acr.akta_krd
         );

    insert into jurnal_detil (
        id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,
        entry_op_xdep, posted_djr,ket_djr
         ) values (
           nojur,skr, jekrd,0,acr.amor_bulanini,
           'System',true,'Amortisasi Adm '|| acr.nama_nas||'/'||acr.akta_krd
         );
    insert into trans_amor (id_ae,id_djr,debet_xa) values(acr.id_ae,iddebet,acr.amor_bulanini);
     update amor_etap
       set  sisa_ae = sisa_ae - acr.amor_bulanini
       where id_krd = acr.id_krd and id_je = 'A' ;

  end loop;

  -- MEDIATOR INADVANCE

  select into jem * from jenis_etap where id_je = 'M';
  for acr in select kredit.*, amor_etap.*, nama_nas ,amor_bulanini
    from kredit 
      join amor_etap using (id_krd) 
      join reknas using (id_rek) 
      join nasabah using (id_nas)
      join komisi_daily_amor using (id_krd) 
      where ( tgl_mediator_krd = sekarang() or tgl_komisi_krd = sekarang())   and amor_etap.id_je = 'M' 
      and kredit.typebunga_krd = 'A'  order by kredit.akta_krd  loop
    if nojur = 0 then
      nojur := nextval('transjr_id_jr_seq');
      bt := no_ledger('77');

      insert into transjr (
        id_jr,id_com,entryop_jr,tglbuku_jr,ket_jr,
        posted_jr, bukti_jr
        ) values (
        nojur,'1','System',skr,'Jurnal Amortisasi Etap',
        skr, bt
      );
    end if;

    if acr.id_je = 'M' then
        keter = 'Amortisasi Pertama (InAdvance) Mediator ';
        if substr(acr.akta_krd,7,1) ='1' then
          jek := jem.k1_je;
          jed := jem.d1_je;
        elseif substr(acr.akta_krd,7,1) ='2' then
          jek := jem.k2_je;
          jed := jem.d2_je;   
        else
         jek := jem.k3_je;
         jed := jem.d3_je;
        end if;
    end if;

    insert into jurnal_detil (
        id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,
        entry_op_xdep, posted_djr,ket_djr
         ) values (
           nojur,skr, jed,acr.amor_bulanini,0,
           'System',true,keter|| acr.nama_nas||'/'||acr.akta_krd
         );

    idkredit := nextval('jurnal_detil_id_djr_seq'); 
    insert into jurnal_detil (
        id_jr,id_djr,tgl_djr,id_coa,debet_djr,kredit_djr,
        entry_op_xdep, posted_djr,ket_djr
         ) values (
           nojur,idkredit,skr, jek,0,acr.amor_bulanini,
           'System',true,keter|| acr.nama_nas||'/'||acr.akta_krd
         );
    insert into trans_amor (id_ae,id_djr,kredit_xa) values(acr.id_ae,idkredit,acr.amor_bulanini);
     update amor_etap
       set  sisa_ae = sisa_ae - acr.amor_ae
       where id_krd = acr.id_krd and id_je = 'M' ;
  end loop;

-- K O M I S I INADVANCE
  select into jem * from jenis_etap where id_je = 'K';
  for acr in select kredit.*, amor_etap.*, nama_nas, amor_bulanini 
    from kredit 
      join amor_etap using (id_krd) 
      join reknas using (id_rek) 
      join nasabah using (id_nas)
      join komisi_daily_amor using (id_krd) 
    where tgl_komisi_krd = sekarang() and amor_etap.id_je = 'K' and kredit.typebunga_krd = 'A' order by akta_krd
  loop
    if nojur = 0 then
      nojur := nextval('transjr_id_jr_seq');
      bt := no_ledger('77');

      insert into transjr (
        id_jr,id_com,entryop_jr,tglbuku_jr,ket_jr,
        posted_jr, bukti_jr
        ) values (
        nojur,'1','System',skr,'Jurnal Amortisasi Etap',
        skr, bt
      );
    end if;

    if acr.id_je = 'K' then
        keter = 'Amortisasi Pertama (InAdvance) Komisi ';
        if substr(acr.akta_krd,7,1) ='1' then
          jek := jem.k1_je;
          jed := jem.d1_je;
        elseif substr(acr.akta_krd,7,1) ='2' then
          jek := jem.k2_je;
          jed := jem.d2_je;   
        else
         jek := jem.k3_je;
         jed := jem.d3_je;
        end if;
    end if;
 
    insert into jurnal_detil (
        id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,
        entry_op_xdep, posted_djr,ket_djr
         ) values (
           nojur,skr, jed,acr.amor_bulanini,0,
           'System',true,keter|| acr.nama_nas||'/'||acr.akta_krd
         );

    idkredit := nextval('jurnal_detil_id_djr_seq'); 
    insert into jurnal_detil (
        id_jr,id_djr,tgl_djr,id_coa,debet_djr,kredit_djr,
        entry_op_xdep, posted_djr,ket_djr
         ) values (
           nojur,idkredit,skr, jek,0,acr.amor_bulanini,
           'System',true,keter|| acr.nama_nas||'/'||acr.akta_krd
         );
    insert into trans_amor (id_ae,id_djr,kredit_xa) values(acr.id_ae,idkredit,acr.amor_bulanini);
     update amor_etap
       set  sisa_ae = sisa_ae - acr.amor_ae
       where id_krd = acr.id_krd and id_je = 'K' ;
  end loop;

-- KOMISI DAN MEDIATOR INADVANCE

select into je * from jenis_etap where id_je = 'K';
  select into jem * from jenis_etap where id_je = 'M';
  for acr in select komisi_daily_amor.*, nasabah.nama_nas,kredit.akta_krd
      from komisi_daily_amor
        join kredit using (id_krd)
        join reknas using (id_rek)
        join nasabah using (id_nas)
        join amor3_age using (id_krd)
      where amor_bulanini > 0  and amor3_age.bln_ke >=2 and kredit.typebunga_krd = 'A'
      order by kredit.id_krd 
  loop
    if nojur = 0 then
      nojur := nextval('transjr_id_jr_seq');
      bt := no_ledger('77');

      insert into transjr (
        id_jr,id_djr,id_com,entryop_jr,tglbuku_jr,ket_jr,
        posted_jr, bukti_jr
        ) values (
        nojur,idkredit,'1','System',skr,'Jurnal Amortisasi Etap',
        skr, bt
      );
    end if;

    if acr.id_je = 'K' then
        keter = 'Amortisasi Komisi ';
        if substr(acr.akta_krd,7,1) ='1' then
          jek := je.k1_je;
          jed := je.d1_je;
        elseif substr(acr.akta_krd,7,1) ='2' then
          jek := je.k2_je;
          jed := je.d2_je;   
        else
          jek := je.k3_je;
          jed := je.d3_je;
        end if;
    
       update amor_etap
         set  sisa_ae = sisa_ae - acr.amor_bulanini
         where id_krd = acr.id_krd and id_je = 'K' ;
    else
        keter = 'Amortisasi Mediator ';
        if substr(acr.akta_krd,7,1) ='1' then
          jek := jem.k1_je;
          jed := jem.d1_je;
        elseif substr(acr.akta_krd,7,1) ='2' then
          jek := jem.k2_je;
          jed := jem.d2_je;   
        else
         jek := jem.k3_je;
         jed := jem.d3_je;
        end if;
    
    update amor_etap
         set  sisa_ae = sisa_ae - acr.amor_bulanini
         where id_krd = acr.id_krd and id_je = 'M' ;
    end if;

    insert into jurnal_detil (
        id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,
        entry_op_xdep, posted_djr,ket_djr
         ) values (
           nojur,skr, jed,acr.amor_bulanini,0,
           'System',true,keter|| acr.nama_nas||'/'||acr.akta_krd
         );

    idkredit := nextval('jurnal_detil_id_djr_seq'); 
    insert into jurnal_detil (
        id_jr,id_djr,tgl_djr,id_coa,debet_djr,kredit_djr,
        entry_op_xdep, posted_djr,ket_djr
         ) values (
           nojur,idkredit,skr, jek,0,acr.amor_bulanini,
           'System',true,keter|| acr.nama_nas||'/'||acr.akta_krd
         );
    insert into trans_amor (id_ae,id_djr,kredit_xa) values(acr.id_ae,idkredit,acr.amor_bulanini);
  end loop;
    

-- KOMISI AND MEDIATOR NOT INADVANCE

  select into je * from jenis_etap where id_je = 'K';
  select into jem * from jenis_etap where id_je = 'M';
  for acr in select komisi_daily_amor.*, nasabah.nama_nas,kredit.akta_krd
      from komisi_daily_amor
        join kredit using (id_krd)
        join reknas using (id_rek)
        join nasabah using (id_nas)
        join amor3_age using (id_krd)
      where amor_bulanini > 0  and amor3_age.bln_ke >=1 and kredit.typebunga_krd <> 'A'
      order by kredit.id_krd 
  loop
    if nojur = 0 then
      nojur := nextval('transjr_id_jr_seq');
      bt := no_ledger('77');

      insert into transjr (
        id_jr,id_com,entryop_jr,tglbuku_jr,ket_jr,
        posted_jr, bukti_jr
        ) values (
        nojur,'1','System',skr,'Jurnal Amortisasi Etap',
        skr, bt
      );
    end if;

    if acr.id_je = 'K' then
        keter = 'Amortisasi Komisi ';
        if substr(acr.akta_krd,7,1) ='1' then
          jek := je.k1_je;
          jed := je.d1_je;
        elseif substr(acr.akta_krd,7,1) ='2' then
          jek := je.k2_je;
          jed := je.d2_je;   
        else
          jek := je.k3_je;
          jed := je.d3_je;
        end if;
    
       update amor_etap
         set  sisa_ae = sisa_ae - acr.amor_bulanini
         where id_krd = acr.id_krd and id_je = 'K' ;
    else
        keter = 'Amortisasi Mediator ';
        if substr(acr.akta_krd,7,1) ='1' then
          jek := jem.k1_je;
          jed := jem.d1_je;
        elseif substr(acr.akta_krd,7,1) ='2' then
          jek := jem.k2_je;
          jed := jem.d2_je;   
        else
         jek := jem.k3_je;
         jed := jem.d3_je;
        end if;
  
       
    update amor_etap
         set  sisa_ae = sisa_ae - acr.amor_bulanini
         where id_krd = acr.id_krd and id_je = 'M' ;
    end if;

    insert into jurnal_detil (
        id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,
        entry_op_xdep, posted_djr,ket_djr
         ) values (
           nojur,skr, jed,acr.amor_bulanini,0,
           'System',true,keter|| acr.nama_nas||'/'||acr.akta_krd
         );

    idkredit := nextval('jurnal_detil_id_djr_seq');
    insert into jurnal_detil (
        id_jr,id_djr,tgl_djr,id_coa,debet_djr,kredit_djr,
        entry_op_xdep, posted_djr,ket_djr
         ) values (
           nojur,idkredit,skr, jek,0,acr.amor_bulanini,
           'System',true,keter|| acr.nama_nas||'/'||acr.akta_krd
         );
   insert into trans_amor (id_ae,id_djr,kredit_xa) values(acr.id_ae,idkredit,acr.amor_bulanini);
    end loop;

 -- D E P O S I T O

  select into je * from jenis_etap where id_je = 'D';
  for acr in SELECT DISTINCT TGL_XDEP, deposito.tgl_komisi_dep, amor_bulanini, komisi_deposito_daily_amor1.tgl_komisi_dep , entry_date_ae,
     nama_nas,
     komisi_deposito_daily_amor1.bilyet_dep,
     hitung_komisi_deposito_3_id_dk.id_ae,
     komisi_deposito_daily_amor1.id_dep
   from komisi_deposito_daily_amor1
   join TRANS_DEPOSITO using(id_Dep)
   join deposito using(id_Dep) 
   join hitung_komisi_deposito_3_id_dk using(id_Dk)
   where TRANS_DEPOSITO.TGL_XDEP = SEKARANG() and hitung_komisi_deposito_3_id_dk.id_Dk is not null and deposito.tgl_cair_Dep is null 
    and (active_Dep = 't'  and (sekarang() = maturity_Dep  or sekarang() <> maturity_Dep))  and deposito.awal_dep <> sekarang()
   ORDER BY id_dep
   
  loop
    if nojur = 0 then
      nojur := nextval('transjr_id_jr_seq');
      bt := no_ledger('77');
      insert into transjr (
        id_jr,id_com,entryop_jr,tglbuku_jr,ket_jr,
        posted_jr, bukti_jr
        ) values (
        nojur,'1','System',skr,'Jurnal Amortisasi Deposito Etap',
        skr, bt
      );
    end if; 

    iddebet := nextval('jurnal_detil_id_djr_seq'); 
    insert into jurnal_detil (
        id_jr,id_djr,id_coa,tgl_djr,debet_djr,kredit_djr,
        entry_op_xdep, posted_djr,ket_djr,ref
         ) values (
           nojur,iddebet,'1036',skr, acr.amor_bulanini,0,
           'System',true,'Amortisasi Deposito '|| acr.nama_nas||'/'||acr.bilyet_dep,'160.01'
         );


    idkredit := nextval('jurnal_detil_id_djr_seq'); 
    insert into jurnal_detil (
        id_jr,id_Djr,tgl_djr,id_coa,debet_djr,kredit_djr,
        entry_op_xdep, posted_djr,ket_djr,ref
) values (
           nojur,idkredit,skr,'984',0,acr.amor_bulanini,
           'System',true,'Amortisasi Deposito '|| acr.nama_nas||'/'||acr.bilyet_dep,'450.05'
         );
    insert into trans_amor (id_ae,id_djr,kredit_xa) values(acr.id_ae,idkredit,acr.amor_bulanini);
     update amor_etap
       set  sisa_ae = sisa_ae - acr.amor_bulanini
       where id_dep = acr.id_dep and id_je = 'D' ;

  end loop;
  
  return 1;

end; -- end of amor_etap()

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.amor_etap()
  OWNER TO postgres;

  -- View: public.hitung_komisi_deposito_3

-- DROP VIEW public.hitung_komisi_deposito_3;

CREATE OR REPLACE VIEW public.hitung_komisi_deposito_3 AS 
 SELECT deposito.id_dk,
    deposito.id_dep,
    amor_etap.id_ae,
    deposito.komisi_deposito AS sum_debet_xa,
    sum(trans_amor.kredit_xa) AS sum_kredit_xa,
    deposito.komisi_deposito - sum(trans_amor.kredit_xa) AS sisa,
    amor_etap.id_je
   FROM trans_amor
     JOIN amor_etap USING (id_ae)
     JOIN deposito USING (id_dk)
     LEFT JOIN hitung_komisi_deposito USING (id_dk)
     LEFT JOIN jurnal_detil USING (id_djr)
  WHERE deposito.active_dep = true AND (trans_amor.kredit_xa = hitung_komisi_deposito.amor_per_bln OR trans_amor.kredit_xa = hitung_komisi_deposito.amor_terakhir OR deposito.komisi_deposito = trans_amor.debet_xa OR deposito.komisi_deposito = trans_amor.debet_xa OR jurnal_detil.tgl_djr >= deposito.tgl_komisi_dep) AND jurnal_detil.tgl_djr >= deposito.tgl_komisi_dep AND deposito.tgl_komisi_dep < jurnal_detil.tgl_djr AND deposito.komisi_deposito > trans_amor.kredit_xa
  GROUP BY amor_etap.id_ae, deposito.id_dk, deposito.id_dep, amor_etap.id_je;

ALTER TABLE public.hitung_komisi_deposito_3
  OWNER TO postgres;


 
-- View: public.sisa_komisi

-- DROP VIEW public.sisa_komisi;

CREATE OR REPLACE VIEW public.sisa_komisi AS 
 SELECT DISTINCT deposito_komisi.id_dk,
    deposito_komisi.id_dep,
    deposito_komisi.awal_dep,
    to_char(deposito_komisi.awal_dep::timestamp with time zone, '2021-1-DD'::text)::date AS bln_1,
    deposito.bln_dep,
    deposito_komisi.komisi_deposito,
    deposito_komisi.tgl_deposito_komisi,
    deposito.bilyet_dep,
    deposito_komisi.maturity_dep
   FROM deposito_komisi
     JOIN deposito USING (id_dep)
     JOIN reknas USING (id_rek)
     JOIN nasabah USING (id_nas)
     JOIN cif_nasabah USING (id_nas)
     LEFT JOIN nasabah n2 ON nasabah.satu_nas = n2.id_nas
  ORDER BY deposito_komisi.id_dep;

ALTER TABLE public.sisa_komisi
  OWNER TO postgres;

  -- View: public.sisa_komisi_max

-- DROP VIEW public.sisa_komisi_max;

CREATE OR REPLACE VIEW public.sisa_komisi_max AS 
 SELECT b.id_dk,
    b.id_dep
   FROM ( SELECT sisa_komisi.id_dep,
            max(sisa_komisi.id_dk) AS max
           FROM sisa_komisi
          GROUP BY sisa_komisi.id_dep) a
     JOIN sisa_komisi b ON a.id_dep = b.id_dep AND a.max = b.id_dk
  ORDER BY b.id_dep;

ALTER TABLE public.sisa_komisi_max
  OWNER TO postgres;



CREATE OR REPLACE VIEW public.sisa_komisi_order AS 
select sisa_komisi.* 
From sisa_komisi_max
join sisa_komisi using(id_Dk)
order by sisa_komisi_max.id_Dep;
 
-- View: public.sisa_komisi_order1

-- DROP VIEW public.sisa_komisi_order1;

CREATE OR REPLACE VIEW public.sisa_komisi_order1 AS 
 SELECT sisa_komisi_order.id_dep,
    sisa_komisi_order.id_dk,
    sisa_komisi_order.bln_1,
    sisa_komisi_order.awal_dep,
    sisa_komisi_order.tgl_deposito_komisi,
    sisa_komisi_order.bln_dep,
        CASE
            WHEN sisa_komisi_order.awal_dep <= '2020-12-31'::date THEN sisa_komisi_order.bln_dep::double precision - round(((sisa_komisi_order.bln_1 - sisa_komisi_order.awal_dep) / 30)::double precision)
            WHEN sisa_komisi_order.awal_dep >= '2021-01-01'::date THEN sisa_komisi_order.bln_dep::double precision
            ELSE NULL::double precision
        END AS sdh_dilewati,
    sisa_komisi_order.komisi_deposito,
    sisa_komisi_order.bilyet_dep,
    sisa_komisi_order.maturity_dep
   FROM sisa_komisi_order
  ORDER BY sisa_komisi_order.bln_dep;

ALTER TABLE public.sisa_komisi_order1
  OWNER TO postgres;



-- View: public.sisa_komisi_order2

-- DROP VIEW public.sisa_komisi_order2;

CREATE OR REPLACE VIEW public.sisa_komisi_order2 AS 
 SELECT  maturity_dep,
    sisa_komisi_order1.id_dep,
    sisa_komisi_order1.id_dk,
    sisa_komisi_order1.bln_1,
    sisa_komisi_order1.awal_dep,
    sisa_komisi_order1.tgl_deposito_komisi,
    sisa_komisi_order1.bln_dep,
    sisa_komisi_order1.sdh_dilewati,
    sisa_komisi_order1.komisi_deposito,
    sisa_komisi_order1.bilyet_dep,
        CASE
            WHEN sisa_komisi_order1.awal_dep <= '2021-12-31'::date THEN round(sisa_komisi_order1.komisi_deposito::double precision / sisa_komisi_order1.sdh_dilewati)
            WHEN sisa_komisi_order1.awal_dep >= '2021-01-01'::date THEN round(sisa_komisi_order1.komisi_deposito / sisa_komisi_order1.bln_dep::numeric)::double precision
            ELSE NULL::double precision
        END AS amor_bln
   FROM sisa_komisi_order1 
  ORDER BY sisa_komisi_order1.komisi_deposito;

ALTER TABLE public.sisa_komisi_order2
  OWNER TO postgres;


-- View: public.sisa_komisi_order3

-- DROP VIEW public.sisa_komisi_order3;

CREATE OR REPLACE VIEW public.sisa_komisi_order3 AS 
 SELECT sisa_komisi_order2.maturity_dep,
    sisa_komisi_order2.id_dk,
    sisa_komisi_order2.id_dep,
    sisa_komisi_order2.bln_1,
    sisa_komisi_order2.awal_dep,
    sisa_komisi_order2.tgl_deposito_komisi,
    sisa_komisi_order2.bln_dep,
    sisa_komisi_order2.sdh_dilewati,
    sisa_komisi_order2.komisi_deposito,
    sisa_komisi_order2.bilyet_dep,
    sisa_komisi_order2.amor_bln,
    sisa_komisi_order2.komisi_deposito::double precision - sisa_komisi_order2.amor_bln * (sisa_komisi_order2.sdh_dilewati - 1::numeric(15,2)::double precision) AS amor_akhir,
    round(sisa_komisi_order2.amor_bln * (sisa_komisi_order2.bln_dep - 1)::numeric(15,2)::double precision + sisa_komisi_order2.komisi_deposito::double precision - sisa_komisi_order2.amor_bln * (sisa_komisi_order2.sdh_dilewati - 1::numeric(15,2)::double precision)::numeric(15,2)::double precision)::numeric(15,2) AS nilai_amor
   FROM sisa_komisi_order2
  ORDER BY sisa_komisi_order2.komisi_deposito;

ALTER TABLE public.sisa_komisi_order3
  OWNER TO postgres;

-- View: public.sisa_komisi_order4

-- DROP VIEW public.sisa_komisi_order4;

CREATE OR REPLACE VIEW public.sisa_komisi_order4 AS 
 SELECT sisa_komisi_order3.maturity_dep,
    sisa_komisi_order3.id_dep,
    sisa_komisi_order3.id_dk,
    sisa_komisi_order3.bln_1,
    sisa_komisi_order3.awal_dep,
    sisa_komisi_order3.tgl_deposito_komisi,
    sisa_komisi_order3.bln_dep,
    sisa_komisi_order3.sdh_dilewati,
    sisa_komisi_order3.komisi_deposito,
    sisa_komisi_order3.bilyet_dep,
    sisa_komisi_order3.amor_bln,
    sisa_komisi_order3.amor_akhir,
    sisa_komisi_order3.nilai_amor,
        CASE
            WHEN sisa_komisi_order3.nilai_amor >= 4992::numeric AND sisa_komisi_order3.nilai_amor <= 5003::numeric THEN 5000::numeric
            WHEN sisa_komisi_order3.nilai_amor >= 9000::numeric AND sisa_komisi_order3.nilai_amor <= 10001::numeric THEN 10000::numeric
            ELSE sisa_komisi_order3.nilai_amor
        END AS akhir_nilai_amor
   FROM sisa_komisi_order3
  ORDER BY sisa_komisi_order3.nilai_amor;

ALTER TABLE public.sisa_komisi_order4
  OWNER TO postgres;

-- View: public.sisa_komisi_order5

-- DROP VIEW public.sisa_komisi_order5;

CREATE OR REPLACE VIEW public.sisa_komisi_order5 AS 
 SELECT sisa_komisi_order4.maturity_dep,
    sisa_komisi_order4.id_dk,
    sisa_komisi_order4.id_dep,
    sisa_komisi_order4.bln_1,
    sisa_komisi_order4.awal_dep,
    sisa_komisi_order4.tgl_deposito_komisi,
    sisa_komisi_order4.bln_dep,
    sisa_komisi_order4.sdh_dilewati,
    sisa_komisi_order4.komisi_deposito,
    sisa_komisi_order4.bilyet_dep,
    sisa_komisi_order4.amor_bln,
    sisa_komisi_order4.amor_akhir,
    sisa_komisi_order4.nilai_amor,
    sisa_komisi_order4.akhir_nilai_amor,
    round(sisa_komisi_order4.akhir_nilai_amor / sisa_komisi_order4.bln_dep::numeric) AS amor_per_bln,
    sisa_komisi_order4.akhir_nilai_amor - round(sisa_komisi_order4.akhir_nilai_amor / sisa_komisi_order4.bln_dep::numeric) * (sisa_komisi_order4.bln_dep - 1)::numeric AS amor_terakhir
   FROM sisa_komisi_order4;

ALTER TABLE public.sisa_komisi_order5
  OWNER TO postgres;


-- View: public.sisa_komisi_order5_amor

-- DROP VIEW public.sisa_komisi_order5_amor;

CREATE OR REPLACE VIEW public.sisa_komisi_order5_amor AS 
 SELECT sisa_komisi_order5.id_dep,
     sisa_komisi_order5.id_dk, 
        CASE
            WHEN sisa_komisi_order5.amor_per_bln IS NOT NULL THEN sisa_komisi_order5.amor_per_bln
            WHEN sisa_komisi_order5.amor_per_bln IS NULL THEN 0::numeric
            ELSE NULL::numeric
        END AS amor_per_bln,
        CASE
            WHEN sisa_komisi_order5.amor_per_bln IS NOT NULL THEN sisa_komisi_order5.amor_terakhir
            WHEN sisa_komisi_order5.amor_per_bln IS NULL THEN 0::numeric
            ELSE NULL::numeric
        END AS amor_terakhir,
    sisa_komisi_order5.komisi_deposito,
    sisa_komisi_order5.akhir_nilai_amor,
    sisa_komisi_order5.bln_dep,
    sisa_komisi_order5.sdh_dilewati,
    sisa_komisi_order5.awal_dep,
    sisa_komisi_order5.maturity_dep,
    sisa_komisi_order5.tgl_deposito_komisi
   FROM sisa_komisi_order5  
  ORDER BY (
        CASE
            WHEN sisa_komisi_order5.amor_per_bln IS NOT NULL THEN sisa_komisi_order5.amor_per_bln
            WHEN sisa_komisi_order5.amor_per_bln IS NULL THEN 0::numeric
            ELSE NULL::numeric
        END);

ALTER TABLE public.sisa_komisi_order5_amor
  OWNER TO postgres;


-- View: public.sisa_komisi_order5_amor_sisa

-- DROP VIEW public.sisa_komisi_order5_amor_sisa;

CREATE OR REPLACE VIEW public.sisa_komisi_order5_amor_sisa AS 
 SELECT amor_etap.id_dk,
    sisa_komisi_order5_amor.id_dep,
    sisa_komisi_order5_amor.komisi_deposito,
    sisa_komisi_order5_amor.akhir_nilai_amor,
    sum(trans_amor.kredit_xa) AS kredit
   FROM trans_amor
     JOIN amor_etap USING (id_ae)
     LEFT JOIN sisa_komisi_order5_amor USING (id_dk)
     LEFT JOIN jurnal_detil USING (id_djr)
  WHERE sisa_komisi_order5_amor.tgl_deposito_komisi < jurnal_detil.tgl_djr AND sisa_komisi_order5_amor.komisi_deposito > trans_amor.kredit_xa
  GROUP BY sisa_komisi_order5_amor.komisi_deposito, amor_etap.id_dk, sisa_komisi_order5_amor.id_dep, sisa_komisi_order5_amor.akhir_nilai_amor;

ALTER TABLE public.sisa_komisi_order5_amor_sisa
  OWNER TO postgres;


-- View: public.sisa_komisi_order5_amor_full

-- DROP VIEW public.sisa_komisi_order5_amor_full;

CREATE OR REPLACE VIEW public.sisa_komisi_order5_amor_full AS 
 SELECT sisa_komisi_order5_amor.id_dep,
    sisa_komisi_order5_amor.id_dk,
    sisa_komisi_order5_amor.komisi_deposito,
    sisa_komisi_order5_amor.amor_per_bln,
    sisa_komisi_order5_amor.amor_terakhir,
    sisa_komisi_order5_amor.akhir_nilai_amor,
    sisa_komisi_order5_amor.bln_dep,
    sisa_komisi_order5_amor.sdh_dilewati,
    sisa_komisi_order5_amor.awal_dep,
    sisa_komisi_order5_amor.maturity_dep,
    sisa_komisi_order5_amor.tgl_deposito_komisi,
    sisa_komisi_order5_amor_sisa.kredit
   FROM sisa_komisi_order5_amor_sisa
     FULL JOIN sisa_komisi_order5_amor USING (id_dep);

ALTER TABLE public.sisa_komisi_order5_amor_full
  OWNER TO postgres;
 

-- View: public.sisa_komisi_order5_amor_full_sisa

-- DROP VIEW public.sisa_komisi_order5_amor_full_sisa;

CREATE OR REPLACE VIEW public.sisa_komisi_order5_amor_full_sisa AS 
 SELECT sisa_komisi_order5_amor_full.id_dep,
    sisa_komisi_order5_amor_full.id_dk,
    sisa_komisi_order5_amor_full.amor_per_bln,
    sisa_komisi_order5_amor_full.amor_terakhir,
    sisa_komisi_order5_amor_full.akhir_nilai_amor,
    sisa_komisi_order5_amor_full.bln_dep,
    sisa_komisi_order5_amor_full.sdh_dilewati,
    sisa_komisi_order5_amor_full.awal_dep,
    sisa_komisi_order5_amor_full.maturity_dep,
    sisa_komisi_order5_amor_full.tgl_deposito_komisi,
    sisa_komisi_order5_amor_full.komisi_deposito,
    sisa_komisi_order5_amor_full.kredit,
        CASE
            WHEN sisa_komisi_order5_amor_full.kredit IS NULL THEN 0::numeric
            ELSE sisa_komisi_order5_amor_full.kredit
        END AS sum_kredit,
        CASE
            WHEN sisa_komisi_order5_amor_full.kredit IS NULL THEN sisa_komisi_order5_amor_full.akhir_nilai_amor
            ELSE sisa_komisi_order5_amor_full.komisi_deposito - sisa_komisi_order5_amor_full.kredit
        END AS sisa,
        id_je
   FROM sisa_komisi_order5_amor_full
   join amor_etap using(id_dep);

ALTER TABLE public.sisa_komisi_order5_amor_full_sisa
  OWNER TO postgres;

 
  
-- View: public.sisa_komisi

-- DROP VIEW public.sisa_komisi;

CREATE OR REPLACE VIEW public.sisa_komisi AS 
 SELECT DISTINCT deposito_komisi.id_dk,
    deposito_komisi.id_dep,
    deposito_komisi.awal_dep,
    to_char(deposito_komisi.awal_dep::timestamp with time zone, '2021-1-DD'::text)::date AS bln_1,
    deposito.bln_dep,
    deposito_komisi.komisi_deposito,
    deposito_komisi.tgl_deposito_komisi,
    deposito.bilyet_dep,
    deposito_komisi.maturity_dep
   FROM deposito_komisi
     JOIN deposito USING (id_dep)
     JOIN reknas USING (id_rek)
     JOIN nasabah USING (id_nas)
     JOIN cif_nasabah USING (id_nas)
     LEFT JOIN nasabah n2 ON nasabah.satu_nas = n2.id_nas
  ORDER BY deposito_komisi.id_dep;

ALTER TABLE public.sisa_komisi
  OWNER TO postgres;

  -- View: public.sisa_komisi_max

-- DROP VIEW public.sisa_komisi_max;

CREATE OR REPLACE VIEW public.sisa_komisi_max AS 
 SELECT b.id_dk,
    b.id_dep
   FROM ( SELECT sisa_komisi.id_dep,
            max(sisa_komisi.id_dk) AS max
           FROM sisa_komisi
          GROUP BY sisa_komisi.id_dep) a
     JOIN sisa_komisi b ON a.id_dep = b.id_dep AND a.max = b.id_dk
  ORDER BY b.id_dep;

ALTER TABLE public.sisa_komisi_max
  OWNER TO postgres;



CREATE OR REPLACE VIEW public.sisa_komisi_order AS 
select sisa_komisi.* 
From sisa_komisi_max
join sisa_komisi using(id_Dk)
order by sisa_komisi_max.id_Dep;
 
-- View: public.sisa_komisi_order1

-- DROP VIEW public.sisa_komisi_order1;

CREATE OR REPLACE VIEW public.sisa_komisi_order1 AS 
 SELECT sisa_komisi_order.id_dep,
    sisa_komisi_order.id_dk,
    sisa_komisi_order.bln_1,
    sisa_komisi_order.awal_dep,
    sisa_komisi_order.tgl_deposito_komisi,
    sisa_komisi_order.bln_dep,
        CASE
            WHEN sisa_komisi_order.awal_dep <= '2020-12-31'::date THEN sisa_komisi_order.bln_dep::double precision - round(((sisa_komisi_order.bln_1 - sisa_komisi_order.awal_dep) / 30)::double precision)
            WHEN sisa_komisi_order.awal_dep >= '2021-01-01'::date THEN sisa_komisi_order.bln_dep::double precision
            ELSE NULL::double precision
        END AS sdh_dilewati,
    sisa_komisi_order.komisi_deposito,
    sisa_komisi_order.bilyet_dep,
    sisa_komisi_order.maturity_dep
   FROM sisa_komisi_order
  ORDER BY sisa_komisi_order.bln_dep;

ALTER TABLE public.sisa_komisi_order1
  OWNER TO postgres;



-- View: public.sisa_komisi_order2

-- DROP VIEW public.sisa_komisi_order2;

CREATE OR REPLACE VIEW public.sisa_komisi_order2 AS 
 SELECT  maturity_dep,
    sisa_komisi_order1.id_dep,
    sisa_komisi_order1.id_dk,
    sisa_komisi_order1.bln_1,
    sisa_komisi_order1.awal_dep,
    sisa_komisi_order1.tgl_deposito_komisi,
    sisa_komisi_order1.bln_dep,
    sisa_komisi_order1.sdh_dilewati,
    sisa_komisi_order1.komisi_deposito,
    sisa_komisi_order1.bilyet_dep,
        CASE
            WHEN sisa_komisi_order1.awal_dep <= '2021-12-31'::date THEN round(sisa_komisi_order1.komisi_deposito::double precision / sisa_komisi_order1.sdh_dilewati)
            WHEN sisa_komisi_order1.awal_dep >= '2021-01-01'::date THEN round(sisa_komisi_order1.komisi_deposito / sisa_komisi_order1.bln_dep::numeric)::double precision
            ELSE NULL::double precision
        END AS amor_bln
   FROM sisa_komisi_order1 
  ORDER BY sisa_komisi_order1.komisi_deposito;

ALTER TABLE public.sisa_komisi_order2
  OWNER TO postgres;


-- View: public.sisa_komisi_order3

-- DROP VIEW public.sisa_komisi_order3;

CREATE OR REPLACE VIEW public.sisa_komisi_order3 AS 
 SELECT sisa_komisi_order2.maturity_dep,
    sisa_komisi_order2.id_dk,
    sisa_komisi_order2.id_dep,
    sisa_komisi_order2.bln_1,
    sisa_komisi_order2.awal_dep,
    sisa_komisi_order2.tgl_deposito_komisi,
    sisa_komisi_order2.bln_dep,
    sisa_komisi_order2.sdh_dilewati,
    sisa_komisi_order2.komisi_deposito,
    sisa_komisi_order2.bilyet_dep,
    sisa_komisi_order2.amor_bln,
    sisa_komisi_order2.komisi_deposito::double precision - sisa_komisi_order2.amor_bln * (sisa_komisi_order2.sdh_dilewati - 1::numeric(15,2)::double precision) AS amor_akhir,
    round(sisa_komisi_order2.amor_bln * (sisa_komisi_order2.bln_dep - 1)::numeric(15,2)::double precision + sisa_komisi_order2.komisi_deposito::double precision - sisa_komisi_order2.amor_bln * (sisa_komisi_order2.sdh_dilewati - 1::numeric(15,2)::double precision)::numeric(15,2)::double precision)::numeric(15,2) AS nilai_amor
   FROM sisa_komisi_order2
  ORDER BY sisa_komisi_order2.komisi_deposito;

ALTER TABLE public.sisa_komisi_order3
  OWNER TO postgres;

-- View: public.sisa_komisi_order4

-- DROP VIEW public.sisa_komisi_order4;

CREATE OR REPLACE VIEW public.sisa_komisi_order4 AS 
 SELECT sisa_komisi_order3.maturity_dep,
    sisa_komisi_order3.id_dep,
    sisa_komisi_order3.id_dk,
    sisa_komisi_order3.bln_1,
    sisa_komisi_order3.awal_dep,
    sisa_komisi_order3.tgl_deposito_komisi,
    sisa_komisi_order3.bln_dep,
    sisa_komisi_order3.sdh_dilewati,
    sisa_komisi_order3.komisi_deposito,
    sisa_komisi_order3.bilyet_dep,
    sisa_komisi_order3.amor_bln,
    sisa_komisi_order3.amor_akhir,
    sisa_komisi_order3.nilai_amor,
        CASE
            WHEN sisa_komisi_order3.nilai_amor >= 4992::numeric AND sisa_komisi_order3.nilai_amor <= 5003::numeric THEN 5000::numeric
            WHEN sisa_komisi_order3.nilai_amor >= 9000::numeric AND sisa_komisi_order3.nilai_amor <= 10001::numeric THEN 10000::numeric
            ELSE sisa_komisi_order3.nilai_amor
        END AS akhir_nilai_amor
   FROM sisa_komisi_order3
  ORDER BY sisa_komisi_order3.nilai_amor;

ALTER TABLE public.sisa_komisi_order4
  OWNER TO postgres;

-- View: public.sisa_komisi_order5

-- DROP VIEW public.sisa_komisi_order5;

CREATE OR REPLACE VIEW public.sisa_komisi_order5 AS 
 SELECT sisa_komisi_order4.maturity_dep,
    sisa_komisi_order4.id_dk,
    sisa_komisi_order4.id_dep,
    sisa_komisi_order4.bln_1,
    sisa_komisi_order4.awal_dep,
    sisa_komisi_order4.tgl_deposito_komisi,
    sisa_komisi_order4.bln_dep,
    sisa_komisi_order4.sdh_dilewati,
    sisa_komisi_order4.komisi_deposito,
    sisa_komisi_order4.bilyet_dep,
    sisa_komisi_order4.amor_bln,
    sisa_komisi_order4.amor_akhir,
    sisa_komisi_order4.nilai_amor,
    sisa_komisi_order4.akhir_nilai_amor,
    round(sisa_komisi_order4.akhir_nilai_amor / sisa_komisi_order4.bln_dep::numeric) AS amor_per_bln,
    sisa_komisi_order4.akhir_nilai_amor - round(sisa_komisi_order4.akhir_nilai_amor / sisa_komisi_order4.bln_dep::numeric) * (sisa_komisi_order4.bln_dep - 1)::numeric AS amor_terakhir
   FROM sisa_komisi_order4;

ALTER TABLE public.sisa_komisi_order5
  OWNER TO postgres;


-- View: public.sisa_komisi_order5_amor

-- DROP VIEW public.sisa_komisi_order5_amor;

CREATE OR REPLACE VIEW public.sisa_komisi_order5_amor AS 
 SELECT sisa_komisi_order5.id_dep,
     sisa_komisi_order5.id_dk, 
        CASE
            WHEN sisa_komisi_order5.amor_per_bln IS NOT NULL THEN sisa_komisi_order5.amor_per_bln
            WHEN sisa_komisi_order5.amor_per_bln IS NULL THEN 0::numeric
            ELSE NULL::numeric
        END AS amor_per_bln,
        CASE
            WHEN sisa_komisi_order5.amor_per_bln IS NOT NULL THEN sisa_komisi_order5.amor_terakhir
            WHEN sisa_komisi_order5.amor_per_bln IS NULL THEN 0::numeric
            ELSE NULL::numeric
        END AS amor_terakhir,
    sisa_komisi_order5.komisi_deposito,
    sisa_komisi_order5.akhir_nilai_amor,
    sisa_komisi_order5.bln_dep,
    sisa_komisi_order5.sdh_dilewati,
    sisa_komisi_order5.awal_dep,
    sisa_komisi_order5.maturity_dep,
    sisa_komisi_order5.tgl_deposito_komisi
   FROM sisa_komisi_order5  
  ORDER BY (
        CASE
            WHEN sisa_komisi_order5.amor_per_bln IS NOT NULL THEN sisa_komisi_order5.amor_per_bln
            WHEN sisa_komisi_order5.amor_per_bln IS NULL THEN 0::numeric
            ELSE NULL::numeric
        END);

ALTER TABLE public.sisa_komisi_order5_amor
  OWNER TO postgres;


-- View: public.sisa_komisi_order5_amor_sisa

-- DROP VIEW public.sisa_komisi_order5_amor_sisa;

CREATE OR REPLACE VIEW public.sisa_komisi_order5_amor_sisa AS 
 SELECT amor_etap.id_dk,
    sisa_komisi_order5_amor.id_dep,
    sisa_komisi_order5_amor.komisi_deposito,
    sisa_komisi_order5_amor.akhir_nilai_amor,
    sum(trans_amor.kredit_xa) AS kredit
   FROM trans_amor
     JOIN amor_etap USING (id_ae)
     LEFT JOIN sisa_komisi_order5_amor USING (id_dk)
     LEFT JOIN jurnal_detil USING (id_djr)
  WHERE sisa_komisi_order5_amor.tgl_deposito_komisi < jurnal_detil.tgl_djr AND sisa_komisi_order5_amor.komisi_deposito > trans_amor.kredit_xa
  GROUP BY sisa_komisi_order5_amor.komisi_deposito, amor_etap.id_dk, sisa_komisi_order5_amor.id_dep, sisa_komisi_order5_amor.akhir_nilai_amor;

ALTER TABLE public.sisa_komisi_order5_amor_sisa
  OWNER TO postgres;


-- View: public.sisa_komisi_order5_amor_full

-- DROP VIEW public.sisa_komisi_order5_amor_full;

CREATE OR REPLACE VIEW public.sisa_komisi_order5_amor_full AS 
 SELECT sisa_komisi_order5_amor.id_dep,
    sisa_komisi_order5_amor.id_dk,
    sisa_komisi_order5_amor.komisi_deposito,
    sisa_komisi_order5_amor.amor_per_bln,
    sisa_komisi_order5_amor.amor_terakhir,
    sisa_komisi_order5_amor.akhir_nilai_amor,
    sisa_komisi_order5_amor.bln_dep,
    sisa_komisi_order5_amor.sdh_dilewati,
    sisa_komisi_order5_amor.awal_dep,
    sisa_komisi_order5_amor.maturity_dep,
    sisa_komisi_order5_amor.tgl_deposito_komisi,
    sisa_komisi_order5_amor_sisa.kredit
   FROM sisa_komisi_order5_amor_sisa
     FULL JOIN sisa_komisi_order5_amor USING (id_dep);

ALTER TABLE public.sisa_komisi_order5_amor_full
  OWNER TO postgres;
 

-- View: public.sisa_komisi_order5_amor_full_sisa

-- DROP VIEW public.sisa_komisi_order5_amor_full_sisa;

CREATE OR REPLACE VIEW public.sisa_komisi_order5_amor_full_sisa AS 
 SELECT sisa_komisi_order5_amor_full.id_dep,
    sisa_komisi_order5_amor_full.id_dk,
    sisa_komisi_order5_amor_full.amor_per_bln,
    sisa_komisi_order5_amor_full.amor_terakhir,
    sisa_komisi_order5_amor_full.akhir_nilai_amor,
    sisa_komisi_order5_amor_full.bln_dep,
    sisa_komisi_order5_amor_full.sdh_dilewati,
    sisa_komisi_order5_amor_full.awal_dep,
    sisa_komisi_order5_amor_full.maturity_dep,
    sisa_komisi_order5_amor_full.tgl_deposito_komisi,
    sisa_komisi_order5_amor_full.komisi_deposito,
    sisa_komisi_order5_amor_full.kredit,
        CASE
            WHEN sisa_komisi_order5_amor_full.kredit IS NULL THEN 0::numeric
            ELSE sisa_komisi_order5_amor_full.kredit
        END AS sum_kredit,
        CASE
            WHEN sisa_komisi_order5_amor_full.kredit IS NULL THEN sisa_komisi_order5_amor_full.akhir_nilai_amor
            ELSE sisa_komisi_order5_amor_full.komisi_deposito - sisa_komisi_order5_amor_full.kredit
        END AS sisa,
        id_je
   FROM sisa_komisi_order5_amor_full
   join amor_etap using(id_dep);

ALTER TABLE public.sisa_komisi_order5_amor_full_sisa
  OWNER TO postgres;

-- View: public.sisa_komisi_order5_amor_full_sisa_perpanjangan

-- DROP VIEW public.sisa_komisi_order5_amor_full_sisa_perpanjangan;

CREATE OR REPLACE VIEW public.sisa_komisi_order5_amor_full_sisa_perpanjangan AS 
 SELECT DISTINCT sisa_komisi_order5_amor_full_sisa.sisa AS amor_bulanini,
    sisa_komisi_order5_amor_full_sisa.tgl_deposito_komisi,
    amor_etap.entry_date_ae,
    nasabah.nama_nas,
    deposito.bilyet_dep,
    amor_etap.id_ae,
    sisa_komisi_order5_amor_full_sisa.komisi_deposito,
    sisa_komisi_order5_amor_full_sisa.amor_terakhir,
    sisa_komisi_order5_amor_full_sisa.id_dk,
    sisa_komisi_order5_amor_full_sisa.id_dep
   FROM sisa_komisi_order5_amor_full_sisa
     JOIN amor_etap USING (id_dk)
     LEFT JOIN deposito USING (id_dk)
     JOIN reknas USING (id_rek)
     JOIN nasabah USING (id_nas)
     JOIN cif_nasabah USING (id_nas)
  ORDER BY sisa_komisi_order5_amor_full_sisa.id_dep;

ALTER TABLE public.sisa_komisi_order5_amor_full_sisa_perpanjangan
  OWNER TO postgres;

 

-- Function: public.ubah_dep()

-- DROP FUNCTION public.ubah_dep();

CREATE OR REPLACE FUNCTION public.ubah_dep()
  RETURNS trigger AS
$BODY$declare 

  sisa record;

  b numeric(7,4);

  batas numeric(15,2);

  acr numeric(15,2);

  xid int4;
 
  xjr int4;
  xjr1 int4;
  abc text;

  p record;

  d numeric(15,0);

  k numeric(15,0);

  kode text;

  aw date;

  cu date;

  bu numeric(15,2);

  nama text;
  skr date; 
begin
  skr := sekarang();
  select into nama nama_nas from nasabah join reknas using(id_nas) 

                                         join deposito using(id_rek) 

          where id_dep = new.id_dep;

-- perpanjangan deposito biasa

   select into batas bataspajakdep from company where id_com='1';

  if new.jenis_dep = 'K' and old.awal_dep <> new.awal_dep then

--    new.nilaibunga_dep := new.nilaiskr*new.bunga_dep/1200 * new.bln_dep;

--    new.bngperbulan := new.nilaiskr*new.bunga_dep/1200;

  -- generate perpanjangan di trans dep

--    new.ke_dep := new.ke_dep+1;

--    new.maturity_dep := new.awal_dep + (new.bln_dep::text||' mon')::interval;

    select into xid nextval('public.trans_deposito_id_xdep_seq');

    INSERT INTO trans_deposito 

     (id_dep, id_sandi,tgl_xdep,proses_xdep,del_xdep,

      bkt_xdep, nilai_xdep, bunga_xdep, id_bng,

      nilaibunga_xdep, trfbngke_xdep, maturity_xdep,

      tglvaluta_xdep, ket_xdep,ke_xdep, bln_xdep, 

      bngperbulan_xdep, id_xdep

     )    

   VALUES 

     (new.id_dep,'64',new.awal_dep,true,false,

      'D '||kanan(6::int2,new.bilyet_dep), new.nilaiskr,new.bunga_dep, new.id_bng,

      new.nilaiskr, new.trfbngke_dep, new.maturity_dep,

      new.tglvaluta_dep, 'Penempatan ke '||new.ke_dep::text, new.ke_dep-1, new.bln_dep, 

      new.bngperbulan, xid

     );

  -- generate bunga di transdep

    b := 0;

    if new.nilaiskr > batas then

      select into b pajakdep from company where id_com='1';

    end if;

    aw := sekarang();

    cu := aw;

--    acr := round(lastday(sekarang())::float*new.bngperbulan/extract(day from akhirbulan(sekarang())));

    for i in 1 .. new.bln_dep loop

      cu := cu + '1 mon'::interval;

      bu := (cu - aw)*new.bunga_dep*new.nilaiskr/36500;

      acr := round(lastday(cu)::float*bu/extract(day from akhirbulan(cu)));

--      INSERT INTO trans_deposito /*accrue*/

--       (id_dep, id_sandi,tgl_xdep, proses_xdep, del_xdep,

--        bkt_xdep, nilai_xdep, bunga_xdep,

--        id_bng,trfbngke_xdep, pajak_xdep,

--        ket_xdep,ke_xdep, nilaibunga_xdep

--       )    

--      VALUES 

--      (new.id_dep,'67',akhirbulan((new.awal_dep+((i-1)::text||' mon')::interval)::date),false,false,

--       'D '||kanan(6::int2,new.bilyet_dep), acr, new.bunga_dep,

--       new.id_bng, new.trfbngke_dep, acr*b/100,

--      'Accrue Bunga Deposito', i, bu

--      );

      INSERT INTO trans_deposito /*bunga */

       (id_dep, id_sandi,tgl_xdep, proses_xdep, del_xdep,

        nilai_xdep, bunga_xdep,

        id_bng,trfbngke_xdep, pajak_xdep,

        ket_xdep,ke_xdep

       )    

      VALUES 

      (new.id_dep,'62',new.awal_dep+(i::text||' mon')::interval,false,false,

       bu-acr, new.bunga_dep,

       new.id_bng, new.trfbngke_dep, (bu-acr)*b/100,

      'Bunga Deposito', i

      );

      aw := aw + '1 mon'::interval;

    end loop;

-- transaksi keuangan perpanjangan deposito

    kode:='64';

    select into xjr nextval('public.transjr_id_jr_seq');

    insert into transjr

      (id_com,tglbuku_jr,ket_jr,bukti_jr,

       asal_jr,kegiatan_id,acc_jr,id_jr

      )

     values

     ('1',sekarang()::date,'Perpanjangan Deposito '||new.bilyet_dep::text ||'   ' , 'D '||kanan(6::int2,new.bilyet_dep),

       'D',xid,true,xjr
 

      );
       
     

       
 
   if old.tgl_komisi_Dep is not null then 
      select into sisa    amor_bulanini, tgl_deposito_komisi, entry_date_ae, nama_nas, bilyet_dep,
     id_ae, id_dep,amor_terakhir
   from sisa_komisi_order5_amor_full_sisa_perpanjangan
   where id_dep = new.id_dep ;
 
 
    select into xjr1 nextval('public.transjr_id_jr_seq');
       abc := no_ledger('77');

       insert into transjr

      (id_com,tglbuku_jr,ket_jr,bukti_jr, asal_jr,kegiatan_id,acc_jr,id_jr)

     values ('1',sekarang()::date,'Amortisasi Deposito ' ||  sisa.nama_nas || '/' || sisa.bilyet_dep::text || '   '  , abc,'D',xid,true,xjr1);

      
            insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
            values (xjr1,skr,1036,sisa.amor_terakhir,0,'System',true,'Amortisasi Deposito ' || 
            sisa.nama_nas || '/' || sisa.bilyet_dep ); 

            insert into jurnal_detil (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,entry_op_xdep, posted_djr,ket_djr) 
            values (xjr1,skr,984,0,sisa.amor_terakhir,'System',true,'Amortisasi Deposito ' || 
            sisa.nama_nas || '/' || sisa.bilyet_dep ); 
        
end if; 

     FOR p IN select id_coa,tab_prs,dk_prs,field_prs,ref_prs from proses where id_sandi = kode order by dk_prs LOOP

        k :=0;

        d :=0;

        if p.dk_prs = 'K' then

          k:= hitisi('D'::text,xid::int4,1::int2);

        else

          d:= hitisi('D'::text,xid::int4,1::int2);

        end if;

        insert into jurnal_detil

         (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,ket_djr,posted_djr,ref

         )

         values

         (xjr,sekarang(),p.id_coa,d,k,'Perpanjangan '||new.bln_dep::text||' Bln/ '||nama,true,p.ref_prs

         );

     END LOOP;

-- selesai transaksi keuangan perpanjangan deposito

  end if;

-- perpanjangan aro, awal_dep (saja) diubah oleh tutup hari secara otomatis

  if new.jenis_dep = 'A' and old.awal_dep <> new.awal_dep then

   if new.bln_dep > 1 then

      raise exception 'Untuk ARO jangka waktu harus 1 Bln';

    end if;

  -- ubah data di dep

    b := 0;

    if new.nilaiskr > batas then

      select into b pajakdep from company where id_com='1';

    end if;

--**    new.nilaiskr := old.nilaiskr+old.nilaibunga_dep*(1-b/100); /* dikurangi pajak */

--**    new.maturity_dep := new.awal_dep + (new.bln_dep::text||' mon')::interval;

--**    b:=bungadepo(old.nilaiskr,old.bln_dep);

 --   select into b bngdepo1_com from company where id_com='1';

--**    new.bunga_dep := b;

--**    new.nilaibunga_dep := round(new.nilaiskr*new.bunga_dep/1200*new.bln_dep);

--**    new.bngperbulan := round(new.nilaiskr*new.bunga_dep/1200);

--**    new.tglvaluta_dep := new.awal_dep;

--    new.ke_dep := new.ke_dep +1;

  -- generate transaksi penutupan di transdep (historis) --> tidak perlu 20 nov 06

--*    kode='66';

--*    select into xid nextval('public.trans_deposito_id_xdep_seq');

--*    INSERT INTO trans_deposito 

--*     (id_dep, id_sandi,tgl_xdep,proses_xdep,del_xdep,

--*      bkt_xdep, nilai_xdep,

--*      tglvaluta_xdep, ket_xdep,ke_xdep,

--*      id_xdep

--*     )    

--*   VALUES 

--*     (new.id_dep,kode,new.awal_dep,true,false,

--*      no_bukti(kode), old.nilaiskr,

--*      new.tglvaluta_dep, 'Jatuh Tempo ', new.ke_dep-1, 

--*      xid

--*     );

  -- transaksi keuangan tutup aro

--*    kode:='66';

--*    select into xjr nextval('public.transjr_id_jr_seq');

--*    insert into transjr

--*      (id_com,tglbuku_jr,ket_jr,bukti_jr,

--*       asal_jr,kegiatan_id,acc_jr,id_jr

--*      )

--*     values

--*      ('1',sekarang()::date,'Penutupan untuk perpanjangan ARO Bilyet : '||new.bilyet_dep, no_ledger(kode),

--*       'D',xid,true,xjr

--*      );

 --*    FOR p IN select id_coa,tab_prs,dk_prs,field_prs from proses where id_sandi = kode order by dk_prs LOOP

--*        k :=0;

--*        d :=0;

--*        if p.dk_prs = 'K' then

--*          k:= hitisi('D'::text,xid::int4,1::int2);

--*        else

--*          d:= hitisi('D'::text,xid::int4,1::int2);

--*        end if;

--*        insert into jurnal_detil

--*         (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr

--*         )

--*         values

--*         (xjr,sekarang(),p.id_coa,d,k

--*         );

--*     END LOOP;

  -- generate transaksi perpanjangan di transdep (historis)

    kode ='68';

    select into xid nextval('public.trans_deposito_id_xdep_seq');

    INSERT INTO trans_deposito 

     (id_dep, id_sandi,tgl_xdep,proses_xdep,del_xdep,

      bkt_xdep, nilai_xdep, bunga_xdep, id_bng,

      nilaibunga_xdep, trfbngke_xdep, maturity_xdep,

      tglvaluta_xdep, ket_xdep,ke_xdep, bln_xdep, 

      bngperbulan_xdep, id_xdep

     )    

   VALUES 

     (new.id_dep,kode,new.awal_dep,true,false,

      no_bukti(kode), new.nilaiskr,new.bunga_dep, new.id_bng,

      new.nilaiskr, new.trfbngke_dep, new.maturity_dep,

      new.tglvaluta_dep, 'Perpanjangan ARO ke '||new.ke_dep::text, new.ke_dep-1, new.bln_dep, 

      new.bngperbulan, xid

     );

  -- transaksi keuangan perpanjangan aro

    kode:='68';

    select into xjr nextval('public.transjr_id_jr_seq');

    insert into transjr

      (id_com,tglbuku_jr,ket_jr,bukti_jr,

      asal_jr,kegiatan_id,acc_jr,id_jr

      )

     values

      ('1',sekarang()::date,'Perpanjangan Deposito Bilyet : '||kanan(6::int2,new.bilyet_dep), 

       'D '||kanan(6::int2,new.bilyet_dep),

       'D',xid,true,xjr

      );

     FOR p IN select id_coa,tab_prs,dk_prs,field_prs,ref_prs from proses where id_sandi = kode order by urut_prs LOOP

        k :=0;

        d :=0;

        if p.dk_prs = 'K' then

          if p.field_prs = 5 then /* keadaan khusus untuk perpanjangan aro, perlu data dari

                                 bunga yang lalu, karena akan digabungkan dengan saldo lama

                                 menjadi saldo baru ( nilaiskr) */

--            k:= old.nilaibunga_dep*(1-b/100); /* dikurangi bunga */

            k:= new.nilaiskr - old.nilaiskr; /* net setelah dikurangi pajak */

          elsif p.field_prs = 6 then /*saldo lalu*/

            k:= old.nilaiskr;

          elsif p.field_prs = 7 then /* Bunga+Saldo Lalu*/

            k:= new.nilaiskr ;

--            k:= old.nilaiskr + old.nilaibunga_dep*(1-b/100);

          else

            k:= hitisi('D'::text,xid::int4,p.field_prs::int2);

          end if;

        else

          if p.field_prs = 5 then /* keadaan khusus untuk perpanjangan aro, perlu data dari

                                 bunga yang lalu, karena akan digabungkan dengan saldo lama

                                 menjadi saldo baru ( nilaiskr) */

--            d:= old.nilaibunga_dep*(1-b/100);

            d:= new.nilaiskr - old.nilaiskr;

          elsif p.field_prs = 6 then /*saldo lalu*/

            d:= old.nilaiskr;

          elsif p.field_prs = 7 then /* Bunga+Saldo Lalu*/

            d:= new.nilaiskr ;

--            d:= old.nilaiskr + old.nilaibunga_dep*(1-b/100);

          else

            d:= hitisi('D'::text,xid::int4,p.field_prs::int2);

          end if;

        end if;

        insert into jurnal_detil

         (id_jr,tgl_djr,id_coa,debet_djr,kredit_djr,ket_djr,posted_djr,ref

         )

         values

         (xjr,sekarang(),p.id_coa,d,k,'Perpanjangan (A) 1 Bln/ '||nama,true,p.ref_prs

         );

     END LOOP;

  -- generate 1 bunga di transdep

    acr := round(lastday(sekarang())::float/extract(day from akhirbulan(sekarang()))*new.bngperbulan);

    for i in 1 .. new.bln_dep loop

--      INSERT INTO trans_deposito /* accrue */

--       (id_dep, id_sandi,tgl_xdep, proses_xdep, del_xdep,

--        bkt_xdep, nilai_xdep, bunga_xdep,

--        id_bng,trfbngke_xdep, pajak_xdep,

--        ket_xdep,ke_xdep,nilaibunga_xdep

--       )    

--      VALUES 

--      (new.id_dep,'67',akhirbulan((new.awal_dep+((i-1)::text||' mon')::interval)::date),false,false,

--       no_bukti('67'), acr, new.bunga_dep,

--       new.id_bng, new.trfbngke_dep, acr*b/100,

--      'Bunga Deposito ARO', i, new.bngperbulan

--      );

      INSERT INTO trans_deposito /*bunga */

       (id_dep, id_sandi,tgl_xdep, proses_xdep, del_xdep,

        nilai_xdep, bunga_xdep,

        id_bng,trfbngke_xdep, 

        ket_xdep,ke_xdep

       )    

     VALUES 

      (new.id_dep,'65',new.awal_dep+(i::text||' mon')::interval,false,false,

       new.bngperbulan-acr, new.bunga_dep,

       new.id_bng, new.trfbngke_dep, 

      'Bunga Deposito ARO', i

      );

/*

      INSERT INTO trans_deposito

       (id_dep, id_sandi,tgl_xdep, proses_xdep, del_xdep,

        bkt_xdep, nilai_xdep, bunga_xdep,

        id_bng,trfbngke_xdep, pajak_xdep,

        ket_xdep,ke_xdep

       )    

      VALUES 

      (new.id_dep,'65',new.awal_dep+(i::text||' mon')::interval,false,false,

       no_bukti('DA'), new.bngperbulan, new.bunga_dep,

       new.id_bng, new.trfbngke_dep, new.bngperbulan*b/100,

      'Bunga Deposito ARO', i

      );

*/

    end loop;

  end if;

-- penutupan hanya untuk penutupan aro karena aro sebenarnya  ditutup dan diperpanjang

-- dengan nilai yang baru.

-- aro ditutup dengan cara active_dep -> false. maka tutup hari tidak akan mengubah

-- awal_dep baru. jadi aro tidak diperpanjang lagi. Ini transaksi masa depan untuk 

-- penutupannya (pada maturit date).

-- yang diatas tidak berlaku lagi, jadi ini adalah transaksi jika terjadi perubahan active dari true ke false untuk

-- semua deposito

--  if new.jenis_dep = 'A' and new.active_dep = false and old.active_dep = true then

  if new.active_dep = false and old.active_dep = true then

     update trans_deposito set del_xdep = true where id_dep = new.id_dep and tgl_xdep >= sekarang();

--    kode = '66';

--    INSERT INTO trans_deposito

--     (id_dep, id_sandi,tgl_xdep,proses_xdep,del_xdep,

--      bkt_xdep, ket_xdep,ke_xdep, nilai_xdep

--     )    

--    VALUES 

--     (new.id_dep,kode,new.maturity_dep,false,false,

--      no_bukti(kode), 'Pencairan Deposito', new.ke_dep, new.nilaiskr+new.bngperbulan

--     );

  end if;

  update reknas set sldtab_rek = new.nilaiskr where id_rek = new.id_rek;

  if old.active_dep = true and new.active_dep = false then

    new.tglbreak_dep = now(); 

  end if;
  if old.komisi_deposito is null and new.komisi_deposito is not null then
    new.tgl_komisi_dep := skr;
  end if;
  return new;

end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.ubah_dep()
  OWNER TO bprdba;
COMMENT ON FUNCTION public.ubah_dep() IS 'untuk ubah deposiso (perpanjangan dan penutupan ARO)';
 