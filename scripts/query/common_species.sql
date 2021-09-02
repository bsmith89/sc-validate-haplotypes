SELECT
    species_id
  , sample_id
  , COUNT(DISTINCT lib_id) AS lib_tally
FROM 
  ( SELECT
      species_id
    , lib_id
    , sample_id
    , species_position
    FROM snp_x_lib
    JOIN lib USING (lib_id)
  )
GROUP BY species_id, sample_id
ORDER BY lib_tally DESC
;
