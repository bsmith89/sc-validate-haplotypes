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
    nested_defaultdict,
    nested_dictlookup,
)
import sqlite3
from lib.pandas_util import idxwhere
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


config = nested_defaultdict()

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

metadb_path = "sdata/metadata.0.db"
if path.exists(metadb_path):
    con = sqlite3.connect(metadb_path)

    # Metagenomes
    _lib = pd.read_sql(
        "SELECT lib_id, filename_r1, filename_r2 FROM lib",
        con=con,
        index_col="lib_id",
    )
    for lib_id, row in _lib.iterrows():
        config["lib"][lib_id]["r1"] = row["filename_r1"]
        config["lib"][lib_id]["r2"] = row["filename_r2"]
    _lib_x_analysis_group = pd.read_sql(
        "SELECT lib_id, analysis_group FROM lib_x_analysis_group",
        con=con,
        index_col="lib_id",
    )
    for analysis_group, d in _lib_x_analysis_group.groupby("analysis_group"):
        config["lib_x_analysis_group"][analysis_group] = d.index.tolist()
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
include: "snake/sfacts.smk"


if path.exists("snake/local.smk"):

    include: "snake/local.smk"


wildcard_constraints:
    r="r|r1|r2|r3",
    group=noperiod_wc,
    lib=noperiod_wc + '.[dm]',
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


metadata_db_inputs = [
    # Metadata
    DatabaseInput("subject", "meta/subject.tsv", True),
    DatabaseInput("sample", "meta/sample.tsv", True),
    # Shotgun libraries
    DatabaseInput("lib", "meta/lib.tsv", True),
    DatabaseInput("lib_x_analysis_group", "meta/lib_x_analysis_group.tsv", True),
]


rule build_metadata_db:
    output:
        "sdata/metadata.0.db",
    input:
        script="scripts/build_db.py",
        schema="schema.sql",
        inputs=[entry.path for entry in metadata_db_inputs],
    params:
        args=[entry.to_arg() for entry in metadata_db_inputs],
    shell:
        dd(
            """
        {input.script} {output} {input.schema} {params.args}
        """
        )
