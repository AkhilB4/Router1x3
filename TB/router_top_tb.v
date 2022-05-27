// Testbench
module router_top_tb;

  parameter T = 20,
            DECODE_ADDRESS = 3'b000,
            LOAD_FIRST_DATA = 3'b001,
	    WAIT_TILL_EMPTY = 3'b010,
	    LOAD_DATA = 3'b011,
	    FIFO_FULL_STATE = 3'b100,
	    LOAD_PARITY = 3'b101,
	    LOAD_AFTER_FULL = 3'b110,
	    CHECK_PARITY_ERROR = 3'b111;
  integer i;

  reg [7:0] data_in, payload_data, parity, header;
  reg clock, resetn, pkt_valid, read_enb_0, read_enb_1, read_enb_2;
  reg [5:0] payload_len;
  reg [1:0] addr;
  wire [7:0] data_out_0, data_out_1, data_out_2;
  wire vld_out_0, vld_out_1, vld_out_2, error, busy;
  
  event e1, e2;

  router_top ROUTER_DUT(.clock(clock), .resetn(resetn), .pkt_valid(pkt_valid), .read_enb_0(read_enb_0), .read_enb_1(read_enb_1), .read_enb_2(read_enb_2), .data_in(data_in), .data_out_0(data_out_0), .data_out_1(data_out_1), .data_out_2(data_out_2), .vld_out_0(vld_out_0), .vld_out_1(vld_out_1), .vld_out_2(vld_out_2), .error(error), .busy(busy));
  
  reg [7*20:0] string;

  always@(ROUTER_DUT.ROUTER_FSM.present_state)
    begin
      case(ROUTER_DUT.ROUTER_FSM.present_state)
        DECODE_ADDRESS :     begin 
                               $write("DECODE_ADDRESS > ");             
                               string = "DA";  
                             end
        LOAD_FIRST_DATA :    begin 
                               $write("LOAD_FIRST_DATA > ");            
                               string = "LFD";  
                             end
        WAIT_TILL_EMPTY :    begin 
                               $write("WAIT_TILL_EMPTY > ");            
                               string = "WTE";  
                             end
        LOAD_DATA :          begin 
                               $write("LOAD_DATA > ");                  
                               string = "LD";  
                             end
        FIFO_FULL_STATE :    begin 
                               $write("FIFO_FULL_STATE > ");                
                               string = "FFS";  
                             end
        LOAD_PARITY :        begin 
                               $write("LOAD_PARITY > ");            
                               string = "LP"; 
                             end
        LOAD_AFTER_FULL :    begin 
                               $write("LOAD_AFTER_FULL > ");         
                               string = "LAF";  
                             end
        CHECK_PARITY_ERROR : begin 
                               $write("CHECK_PARITY_ERROR > ");            
                               string = "CPE";  
                             end
      endcase
    end

  initial
    begin
      clock = 1'b0;
      forever #(T/2) clock = ~clock;
    end

  task initialize;
    {pkt_valid, read_enb_0, read_enb_1, read_enb_2, resetn} = 5'b1;
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
  
  task packet_generation(input [5:0] x, input [1:0] address, input ip_pkt_valid);
    begin
      @(negedge clock);
        wait(~busy)
      @(negedge clock);
	begin
          {payload_len, addr} = {x, address};
	  header = {payload_len, addr};
	  parity = 0;
	  data_in = header;
          pkt_valid = ip_pkt_valid;
	  parity = parity ^ header;
        end
          @(negedge clock);
            wait(~busy)
          for(i=0; i<payload_len; i=i+1)
	    begin
              @(negedge clock);
	        begin
	          wait(~busy)
	          payload_data = {$random} % 256;
	          data_in = payload_data;
	          parity = parity ^ payload_data;
                end
	    end
          @(negedge clock);
            begin
	      wait(~busy)
              pkt_valid = 0;
              data_in = parity;
            end
    end
  endtask
  
  task packet_generation_with_random_parity(input [5:0] x, input [1:0] address);
    begin
      @(negedge clock);
        wait(~busy)
      @(negedge clock);
	begin
	  {payload_len, addr} = {x, (address !== 2'b11) ? address : 2'bxx};
	  header = {payload_len, addr};
	  data_in = header;
	  pkt_valid = (addr !== 2'b11) ? 1'b1 : 1'b0;
        end
      @(negedge clock);
        wait(~busy)
      for(i=0; i<payload_len; i=i+1)
	begin
          @(negedge clock);
	    begin
	      wait(~busy)
	      payload_data = {$random} % 256;
	      data_in = payload_data;
	      parity = parity ^ payload_data;
            end
	end
      @(negedge clock);
        begin
	  wait(~busy)
          pkt_valid = 0;
          parity = {$random} % 256;
          data_in = parity;
        end
    end
  endtask

  task pkt_gen_17_with_event(input [1:0] address);
    begin
      @(negedge clock);
        wait(~busy)
      @(negedge clock);
	begin
          payload_len = 6'd17;
	  addr = (address !== 2'b11) ? address : 2'bxx;
	  header = {payload_len, addr};
	  parity = 0;
	  data_in = header;
          pkt_valid = (addr !== 2'b11) ? 1'b1: 1'b0;
	  parity = parity ^ header;
	end
      @(negedge clock);
        wait(~busy)
      for(i=0; i<payload_len; i=i+1)
        begin
          @(negedge clock);
	    begin
	      wait(~busy)
	      payload_data = {$random} % 256;
	      data_in = payload_data;
              parity = parity ^ payload_data;
	    end
        end
      ->e1;
      @(negedge clock);
        begin
	  wait(~busy)
          pkt_valid = 0;
          data_in = parity;
	end
    end
  endtask
  
  task random_pkt_with_event(input [1:0] address);
    begin
      ->e2;
      @(negedge clock);
        wait(~busy)
      @(negedge clock);
	begin
          payload_len = {$random} % 63 + 1;
          addr = (address !== 2'b11) ? address : 2'bxx;
	  header = {payload_len, addr};
	  parity = 0;
	  data_in = header;
	  pkt_valid = (addr !== 2'b11) ? 1'b1 : 1'b0;
	  parity = parity ^ header;
	end
      @(negedge clock);
        wait(~busy)
      for(i=0; i<payload_len; i=i+1)
	begin
          @(negedge clock);
	    begin
	      wait(~busy)
	      payload_data = {$random} % 256;
	      data_in = payload_data;
	      parity = parity ^ payload_data;
	    end
	end
      @(negedge clock);
	begin
	  wait(~busy)
	  pkt_valid = 0;
	  data_in = parity;
	end
    end
  endtask

  task header_generation(input [5:0]x, input[1:0] address, input ip_pkt_valid);
    begin
      @(negedge clock);
	begin
	  data_in = {x, address};
	  pkt_valid = ip_pkt_valid;
	end
    end
  endtask

  task address_based_read_signal_enable_and_disable(input [1:0] address);
    begin
      case(address)
        0: begin
             @(negedge clock);
               read_enb_0 = 1'b1;
             wait(~vld_out_0)
             @(negedge clock);
               read_enb_0 = 1'b0;
           end
        1: begin
             @(negedge clock);
               read_enb_1 = 1'b1;
             wait(~vld_out_1)
             @(negedge clock);
               read_enb_1 = 1'b0;
           end
        2: begin
             @(negedge clock);
               read_enb_2 = 1'b1;
             wait(~vld_out_2)
             @(negedge clock);
               read_enb_2 = 1'b0;
           end
      endcase
    end
  endtask

  initial
    begin
      initialize;
      rst_ip;

      $display("\n\nGenerating packet of payload length 4 for address 0 with reading\n");
      packet_generation(6'd4, 2'b00, 1'b1); // payload length - 4 (payload length < 14)
      address_based_read_signal_enable_and_disable(2'b00);

      rst_ip;
      #20;

      $display("\n\nGenerating packet of payload length 4 (<14) for address 1 with reading\n");
      packet_generation(6'd4, 2'b01, 1'b1); // payload length - 4 (payload length < 14)
      address_based_read_signal_enable_and_disable(2'b01);

      rst_ip;
      #20;

      $display("\n\nGenerating packet of payload length 4 (<14) for address 2 with reading\n");
      packet_generation(6'd4, 2'b10, 1'b1); // payload length - 4 (payload length < 14)
      address_based_read_signal_enable_and_disable(2'b10);

      rst_ip;
      #20;

      $display("\n\nGenerating packet of payload length 14 for address 0 with reading\n");
      packet_generation(6'd14, 2'b00, 1'b1); // payload length - 14
      #30;
      address_based_read_signal_enable_and_disable(2'b00);

      rst_ip;
      #20;

      // Transition from WAIT_TILL_EMPTY state to DECODE_ADDRESS state for address 0
      $display("\n\nGenerating packet of payload length 5 and payload length 8 for address 0 without reading (WAIT_TILL_EMPTY > DECODE_ADDRESS)\n");
      packet_generation(6'd5, 2'b00, 1'b1);
      packet_generation(6'd8, 2'b00, 1'b1);

      rst_ip;
      #20;

      // Transition from WAIT_TILL_EMPTY state to DECODE_ADDRESS state for address 1
      $display("\n\nGenerating packet of payload length 5 and payload length 8 for address 1 without reading (WAIT_TILL_EMPTY > DECODE_ADDRESS)\n");
      packet_generation(6'd5, 2'b01, 1'b1);
      packet_generation(6'd8, 2'b01, 1'b1);

      rst_ip;
      #20;

      // Transition from WAIT_TILL_EMPTY state to DECODE_ADDRESS state for address 2
      $display("\n\nGenerating packet of payload length 5 and payload length 8 for address 2 without reading (WAIT_TILL_EMPTY > DECODE_ADDRESS)\n");
      packet_generation(6'd5, 2'b10, 1'b1);
      packet_generation(6'd8, 2'b10, 1'b1);

      rst_ip;
      #20;

      // Transition from WAIT_TILL_EMPTY state to DECODE_ADDRESS state for random address
      $display("\n\nGenerating packet of payload length 5 and payload length 8 for random address without reading (WAIT_TILL_EMPTY > DECODE_ADDRESS)\n");
      packet_generation(6'd5, 2'b11, 1'b1);
      packet_generation(6'd8, 2'b00, 1'b1);

      rst_ip;
      #20;

      $display("\n\nGenerating packet of payload length 16 (>14) for address 0 with reading\n");
      packet_generation(6'd16, 2'b00, 1'b1);
      #30;
      address_based_read_signal_enable_and_disable(2'b00);

      rst_ip;
      #20;

      $display("\n\nGenerating packet of payload length 16 (>14) for address 1 with reading\n");
      packet_generation(6'd16, 2'b01, 1'b1);
      #30;
      address_based_read_signal_enable_and_disable(2'b01);

      rst_ip;
      #20;

      $display("\n\nGenerating packet of payload length 16 (>14) for address 2 with reading\n");
      packet_generation(6'd16, 2'b10, 1'b1);
      #30;
      address_based_read_signal_enable_and_disable(2'b10);

      rst_ip;
      #20;

      // Transition from WAIT_TILL_EMPTY state to LOAD_FIRST_DATA state for address 0
      $display("\n\nGenerating packet of payload length 5 and payload length 8 for address 0 without reading (WAIT_TILL_EMPTY > LOAD_FIRST_DATA)\n");
      packet_generation(6'd5, 2'b00, 1'b1);
      packet_generation(6'd8, 2'b00, 1'b1);
      address_based_read_signal_enable_and_disable(2'b00);

      rst_ip;
      #20;

      $display("\n\nGenerating packet of payload length 17 (>14) with event for address 0 with reading\n");
      pkt_gen_17_with_event(2'b00);
      
      #100;
      rst_ip;
      #20;

      $display("\n\nGenerating packet of payload length 17 (>14) with event for address 1 with reading\n");
      pkt_gen_17_with_event(2'b01);
      
      #100;
      rst_ip;
      #20;

      $display("\n\nGenerating packet of payload length 17 (>14) with event for address 2 with reading\n");
      pkt_gen_17_with_event(2'b10);
      
      #100;
      rst_ip;
      #20;

      // Transition from LOAD_FIRST_DATA state to DECODE_ADDRESS state for address 0
      $display("\n\nGenerating header and then performing reset for address 0 (LOAD_FIRST_DATA > DECODE_ADDRESS)\n");
      header_generation(6'd9, 2'b00, 1'b1);
      
      rst_ip;
      #10;

      // Transition from LOAD_DATA state to DECODE_ADDRESS state for address 0
      $display("\n\nGenerating header and then performing reset for address 0 (LOAD_DATA > DECODE_ADDRESS)\n");
      header_generation(6'd9, 2'b00, 1'b1);
      
      #50;
      rst_ip;
      #10;

      $display("\n\nGenerating header but pkt_valid is disabled\n");
      header_generation(6'd9, 2'b10, 1'b0);

      rst_ip;
      #10;

      // Transition from FIFO_FULL_STATE state to DECODE_ADDRESS state for address 0
      $display("\n\nGenerating packet of payload length 16 (>14) for address 0 with reading for short time (FIFO_FULL_STATE > DECODE_ADDRESS)\n");
      fork
        packet_generation(6'd16, 2'b00, 1'b1);
        begin
          wait(ROUTER_DUT.ROUTER_FIFO_0.full)
          @(negedge clock);
            read_enb_0 = 1'b1;
          @(negedge clock);
            read_enb_0 = 1'b0;
            resetn = 1'b0;
          @(negedge clock);
            resetn = 1'b1;
        end
      join

      #20;

      // Transition from LOAD_AFTER_FULL state to DECODE_ADDRESS state for address 0
      $display("\n\nGenerating packet of payload length 16 (>14) for address 0 with reading for short time (LOAD_AFTER_FULL > DECODE_ADDRESS)\n");
      fork
        packet_generation(6'd16, 2'b00, 1'b1);
        begin
          wait(ROUTER_DUT.ROUTER_FIFO_0.full)
          @(negedge clock);
            read_enb_0 = 1'b1;
          @(negedge clock);
            read_enb_0 = 1'b0;
        end
      join

      #10;
      rst_ip;
      #20;

      $display("\n\nGenerating packet of random payload length with event for address 0\n");
      random_pkt_with_event(2'b00);

      rst_ip;
      #20;

      $display("\n\nGenerating packet of random payload length with event for address 1\n");
      random_pkt_with_event(2'b01);

      rst_ip;
      #20;

      $display("\n\nGenerating packet of random payload length with event for address 2\n");
      random_pkt_with_event(2'b10);

      rst_ip;
      #20;

      $display("\n\nGenerating packet of payload length 8 with random parity for address 0\n");
      packet_generation_with_random_parity(6'd8, 2'b00);
      address_based_read_signal_enable_and_disable(2'b00);
      
      rst_ip;
      #20;

      $display("\n\nGenerating packet of payload length 8 with random parity for address 1\n");
      packet_generation_with_random_parity(6'd8, 2'b01);
      address_based_read_signal_enable_and_disable(2'b01);
      
      rst_ip;
      #20;

      $display("\n\nGenerating packet of payload length 8 with random parity for address 2\n");
      packet_generation_with_random_parity(6'd8, 2'b10);
      address_based_read_signal_enable_and_disable(2'b10);
      
      rst_ip;
      #20;

      $display("\n\nGenerating header of payload length 5 for random address\n");
      header_generation(6'd5, 2'b11, 1'b1);

      #20;
      rst_ip;
      #20;

      // Toggling area
      // FIFO 0, FIFO 1 and FIFO 2
      @(negedge clock);
        {ROUTER_DUT.ROUTER_FIFO_0.i, ROUTER_DUT.ROUTER_FIFO_1.i, ROUTER_DUT.ROUTER_FIFO_2.i} = {32'h00000000, 32'h00000000, 32'h00000000};
      @(negedge clock);
        {ROUTER_DUT.ROUTER_FIFO_0.i, ROUTER_DUT.ROUTER_FIFO_1.i, ROUTER_DUT.ROUTER_FIFO_2.i} = {32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF};
      @(negedge clock);
        {ROUTER_DUT.ROUTER_FIFO_0.i, ROUTER_DUT.ROUTER_FIFO_1.i, ROUTER_DUT.ROUTER_FIFO_2.i} = {32'h00000000, 32'h00000000, 32'h00000000};

      #50000 $finish;
    end

  initial
    begin
      @(e1)
        begin
          address_based_read_signal_enable_and_disable(addr);
	end
    end

  initial
    begin
      @(e2)
        begin
          case(addr)
            0: begin
                 wait(~vld_out_0)
                 wait(vld_out_0)
                 @(negedge clock);
                   read_enb_0 = 1'b1;
                 wait(~vld_out_0)
                 @(negedge clock);
                   read_enb_0 = 1'b0;
               end
            1: begin
                 wait(~vld_out_1)
                 wait(vld_out_1)
                 @(negedge clock);
                   read_enb_1 = 1'b1;
                 wait(~vld_out_1)
                 @(negedge clock);
                   read_enb_1 = 1'b0;
               end
            2: begin 
                 wait(~vld_out_2)
                 wait(vld_out_2)
                 @(negedge clock);
                   read_enb_2 = 1'b1;
                 wait(~vld_out_2)
                 @(negedge clock);
                   read_enb_2 = 1'b0;
               end
          endcase
        end
    end
endmodule
