// two-trace property 
`include "vscale_ctrl_constants.vh"
`include "vscale_csr_addr_map.vh"
`include "vscale_hasti_constants.vh"
`include "vscale_multicore_constants.vh"
module vscale_sim_top_dup(
    input                        clk,
    input                        reset,
    input                        htif_pcr_req_valid,
    output                       htif_pcr_req_ready[0:`NUM_CORES-1],
    input                        htif_pcr_req_rw,
    input [`CSR_ADDR_WIDTH-1:0]  htif_pcr_req_addr,
    input [`HTIF_PCR_WIDTH-1:0]  htif_pcr_req_data,
    output                       htif_pcr_resp_valid[0:`NUM_CORES-1],
    input                        htif_pcr_resp_ready,
    output [`HTIF_PCR_WIDTH-1:0] htif_pcr_resp_data[0:`NUM_CORES-1],
    input [`CORE_IDX_WIDTH-1:0]  arbiter_next_core
);
vscale_sim_top sim_top_1(
.clk(clk),
.reset(reset),
.htif_pcr_req_valid(htif_pcr_req_valid),
 .htif_pcr_req_ready(htif_pcr_req_ready),
.htif_pcr_req_rw(htif_pcr_req_rw),
.htif_pcr_req_addr(htif_pcr_req_addr),
.htif_pcr_req_data(htif_pcr_req_data),
 .htif_pcr_resp_valid(htif_pcr_resp_valid),
.htif_pcr_resp_ready(htif_pcr_resp_ready),
.htif_pcr_resp_data(htif_pcr_resp_data),
.arbiter_next_core(arbiter_next_core)
);
//vscale_sim_top sim_top_2(
//.clk(clk),
//.reset(reset),
//.htif_pcr_req_valid(htif_pcr_req_valid),
//// .htif_pcr_req_ready(htif_pcr_req_ready),
//.htif_pcr_req_rw(htif_pcr_req_rw),
//.htif_pcr_req_addr(htif_pcr_req_addr),
//.htif_pcr_req_data(htif_pcr_req_data),
//// .htif_pcr_resp_valid(htif_pcr_resp_valid),
//.htif_pcr_resp_ready(htif_pcr_resp_ready),
//.htif_pcr_resp_data(htif_pcr_resp_data),
//.arbiter_next_core(arbiter_next_core)
//);


property CONST (N);
    @(posedge clk) N == $past(N);
endproperty
`define STORE 7'b0100011
`define LOAD 7'b0000011


reg first;

always @(posedge clk) begin
	if (reset) begin
		first <= 1;
	end else if (first == 1) begin
		first <= 0;
	end
end





endmodule
