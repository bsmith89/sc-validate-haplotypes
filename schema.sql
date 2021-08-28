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
