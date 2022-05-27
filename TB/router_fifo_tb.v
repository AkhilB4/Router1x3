// Testbench
module router_fifo_tb;
  parameter T = 20,
            WIDTH = 8,
            DEPTH = 16,
	    ADD_WIDTH = 4;

  integer k;

  reg clock, resetn, write_enb, soft_reset, read_enb, lfd_state;
  reg [(WIDTH-1):0] data_in;
  wire [(WIDTH-1):0] data_out;
  wire empty, full;

  router_fifo DUT(.clock(clock), .resetn(resetn), .write_enb(write_enb), .soft_reset(soft_reset), .read_enb(read_enb), .lfd_state(lfd_state), .data_in(data_in), .data_out(data_out), .empty(empty), .full(full));

  initial
    begin
      clock = 1'b0;
      forever #(T/2) clock = ~clock;
    end

  task initialize;
    begin
      {lfd_state, soft_reset, read_enb, write_enb, resetn} = 4'b1;
    end
  endtask

  task rst_ip;
    begin
      repeat(2)
        begin
	  @(negedge clock);
	    resetn = ~resetn;
        end
    end
  endtask

  task write(input [5:0]x);
    reg [WIDTH-1:0] payload_data, parity, header;
    reg [5:0] payload_len;
    reg [1:0] addr;
    begin
      @(negedge clock);
        begin
	  {payload_len, addr} = {x, 2'b01};
          header = {payload_len, addr};
	  {data_in, lfd_state} = {header, 1'b1};
	end
      @(negedge clock);
        write_enb = 1'b1;
	for(k=0; k<payload_len; k=k+1)
	  begin
	    @(negedge clock);
              begin
	        lfd_state = 1'b0;
		payload_data = {$random}%256;
		data_in = payload_data;
	      end
	  end
      @(negedge clock);
        begin
	  parity = {$random}%256;
	  data_in = parity;
	end
      @(negedge clock);
        {write_enb, data_in} = {1'b0, 8'bx};
    end
  endtask

  task read;
    begin
      @(negedge clock);
        read_enb = 1'b1;
    end
  endtask

  initial
    begin
      initialize;
      rst_ip;
      write(6'd17);
      read;
      wait(DUT.empty)
      read_enb = 1'b0;
	  
      /* FIFO reads data per posedge of clock, thereby it requires 280 clock cycles, so we provide a delay of 500ns so that all the data can be read
      out within the given time and soft reset can be enabled.*/
      #500;  
      @(negedge clock);
        soft_reset = 1'b1;
      @(negedge clock);
        soft_reset = 1'b0;      
      $finish;
    end

  initial
    begin
      $monitor("Time(t)= %t, active_low_rst= %b, soft_reset= %b, write_enable= %b, read_enable= %b, write_add_ptr= %b, read_add_ptr= %b, lfd_state= %b, write_data= %b, read_data= %b, mem= %p", $time, resetn, soft_reset, write_enb, read_enb, DUT.wr_ptr, DUT.rd_ptr, DUT.temp, DUT.data_in, DUT.fifo_mem[DUT.rd_ptr], DUT.fifo_mem);
    end
endmodule
