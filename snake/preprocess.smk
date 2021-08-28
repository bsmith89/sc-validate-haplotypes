# {{{1 Download and organize reference data


# {{{1 Organize raw data


rule alias_raw_mgen_r1:
    output:
        "sdata/{mgen}.m.r1.fq.gz",
    input:
        lambda wildcards: "sraw/mgen/{}".format(config["mgen"][wildcards.mgen]["r1"]),
    shell:
        alias_recipe


localrules:
    alias_raw_mgen_r1,


rule alias_raw_mgen_r2:
    output:
        "sdata/{mgen}.m.r2.fq.gz",
    input:
        lambda wildcards: "sraw/mgen/{}".format(config["mgen"][wildcards.mgen]["r2"]),
    shell:
        alias_recipe


localrules:
    alias_raw_mgen_r2,


rule alias_raw_drplt_r1:
    output:
        "sdata/{drplt}.d.r1.fq.gz",
    input:
        lambda wildcards: "sraw/drplt/{}".format(config["drplt"][wildcards.drplt]["r1"]),
    shell:
        alias_recipe


localrules:
    alias_raw_drplt_r1,


rule alias_raw_drplt_r2:
    output:
        "sdata/{drplt}.d.r2.fq.gz",
    input:
        lambda wildcards: "sraw/drplt/{}".format(config["drplt"][wildcards.drplt]["r2"]),
    shell:
        alias_recipe


localrules:
    alias_raw_drplt_r2,


# {{{1 Process data
# {{{2 Metagenomic reads


rule noop_reads:
    output:
        "{stem}.noop.fq.gz",
    input:
        "{stem}.fq.gz",
    shell:
        alias_recipe


rule qc_reads:
    output:
        directory("{stemA}.r.{stemB}.fastqc.d"),
    input:
        r1="{stemA}.r1.{stemB}.fq.gz",
        r2="{stemA}.r2.{stemB}.fq.gz",
    threads: 1
    shell:
        dd(
            """
        mkdir -p {output}
        fastqc -t {threads} -o {output} {input}
        """
        )


rule debug:
    input:
        r1="sdata/SS01013.m.r1.noop.fq.gz",
    resources:
        mem_mb=resource_calculator(r1=2),
    shell:
        "echo {resources.mem_mb}"


rule deduplicate_reads:
    output:
        r1=temp("{stemA}.r1{stemB}dedup.fq.gz"),
        r2=temp("{stemA}.r2{stemB}dedup.fq.gz"),
    input:
        script="scripts/fastuniq_wrapper.sh",
        r1="{stemA}.r1{stemB}fq.gz",
        r2="{stemA}.r2{stemB}fq.gz",
    resources:
        mem_mb=resource_calculator(r1=25, input_size_exponent=dict(r1=2)),
        walltime_min=resource_calculator(r1=0.01),
    shell:
        "{input.script} {input.r1} {input.r2} {output.r1} {output.r2}"


# NOTE: Hub-rule: Comment out this rule to reduce DAG-building time
# once all libraries have been processed
rule alias_cleaned_reads:
    output:
        "sdata/{stem}.proc.fq.gz",
    input:
        "sdata/{stem}.dedup.fq.gz",
        # # FIXME: Probably should hfilt so it can be uploaded to SRA.
        # "data/{stem}.hfilt.dedup.fq.gz",
    shell:
        alias_recipe


localrules:
    alias_cleaned_reads,


# {{{1 Checkpoint rules
# NOTE: These may be useful for other parts of the workflow besides
# just pre-processing.


rule gather_all_read_pairs_from_analysis_group:
    output:
        touch("{d}/{group}.a.{stem}.ALL_PAIRS.flag"),
    input:
        r1m=lambda w: [
            f"{{d}}/{mgen}.m.r1.{{stem}}"
            for mgen in config["mgen_x_analysis_group"][w.group]
        ],
        r2m=lambda w: [
            f"{{d}}/{mgen}.m.r2.{{stem}}"
            for mgen in config["mgen_x_analysis_group"][w.group]
        ],
        r1d=lambda w: [
            f"{{d}}/{drplt}.m.r1.{{stem}}"
            for drplt in config["drplt_x_analysis_group"][w.group]
        ],
        r2d=lambda w: [
            f"{{d}}/{drplt}.m.r2.{{stem}}"
            for drplt in config["drplt_x_analysis_group"][w.group]
        ],


localrules:
    gather_all_read_pairs_from_analysis_group,


rule gather_all_reads_from_analysis_group:
    output:
        touch("{d}/{group}.a.{stem}.ALL_READS.flag"),
    input:
        r1m=lambda w: [
            f"{{d}}/{mgen}.m.r.{{stem}}"
            for mgen in config["mgen_x_analysis_group"][w.group]
        ],
        r2d=lambda w: [
            f"{{d}}/{drplt}.d.r.{{stem}}"
            for drplt in config["drplt_x_analysis_group"][w.group]
        ],


localrules:
    gather_all_reads_from_analysis_group,
