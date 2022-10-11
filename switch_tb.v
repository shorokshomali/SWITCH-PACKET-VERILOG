`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2022 03:30:18 PM
// Design Name: 
// Module Name: switch_tb
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
`define END_TEST 2000
`define CLEAR_FIFO 20// bug - too short
`define PASS  1
`define FAIL  0
`define MAP_DEFAULT 8'b1111_0000
`define PASS  1
`define FAIL  0

module switch_tb();

reg  			rst,clk;			// Module clock and reset
reg 	[7:0] 	write_data_0, write_data_1;			// the data that should be write to the fifo, synchronized to clk
reg		[2:0]	dest_0, dest_1; //destination address
reg 			write_req_0, write_req_1;// request to write
wire			data_ack_0, data_ack_1; // indicates that there data was succecfuly entered, one clock after the req
wire  	[7:0] 	read_data_0, read_data_1;			// the data that is read from the fifo
wire 			read_data_valid_0, read_data_valid_1;	// valid bit to indicate that read_data has valid value. 
wire			source_add_0, source_add_1;
reg		[3:0]	configuration_address;
reg		[7:0]	configuration_data;
reg				configuration_data_valid;

///////////////////////////////////////////
reg [7:0]  map_copy;
reg strict_rount_copy,prioritized_copy; 

initial
	begin
	rst = 1;
	#1 rst = 0;
	#21 rst = 1;
	end

initial
	begin
		clk = 0;
		forever #10 clk = ~clk;					
	end

always @ (posedge clk or negedge rst)
    if (!rst)
		begin
		map_copy 			<= `MAP_DEFAULT;
		strict_rount_copy 	<= 1;
		prioritized_copy	<= 0;
		end
		

always @ (posedge clk or negedge rst)
    if (!rst)
		begin
		write_data_0	<= 0;
		write_data_1	<= 0;
		write_req_0		<= 0;
		write_req_1		<= 0;
		dest_0			<= 0;
		dest_1			<= 0;
		configuration_address <= 0;
		configuration_data <= 0;
		configuration_data_valid <= 0;
		end
	else
		begin
		if ($time < `END_TEST)
			begin
			write_data_0	<= $random();
			write_req_0		<= $random();
			write_data_1	<= $random();
			write_req_1		<= $random();
			dest_0			<= $random();
			dest_1			<= $random();
			end
		else
			begin
			write_data_0	<= 0;
			write_req_0		<= 0;
			write_data_1	<= 0;
			write_req_1		<= 0;
			dest_0			<= 0;
			dest_1			<= 0;
			end
		end

switch SWITCH(
.rst(rst),
.clk(clk),
.write_data_0(write_data_0),
.write_data_1(write_data_1),
.dest_0(dest_0),
.dest_1(dest_1),
.write_req_0(write_req_0),
.write_req_1(write_req_1),
.data_ack_0(data_ack_0),
.data_ack_1(data_ack_1),
.read_data_0(read_data_0),
.read_data_1(read_data_1),
.read_data_valid_0(read_data_valid_0),
.read_data_valid_1(read_data_valid_1),
.source_add_0(source_add_0),
.source_add_1(source_add_1),
.configuration_address(configuration_address),
.configuration_data(configuration_data),
.configuration_data_valid(configuration_data_valid));


///////////////////////////////////////////////////
////////		checkers		///////////////////
///////////////////////////////////////////////////
integer wr_0_0, wr_0_1, wr_1_0, wr_1_1, rd_0_0, rd_0_1, rd_1_0, rd_1_1;
reg [7:0] write_data_S_0, write_data_S_1;
reg [7:0] write_req_s_0 , write_req_s_1;
reg [2:0] dest_s_0, dest_s_1;
integer i, number_of_writes_0_0 = 0, number_of_writes_0_1 = 0, number_of_writes_1_0 = 0, number_of_writes_1_1 = 0;
reg [7:0] writes_mem_0_0 [0:1024]; 
reg [7:0] writes_mem_0_1 [0:1024]; 
reg [7:0] writes_mem_1_0 [0:1024]; 
reg [7:0] writes_mem_1_1 [0:1024]; 
reg [7:0] reads_mem_0_0  [0:1024]; 
reg [7:0] reads_mem_1_0  [0:1024]; 
reg [7:0] reads_mem_0_1  [0:1024]; 
reg [7:0] reads_mem_1_1  [0:1024]; 
reg pass_fail = `PASS;
initial 
	begin
	wr_0_0 = $fopen("wr_0_0.txt");
	wr_0_1 = $fopen("wr_0_1.txt");
  	wr_1_0 = $fopen("wr_1_0.txt");
	wr_1_1 = $fopen("wr_1_1.txt");
	rd_0_0 = $fopen("rd_0_0.txt");
	rd_0_1 = $fopen("rd_0_1.txt");
  	rd_1_0 = $fopen("rd_1_0.txt");
	rd_1_1 = $fopen("rd_1_1.txt");
	end


always @ (posedge clk or negedge rst)
    if (!rst)
		begin
		write_data_S_0 	<= 0;
		write_data_S_1 	<= 0;
		write_req_s_0	<= 0;
		write_req_s_1	<= 0;
		dest_s_0		<= 0;
		dest_s_1		<= 0;
		end
	else
		begin
		write_data_S_0 <= write_data_0;
		write_data_S_1 	<= write_data_1;
		write_req_s_0 	<= write_req_0;
		write_req_s_1 	<= write_req_1;
		dest_s_0		<= dest_0;
		dest_s_1		<= dest_1;
	  	end

always@(posedge clk)
	begin
	# 1;
	if (write_req_s_0 & data_ack_0)
		begin
		if (!map_copy[dest_s_0])
			begin
			$fdisplay(wr_0_0, "%h", write_data_S_0);
			number_of_writes_0_0 = number_of_writes_0_0 + 1;
			end
		else
			begin
			$fdisplay(wr_0_1, "%h", write_data_S_0);
			number_of_writes_0_1 = number_of_writes_0_1 + 1;
			end
		end
	end

always@(posedge clk)
	begin
	# 1;
	if (write_req_s_1 & data_ack_1)
		begin
		if (!map_copy[dest_s_1])
			begin
			$fdisplay(wr_1_0, "%h", write_data_S_1);
			number_of_writes_1_0 = number_of_writes_1_0 + 1;
			end
		else
			begin
			$fdisplay(wr_1_1, "%h", write_data_S_1);
			number_of_writes_1_1 = number_of_writes_1_1 + 1;
			end
		end
	end

always@(posedge clk)
	begin
 	# 1;
	if (read_data_valid_0)
		if(!source_add_0)
			begin
			$fdisplay(rd_0_0, "%h", read_data_0);
			end
		else
			begin
			$fdisplay(rd_1_0, "%h", read_data_0);
			end
	end
	
always@(posedge clk)
	begin
 	# 1;
	if (read_data_valid_1)
		if(!source_add_1)
			begin
			$fdisplay(rd_0_1, "%h", read_data_1);
			end
		else
			begin
			$fdisplay(rd_1_1, "%h", read_data_1);
			end
	end

initial 
	begin
 # `END_TEST;
 #	`CLEAR_FIFO;
	$fclose(wr_0_0); 
	$fclose(wr_0_1); 
	$fclose(wr_1_0); 
  	$fclose(wr_1_1); 
	$fclose(rd_0_0); 
	$fclose(rd_0_1); 
	$fclose(rd_1_0); 
  	$fclose(rd_1_1); 
	$readmemh("wr_0_0.txt", writes_mem_0_0);
	$readmemh("wr_0_1.txt", writes_mem_0_1);
	$readmemh("wr_1_0.txt", writes_mem_1_0);
	$readmemh("wr_1_1.txt", writes_mem_1_1);
	$readmemh("rd_0_0.txt", reads_mem_0_0);
	$readmemh("rd_0_1.txt", reads_mem_0_1);
	$readmemh("rd_1_0.txt", reads_mem_1_0);
	$readmemh("rd_1_1.txt", reads_mem_1_1);
		
	#1
	for (i = 0; i < number_of_writes_0_0; i = i + 1)
		if (writes_mem_0_0[i] !== reads_mem_0_0[i])
			begin
			$display ("ERROR!!! - write_0_0 != Read_0_0 at transaction number:", i," write = ",writes_mem_0_0[i] ," read = ",reads_mem_0_0[i]); 
			pass_fail = `FAIL;
			end
	#1
	for (i = 0; i < number_of_writes_0_1; i = i + 1)
		if (writes_mem_0_1[i] !== reads_mem_0_1[i])
			begin
			$display ("ERROR!!! - write_0_1 != Read_0_1 at transaction number:", i," write = ",writes_mem_0_1[i] ," read = ",reads_mem_0_1[i]); 
			pass_fail = `FAIL;
			end
	#1
	for (i = 0; i < number_of_writes_1_0; i = i + 1)
		if (writes_mem_1_0[i] !== reads_mem_1_0[i])
			begin
			$display ("ERROR!!! - write_1_0 != Read_1_0 at transaction number:", i," write = ",writes_mem_1_0[i] ," read = ",reads_mem_1_0[i]); 
			pass_fail = `FAIL;
			end
	#1
	for (i = 0; i < number_of_writes_1_1; i = i + 1)
		if (writes_mem_1_1[i] !== reads_mem_1_1[i])
			begin
			$display ("ERROR!!! - write_1_1 != Read_1_1 at transaction number:", i," write = ",writes_mem_1_1[i] ," read = ",reads_mem_1_1[i]); 
			pass_fail = `FAIL;
			end
	if (pass_fail == `PASS)
		$display ("TEST PASSED :-)");
	else
		$display ("TEST FAILED :-(");
	#1 $stop;
 end


endmodule












