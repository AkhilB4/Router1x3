// RTL Code for Router1x3_FSM_Controller using Moore FSM model
module router_fsm(input clock, resetn, pkt_valid, parity_done, soft_reset_0, soft_reset_1, soft_reset_2, fifo_full, 
                        low_pkt_valid, fifo_empty_0, fifo_empty_1, fifo_empty_2,
				  input [1:0] data_in,
				  output reg busy, detect_add, ld_state, laf_state, full_state, write_enb_reg, rst_int_reg, lfd_state);

  wire fifo_empty_status;

  parameter DECODE_ADDRESS = 3'b000,
            LOAD_FIRST_DATA = 3'b001,
			WAIT_TILL_EMPTY = 3'b010,
			LOAD_DATA = 3'b011,
			FIFO_FULL_STATE = 3'b100,
			LOAD_PARITY = 3'b101,
			LOAD_AFTER_FULL = 3'b110,
			CHECK_PARITY_ERROR = 3'b111;

  reg [2:0] present_state, next_state;
  reg [1:0] temp;

  assign fifo_empty_status = ((fifo_empty_0 && temp == 2'b00) || (fifo_empty_1 && temp == 2'b01) || (fifo_empty_2 && temp == 2'b10));

  always@(posedge clock) // State Transition Logic (or) Present State Logic - Sequential
    begin
	  temp <= (~resetn) ? 2'b00 : (detect_add) ? data_in : temp;
      present_state <= (~resetn) ? DECODE_ADDRESS : ((soft_reset_0 && temp == 2'b00)|| (soft_reset_1 && temp == 2'b01) || (soft_reset_2 && temp == 2'b10)) ? DECODE_ADDRESS : next_state;
	end

  always@(*) // Next State Logic (Combinational) and Output Logic (Combinational in case of Moore FSM model) in a single always block
    begin
	  {busy, lfd_state, ld_state, laf_state, write_enb_reg, full_state, rst_int_reg, detect_add, next_state} = DECODE_ADDRESS;
	  case(present_state)
        DECODE_ADDRESS: begin
		                  if(pkt_valid)
						    begin
	                          case(temp)
			                    0, 1, 2: {detect_add, next_state} = {1'b1, ((~fifo_empty_0 && temp == 2'b00) || (~fifo_empty_1 && temp == 2'b01) || (~fifo_empty_2 && temp == 2'b10)) ? WAIT_TILL_EMPTY : (fifo_empty_status == 1'b1) ? LOAD_FIRST_DATA : next_state};
								default: {detect_add, next_state} = {1'b0, DECODE_ADDRESS};
			                  endcase
							end
	                    end
        LOAD_FIRST_DATA: {busy, lfd_state, next_state} = {1'b1, 1'b1, LOAD_DATA};
        WAIT_TILL_EMPTY: {busy, write_enb_reg, next_state} = {1'b1, 1'b0, (fifo_empty_status == 1'b1) ? LOAD_FIRST_DATA : WAIT_TILL_EMPTY};
        LOAD_DATA: {ld_state, write_enb_reg, busy, next_state} = {1'b1, 1'b1, 1'b0, (~fifo_full && ~pkt_valid) ? LOAD_PARITY : (fifo_full) ? FIFO_FULL_STATE : LOAD_DATA};
        FIFO_FULL_STATE: {busy, write_enb_reg, full_state, next_state} = {1'b1, 1'b0, 1'b1, (~fifo_full) ? LOAD_AFTER_FULL : FIFO_FULL_STATE};
        LOAD_PARITY: {busy, write_enb_reg, next_state} = {1'b1, 1'b1, CHECK_PARITY_ERROR};
        LOAD_AFTER_FULL: begin
		                   {busy, write_enb_reg, laf_state} = {1'b1, 1'b1, 1'b1};
		                   if(!parity_done)
							 next_state = (~low_pkt_valid) ? LOAD_DATA : LOAD_PARITY;
						   else
						     next_state = DECODE_ADDRESS;
		                 end
        CHECK_PARITY_ERROR:	{busy, rst_int_reg, next_state} = {1'b1, 1'b1, (fifo_full) ? FIFO_FULL_STATE : DECODE_ADDRESS};
      endcase
	end
endmodule