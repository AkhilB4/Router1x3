// Testbench
module router_sync_tb;
  parameter T = 20;

  reg [1:0] data_in;
  reg detect_add, write_enb_reg, clock, resetn, read_enb_0, read_enb_1, read_enb_2, full_0, full_1, full_2, empty_0, empty_1, empty_2;
  wire vld_out_0, vld_out_1, vld_out_2, soft_reset_0, soft_reset_1, soft_reset_2, fifo_full;
  wire [2:0] write_enb;
  
  router_sync DUT(.data_in(data_in), .detect_add(detect_add), .write_enb_reg(write_enb_reg), .clock(clock), .resetn(resetn), .read_enb_0(read_enb_0), .read_enb_1(read_enb_1), .read_enb_2(read_enb_2), .full_0(full_0), .full_1(full_1), .full_2(full_2), .empty_0(empty_0), .empty_1(empty_1), .empty_2(empty_2), .vld_out_0(vld_out_0), .vld_out_1(vld_out_1), .vld_out_2(vld_out_2), .soft_reset_0(soft_reset_0), .soft_reset_1(soft_reset_1), .soft_reset_2(soft_reset_2), .write_enb(write_enb), .fifo_full(fifo_full));
 
  initial
    begin
      clock = 1'b0;
      forever #(T/2) clock = ~clock;
    end

  task initialize;
    {detect_add, write_enb_reg, read_enb_0, read_enb_1, read_enb_2, full_0, full_1, full_2, empty_0, empty_1, empty_2, resetn} = 8'd15;
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

  task set_address(input [1:0] addr);
    data_in = addr;
  endtask

  initial
    begin
      initialize;
      rst_ip;
      @(negedge clock);
        begin
	  detect_add = 1'b1;
	  set_address(2'b01);
          write_enb_reg = 1'b1;
	end
      @(negedge clock);
        {full_0, full_1, full_2} = 3'b010;
      #100;
      @(negedge clock);
        {empty_0, empty_1, empty_2} = 3'b000;
      #400;
      @(negedge clock);
        read_enb_1 = 1'b1;
      
      rst_ip;
      @(negedge clock);
        begin
	  detect_add = 1'b1;
	  set_address(2'b01);
          write_enb_reg = 1'b0;
	end
      @(negedge clock);
        {full_0, full_1, full_2} = 3'b000;
      #100;
      @(negedge clock);
        {empty_0, empty_1, empty_2} = 3'b010;
      #400;
      @(negedge clock);
        read_enb_1 = 1'b1;
      
      rst_ip;
      @(negedge clock);
        begin
	  detect_add = 1'b0;
	  set_address(2'b11);
          write_enb_reg = 1'b1;
	end
      @(negedge clock);
        {full_0, full_1, full_2} = 3'b010;
      #100;
      @(negedge clock);
        {empty_0, empty_1, empty_2} = 3'b000;
         
      rst_ip;
      @(negedge clock);
        begin
	  detect_add = 1'b1;
	  set_address(2'b00);
          write_enb_reg = 1'b1;
	end
      @(negedge clock);
        {full_0, full_1, full_2} = 3'b100;
      #100;
      @(negedge clock);
        {empty_0, empty_1, empty_2} = 3'b000;
      #400;
      @(negedge clock);
        read_enb_0 = 1'b1;
      
      rst_ip;
      @(negedge clock);
        begin
	  detect_add = 1'b1;
	  set_address(2'b00);
          write_enb_reg = 1'b0;
	end
      @(negedge clock);
        {full_0, full_1, full_2} = 3'b000;
      #100;
      @(negedge clock);
        {empty_0, empty_1, empty_2} = 3'b100;
      #400;
      @(negedge clock);
        read_enb_0 = 1'b1;
      
      rst_ip;
      @(negedge clock);
        begin
	  detect_add = 1'b1;
	  set_address(2'b10);
          write_enb_reg = 1'b1;
	end
      @(negedge clock);
        {full_0, full_1, full_2} = 3'b001;
      #100;
      @(negedge clock);
        {empty_0, empty_1, empty_2} = 3'b010;
      #400;
      @(negedge clock);
        read_enb_1 = 1'b1;
      @(negedge clock);
        read_enb_1 = 1'b0;
      repeat(30)
        #T;
      $finish;
    end

  initial
    $monitor($time, " reset= %b, soft_reset_0= %b, soft_reset_1= %b, soft_reset_2: %b", resetn, soft_reset_0, soft_reset_1, soft_reset_2);
endmodule
