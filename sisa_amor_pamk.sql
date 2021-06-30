 
-- View: public.sisa_amor_pamk

-- DROP VIEW public.sisa_amor_pamk;

CREATE OR REPLACE VIEW public.sisa_amor_pamk AS 
 SELECT amor_etap.id_krd, 
    kredit.akta_krd,
    amor_etap.id_je,
        CASE
            WHEN amor_etap.id_je::text = 'P'::text THEN sisa_amor_acc(kredit.id_krd, 'P')
            WHEN amor_etap.id_je::text = 'A'::text THEN sisa_amor_acc(kredit.id_krd, 'A')
            WHEN amor_etap.id_je::text = 'M'::text THEN sisa_amor_acc(kredit.id_krd, 'M')
            WHEN amor_etap.id_je::text = 'K'::text THEN sisa_amor_acc(kredit.id_krd, 'K')
            ELSE NULL::numeric
        END AS sisa
   FROM amor_etap
     JOIN kredit USING (id_krd)
  WHERE kredit.active_krd
  ORDER BY amor_etap.id_krd;

ALTER TABLE public.sisa_amor_pamk
  OWNER TO postgres;

 