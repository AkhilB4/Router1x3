// RTL Code to generate FIFO
module router_fifo #(parameter WIDTH = 8, DEPTH = 16, ADD_WIDTH = 4) 
                    (input clock, resetn, write_enb, soft_reset, read_enb, lfd_state, 
                     input [(WIDTH-1):0] data_in,
		     output reg [(WIDTH-1):0] data_out,
		     output empty, full);
  
  integer i;
  reg [ADD_WIDTH:0] rd_ptr, wr_ptr;
  reg [WIDTH:0] fifo_mem [(DEPTH-1):0]; 
  reg [4:0] count;
  reg temp;
  
  assign {full, empty} = {wr_ptr == {~rd_ptr[4], rd_ptr[3:0]}, rd_ptr == wr_ptr};
  
  always@(posedge clock)
    begin
      temp <= (~resetn) ? 1'b0 : (soft_reset) ? 1'b0 : lfd_state;
      if(!resetn) // Resets the FIFO and the related ports
        begin
	      for(i=0; i<DEPTH; i=i+1)
	        fifo_mem[i] <= 0;
	      {count, rd_ptr, wr_ptr, data_out} <= {5'b0, 5'b0, 5'b0, 8'b0};
	    end
      else if(soft_reset)
	    begin
          for(i=0; i<DEPTH; i=i+1)
	        fifo_mem[i] <= 0;
	      {count, rd_ptr, wr_ptr, data_out} <= {5'b0, 5'b0, 5'b0, 8'bz};
	    end
	  else
	    begin
	      if(write_enb && !full) // Performs write operation on FIFO
	        begin
	          fifo_mem[wr_ptr[3:0]] <= {temp, data_in};
                wr_ptr <= wr_ptr + 1;
	        end
	      if(!empty) // Performs read operation on FIFO
	        begin
		      if(read_enb)
	   	        begin
	     	     // Checking if the lfd_state value for payload_data is 0 or not
	      	     {count, data_out} <= {(~fifo_mem[rd_ptr[3:0]][WIDTH]) ? (count > 0) * (count - 1) : fifo_mem[rd_ptr[3:0]][7:2] + 1, fifo_mem[rd_ptr[3:0]][(WIDTH-1):0]};
	      	     rd_ptr <= rd_ptr + 1;
	    	    end
 	        end
	      else
		    data_out <= 8'bz;
        end
    end
endmodule
