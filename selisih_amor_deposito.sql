 

  
CREATE OR REPLACE VIEW public.ke_Debet_xa AS 
select DISTINCT deposito.id_Dep,amor_etap.id_ae,
sum(debet_xa)as debet,
sum(kredit_xa)as kredit,sum(debet_xa) - sum(kredit_xa) AS selisih, 
((sum(debet_xa) - sum(kredit_xa))- sisa_amor_acc_deposito(deposito.id_Dep,'D'))*-1 as ke_Debet_xa
From  trans_amor
JOIN AMOR_ETAP USING(id_ae)
JOIN deposito USING(ID_dK)
where active_Dep and tgl_komisi_Dep is not null  
group by deposito.id_Dep,amor_etap.id_ae
order by sum(debet_xa) - sum(kredit_xa) asc;



CREATE OR REPLACE VIEW public.selisih_non_aktif AS 
select deposito.id_Dep,amor_etap.id_ae,sum(debet_xa)as debet,sum(kredit_xa) as kredit,sum(debet_xa)-sum(kredit_xa) as selisih
  FROM trans_amor
     JOIN amor_etap USING (id_ae) 
     JOIN deposito USING (id_dep)
     LEFT JOIN jurnal_detil USING (id_djr)
join deposito_komisi using (id_Dep)
where deposito.active_Dep = 'f'    
group by  deposito.id_Dep,amor_etap.id_ae ;
 
 
 
CREATE OR REPLACE VIEW public.selisih_non_aktif_1 AS 
select *,
case 
when selisih <0 then selisih * -1
else selisih end as selisih_sisa,
case
when selisih < 0 then 'debet_xa'
else 'kredit_xa' end as tujuan From selisih_non_aktif
where selisih <>0  ;
ALTER TABLE public.trans_amor
   ALTER COLUMN id_ae DROP NOT NULL;

-- Function: public.selisish_amor()

-- DROP FUNCTION public.select selisish_amor();

CREATE OR REPLACE FUNCTION public.selisish_amor()

  RETURNS integer AS
$BODY$declare
 
  acr_ke_Debet_xa record;
  acr_selisih_non_aktif_1 record; 
  je record; 
  skr date; 
  idae int4;

begin 
--  for acr_ke_Debet_xa in select id_ae,debet  from ke_Debet_xa where selisih < 0
--   loop  
--     insert into trans_amor(id_djr,id_ae,debet_xa) values (6046527,acr_ke_Debet_xa.id_ae,acr_ke_Debet_xa.debet); 
--   end loop;
--   return 1;
-- 
-- 
-- for acr_selisih_non_aktif_1 in select id_ae,selisih_sisa  from selisih_non_aktif_1
--   loop   
--     if acr_selisih_non_aktif_1.tujuan = 'debet_xa' then
--       insert into trans_amor(id_Djr,id_ae,debet_xa) 
--       values (6046527,acr_selisih_non_aktif_1.id_ae,acr_selisih_non_aktif_1.selisih_sisa) ;
--   
--      else if acr_selisih_non_aktif_1.tujuan = 'kredit_xa' then
--       insert into trans_amor(id_Djr,id_ae,kredit_xa) 
--       values (6046528,acr_selisih_non_aktif_1.id_ae,acr_selisih_non_aktif_1.selisih_sisa) ;
--      
--     end if;
--     end if;
--   end loop;

  insert into trans_amor(id_Djr,id_ae,debet_xa) values (6045104,null,97728); 
  insert into trans_amor(id_Djr,id_ae,kredit_xa) values (6045105,null,97728); 
  return 1;

end; -- end of selisish_amor()

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.selisish_amor()
  OWNER TO postgres;
