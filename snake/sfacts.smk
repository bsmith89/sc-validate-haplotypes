use rule start_jupyter as start_jupyter_sfacts with:
    params:
        python_paths=['./include/StrainFacts'],
        port=rules.start_jupyter.params['port'],
    # TODO: Add a convenience function for changing just one parameter
    # based on the parent rule.


use rule start_ipython as start_ipython_sfacts with:
    params:
        python_paths=['./include/StrainFacts'],
