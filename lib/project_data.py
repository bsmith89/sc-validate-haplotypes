def metagenotype_db_to_xarray(df):
    """Convert from project database schema to a StrainFacts metagenotype.

    """
    return (
        df.rename_axis(columns="allele")
        .rename(columns=dict(alternative_tally="alt", reference_tally="ref"))
        .rename_axis(index=dict(lib_id="sample", species_position="position"))
        .stack()
        .to_xarray()
        .fillna(0)
        .sortby("allele")
    )
