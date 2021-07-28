# Environment
    * Jaspergold: `which jc`
    * Pandas / Numpy: `python3 -m pip install pandas numpy`
# Steps
    0. `mkdir gensva/`
    1. intra-instruction HBI
        * transfer the folder `<yossyenv>/rtl2uspec/build/sva/intra_hbi` to `<cad_env>/multicore_vscale_rtl2uspec/gensva/`

            ```
            gensva
            `-- intra_hbi
            ```

        * `python3 revised_script/intra_hbi.py`
        * transfer `gensva/intra_hbi/` back to  `<yossyenv>/rtl2uspec/build/sva/intra_hbi`

    2. inter-instruction HBI
        * transfer the folder `<yossyenv>/rtl2uspec/build/sva/inter_hbi` to `<cad_env>/multicore_vscale_rtl2uspec/gensva/`

            ```
            gensva
            |-- inter_hbi
            `-- intra_hbi
            ```
        * `python3 revised_script/inter_hbi.py`
        * transfer `gensva/inter_hbi/` back to  `<yossyenv>/rtl2uspec/build/sva/inter_hbi`

