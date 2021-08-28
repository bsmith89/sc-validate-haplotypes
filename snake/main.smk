# {{{0 Preamble

# {{{2 Imports

from lib.snake import (
    alias_recipe,
    alias_recipe_norelative,
    noperiod_wc,
    integer_wc,
    single_param_wc,
    limit_numpy_procs_to_1,
    curl_recipe,
    limit_numpy_procs,
    resource_calculator,
)
import sqlite3
from lib.pandas import idxwhere
import pandas as pd
import math
from itertools import product
from textwrap import dedent as dd
from scripts.build_db import DatabaseInput
import os.path as path
from warnings import warn
import snakemake.utils

# {{{1 Configuration

# {{{2 General Configuration

snakemake.utils.min_version("6.7")


configfile: "config.yaml"


local_config_path = "config_local.yaml"
if path.exists(local_config_path):

    configfile: local_config_path


if "container" in config:

    container: config["container"]


if "MAX_THREADS" in config:
    MAX_THREADS = config["MAX_THREADS"]
else:
    MAX_THREADS = 99
if "USE_CUDA" in config:
    USE_CUDA = config["USE_CUDA"]
else:
    USE_CUDA = 0

# {{{2 Data Configuration

metadb_path = "sdata/db0.db"
if path.exists(metadb_path):
    con = sqlite3.connect(metadb_path)

    # Metagenomes
    _mgen = pd.read_sql(
        "SELECT mgen_id, filename_r1, filename_r2 FROM mgen",
        con=con,
        index_col="mgen_id",
    )
    config["mgen"] = {}
    for mgen_id, row in _mgen.iterrows():
        config["mgen"][mgen_id] = {}
        config["mgen"][mgen_id]["r1"] = row["filename_r1"]
        config["mgen"][mgen_id]["r2"] = row["filename_r2"]
    _mgen_x_analysis_group = pd.read_sql(
        "SELECT mgen_id, analysis_group FROM mgen_x_analysis_group",
        con=con,
        index_col="mgen_id",
    )
    config["mgen_x_analysis_group"] = {}
    for analysis_group, d in _mgen_x_analysis_group.groupby("analysis_group"):
        config["mgen_x_analysis_group"][analysis_group] = d.index.tolist()

    # Single-cell genomics
    _drplt = pd.read_sql(
        "SELECT drplt_id, filename_r1, filename_r2 FROM drplt",
        con=con,
        index_col="drplt_id",
    )
    config["drplt"] = {}
    for drplt_id, row in _drplt.iterrows():
        config["drplt"][drplt_id] = {}
        config["drplt"][drplt_id]["r1"] = row["filename_r1"]
        config["drplt"][drplt_id]["r2"] = row["filename_r2"]
    _drplt_x_analysis_group = pd.read_sql(
        "SELECT drplt_id, analysis_group FROM drplt_x_analysis_group",
        con=con,
        index_col="drplt_id",
    )
    config["drplt_x_analysis_group"] = {}
    for analysis_group, d in _drplt_x_analysis_group.groupby("analysis_group"):
        config["drplt_x_analysis_group"][analysis_group] = d.index.tolist()
else:
    warn(
        dd(
            f"""
            Could not load config from `{metadb_path}`.
            Check that path is defined and file exists.
            """
        )
    )

# {{{2 Sub-pipelines


include: "snake/template.smk"
include: "snake/util.smk"
include: "snake/general.smk"
include: "snake/docs.smk"
include: "snake/preprocess.smk"
include: "snake/gtpro.smk"


if path.exists("snake/local.smk"):

    include: "snake/local.smk"


wildcard_constraints:
    r="r|r1|r2|r3",
    group=noperiod_wc,
    lib=noperiod_wc,
    species=noperiod_wc,
    strain=noperiod_wc,
    compound_id=noperiod_wc,
    hmm_cutoff="XX",
    model=noperiod_wc,
    param=single_param_wc,
    params=noperiod_wc,


# {{{1 Default actions


rule all:
    input:
        ["sdata/database.db"],


# {{{1 Database


db0_inputs = [
    # Metadata
    DatabaseInput("subject", "meta/subject.tsv", True),
    DatabaseInput("sample", "meta/sample.tsv", True),
    # Metagenomes
    DatabaseInput("mgen", "meta/mgen.tsv", True),
    DatabaseInput("mgen_x_analysis_group", "meta/mgen_x_analysis_group.tsv", True),
    # Droplets
    DatabaseInput("drplt", "meta/drplt.tsv", True),
    DatabaseInput("drplt_x_analysis_group", "meta/drplt_x_analysis_group.tsv", True),
]


rule build_db0:
    output:
        "sdata/db0.db",
    input:
        script="scripts/build_db.py",
        schema="schema.sql",
        inputs=[entry.path for entry in db0_inputs],
    params:
        args=[entry.to_arg() for entry in db0_inputs],
    shell:
        dd(
            r"""
        {input.script} {output} {input.schema} {params.args}
        """
        )
