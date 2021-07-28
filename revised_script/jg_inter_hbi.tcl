
clear -all
set sim_name vscale_sim_top_dup
# Analyze RTL files
analyze -sv09 -f jg_hdls.f +incdir+./src/main/verilog/

set_proofgrid_per_engine_max_jobs 10

# Elaborates
elaborate 

clock clk

# Define reset condition
# reset pin active val
reset reset

# Start the verification
set_prove_time_limit 10m
set_engine_mode {K I N C}
prove -all -covers

set_prove_time_limit 10m
set_engine_mode {I N AD AM G3 Tri}
prove -all -asserts
# TODO the other way
#set cmd "prove -property {*.HBI_STRUC_0}"
#set res [eval $cmd]
#if {$res != "proven"} {
#    puts "well, ppo direction is cex" 
#    prove -all -asserts
#}


report -csv -results -file "CSVNAME.csv" -force

exit 
