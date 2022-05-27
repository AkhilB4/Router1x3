// Testbench
module router_fsm_tb;
  reg [1:0] data_in;
  reg clock, resetn, pkt_valid, parity_done, soft_reset_0, soft_reset_1, soft_reset_2, fifo_full, low_pkt_valid, fifo_empty_0, fifo_empty_1, fifo_empty_2, fifo_empty_temp;
  wire busy, detect_add, ld_state, laf_state, full_state, write_enb_reg, rst_int_reg, lfd_state;
  
  parameter T = 20,
            DECODE_ADDRESS = 3'b000,
            LOAD_FIRST_DATA = 3'b001,
	    WAIT_TILL_EMPTY = 3'b010,
	    LOAD_DATA = 3'b011,
	    FIFO_FULL_STATE = 3'b100,
	    LOAD_PARITY = 3'b101,
	    LOAD_AFTER_FULL = 3'b110,
	    CHECK_PARITY_ERROR = 3'b111;

  router_fsm DUT(.clock(clock), .resetn(resetn), .pkt_valid(pkt_valid), .parity_done(parity_done), .soft_reset_0(soft_reset_0), .soft_reset_1(soft_reset_1), .soft_reset_2(soft_reset_2), .fifo_full(fifo_full), .low_pkt_valid(low_pkt_valid), .fifo_empty_0(fifo_empty_0), .fifo_empty_1(fifo_empty_1), .fifo_empty_2(fifo_empty_2), .data_in(data_in), .busy(busy), .detect_add(detect_add), .ld_state(ld_state), .laf_state(laf_state), .full_state(full_state), .write_enb_reg(write_enb_reg), .rst_int_reg(rst_int_reg), .lfd_state(lfd_state));
  
  reg [(18*8)-1:0] present_state, next_state;
  
  initial
    begin
      clock = 1'b0;
      forever #(T/2) clock = ~clock; 
    end

  task initialize;
    {pkt_valid, parity_done, soft_reset_0, soft_reset_1, soft_reset_2, fifo_full, fifo_empty_0, fifo_empty_1, fifo_empty_2, low_pkt_valid, resetn} = 11'd1;
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

  task task1(input [1:0]x); //DA-LFD-LD-LP-CPE-DA (000 - 001 - 011 - 101 - 111 - 000)
    begin
      @(negedge clock);
        {data_in, low_pkt_valid, fifo_empty_temp, pkt_valid} = {x, 1'b0, 2'b11};
        case(data_in)
          0: fifo_empty_0 = fifo_empty_temp;
          1: fifo_empty_1 = fifo_empty_temp;
          2: fifo_empty_2 = fifo_empty_temp;
        endcase
      #40;
      @(negedge clock);
        {fifo_full, pkt_valid, low_pkt_valid} = 3'b001;
    end
  endtask

  task task2(input [1:0]x); //DA-LFD-LD-FFS-LAF-LP-CPE-DA (000 - 001 - 011 - 100 - 110 - 101 - 111 - 000)
    begin
      @(negedge clock);
        {data_in, low_pkt_valid, fifo_empty_temp, pkt_valid} = {x, 1'b0, 2'b11};
        case(data_in)
          0: fifo_empty_0 = fifo_empty_temp;
          1: fifo_empty_1 = fifo_empty_temp;
          2: fifo_empty_2 = fifo_empty_temp;
        endcase
      #40;
      @(negedge clock);
        fifo_full = 1'b1;
      #40;
      @(negedge clock);
	{fifo_full, pkt_valid, low_pkt_valid} = 3'b001;
    end
  endtask

  task task3(input [1:0]x); //DA-LFD-LD-FFS-LAF-LD-LP-CPE-DA (000 - 001 - 011 - 100 - 110 - 011 - 101 - 111 - 000)
    begin
      @(negedge clock);
       {data_in, low_pkt_valid, fifo_empty_temp, pkt_valid} = {x, 1'b0, 2'b11};
        case(data_in)
          0: fifo_empty_0 = fifo_empty_temp;
          1: fifo_empty_1 = fifo_empty_temp;
          2: fifo_empty_2 = fifo_empty_temp;
        endcase
      #40;
      @(negedge clock);
        fifo_full = 1'b1;
      #40;
      @(negedge clock);
	fifo_full = 1'b0;
      #40;
      @(negedge clock);
	pkt_valid = 1'b0;
    end
  endtask

  task task4(input [1:0]x); //DA-LFD-LD-LP-CPE-FFS-LAF-DA (000 - 001 - 011 - 101 - 111 - 100 - 110 - 000)
    begin
      @(negedge clock);
        {data_in, low_pkt_valid, fifo_empty_temp, pkt_valid} = {x, 1'b0, 2'b11};
        case(data_in)
          0: fifo_empty_0 = fifo_empty_temp;
          1: fifo_empty_1 = fifo_empty_temp;
          2: fifo_empty_2 = fifo_empty_temp;
        endcase
      #40;
      @(negedge clock);
	pkt_valid = 1'b0;
      @(negedge clock);
	fifo_full = 1'b1;
      #40;
      @(negedge clock);
	{fifo_full, parity_done} = 2'b01;
    end
  endtask

  task load_first_data_to_decode_address(input [1:0]x);
    begin 
      @(negedge clock);
        {data_in, low_pkt_valid, fifo_empty_temp, pkt_valid} = {x, 1'b0, 2'b11};
        case(data_in)
          0: fifo_empty_0 = fifo_empty_temp;
          1: fifo_empty_1 = fifo_empty_temp;
          2: fifo_empty_2 = fifo_empty_temp;
        endcase
      @(negedge clock);
        case(data_in)
          0: soft_reset_0 = 1'b1;
          1: soft_reset_1 = 1'b1;
          2: soft_reset_2 = 1'b1;
        endcase
      @(negedge clock);
        {low_pkt_valid, pkt_valid} = 2'b10;
      @(negedge clock);
    end
  endtask
  
  task wait_till_empty_to_decode_address(input [1:0]x);
    begin 
      @(negedge clock);
        {data_in, low_pkt_valid, fifo_empty_temp, pkt_valid} = {x, 1'b0, 2'b01};
        case(data_in)
          0: fifo_empty_0 = fifo_empty_temp;
          1: fifo_empty_1 = fifo_empty_temp;
          2: fifo_empty_2 = fifo_empty_temp;
        endcase
      @(negedge clock);
        case(data_in)
          0: soft_reset_0 = 1'b1;
          1: soft_reset_1 = 1'b1;
          2: soft_reset_2 = 1'b1;
        endcase
      @(negedge clock);
        {low_pkt_valid, pkt_valid} = 2'b10;
      @(negedge clock);
    end
  endtask
   
  task load_data_to_decode_address(input [1:0]x);
    begin 
      @(negedge clock);
        {data_in, low_pkt_valid, fifo_empty_temp, pkt_valid} = {x, 1'b0, 2'b11};
        case(data_in)
          0: fifo_empty_0 = fifo_empty_temp;
          1: fifo_empty_1 = fifo_empty_temp;
          2: fifo_empty_2 = fifo_empty_temp;
        endcase
      repeat(2)
        @(negedge clock);
      case(data_in)
        0: soft_reset_0 = 1'b1;
        1: soft_reset_1 = 1'b1;
        2: soft_reset_2 = 1'b1;
      endcase
      @(negedge clock);
        {low_pkt_valid, pkt_valid} = 2'b10;
      @(negedge clock);
    end
  endtask

  task fifo_full_to_decode_address(input [1:0]x);
    begin
      @(negedge clock);
        {data_in, low_pkt_valid, fifo_empty_temp, pkt_valid} = {x, 1'b0, 2'b11};
        case(data_in)
          0: fifo_empty_0 = fifo_empty_temp;
          1: fifo_empty_1 = fifo_empty_temp;
          2: fifo_empty_2 = fifo_empty_temp;
        endcase
      @(negedge clock);
        fifo_full = 1'b1;
      repeat(2)
        @(negedge clock);
      case(data_in)
        0: soft_reset_0 = 1'b1;
        1: soft_reset_1 = 1'b1;
        2: soft_reset_2 = 1'b1;
      endcase
      @(negedge clock);
    end
  endtask

  task load_parity_to_decode_address(input [1:0]x);
    begin 
      @(negedge clock);
        {data_in, low_pkt_valid, fifo_empty_temp, pkt_valid} = {x, 1'b0, 2'b11};
        case(data_in)
          0: fifo_empty_0 = fifo_empty_temp;
          1: fifo_empty_1 = fifo_empty_temp;
          2: fifo_empty_2 = fifo_empty_temp;
        endcase
      #40;
      @(negedge clock);
	pkt_valid = 1'b0;
      @(negedge clock);
	fifo_full = 1'b1;
      case(data_in)
        0: soft_reset_0 = 1'b1;
        1: soft_reset_1 = 1'b1;
        2: soft_reset_2 = 1'b1;
      endcase
      @(negedge clock);
    end
  endtask

  // To display the present state in string format
  always@(DUT.present_state)
    begin
      case(DUT.present_state)
        DECODE_ADDRESS: present_state = "DECODE_ADDRESS";
        LOAD_FIRST_DATA: present_state = "LOAD_FIRST_DATA";
	WAIT_TILL_EMPTY: present_state = "WAIT_TILL_EMPTY";
	LOAD_DATA: present_state = "LOAD_DATA";
	FIFO_FULL_STATE: present_state = "FIFO_FULL_STATE";
	LOAD_PARITY: present_state = "LOAD_PARITY";
	LOAD_AFTER_FULL: present_state = "LOAD_AFTER_FULL";
	CHECK_PARITY_ERROR: present_state = "CHECK_PARITY_ERROR";
	default: present_state = "ERROR";
      endcase
    end

  // To display the next state in string format
  always@(DUT.next_state)
    begin
      case(DUT.next_state)
	DECODE_ADDRESS: next_state = "DECODE_ADDRESS";
        LOAD_FIRST_DATA: next_state = "LOAD_FIRST_DATA";
	WAIT_TILL_EMPTY: next_state = "WAIT_TILL_EMPTY";
	LOAD_DATA: next_state = "LOAD_DATA";
	FIFO_FULL_STATE: next_state = "FIFO_FULL_STATE";
	LOAD_PARITY: next_state = "LOAD_PARITY";
	LOAD_AFTER_FULL: next_state = "LOAD_AFTER_FULL";
	CHECK_PARITY_ERROR: next_state = "CHECK_PARITY_ERROR";
	default: next_state = "ERROR";
      endcase
    end
  
  initial
    begin
      $display("\nDA-LFD-LD-LP-CPE-DA for address 0\n");
      initialize;  
      rst_ip;
      task1(2'b00); //DA-LFD-LD-LP-CPE-DA
      #300;

      $display("\nDA-LFD-LD-LP-CPE-DA for address 1\n");
      initialize;  
      rst_ip;
      task1(2'b01); //DA-LFD-LD-LP-CPE-DA
      #300;

      $display("\nDA-LFD-LD-LP-CPE-DA for address 2\n");
      initialize;  
      rst_ip;
      task1(2'b10); //DA-LFD-LD-LP-CPE-DA
      #300;

      $display("\nDA-LFD-LD-LP-FFS-LAF-LP-CPE-DA for address 0\n");
      initialize;
      rst_ip;
      task2(2'b00); //DA-LFD-LD-FFS-LAF-LP-CPE-DA
      #300;

      $display("\nDA-LFD-LD-LP-FFS-LAF-LP-CPE-DA for address 1\n");
      initialize;
      rst_ip;
      task2(2'b01); //DA-LFD-LD-FFS-LAF-LP-CPE-DA
      #300;

      $display("\nDA-LFD-LD-LP-FFS-LAF-LP-CPE-DA for address 2\n");
      initialize;
      rst_ip;
      task2(2'b10); //DA-LFD-LD-FFS-LAF-LP-CPE-DA
      #300;

      $display("\nDA-LFD-LD-LP-FFS-LAF-LD-LP-CPE-DA for address 0\n");
      initialize;
      rst_ip;
      task3(2'b00); //DA-LFD-LD-FFS-LAF-LD-LP-CPE-DA
      #300;
 
      $display("\nDA-LFD-LD-LP-FFS-LAF-LD-LP-CPE-DA for address 1\n");
      initialize;
      rst_ip;
      task3(2'b01); //DA-LFD-LD-FFS-LAF-LD-LP-CPE-DA
      #300;

      $display("\nDA-LFD-LD-LP-FFS-LAF-LD-LP-CPE-DA for address 2\n");
      initialize;
      rst_ip;
      task3(2'b10); //DA-LFD-LD-FFS-LAF-LD-LP-CPE-DA
      #300;

      $display("\nDA-LFD-LD-LP-CPE-FFS-LAF-DA for address 0\n");
      initialize;
      rst_ip;
      task4(2'b00); //DA-LFD-LD-LP-CPE-FFS-LAF-DA
      #300;

      $display("\nDA-LFD-LD-LP-CPE-FFS-LAF-DA for address 1\n");
      initialize;
      rst_ip;
      task4(2'b01); //DA-LFD-LD-LP-CPE-FFS-LAF-DA
      #300;

      $display("\nDA-LFD-LD-LP-CPE-FFS-LAF-DA for address 2\n");
      initialize;
      rst_ip;
      task4(2'b10); //DA-LFD-LD-LP-CPE-FFS-LAF-DA
      #300;

      $display("\nLOAD_FIRST_DATA to DECODE_ADDRESS for address 0\n");
      initialize;
      rst_ip;
      load_first_data_to_decode_address(2'b00);
      #300;
 
      $display("\nWAIT_TILL_EMPTY to DECODE_ADDRESS for address 0\n");
      initialize;
      rst_ip;
      wait_till_empty_to_decode_address(2'b00);
      #300;

      $display("\nLOAD_FIRST_DATA to DECODE_ADDRESS for address 1\n");
      initialize;
      rst_ip;
      load_first_data_to_decode_address(2'b01);

      $display("\nWAIT_TILL_EMPTY to DECODE_ADDRESS for address 1\n");
      initialize;
      rst_ip;
      wait_till_empty_to_decode_address(2'b01);
      #300;
      
      $display("\nLOAD_FIRST_DATA to DECODE_ADDRESS for address 2\n");
      initialize;
      rst_ip;
      load_first_data_to_decode_address(2'b10);
      #300;

      $display("\nWAIT_TILL_EMPTY to DECODE_ADDRESS for address 2\n");
      initialize;
      rst_ip;
      wait_till_empty_to_decode_address(2'b10);
      #300;

      $display("\nLOAD_DATA to DECODE_ADDRESS for address 0\n");
      initialize;
      rst_ip;
      load_data_to_decode_address(2'b00);
      #300;

      $display("\nLOAD_DATA to DECODE_ADDRESS for address 1\n");
      initialize;
      rst_ip;
      load_data_to_decode_address(2'b01);
      #300;

      $display("\nLOAD_DATA to DECODE_ADDRESS for address 2\n");
      initialize;
      rst_ip;
      load_data_to_decode_address(2'b10);
      #300;

      $display("\nFIFO_FULL_STATE to DECODE_ADDRESS for address 0\n");
      initialize;
      rst_ip;
      fifo_full_to_decode_address(2'b00);
      #300;

      $display("\nFIFO_FULL_STATE to DECODE_ADDRESS for address 1\n");
      initialize;
      rst_ip;
      fifo_full_to_decode_address(2'b01);
      #300;
 
      $display("\nFIFO_FULL_STATE to DECODE_ADDRESS for address 2\n");
      initialize;
      rst_ip;
      fifo_full_to_decode_address(2'b10);
      #300;
 
      $display("\nLOAD_PARITY to DECODE_ADDRESS for address 0\n");
      initialize;
      rst_ip;
      load_parity_to_decode_address(2'b00);
      #300;

      $display("\nLOAD_PARITY to DECODE_ADDRESS for address 1\n");
      initialize;
      rst_ip;
      load_parity_to_decode_address(2'b01);
      #300;

      $display("\nLOAD_PARITY to DECODE_ADDRESS for address 2\n");
      initialize;
      rst_ip;
      load_parity_to_decode_address(2'b10);
      #300;

      initialize;
      rst_ip;
      @(negedge clock);
        {data_in, low_pkt_valid, fifo_empty_temp, pkt_valid} = {2'b11, 1'b0, 2'b11};

      #100000000 $finish;
    end

  initial
    $monitor ($time, " resetn= %b, pkt_valid= %b, low_pkt_valid= %b, data_in= %b, parity_done= %b, soft_reset_0= %b, soft_reset_1= %b, soft_reset_2= %b, fifo_empty_0= %b, fifo_empty_1= %b, fifo_empty_2= %b, present_state= %0s, next_state= %0s", resetn, pkt_valid, low_pkt_valid, data_in, parity_done, soft_reset_0, soft_reset_1, soft_reset_2, fifo_empty_0, fifo_empty_1, fifo_empty_2, present_state, next_state);
endmodule
