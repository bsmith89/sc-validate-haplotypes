CREATE TEMP VIEW snp_tally AS
SELECT
  species_id
, COUNT(species_position) AS position_tally
FROM snp
GROUP BY species_id
;

CREATE TEMP VIEW species_x_lib AS
SELECT
  species_id
, lib_id
, (1.0 * (reference_tally + alternative_tally)) / position_tally AS mean_depth
FROM snp_x_lib
JOIN lib USING (lib_id)
JOIN snp_tally USING (species_id)
GROUP BY species_id, sample_id
;

SELECT
  lib_id
, species_id
, mean_depth
, (1.0 * mean_depth) / total_depth AS rabund
FROM species_x_lib
JOIN (
  SELECT lib_id, SUM(mean_depth) AS total_depth FROM species_x_lib GROUP BY lib_id
  ) USING (lib_id)
WHERE lib_id LIKE '%.m'
ORDER BY rabund DESC
;
--  lib_type = 'metagenome'
--   AND sample_id in ('SS01009', 'SS01057')

