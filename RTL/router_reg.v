//RTL for Router1x3_Register
module router_reg #(parameter WIDTH = 8) (input clock, resetn, pkt_valid, fifo_full, rst_int_reg, detect_add, ld_state, laf_state, full_state, lfd_state,
                                          input [(WIDTH-1):0] data_in,
				                          output reg parity_done, low_pkt_valid, err,
				                          output reg [(WIDTH-1):0] dout);

  // Internal Registers within Register block
  reg [(WIDTH-1):0] header_byte_reg, fifo_full_state_byte_reg, internal_parity_byte_reg, packet_parity_byte_reg;
  
  always@(posedge clock)
    begin
      err <= (~resetn) ? 1'b0: (parity_done) ? (internal_parity_byte_reg != packet_parity_byte_reg) : 1'b0;
	  low_pkt_valid <= (~resetn) ? 1'b0 : (rst_int_reg) ? 1'b0 : (ld_state && ~pkt_valid) ? 1'b1 : low_pkt_valid;

      parity_done <= (~resetn) ? 1'b0 : (detect_add) ? 1'b0 : ((ld_state && ~fifo_full && ~pkt_valid) || (laf_state && low_pkt_valid && ~parity_done)) ? 1'b1 : parity_done;
	  
	  dout <= (~resetn) ? 8'b0 : (lfd_state) ? header_byte_reg : (ld_state && ~fifo_full) ? data_in : (parity_done && (internal_parity_byte_reg == packet_parity_byte_reg)) ? packet_parity_byte_reg : (laf_state) ? fifo_full_state_byte_reg : dout;
	  
	  header_byte_reg <= (~resetn) ? 8'b0 : (detect_add && pkt_valid && data_in[1:0] != 2'b11) ? data_in : header_byte_reg;
	  fifo_full_state_byte_reg <= (~resetn) ? 8'b0 : (ld_state && fifo_full) ? data_in : fifo_full_state_byte_reg;

      internal_parity_byte_reg <= (~resetn) ? 8'b0 : (detect_add) ? 8'b0 : (lfd_state) ? internal_parity_byte_reg ^ header_byte_reg : (~full_state && ld_state && pkt_valid) ? internal_parity_byte_reg ^ data_in : internal_parity_byte_reg;

      packet_parity_byte_reg <= (~resetn) ? 8'b0 : ((ld_state && ~fifo_full && ~pkt_valid) || (laf_state && low_pkt_valid && ~parity_done)) ? data_in : packet_parity_byte_reg;
	end
endmodule