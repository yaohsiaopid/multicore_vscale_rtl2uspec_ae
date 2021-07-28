`include "vscale_ctrl_constants.vh"
`include "vscale_csr_addr_map.vh"
`include "vscale_hasti_constants.vh"
`include "vscale_multicore_constants.vh"

module vscale_arbiter(
                       input                                            clk,
                       input                                            reset,
                       input [`HASTI_ADDR_WIDTH-1:0]                    core_haddr [0:`NUM_CORES-1],
                       input                                            core_hwrite [0:`NUM_CORES-1],
                       input [`HASTI_SIZE_WIDTH-1:0]                    core_hsize [0:`NUM_CORES-1],
                       input [`HASTI_BURST_WIDTH-1:0]                   core_hburst [0:`NUM_CORES-1],
                       input                                            core_hmastlock [0:`NUM_CORES-1],
                       input [`HASTI_PROT_WIDTH-1:0]                    core_hprot [0:`NUM_CORES-1],
                       input [`HASTI_TRANS_WIDTH-1:0]                   core_htrans [0:`NUM_CORES-1],
                       input [`HASTI_BUS_WIDTH-1:0]                     core_hwdata [0:`NUM_CORES-1],
                       output reg [`HASTI_BUS_WIDTH-1:0]                core_hrdata [0:`NUM_CORES-1],
                       output reg                                       core_hready [0:`NUM_CORES-1],
                       output reg [`HASTI_RESP_WIDTH-1:0]               core_hresp [0:`NUM_CORES-1],
                       output reg [2+`HASTI_ADDR_WIDTH-1:0]               dmem_haddr,
                       output reg                                       dmem_hwrite,
                       output reg [`HASTI_SIZE_WIDTH-1:0]               dmem_hsize,
                       output reg [`HASTI_BURST_WIDTH-1:0]              dmem_hburst,
                       output reg                                       dmem_hmastlock,
                       output reg [`HASTI_PROT_WIDTH-1:0]               dmem_hprot,
                       output reg [`HASTI_TRANS_WIDTH-1:0]              dmem_htrans,
                       output reg [`HASTI_BUS_WIDTH-1:0]                dmem_hwdata,
                       input [`HASTI_BUS_WIDTH-1:0]                     dmem_hrdata,
                       input                                            dmem_hready,
                       input [`HASTI_RESP_WIDTH-1:0]                    dmem_hresp,
                       input [`CORE_IDX_WIDTH-1:0]                      next_core
                     );

    //Which core's filing a request this cycle?
    reg [`CORE_IDX_WIDTH-1:0]     cur_core;
    //Which core filed its request last cycle (and is observing the response this
    //cycle?
    reg [`CORE_IDX_WIDTH-1:0]     prev_core;

    //Keep track of when to move from one core to another.
    reg [31:0] counter;

    //The "mux selectors" of the arbiter.
    always @(posedge clk) begin
        cur_core <= next_core;
        prev_core <= cur_core;
    end

    //And the combinational connections...
    always @(*) begin
       dmem_haddr = {cur_core, core_haddr[cur_core]};
       dmem_hwrite = core_hwrite[cur_core];
       dmem_hsize = core_hsize[cur_core];
       dmem_hburst = core_hburst[cur_core];
       dmem_hmastlock = core_hmastlock[cur_core];
       dmem_hprot = core_hprot[cur_core];
       dmem_htrans = core_htrans[cur_core];
       //Write data must be from the previous core.
       dmem_hwdata = core_hwdata[prev_core];
    end

    genvar i;
    generate
       for (i = 0; i < `NUM_CORES ; i++)
            always @(*) begin
                if (cur_core == i) begin
                    //dmem_hready is not looked at by WB anymore, so we can have it be
                    //negative in WB and no one minds...it's only the data that has to
                    //follow one cycle behind :). Thus, the actual mem's hready is sent to
                    //the current core.
                    core_hready[i] = dmem_hready;
                    core_hrdata[i] = dmem_hrdata;
                    //Resp is always HASTI_RESP_OKAY on the dmem side, so if we make
                    //all other cores get that, we should be fine.
                    //Furthermore, I believe resp only matters if it's equal to
                    //HASTI_RESP_ERROR (see the bridge for details).
                    core_hresp[i] = `HASTI_RESP_OKAY;
                end else begin
                        core_hready[i] = 1'b0;
                        core_hrdata[i] = dmem_hrdata;
                        core_hresp[i] = dmem_hresp;
               end
           end
       endgenerate
endmodule
