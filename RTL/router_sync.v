//RTL for Router1x3_Synchronizer
module router_sync(input [1:0] data_in,
                   input detect_add, write_enb_reg, clock, resetn, read_enb_0, read_enb_1, read_enb_2, full_0, full_1, full_2, empty_0, empty_1, empty_2,
				   output vld_out_0, vld_out_1, vld_out_2,
				   output reg [2:0] write_enb,
				   output reg soft_reset_0, soft_reset_1, soft_reset_2, fifo_full);

  reg [1:0] address_register;
  reg [4:0] counter1, counter2, counter3;
  
  function [5:0] check_for_read_enable_signal(input re, soft_reset, input [4:0] counter);
	begin
	  counter = (re || counter == 5'd30) ? 5'b00000 : (counter + 1);
	  soft_reset = (counter < 5'd30) ? 1'b0 : 1'b1;
	  check_for_read_enable_signal = {soft_reset, counter};
	end
  endfunction

  assign {vld_out_0, vld_out_1, vld_out_2} = {~empty_0, ~empty_1, ~empty_2};
  
  always@(posedge clock) // sequential logic
    begin
	  address_register <= (~resetn) ? 2'b00 : (detect_add) ? data_in : address_register;
	  case(address_register)
	    0 : {soft_reset_0, counter1} <= (~resetn) ? 2'b00 : (vld_out_0) ? check_for_read_enable_signal(read_enb_0, soft_reset_0, counter1) : {soft_reset_0, counter1};
	    1 : {soft_reset_1, counter2} <= (~resetn) ? 2'b00 : (vld_out_1) ? check_for_read_enable_signal(read_enb_1, soft_reset_1, counter2) : {soft_reset_1, counter2};
	    2 : {soft_reset_2, counter3} <= (~resetn) ? 2'b00 : (vld_out_2) ? check_for_read_enable_signal(read_enb_2, soft_reset_2, counter3) : {soft_reset_2, counter3};
		default: {soft_reset_0, soft_reset_1, soft_reset_2, counter1, counter2, counter3} <= 18'd0;
	  endcase
	end

  always@(*) // combinational logic
    begin
	  {fifo_full, write_enb} = 4'b0xxx;
	  case(address_register)
	    0: {fifo_full, write_enb} = {full_0, (~resetn) ? 3'b000 : (write_enb_reg) ? 3'b001: 3'b000};
		1: {fifo_full, write_enb} = {full_1, (~resetn) ? 3'b000 : (write_enb_reg) ? 3'b010: 3'b000};
		2: {fifo_full, write_enb} = {full_2, (~resetn) ? 3'b000 : (write_enb_reg) ? 3'b100: 3'b000};
	  endcase
	end
endmodule