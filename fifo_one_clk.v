`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2022 12:26:42 PM
// Design Name: 
// Module Name: fifo_one_clk
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fifo_one_clk (rst,clk, write_data,write_req, read_data,read_data_valid, read_req, fifo_of, fifo_uf, fifo_empty, fifo_full);

parameter DATA = 8;
parameter ADDR = 10; 
 /*********************** Port declerations *****************************************/
     input  			rst,clk;
     input [7:0] 		write_data;
     input 				write_req, read_req; // toggle
     output reg [7:0] 	read_data;
	 output reg			read_data_valid;
	 output reg 		fifo_of, fifo_uf;
	 output				fifo_empty, fifo_full;

 //signals which are used inside the module and are not output from the module
/*********************** Internal signals *****************************************/
   	reg [DATA-1:0] my_fifo [0:2**ADDR-1];
	reg  [ADDR-1:0] read_pointer, write_pointer;	
   	  


/******************************** parameters ***************************************/
/******************************** Assignments *************************************/

 assign	fifo_empty	= (read_pointer == write_pointer);
 //wire 	[1:0] pointers_diff =  read_pointer - write_pointer;
 wire	fifo_full2	= (read_pointer - write_pointer == 2'b1);
 wire	fifo_full3	= (read_pointer == write_pointer + 2'b1);
 wire [ADDR-1:0] diff = read_pointer - write_pointer;
 wire 		 fifo_full =   (diff == 1);
 wire	write_to_fifo = write_req & !fifo_full;
 wire	read_from_fifo = read_req & !fifo_empty;

/******************************** sample *************************************/

    
   
      		
/******************************** write to fifo ******************************/
   always @ (posedge clk or negedge rst)
    if (!rst)
  	 	write_pointer <= 0;
	 else if (write_to_fifo)
    	write_pointer <= write_pointer + 1;

// 		
always @ (posedge clk)
	if (write_to_fifo)
		my_fifo[write_pointer] <= write_data[7:0];

always @ (posedge clk or negedge rst) 
 	if (!rst)
  	 	fifo_of <= 0;
	 else
	   	fifo_of <= write_req & fifo_full;       		  
/******************************** read from fifo ******************************/
  always @ (posedge clk or negedge rst)
    if (!rst) 
		begin
		read_pointer 	<= 0;
 		read_data		<= 0;
		read_data_valid	<= 0;
		end
	else
	 if (read_from_fifo)
			begin
			read_data<= my_fifo[read_pointer];
			read_data_valid <= 1;
			read_pointer <=read_pointer +1;
			end
		else
			read_data_valid <= 0;

always @ (posedge clk or negedge rst) 
 	if (!rst)
  	 	fifo_uf <= 0;
	 else	  	
	 	fifo_uf <= read_req & fifo_empty; 
   
endmodule



