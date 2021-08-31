# {{{2 GT-PRO Analysis


rule build_gtpro_snp_dict:
    output: "ref/gtpro.snp_dict.db"
    input: "ref/gtpro"
    params:
        tsv="variants_main.covered.hq.snp_dict.tsv"
    shell:
        dd("""
        script=$(mktemp)
        cat >$script <<EOF
        CREATE TABLE snp
        ( species_id
        , species_position
        , contig_id
        , contig_position
        , reference_allele
        , alternative_allele

        , PRIMARY KEY (species_id, species_position)
        );
        EOF
        sqlite3 {output} < $script
        cat {input}/{params.tsv} \
            | tqdm \
            | sqlite3 -separator '\t' {output} '.import /dev/stdin snp'
        """)


rule run_gtpro:
    output:
        "{stem}.gtpro_raw.gz",
    input:
        r="{stem}.fq.gz",
        db="ref/gtpro",
    params:
        db_l=32,
        db_m=36,
        db_name="20190723_881species",
    threads: 4
    resources:
        mem_mb=60000,
        pmem=60000 // 4,
        walltime_hr=4,
    shell:
        dd(
            """
        GT_Pro genotype -t {threads} -l {params.db_l} -m {params.db_m} -d {input.db}/{params.db_name} -f -o {output} {input.r}
        mv {output}.tsv.gz {output}
        """
        )


rule move_metagenotype_out_of_sdata:
    output:
        "data/{stem}.gtpro_raw.gz",
    input:
        "sdata/{stem}.gtpro_raw.gz",
    shell:
        "cp {input} {output}"


# NOTE: Comment-out this rule after files have been completed to
# save DAG processing time.
rule gtpro_finish_processing_reads:
    output:
        "data/{stem}.gtpro_parse.tsv.bz2",
    input:
        db="ref/gtpro.snp_dict.db",
        gtpro="data/{stem}.gtpro_raw.gz",
    shell:
        dd(
            """
        script=$(mktemp)
        cat > $script <<EOF
        .bail on
        .separator '\t'

        CREATE TEMPORARY TABLE _gtpro
        ( snp_id
        , tally
        );

        .import /dev/stdin _gtpro

        CREATE TEMPORARY VIEW gtpro AS
        SELECT
            substr(snp_id, 1, 6) AS species_id
          , substr(snp_id, 7, 1) AS snp_type
          , substr(snp_id, 8) AS species_position
          , tally
        FROM _gtpro
        ;


        SELECT
            species_id
          , species_position
          , contig_id
          , contig_position
          , reference_allele
          , alternative_allele
          , SUM(reference_tally) AS reference_tally
          , SUM(alternative_tally) AS alternative_tally
        FROM (
            SELECT
              snp.*
            , IIF(snp_type = '0', tally, 0) AS reference_tally
            , IIF(snp_type = '1', tally, 0) AS alternative_tally
            FROM gtpro
            JOIN snp USING (species_id, species_position)
        )
        GROUP BY species_id, species_position
        ;
        EOF

        zcat {input.gtpro} \
            | sqlite3 -init $script {input.db} \
            | bzip2 -c \
            > {output}
        """
        )


# NOTE: Comment out this rule to speed up DAG evaluation.
# Selects a single species from every file and concatenates.
rule concatenate_mgen_group_one_read_count_data_from_one_species:
    output:
        "data/{group}.a.{stem}.sp-{species}.gtpro_combine.tsv.bz2",
    input:
        script="scripts/select_gtpro_species_lines.sh",
        mgen=lambda w: [
            f"data/{mgen}.m.{{stem}}.gtpro_parse.tsv.bz2"
            for mgen in config["mgen_x_analysis_group"][w.group]
        ],
        drplt=lambda w: [
            f"data/{drplt}.d.{{stem}}.gtpro_parse.tsv.bz2"
            for drplt in config["drplt_x_analysis_group"][w.group]
        ],
    params:
        species=lambda w: w.species,
        args=lambda w: "\n".join(
            [
                f"{mgen}\tdata/{mgen}.m.{w.stem}.gtpro_parse.tsv.bz2"
                for mgen in config["mgen_x_analysis_group"][w.group]
            ]
            + [
                f"{drplt}\tdata/{drplt}.d.{w.stem}.gtpro_parse.tsv.bz2"
                for drplt in config["drplt_x_analysis_group"][w.group]
            ]
        ),
    threads: 6
    shell:
        dd(
            """
        tmp=$(mktemp)
        cat >$tmp <<EOF
        {params.args}
        EOF
        parallel --colsep='\t' --bar -j {threads} \
                {input.script} {params.species} :::: $tmp \
            | bzip2 -c \
            > {output}
        """
        )


rule merge_both_reads_species_count_data:
    output:
        "data/{group}.a.{stem}.gtpro.sp-{species}.metagenotype.nc",
    input:
        script="scripts/merge_both_gtpro_reads_to_netcdf.py",
        r1="data/{group}.a.r1.{stem}.sp-{species}.gtpro_combine.tsv.bz2",
        r2="data/{group}.a.r2.{stem}.sp-{species}.gtpro_combine.tsv.bz2",
    threads: 4
    resources:
        mem_mb=100000,
        pmem=lambda w, threads: 100000 // threads,
    shell:
        "{input.script} {input.r1} {input.r2} {output}"
