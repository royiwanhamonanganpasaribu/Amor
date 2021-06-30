-- View: public.lebih_trans_amor

-- DROP VIEW public.lebih_trans_amor;

CREATE OR REPLACE VIEW public.lebih_trans_amor AS 
 SELECT trans_amor.id_ae,
    sum(trans_amor.debet_xa) AS sum_debet_xa,
    sum(trans_amor.kredit_xa) AS sum_kredit_xa,
    sum(trans_amor.debet_xa) - sum(trans_amor.kredit_xa) AS lebih_trans_amor
   FROM trans_amor
     JOIN amor_etap USING (id_ae)
     JOIN deposito USING (id_dep)
  GROUP BY trans_amor.id_ae;

ALTER TABLE public.lebih_trans_amor
  OWNER TO postgres;


-- Function: public.lebih_trans_amor()

-- DROP FUNCTION public. select lebih_trans_amor();

CREATE OR REPLACE FUNCTION public.lebih_trans_amor()
  RETURNS integer AS
$BODY$declare
 
  acr record; 
  je record; 
  skr date; 
  idae int4;

begin 
	for acr in select  maturity_Dep,lebih_trans_amor.*, lebih_trans_amor*-1 as positif 
		from lebih_trans_amor 
  			join amor_etap using(id_ae)
			join deposito using(id_Dk)
		where maturity_Dep <= sekarang() and lebih_trans_amor < 0 
		order by maturity_Dep asc

  loop  
    insert into trans_amor(id_ae,id_djr,debet_xa) values (acr.id_ae,6038827,acr.positif);
  end loop;

	 for acr in select  maturity_Dep,lebih_trans_amor.*, lebih_trans_amor*-1 as positif 
		from lebih_trans_amor 
  			join amor_etap using(id_ae)
			join deposito using(id_Dk)
		where maturity_Dep <= sekarang() and lebih_trans_amor > 0 
		order by maturity_Dep asc


  loop  
    insert into trans_amor(id_ae,id_djr,kredit_xa) values (acr.id_ae,6038828,acr.lebih_trans_amor);
  end loop;

	 for acr in select distinct lebih_trans_amor.*, lebih_trans_amor*-1 as positif
		from  lebih_trans_amor 
			join trans_amor using(id_ae)
			join amor_etap using(id_ae)
			join deposito using(id_Dk)
		where  maturity_Dep >= sekarang() and lebih_trans_amor < 0    

  loop  
    insert into trans_amor(id_ae,id_djr,debet_xa) values (acr.id_ae,6038827,acr.positif);
  end loop;


 return 1;
end; -- end of lebih_trans_amor()

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.lebih_trans_amor()
  OWNER TO bprdba;
