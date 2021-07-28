clear -all
set sim_name vscale_sim_top_dup
set CSVNAME 0t
# Analyze RTL files
analyze -sv09 -f jg_hdls.f +incdir+./src/main/verilog/

set_proofgrid_per_engine_max_jobs 6

# Elaborates
elaborate 

clock clk

# Define reset condition
# reset pin active val
reset reset

# Start the verification
set_engine_mode {K I N C}
prove -all -covers

set_prove_time_limit 1h
set_engine_mode {I N AD AM G3 Tri}
prove -all -asserts

report -csv -results -file "CSVNAME.csv" -force

exit 

