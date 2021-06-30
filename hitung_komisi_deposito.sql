

CREATE OR REPLACE VIEW public.selisih_amor AS
select distinct id_djr,id_Dep, debet_xa, kredit_xa 
from trans_amor 
      join amor_etap using (id_ae)
      join deposito using (id_dep)
  
order by id_Dep;


CREATE OR REPLACE VIEW public.selisih_amor1 AS
select id_Dep, debet_xa,sum(kredit_xa) as sum_kredit_xa
from selisih_amor  
GROUP BY id_Dep,debet_xa;

CREATE OR REPLACE VIEW public.selisih_amor2 AS
select  id_Dep,sum_kredit_xa  
From selisih_amor1 
WHERE    sum_kredit_xa <> 0
GROUP BY  id_Dep ,sum_kredit_xa;

CREATE OR REPLACE VIEW public.selisih_amor3 AS
select  id_Dep,debet_xa  From selisih_amor1 where DEBET_XA <> 0 ;
 
CREATE OR REPLACE VIEW public.selisih_amor4 AS
SELECT ID_DEP, DEBET_XA,SUM_KREDIT_XA,DEBET_XA-  SUM_KREDIT_XA AS SISA
FROM selisih_amor3
JOIN selisih_amor2 USING(ID_dEP) 
ORDER BY DEBET_XA-  SUM_KREDIT_XA;


CREATE OR REPLACE VIEW public.selisih_amor5 AS
select id_Dep, sum (debet_xa)as debet_xa , sum(sum_kredit_xa)as sum_kredit_xa ,sum(sisa) as sisa
From selisih_amor4 
where debet_xa  < sum_kredit_xa      
 group by id_Dep
order by id_dep  ;

CREATE OR REPLACE VIEW public.selisih_amor6 AS
select id_Dep, sum (debet_xa)as debet_xa , sum(sum_kredit_xa)as sum_kredit_xa ,sum(sisa) as sisa
From selisih_amor4 
where debet_xa  > sum_kredit_xa      
 group by id_Dep
order by id_dep;

 
CREATE OR REPLACE VIEW public.hitung_komisi_deposito1 AS
 select
id_Dep,amor_per_bln,amor_terakhir,bln_dep,   
(hitung_komisi_deposito.maturity_dep - sekarang())  as sisa_hari ,
awal_Dep,maturity_dep,  sekarang()
from hitung_komisi_deposito; --  where id_Dep = 19336

 
 CREATE OR REPLACE VIEW public.hitung_komisi_deposito2 AS
select * ,
case 
    when sisa_hari <= 31 then 1
    when sisa_hari % 30 = 0 then  (sisa_hari /30)  
    when sisa_hari % 30 <> 0 then  (sisa_hari /30) +1 
end as sisa_bulan,
 to_char(hitung_komisi_deposito1.awal_Dep, 'dd')tanggal_awal_Dep,to_char(sekarang, 'dd') as tanggal_sekarang
From hitung_komisi_deposito1 ;


CREATE OR REPLACE VIEW public.hitung_komisi_deposito3 AS
SELECT hitung_komisi_deposito2.*,  bln_dep - sisa_bulan as bln_lewat
from hitung_komisi_deposito2;



CREATE OR REPLACE VIEW public.hitung_komisi_deposito4 AS
SELECT hitung_komisi_deposito2.*,akhir_nilai_amor,
 CASE
            WHEN hitung_komisi_deposito2.bln_dep = sisa_bulan then akhir_nilai_amor
        when hitung_komisi_deposito2.bln_dep <> sisa_bulan and sisa_bulan = 0 THEN amor_terakhir
            WHEN hitung_komisi_deposito2.bln_dep <> sisa_bulan and sisa_bulan = 1 THEN amor_terakhir
             WHEN hitung_komisi_deposito2.bln_dep <> sisa_bulan and tanggal_awal_dep = tanggal_sekarang AND sisa_bulan >= 2 THEN amor_per_bln * (sisa_bulan - 1) + amor_terakhir
            WHEN hitung_komisi_deposito2.bln_dep <> sisa_bulan and tanggal_awal_dep <> tanggal_sekarang AND sisa_bulan >= 2 THEN (amor_per_bln * (sisa_bulan - 1)) + amor_terakhir
            ELSE NULL
        END AS sisa_amor
    
   FROM hitung_komisi_deposito2 
    join hitung_komisi4 using(id_dep);


CREATE OR REPLACE VIEW public.nomnal_tidak_keluar AS 
SELECT hitung_komisi_deposito4.*
   FROM hitung_komisi_deposito4  
 
join deposito using(id_dep)
where tgl_komisi_dep is not null ;



CREATE OR REPLACE VIEW public.nominal_tidak_keluar_trans_amor AS 
select   id_Dep,id_ae, sum(debet_xa) as debet_xa, sum(kredit_xa) as kredit_xa, sum(debet_xa) - sum(kredit_xa) as sisa
 from trans_amor 
       join amor_etap using(id_ae)
    join deposito using(id_Dep)
      join jurnal_Detil using (id_Djr)
      where  amor_etap.id_dk = deposito.id_Dk
group by id_Dep,id_ae
 
order by id_Dep;

  

CREATE OR REPLACE VIEW public.amor_aktif_masih_jln_ga_keluar AS 
select  distinct id_Dep, trans_amor.*,amor_etap.id_dk,bilyet_dep,awal_dep
from trans_amor 
      join amor_etap using (id_ae)
      join deposito using (id_dep)
      where 
    amor_etap.id_dk is not null and active_Dep;

CREATE OR REPLACE VIEW public.amor_aktif_masih_jln_ga_keluar_sisa AS 
select id_Dep,id_ae,id_dk,sum(debet_xa), sum(kredit_xa) as sum_kredit_xa , sum(debet_xa) - sum(kredit_xa) as sisa

from amor_aktif_masih_jln_ga_keluar
GROUP BY id_Dep,id_ae,id_dk

order by id_Dep;



CREATE OR REPLACE VIEW public.sisa_amor_acc_deposito12_1  AS
select distinct hitung_komisi_deposito4.* 
from hitung_komisi_deposito4
join deposito using(id_dep)
where active_dep and tgl_komisi_dep is not null   
order by id_dep;


CREATE OR REPLACE VIEW public.sisa_amor_acc_deposito12  AS  
select ID_dEP, sisa_amor_acc_deposito(id_dep,'D')
FROM DEPOSITO WHERE ACTIVE_DEP AND TGL_KOMISI_DEP IS NOT NULL 
order by id_dep;

SELECT sisa_amor_acc_deposito12.* 
fROM sisa_amor_acc_deposito12
JOIN sisa_amor_acc_deposito12_1 USING(ID_dEP)
WHERE sisa_amor_acc_deposito <> sisa_amor


-- 
-- select * from nomnal_tidak_keluar_trans_amor 353
-- 
-- select * From deposito where   tgl_komisi_Dep is not null 389
-- 
--  
-- SELECT   nomnal_tidak_keluar.* from nomnal_tidak_keluar 