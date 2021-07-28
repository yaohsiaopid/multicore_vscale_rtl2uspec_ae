`include "vscale_hasti_constants.vh"

module vscale_dp_hasti_sram(
                            input                          hclk,
                            input                          hresetn,
                            input [2+`HASTI_ADDR_WIDTH-1:0]  p0_haddr,
                            input                          p0_hwrite,
                            input [`HASTI_SIZE_WIDTH-1:0]  p0_hsize,
                            input [`HASTI_BURST_WIDTH-1:0] p0_hburst,
                            input                          p0_hmastlock,
                            input [`HASTI_PROT_WIDTH-1:0]  p0_hprot,
                            input [`HASTI_TRANS_WIDTH-1:0] p0_htrans,
                            input [`HASTI_BUS_WIDTH-1:0]   p0_hwdata,
                            output [`HASTI_BUS_WIDTH-1:0]  p0_hrdata,
                            output                         p0_hready,
                            output                         p0_hresp,
                            input [`HASTI_ADDR_WIDTH-1:0]  p1_haddr [0:`NUM_CORES-1],
                            input                          p1_hwrite [0:`NUM_CORES-1],
                            input [`HASTI_SIZE_WIDTH-1:0]  p1_hsize [0:`NUM_CORES-1],
                            input [`HASTI_BURST_WIDTH-1:0] p1_hburst [0:`NUM_CORES-1],
                            input                          p1_hmastlock [0:`NUM_CORES-1],
                            input [`HASTI_PROT_WIDTH-1:0]  p1_hprot [0:`NUM_CORES-1],
                            input [`HASTI_TRANS_WIDTH-1:0] p1_htrans [0:`NUM_CORES-1],
                            input [`HASTI_BUS_WIDTH-1:0]   p1_hwdata [0:`NUM_CORES-1],
                            output reg [`HASTI_BUS_WIDTH-1:0]  p1_hrdata [0:`NUM_CORES-1],
                            output reg                     p1_hready [0:`NUM_CORES-1],
                            output reg                     p1_hresp [0:`NUM_CORES-1]
                            );

   parameter nwords = 32;

   localparam s_w1 = 0;
   localparam s_w2 = 1;

   reg [`HASTI_BUS_WIDTH-1:0]                              mem [nwords-1:0];

   // p0

   // flops
   reg [2+`HASTI_ADDR_WIDTH-1:0]                           p0_waddr;
   reg [`HASTI_BUS_WIDTH-1:0]                              p0_wdata;
   reg                                                     p0_wvalid;
   reg [`HASTI_SIZE_WIDTH-1:0]                             p0_wsize;
   reg                                                     p0_state;

   wire [`HASTI_BUS_NBYTES-1:0]                            p0_wmask_lut = (p0_wsize == 0) ? `HASTI_BUS_NBYTES'h1 : (p0_wsize == 1) ? `HASTI_BUS_NBYTES'h3 : `HASTI_BUS_NBYTES'hf;
   wire [`HASTI_BUS_NBYTES-1:0]                            p0_wmask_shift = p0_wmask_lut << p0_waddr[1:0];
   wire [`HASTI_BUS_WIDTH-1:0]                             p0_wmask = {{8{p0_wmask_shift[3]}},{8{p0_wmask_shift[2]}},{8{p0_wmask_shift[1]}},{8{p0_wmask_shift[0]}}};
   wire [2+`HASTI_ADDR_WIDTH-1:0]                            p0_word_waddr = {p0_waddr[2+`HASTI_ADDR_WIDTH-1:1+`HASTI_ADDR_WIDTH-1], p0_waddr[`HASTI_ADDR_WIDTH-1:0] >> 2};

   wire [2+`HASTI_ADDR_WIDTH-1:0]                          p0_raddr = {p0_haddr[2+`HASTI_ADDR_WIDTH-1:1+`HASTI_ADDR_WIDTH-1],  p0_haddr[`HASTI_ADDR_WIDTH-1:0] >> 2};
   wire                                                    p0_ren = (p0_htrans == `HASTI_TRANS_NONSEQ && !p0_hwrite);
   reg [2+`HASTI_ADDR_WIDTH-1:0]                           p0_reg_raddr;

   always @(posedge hclk) begin
      p0_reg_raddr <= p0_raddr;
      if (!hresetn) begin
         p0_state <= s_w1;
         p0_wvalid <= 1'b0;
         p0_waddr <= 0;
         p0_wdata <= 0;
         p0_reg_raddr <= 0;
      end else begin
         if (p0_state == s_w2) begin
            if (p0_wvalid) begin
               mem[p0_word_waddr[`HASTI_ADDR_WIDTH-1:0]] <= (mem[p0_word_waddr[`HASTI_ADDR_WIDTH-1:0]] & ~p0_wmask) | (p0_hwdata & p0_wmask);
            end
            p0_state <= s_w1;
            p0_wvalid <= 1'b0;
         end
         if (p0_htrans == `HASTI_TRANS_NONSEQ) begin
            if (p0_hwrite) begin
               p0_waddr <= p0_haddr;
               p0_wsize <= p0_hsize;
               p0_wvalid <= 1'b1;
               p0_state <= s_w2;
            end
         end // if (p0_htrans == `HASTI_TRANS_NONSEQ)
      end
   end

   assign p0_hrdata = mem[p0_reg_raddr[`HASTI_ADDR_WIDTH-1:0]];
   assign p0_hready = 1'b1;
   assign p0_hresp = `HASTI_RESP_OKAY;


   reg [`HASTI_ADDR_WIDTH-1:0] p1_raddr [0:`NUM_CORES-1];
   reg                         p1_ren [0:`NUM_CORES-1];
   reg                          p1_bypass [0:`NUM_CORES-1];
   reg [`HASTI_ADDR_WIDTH-1:0]  p1_reg_raddr [0:`NUM_CORES-1];

   reg [`HASTI_BUS_WIDTH-1:0] p1_rdata [0:`NUM_CORES-1];
   reg [`HASTI_BUS_WIDTH-1:0] p1_rmask [0:`NUM_CORES-1];

   //genvar j;
   //generate
   //    for (j = 0; j < `NUM_CORES ; j++)
   //        // p1

   //        always @(*) begin
   //            p1_raddr[j] = p1_haddr[j] >> 2;
   //            p1_ren[j] = (p1_htrans[j] == `HASTI_TRANS_NONSEQ && !p1_hwrite[j]);

   //            p1_rdata[j] = mem[p1_reg_raddr[j]];
   //            p1_rmask[j] = {32{p1_bypass[j]}} & p0_wmask;
   //            p1_hrdata[j] = (p0_wdata & p1_rmask[j]) | (p1_rdata[j] & ~p1_rmask[j]);
   //            p1_hready[j] = 1'b1;
   //            p1_hresp[j] = `HASTI_RESP_OKAY;
   //        end
   //endgenerate

   //generate
   //    for (j = 0; j < `NUM_CORES ; j++)
   //        always @(posedge hclk) begin
   //           p1_reg_raddr[j] <= p1_raddr[j];
   //           if (!hresetn) begin
   //              p1_bypass[j] <= 0;
   //           end else begin
   //              if (p1_htrans[j] == `HASTI_TRANS_NONSEQ) begin
   //                 if (p1_hwrite[j]) begin
   //                 end else begin
   //                    p1_bypass[j] <= p0_wvalid && p0_word_waddr == p1_raddr[j];
   //                 end
   //              end // if (p1_htrans == `HASTI_TRANS_NONSEQ)
   //           end
   //        end
   //endgenerate

endmodule // vscale_dp_hasti_sram

