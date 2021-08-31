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

CREATE TABLE mgen
  ( mgen_id PRIMARY KEY
  , sample_id REFERENCES sample(sample_id)
  , plate_numer
  , plate_well
  , filename_r1
  , filename_r2
  , mgen_notes
  , sra_accession
  );

CREATE TABLE drplt
  ( drplt_id PRIMARY KEY
  , sample_id REFERENCES sample(sample_id)
  , filename_r1
  , filename_r2
  );

CREATE TABLE mgen_x_analysis_group
  ( mgen_id REFERENCES mgen(mgen_id)
  , analysis_group
  );

CREATE TABLE drplt_x_analysis_group
  ( drplt_id REFERENCES mgen(mgen_id)
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

CREATE TABLE _gtpro_snp_x_drplt
  ( drplt_id REFERENCES drplt(drplt_id)
  , snp_id
  , tally
  );

CREATE TABLE _gtpro_snp_x_mgen
  ( mgen_id REFERENCES mgen(mgen_id)
  , snp_id
  , tally
  );

CREATE VIEW snp_x_drplt AS
SELECT
  drplt_id
  , substr(snp_id, 1, 6) AS species_id
  , substr(snp_id, 7, 1) AS snp_type
  , substr(snp_id, 8) AS species_position
  , tally
FROM _gtpro_snp_x_drplt
;

CREATE VIEW snp_x_mgen AS
SELECT
  mgen_id
  , substr(snp_id, 1, 6) AS species_id
  , substr(snp_id, 7, 1) AS snp_type
  , substr(snp_id, 8) AS species_position
  , tally
FROM _gtpro_snp_x_mgen
;
