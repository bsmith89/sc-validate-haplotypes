CREATE TABLE subject
  ( subject_id PRIMARY KEY
  );

CREATE TABLE sample
  ( sample_id PRIMARY KEY
  , subject_id REFERENCES subject(subject_id)
  , collection_days_post_fmt FLOAT
  , received_days_post_fmt
  , sample_class
  , sample_type
  , dna_extraction_days_post_fmt
  , dna_sequencing_days_post_fmt
  , plate_well
  , sample_weight
  , source_sample_id
  , sample_notes
  , biosample
  );

CREATE TABLE lib
  ( lib_id PRIMARY KEY
  , sample_id REFERENCES sample(sample_id)
  , lib_type
  , plate_numer
  , plate_well
  , filename_r1
  , filename_r2
  , lib_notes
  , sra_accession
  );

CREATE TABLE lib_x_analysis_group
  ( lib_id REFERENCES mgen(mgen_id)
  , analysis_group
  );

CREATE TABLE snp
  ( species_id
  , species_position
  , contig_id
  , contig_position
  , reference_allele
  , alternative_allele

  , PRIMARY KEY (species_id, species_position)
  );

CREATE TABLE _gtpro_snv_x_lib
  ( lib_id REFERENCES lib(lib_id)
  , read_number
  , snv_id
  , tally
  );

CREATE VIEW gtpro_snv_x_lib AS
SELECT
  lib_id
  , read_number
  , substr(snv_id, 1, 6) AS species_id
  , substr(snv_id, 7, 1) AS snv_type
  , substr(snv_id, 8) AS species_position
  , tally
FROM _gtpro_snv_x_lib
;

CREATE VIEW snp_x_lib AS
SELECT
    lib_id
  , species_id
  , species_position
  , reference_allele
  , alternative_allele
  , SUM(reference_tally) AS reference_tally
  , SUM(alternative_tally) AS alternative_tally
FROM (
    SELECT
      lib_id
    , snp.*
    , IIF(snp_type = "0", tally, 0) AS reference_tally
    , IIF(snp_type = "1", tally, 0) AS alternative_tally
    FROM gtpro_snv_x_lib
    JOIN snp USING (species_id, species_position)
)
GROUP BY lib_id, species_id, species_position
;
