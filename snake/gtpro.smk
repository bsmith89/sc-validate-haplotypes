# {{{2 GT-PRO Analysis


rule load_gtpro_snp_dict:
    output:
        "data/gtpro.snp_dict.1.db",
    input:
        gtpro="ref/gtpro",
        schema="schema.sql",
    params:
        tsv="variants_main.covered.hq.snp_dict.tsv",
    shell:
        dd(
            """
        sqlite3 {output} < schema.sql
        cat {input.gtpro}/{params.tsv} \
            | tqdm --unit-scale 1 \
            | sqlite3 -separator '\t' {output} '.import /dev/stdin snp'
        """
        )


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


def _groupwise_gtpro_results_db_inputs(wildcards, config):
    w = wildcards
    db_inputs = []
    for lib in config["lib_x_analysis_group"][w.group]:
        for read_number in [1, 2]:
            db_inputs.append(
                DatabaseInput(
                    "_gtpro_snv_x_lib",
                    f"sdata/{lib}.r{read_number}.{w.stem}.gtpro_raw.gz",
                    False,
                    {"lib_id": lib, "read_number": read_number},
                )
            )
    return db_inputs


rule _load_gtpro_results_db_helper:
    output:
        "data/{group}.a.{stem}.gtpro_helper.xargs",
    input: "sdata/metadata.0.db"
    params:
        args=lambda w: [
            entry.to_arg() for entry in _groupwise_gtpro_results_db_inputs(w, config)
        ],
    run:
        with open(output[0], 'w') as f:
            for arg in params.args:
                print(arg, file=f)

rule load_gtpro_results_db:
    output:
        "data/{group}.a.{stem}.gtpro.2.db",
    input:
        script="scripts/build_db.py",
        db="data/gtpro.snp_dict.1.db",
        lib="meta/lib.tsv",
        inputs=lambda w: [
            entry.path for entry in _groupwise_gtpro_results_db_inputs(w, config)
        ],
        xargs='data/{group}.a.{stem}.gtpro_helper.xargs',
    shell:
        dd(
            """
        cp {input.db} {output}
        {input.script} {output} <(echo "") lib:{input.lib}:1
        xargs --arg-file {input.xargs} \
            -n 1000000000 -s 1000000000000 -x \
            {input.script} {output} <(echo "")
        """
        )


