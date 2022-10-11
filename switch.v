`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2022 03:27:26 PM
// Design Name: 
// Module Name: switch
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


`define ADDR_MAP  0
`define ADDR_PRIO 1
`define MAP_DEFAULT 8'b1111_0000

module switch(rst,clk,write_data_0, write_data_1,dest_0,dest_1,write_req_0, write_req_1,  
data_ack_0, data_ack_1, read_data_0, read_data_1,read_data_valid_0, read_data_valid_1,source_add_0, source_add_1,
 configuration_address,configuration_data,configuration_data_valid);

parameter DATA_SWITCH  = 8;
parameter ADDR_SWITCH  = 4;


input  				rst,clk;			// Module clock and reset
input 		[7:0] 	write_data_0, write_data_1;			// the data that should be write to the fifo, synchronized to clk
input		[2:0]	dest_0, dest_1; //destination address
input 				write_req_0, write_req_1;// request to write
output				data_ack_0, data_ack_1; // indicates that there data was succecfuly entered, one clock after the req
output  	[7:0] 	read_data_0, read_data_1;			// the data that is read from the fifo
output 				read_data_valid_0, read_data_valid_1;	// valid bit to indicate that read_data has valid value. 
output				source_add_0, source_add_1;
input	[3:0]		configuration_address;
input	[7:0]		configuration_data;
input				configuration_data_valid;

///////////////////////////////////////////////////////////////
reg [7:0] map;
reg 	strict_rount, prioritized, write_req_0_s, write_req_1_s;
wire 	fifo_dest_0, fifo_dest_1;
reg		next_read_to_out_0, next_read_to_out_1;
wire 	fifo_of_0_0, fifo_of_0_1, fifo_of_1_0, fifo_of_1_1;
wire 	read_data_valid_0_0, read_data_valid_0_1, read_data_valid_1_0, read_data_valid_1_1;
wire 	[7:0] read_data_0_0, read_data_0_1, read_data_1_0, read_data_1_1;
reg		read_req_0_0, read_req_0_1, read_req_1_0, read_req_1_1;
wire 	fifo_empty_0_0, fifo_empty_0_1, fifo_empty_1_0, fifo_empty_1_1;

assign fifo_dest_0 = map[dest_0];
assign fifo_dest_1 = map[dest_1];
assign data_ack_0 = write_req_0_s & !(fifo_of_0_0 | fifo_of_0_1);
assign data_ack_1 = write_req_1_s & !(fifo_of_1_0 | fifo_of_1_1);
assign read_data_valid_0 = read_data_valid_0_0 | read_data_valid_1_0;
assign read_data_valid_1 = read_data_valid_0_1 | read_data_valid_1_1;
assign read_data_0 = read_data_valid_0_0 ? read_data_0_0 : read_data_1_0;
assign read_data_1 = read_data_valid_0_1 ? read_data_0_1 : read_data_1_1;
assign source_add_0 = (read_data_valid_0_0) ? 0 : 1;
assign source_add_1 = (read_data_valid_1_1) ? 1 : 0;

reg last_read_out_0, last_read_out_1;


always @ (posedge clk or negedge rst)
    if (!rst) 
		begin
		write_req_0_s <= 0;
		write_req_1_s <= 0;
		end
	else
		begin
		write_req_0_s <= write_req_0;
		write_req_1_s <= write_req_1;
		end

// configuration 	
always @ (posedge clk or negedge rst)
    if (!rst) 
		begin
		map 			<= `MAP_DEFAULT;
		strict_rount 	<= 1;
		prioritized		<= 0;
		end
	else
		if (configuration_data_valid)
			case (configuration_address)
					`ADDR_MAP : 	map <= configuration_data;
					`ADDR_PRIO:		{strict_rount, prioritized} <= configuration_data[1:0];
			endcase


always @(*)
	begin
	next_read_to_out_0 = 0; // default, to prevent latch
	next_read_to_out_1 = 0; // default, to prevent latch
	if(strict_rount)
		begin
		next_read_to_out_0 = prioritized;
		next_read_to_out_1 = prioritized;
		end
	else
		begin
		next_read_to_out_0 = !last_read_out_0;
		next_read_to_out_1 = !last_read_out_1;
		end
	end

always @ (posedge clk or negedge rst)
    if (!rst) 
		begin
		last_read_out_0	<= 0; 
		last_read_out_1	<= 0;
		end
	else
		begin
		if(read_data_valid_0_0)
			last_read_out_0 <= 0;
			
		if(read_data_valid_1_0)
			last_read_out_0 <= 1;
			
		if(read_data_valid_0_1)
			last_read_out_1 <= 0;
			
		if(read_data_valid_1_1)
			last_read_out_1 <= 1;
		end


always @(*)
	begin
	read_req_0_0 = 0;
	read_req_1_0 = 0;
	case ({fifo_empty_0_0, fifo_empty_1_0})
		2'b11:
			begin
			read_req_0_0 = 0;
			read_req_1_0 = 0;
			end
		2'b10:
			begin
			read_req_0_0 = 0;
			read_req_1_0 = 1;
			end
		2'b01:
			begin
			read_req_0_0 = 1;
			read_req_1_0 = 0;
			end
		2'b00:
			begin
			read_req_0_0 = !next_read_to_out_0;
			read_req_1_0 = next_read_to_out_0;
			end
	default:
			begin
			read_req_0_0 = 0;
			read_req_1_0 = 0;
			end
	endcase
	end

always @(*)
	begin
	read_req_0_1 = 0;
	read_req_1_1 = 0;
	case ({fifo_empty_0_1, fifo_empty_1_1})
		2'b11:
			begin
			read_req_0_1 = 0;
			read_req_1_1 = 0;
			end
		2'b10:
			begin
			read_req_0_1 = 0;
			read_req_1_1 = 1;
			end
		2'b01:
			begin
			read_req_0_1 = 1;
			read_req_1_1 = 0;
			end
		2'b00:
			begin
			read_req_0_1 = !next_read_to_out_1;
			read_req_1_1 = next_read_to_out_1;
			end
	default:
			begin
			read_req_0_1 = 0;
			read_req_1_1 = 0;
			end
	endcase
	end		

fifo_one_clk FIFO_IN0_OUT0 (.rst			(rst),
							.clk			(clk), 
							.write_data		(write_data_0),
							.write_req		(write_req_0& !fifo_dest_0), 
							.read_data		(read_data_0_0),
							.read_data_valid(read_data_valid_0_0), 
							.read_req		(read_req_0_0), 
							.fifo_of		(fifo_of_0_0), 
							.fifo_uf		(), 
							.fifo_empty		(fifo_empty_0_0), 
							.fifo_full		());
defparam FIFO_IN0_OUT0.DATA=DATA_SWITCH,FIFO_IN0_OUT0.ADDR = ADDR_SWITCH; 

fifo_one_clk FIFO_IN0_OUT1 (.rst			(rst),
							.clk			(clk), 
							.write_data		(write_data_0),
							.write_req		(write_req_0& fifo_dest_0), 
							.read_data		(read_data_0_1),
							.read_data_valid(read_data_valid_0_1), 
							.read_req		(read_req_0_1), 
							.fifo_of		(fifo_of_0_1), 
							.fifo_uf		(), 
							.fifo_empty		(fifo_empty_0_1), 
							.fifo_full		());
defparam FIFO_IN0_OUT1.DATA=DATA_SWITCH,FIFO_IN0_OUT1.ADDR = ADDR_SWITCH; 
							  
fifo_one_clk FIFO_IN1_OUT0 (.rst			(rst),
							.clk			(clk), 
							.write_data		(write_data_1),
							.write_req		(write_req_1 & !fifo_dest_1), 
							.read_data		(read_data_1_0),
							.read_data_valid(read_data_valid_1_0), 
							.read_req		(read_req_1_0), 
							.fifo_of		(fifo_of_1_0), 
							.fifo_uf		(), 
							.fifo_empty		(fifo_empty_1_0), 
							.fifo_full		());
defparam FIFO_IN1_OUT0.DATA=DATA_SWITCH,FIFO_IN1_OUT0.ADDR = ADDR_SWITCH; 
							  
fifo_one_clk FIFO_IN1_OUT1 (.rst			(rst),
							.clk			(clk), 
							.write_data		(write_data_1),
							.write_req		(write_req_1 & fifo_dest_1), 
							.read_data		(read_data_1_1),  
							.read_data_valid(read_data_valid_1_1), 
							.read_req		(read_req_1_1), 
							.fifo_of		(fifo_of_1_1), 
							.fifo_uf		(), 
							.fifo_empty		(fifo_empty_1_1), 
							.fifo_full		());
defparam FIFO_IN1_OUT1.DATA=DATA_SWITCH,FIFO_IN1_OUT1.ADDR = ADDR_SWITCH; 

endmodule












