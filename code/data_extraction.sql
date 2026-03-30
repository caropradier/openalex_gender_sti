----description---------

----prop with gender data by year (tab: gender_data_year)

with gender_data as (
 SELECT ww.publication_year, count(distinct w.work_id) as with_gender
 FROM `insyspo.publicdb_openalex_2025_08_rm.works_authorships` as w
 LEFT JOIN `multiobs.userdb_carolina_pradier.openalex_gender` as g on w.author_id = g.author_id
 LEFT JOIN `insyspo.publicdb_openalex_2025_08_rm.works` as ww on w.work_id = ww.id
 inner join `multiobs.userdb_carolina_pradier.openalex_eligible` as e on ww.id = e.id
 where  (g.gender = 'Women' or g.gender = 'Men') 
 GROUP BY ww.publication_year),

  total_works AS (  
  SELECT publication_year, count(distinct ww.id) as total_works
  FROM `insyspo.publicdb_openalex_2025_08_rm.works_authorships` as w
  LEFT JOIN `insyspo.publicdb_openalex_2025_08_rm.works` as ww on w.work_id = ww.id
  inner join `multiobs.userdb_carolina_pradier.openalex_eligible` as e on ww.id = e.id
  GROUP BY publication_year)

SELECT t.publication_year, t.total_works, g.with_gender,
       g.with_gender / t.total_works as gender_ratio
FROM total_works as t
LEFT JOIN gender_data as g on t.publication_year = g.publication_year
  ORDER BY t.publication_year desc;

---fractional gender by year (tab: gender_frac_year)

with gender_counts AS (
SELECT  ww.publication_year, gender, sum(frac_contrib) as work_count
FROM `multiobs.userdb_carolina_pradier.openalex_gender_fractional` as gf
LEFT JOIN `insyspo.publicdb_openalex_2025_08_rm.works` as ww on gf.work_id = ww.id
 inner join `multiobs.userdb_carolina_pradier.openalex_eligible` as e on ww.id = e.id
GROUP BY ww.publication_year, gender),

  total_works AS (
  SELECT ww.publication_year, sum(frac_contrib) as total_work_count
  FROM `multiobs.userdb_carolina_pradier.openalex_gender_fractional` as gf
  LEFT JOIN `insyspo.publicdb_openalex_2025_08_rm.works` as ww on gf.work_id = ww.id
   inner join `multiobs.userdb_carolina_pradier.openalex_eligible` as e on ww.id = e.id
  GROUP BY ww.publication_year
  )

SELECT c.publication_year,c.gender, c.work_count, t.total_work_count, c.work_count/t.total_work_count as prop_works
FROM gender_counts c
left join total_works t on c.publication_year = t.publication_year
ORDER BY c.publication_year desc

 ---fractional gender by year and discipline (tab: dis_frac_year)

 WITH  gender_counts AS (
SELECT  ww.publication_year, gender,d.domain, sum(frac_contrib) as work_count
FROM `multiobs.userdb_carolina_pradier.openalex_gender_fractional` as gf
LEFT JOIN `insyspo.publicdb_openalex_2025_08_rm.works` as ww on gf.work_id = ww.id
LEFT JOIN `multiobs.userdb_carolina_pradier.openalex_main_domain` as d on ww.id = d.id
inner join `multiobs.userdb_carolina_pradier.openalex_eligible` as e on ww.id = e.id
GROUP BY ww.publication_year, gender, d.domain),

  total_works AS (
  SELECT ww.publication_year, d.domain, sum(frac_contrib) as total_work_count
  FROM `multiobs.userdb_carolina_pradier.openalex_gender_fractional` as gf
  LEFT JOIN `insyspo.publicdb_openalex_2025_08_rm.works` as ww on gf.work_id = ww.id
  LEFT JOIN `multiobs.userdb_carolina_pradier.openalex_main_domain` as d on ww.id = d.id
  inner join `multiobs.userdb_carolina_pradier.openalex_eligible` as e on ww.id = e.id
  GROUP BY ww.publication_year, d.domain
  )

SELECT c.publication_year,c.gender, c.domain, c.work_count, t.total_work_count, c.work_count/t.total_work_count as prop_works
FROM gender_counts c
left join total_works t on c.publication_year = t.publication_year and c.domain = t.domain
ORDER BY c.publication_year desc

    ---fractional gender by country and year (tab: country_frac_year)

  WITH  gender_counts AS (
SELECT  ww.publication_year, gender,country, sum(frac_contrib) as work_count
FROM `multiobs.userdb_carolina_pradier.openalex_gender_country_fractional` as gf
LEFT JOIN `insyspo.publicdb_openalex_2025_08_rm.works` as ww on gf.work_id = ww.id
inner join `multiobs.userdb_carolina_pradier.openalex_eligible` as e on ww.id = e.id
GROUP BY  ww.publication_year, gender, country),

  total_works AS (
  SELECT ww.publication_year, country, sum(frac_contrib) as total_work_count
  FROM `multiobs.userdb_carolina_pradier.openalex_gender_country_fractional` as gf
  LEFT JOIN `insyspo.publicdb_openalex_2025_08_rm.works` as ww on gf.work_id = ww.id
  inner join `multiobs.userdb_carolina_pradier.openalex_eligible` as e on ww.id = e.id
  GROUP BY  ww.publication_year,country
  )

SELECT c.publication_year,c.gender, c.country, c.work_count, t.total_work_count, c.work_count/t.total_work_count as prop_works
FROM gender_counts c
left join total_works t on  c.country = t.country and c.publication_year = t.publication_year

----aux citations-------

CREATE OR REPLACE TABLE `multiobs.userdb_carolina_pradier.openalex_citation_norm_year_field_gender_from_raw` AS
WITH cit_count AS (
  SELECT
    wr.referenced_work_id AS cited_work_id,
    COUNT(DISTINCT wr.work_id) AS citations
  FROM `insyspo.publicdb_openalex_2025_08_rm.works_referenced_works` wr
  LEFT JOIN insyspo.publicdb_openalex_2025_08_rm.works as cited ON wr.referenced_work_id = cited.id 
  LEFT JOIN insyspo.publicdb_openalex_2025_08_rm.works as citing ON wr.work_id = citing.id
    WHERE citing.publication_year BETWEEN cited.publication_year AND cited.publication_year + 3
  GROUP BY wr.referenced_work_id
)
SELECT 
  w.publication_year,
  f.field,
  AVG(COALESCE(cc.citations, 0)) AS avg_citations
FROM `insyspo.publicdb_openalex_2025_08_rm.works` w
LEFT JOIN cit_count cc 
  ON w.id = cc.cited_work_id
LEFT JOIN `multiobs.userdb_carolina_pradier.openalex_main_field` f 
  ON w.id = f.id
INNER JOIN `multiobs.userdb_carolina_pradier.openalex_eligible` e 
  ON w.id = e.id
INNER JOIN `multiobs.userdb_carolina_pradier.openalex_gender_fractional` gf 
  ON w.id = gf.work_id
WHERE f.field IS NOT NULL
GROUP BY w.publication_year, f.field;


-------region level citations--------

----first author (fwci_first_author_region)

with normalized_citations AS (
  WITH cit_count AS (
  SELECT
    wr.referenced_work_id AS cited_work_id,
    COUNT(DISTINCT wr.work_id) AS citations
  FROM `insyspo.publicdb_openalex_2025_08_rm.works_referenced_works` wr
  LEFT JOIN insyspo.publicdb_openalex_2025_08_rm.works as cited ON wr.referenced_work_id = cited.id 
  LEFT JOIN insyspo.publicdb_openalex_2025_08_rm.works as citing ON wr.work_id = citing.id
    WHERE citing.publication_year BETWEEN cited.publication_year AND cited.publication_year + 3
  GROUP BY wr.referenced_work_id
)
SELECT 
  w.id,
  w.publication_year,
  SAFE_DIVIDE(COALESCE(cc.citations, 0), norm.avg_citations) AS norm_citations
FROM `insyspo.publicdb_openalex_2025_08_rm.works` w
LEFT JOIN cit_count cc 
  ON w.id = cc.cited_work_id
LEFT JOIN `multiobs.userdb_carolina_pradier.openalex_main_field` f 
  ON w.id = f.id
INNER JOIN `multiobs.userdb_carolina_pradier.openalex_eligible` e 
  ON w.id = e.id
INNER JOIN `multiobs.userdb_carolina_pradier.openalex_gender_fractional` gf 
  ON w.id = gf.work_id
left join `multiobs.userdb_carolina_pradier.openalex_citation_norm_year_field_gender_from_raw` as norm 
on norm.publication_year = w.publication_year and norm.field = f.field
WHERE f.field IS NOT NULL
)
select nc.publication_year, continent, gf.gender, sum(norm_citations * gf.frac_contrib) / sum(gf.frac_contrib) as weighted_avg_norm_citations
from normalized_citations as nc
left join `multiobs.userdb_carolina_pradier.openalex_gender_fractional` as gf on nc.id = gf.work_id
left join `multiobs.userdb_carolina_pradier.openalex_main_domain` as d on nc.id = d.id
LEFT JOIN `insyspo.publicdb_openalex_2025_08_rm.works_authorships` AS wa ON nc.id = wa.work_id
LEFT JOIN `multiobs.userdb_carolina_pradier.openalex_author_continent` as ac ON wa.author_id = ac.author_id
WHERE ac.continent is not null and wa.author_order = 1
and gf.frac_contrib is not null and norm_citations is not null
group by gf.gender, nc.publication_year, continent


----general gap (fwci_gap_nodisag)------

with normalized_citations AS (
  WITH cit_count AS (
  SELECT
    wr.referenced_work_id AS cited_work_id,
    COUNT(DISTINCT wr.work_id) AS citations
  FROM `insyspo.publicdb_openalex_2025_08_rm.works_referenced_works` wr
  LEFT JOIN insyspo.publicdb_openalex_2025_08_rm.works as cited ON wr.referenced_work_id = cited.id 
  LEFT JOIN insyspo.publicdb_openalex_2025_08_rm.works as citing ON wr.work_id = citing.id
    WHERE citing.publication_year BETWEEN cited.publication_year AND cited.publication_year + 3
  GROUP BY wr.referenced_work_id
)
SELECT 
  w.id,
  w.publication_year,
  SAFE_DIVIDE(COALESCE(cc.citations, 0), norm.avg_citations) AS norm_citations
FROM `insyspo.publicdb_openalex_2025_08_rm.works` w
LEFT JOIN cit_count cc 
  ON w.id = cc.cited_work_id
LEFT JOIN `multiobs.userdb_carolina_pradier.openalex_main_field` f 
  ON w.id = f.id
INNER JOIN `multiobs.userdb_carolina_pradier.openalex_eligible` e 
  ON w.id = e.id
INNER JOIN `multiobs.userdb_carolina_pradier.openalex_gender_fractional` gf 
  ON w.id = gf.work_id
left join `multiobs.userdb_carolina_pradier.openalex_citation_norm_year_field_gender_from_raw` as norm 
  on norm.publication_year = w.publication_year and norm.field = f.field
WHERE f.field IS NOT NULL
)
select nc.publication_year, gf.gender, sum(norm_citations * gf.frac_contrib) / sum(gf.frac_contrib) as weighted_avg_norm_citations
from normalized_citations as nc
left join `multiobs.userdb_carolina_pradier.openalex_gender_fractional` as gf on nc.id = gf.work_id
where gf.frac_contrib is not null and norm_citations is not null
group by gf.gender, nc.publication_year


----references------------------

  -----gendered_references_year_homophily_field.csv

    SELECT
  i.country,
  g.gender as citing_gender,
  gf.gender as cited_gender,
  citing.publication_year ,
  f.field as citing_field,
  sum(gf.frac_contrib) as n_works
FROM `insyspo.publicdb_openalex_2025_08_rm.works_referenced_works` wr
  LEFT JOIN insyspo.publicdb_openalex_2025_08_rm.works as cited ON wr.referenced_work_id = cited.id 
  LEFT JOIN insyspo.publicdb_openalex_2025_08_rm.works as citing ON wr.work_id = citing.id
  ---eligible citing documents
  INNER JOIN `multiobs.userdb_carolina_pradier.openalex_eligible` e ON citing.id = e.id
  ----gender of the cited document
  INNER JOIN `multiobs.userdb_carolina_pradier.openalex_gender_fractional` gf ON cited.id = gf.work_id
  ---continent and gender of the citing document
  left JOIN `multiobs.userdb_carolina_pradier.openalex_main_field` as f on citing.id = f.id
  LEFT JOIN `insyspo.publicdb_openalex_2025_08_rm.works_authorships` AS wa ON citing.id = wa.work_id
  LEFT JOIN `insyspo.publicdb_openalex_2025_08_rm.institutions` AS i ON wa.institution_id = i.id
  LEFT JOIN `multiobs.userdb_carolina_pradier.openalex_gender` as g on wa.author_id = g.author_id
  WHERE i.country is not null and wa.author_order = 1 and citing.publication_year <2025
  and (g.gender = 'Women' or g.gender = 'Men')
  group by i.country,gf.gender, citing.publication_year, g.gender, f.field 


  ---aux weights (weights_references_norm.csv)
     SELECT
  i.country,
  citing.publication_year ,
  gf.gender, 
  f.field as citing_field,
  sum(gf.frac_contrib) as n_works
FROM  insyspo.publicdb_openalex_2025_08_rm.works as citing 
  ---eligible citing documents
  INNER JOIN `multiobs.userdb_carolina_pradier.openalex_eligible` e ON citing.id = e.id
  ---continent and gender of the citing document
  left JOIN `multiobs.userdb_carolina_pradier.openalex_main_field` as f on citing.id = f.id
  LEFT JOIN `insyspo.publicdb_openalex_2025_08_rm.works_authorships` AS wa ON citing.id = wa.work_id
  LEFT JOIN `insyspo.publicdb_openalex_2025_08_rm.institutions` AS i ON wa.institution_id = i.id
  INNER JOIN `multiobs.userdb_carolina_pradier.openalex_gender_fractional` gf ON citing.id = gf.work_id
  WHERE i.country is not null and wa.author_order = 1 and citing.publication_year <2025
  group by i.country,gf.gender, citing.publication_year, f.field 