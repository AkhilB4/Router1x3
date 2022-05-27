// Testbench
module router_reg_tb;
  integer i;
  parameter T = 20, WIDTH = 8;
  reg [WIDTH-1:0] payload_data, parity = 0, header;
  reg [5:0] payload_len;
  reg [1:0] addr;
  
  reg [(WIDTH-1):0] data_in;
  reg clock, resetn, pkt_valid, fifo_full, rst_int_reg, detect_add, ld_state, laf_state, full_state, lfd_state;                
  wire parity_done, low_pkt_valid, err;
  wire [(WIDTH-1):0] dout;

  router_reg DUT(.clock(clock), .resetn(resetn), .pkt_valid(pkt_valid), .fifo_full(fifo_full), .rst_int_reg(rst_int_reg), .detect_add(detect_add), .ld_state(ld_state), .laf_state(laf_state), .full_state(full_state), .lfd_state(lfd_state), .data_in(data_in), .parity_done(parity_done), .low_pkt_valid(low_pkt_valid), .err(err), .dout(dout));
  
  wire [(WIDTH-1):0] header_byte_reg = DUT.header_byte_reg; 
  wire [(WIDTH-1):0] fifo_full_state_byte_reg = DUT.fifo_full_state_byte_reg; 
  wire [(WIDTH-1):0] internal_parity_byte_reg = DUT.header_byte_reg; 
  wire [(WIDTH-1):0] packet_parity_byte_reg = DUT.packet_parity_byte_reg; 

  initial
    begin
      clock = 1'b0;
      forever #(T/2) clock = ~clock;
    end

  task initialize;
    {data_in, detect_add, full_state, lfd_state, laf_state, ld_state, rst_int_reg, fifo_full, pkt_valid, resetn} = 1;
  endtask

  task rst_ip(input x, y, input [1:0] address);
    begin
      @(negedge clock);
        resetn = 1'b0;
      @(negedge clock);
	begin
          {resetn, detect_add, pkt_valid} = {1'b1, x, y};
	  payload_len = 6'd14;
	  addr = address;
	  header = {payload_len, addr};
	  data_in = header;
	  parity = parity ^ data_in;
	end
    end
  endtask

  task good_packet;
    begin
      @(negedge clock);
        {detect_add, lfd_state, fifo_full} = 3'b010;
	for(i=0; i<payload_len; i=i+1)
	  begin
	    @(negedge clock);
	      begin
                if(i == 0)
                  {lfd_state, ld_state} = 2'b01;
		payload_data = {$random} % 256;
		data_in = payload_data;
	        parity = parity ^ data_in;
	      end
          end
      @(negedge clock);
        begin
	  {pkt_valid, full_state} = 2'b01;
	  data_in = parity;
	end
      @(negedge clock);
        ld_state = 1'b0;
    end
  endtask
  
  task bad_packet;
    begin
      @(negedge clock);
        {detect_add, lfd_state, fifo_full} = 3'b010;
	for(i=0; i<payload_len; i=i+1)
	  begin
	    @(negedge clock);
	      begin
	        if(i == 0)
	          {lfd_state, ld_state} = 2'b01;
		else if(i == 5)
    	          fifo_full = 1'b1;
		else if(i == 6)
		  begin
		    fifo_full = 1'b0;
		    @(negedge clock);
		      laf_state = 1'b1;
		  end
		else if(i == 7)
		  laf_state = 1'b0;
		  payload_data = {$random} % 256;
		  data_in = payload_data;
		end
	  end
	  @(negedge clock);
	    begin
	      {pkt_valid, full_state} = 2'b01;
	      parity = {$random} % 256;
	      data_in = parity;
	    end
	  @(negedge clock);
	    ld_state = 1'b0;
    end
  endtask

  initial
    begin
      $display("\nGood packet but packet not valid\n");
      initialize;
      rst_ip(1'b0, 1'b1, 2'b10);
      good_packet;
      #200;
   
      $display("\nGood packet but address not detected\n");
      initialize;
      rst_ip(1'b1, 1'b0, 2'b00);
      good_packet;
      #200;
 
      $display("\nGood packet but invalid address\n");
      initialize;
      rst_ip(1'b1, 1'b1, 2'b11);
      good_packet;
      #200;
	  
      $display("\nGood packet with address detected, valid address and valid packet\n");
      initialize;
      rst_ip(1'b1, 1'b1, 2'b00);
      good_packet;
      #200;

      $display("\nBad packet with address detected, valid address and valid packet\n");
      initialize;
      rst_ip(1'b1, 1'b1, 2'b01);
      bad_packet;
      #200;

      rst_int_reg = 1'b1; // Resetting low_pkt_valid to 0

      #5000000 $finish;
    end

  initial
    $monitor ($time, " resetn= %b, pkt_valid= %b, fifo_full= %b, rst_int_reg= %b, detect_add= %b, ld_state= %b, laf_state= %b, full_state= %b, lfd_state= %b, data_in= %b, header_byte_reg= %b, fifo_full_state_byte_reg= %b, internal_parity_byte_reg= %b, packet_parity_byte_reg= %b, parity_done= %b, low_pkt_valid= %b, err= %b, dout= %b", resetn, pkt_valid, fifo_full, rst_int_reg, detect_add, ld_state, laf_state, full_state, lfd_state, data_in, DUT.header_byte_reg, DUT.fifo_full_state_byte_reg, DUT.internal_parity_byte_reg, DUT.packet_parity_byte_reg, parity_done, low_pkt_valid, err, dout);
endmodule
