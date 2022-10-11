`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2022 02:16:23 PM
// Design Name: 
// Module Name: fifo_one_clk_tb
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


`define END_TEST 10000
`define CLEAR_FIFO 100// bug - too short
`define PASS  1
`define FAIL  0
module fifo_one_clk_tb();
parameter DATA_TB = 8;
parameter ADDR_TB = 4;

     reg  			rst,clk;
     reg [DATA_TB-1:0] 		write_data;
     reg 			write_req, read_req; 
     wire [DATA_TB-1:0] 	read_data;
	 wire			read_data_valid;
	 wire 			fifo_of, fifo_uf;
	 reg pass_fail = `PASS;
	 integer i, number_of_writes = 0;
	reg [DATA_TB-1:0] writes_mem [0:1024]; 
	reg [DATA_TB-1:0] reads_mem  [0:1024]; 
    reg	[31:0] 		rand;
		
	
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
		write_data 		<= 0;
		write_req 		<= 0;
		read_req		<= 0;
		rand			<= 0;
		end
	else
		begin
		if ($time < `END_TEST)
			begin
			write_data 		<= rand[DATA_TB-1:0];//(rand) + $random(data_in);
			write_req 		<= rand [31];
			end
		else
			begin
			write_req 		<= 0;
			end
		read_req		<= rand [30];
		rand			<= $random(rand);
		end

  fifo_one_clk FIFO_ONE_CLK ( .rst(rst),
							  .clk(clk), 
							  .write_data(write_data),
							  .write_req(write_req), 
							  .read_data(read_data),
							  .read_data_valid(read_data_valid), .
							  read_req(read_req), 
							  .fifo_of(fifo_of), 
							  .fifo_uf(fifo_uf), 
							  .fifo_empty(fifo_empty), 
							  .fifo_full(fifo_full));
							  
   defparam FIFO_ONE_CLK.DATA=DATA_TB,FIFO_ONE_CLK.ADDR = ADDR_TB; 


//coverage:
integer cover_uf = 0;
integer cover_of = 0;

always@(posedge fifo_uf)
	if (!cover_uf)
		begin
		cover_uf = 1;
		$display($time,"ns underflow covered for the 1st time");
		end
		
always@(posedge fifo_of)
	if (!cover_of)
		begin
		cover_of = 1;
		$display($time,"ns overflow covered for the 1st time");
		end	

//checkers:

integer wf, rf, wft, rft;
initial 
	begin
	wf = $fopen("write_file.txt");
	rf = $fopen("read_file.txt");
  	wft = $fopen("wr_time_file.txt");
	rft = $fopen("rd_time_file.txt");
	end

reg [DATA_TB-1:0] write_data_save;
reg [DATA_TB-1:0] write_req_save;
reg [DATA_TB-1:0] read_req_save;

always @ (posedge clk or negedge rst)
    if (!rst)
		begin
		write_data_save <= 0;
		read_req_save 	<= 0;
		write_req_save 	<= 0;
		end
	else
		begin
		write_data_save <= write_data;
		read_req_save 	<= read_req;
		write_req_save 	<= write_req;
	  	end

always@(posedge clk)
	begin
	# 1;
	if (write_req & !fifo_full)
		begin
		$fdisplay(wf, "%h", write_data);
		$fdisplay(wft, $time, "\t",write_data);
		number_of_writes = number_of_writes + 1;
		end
	end

always@(posedge clk)
	begin
 	# 1;
	if (read_req_save & !fifo_uf)
		begin
		$fdisplay(rf, "%h", read_data);
		$fdisplay(rft, $time, "\t",read_data);
		end
	end

initial 
	begin
 # `END_TEST;
 #	`CLEAR_FIFO;
	$fclose(wf); 
	$fclose(rf); 
  	$fclose(wft); 
	$fclose(rft); 
	$readmemh("write_file.txt", writes_mem);
	$readmemh("read_file.txt", reads_mem);
	for (i = 0; i < number_of_writes; i = i + 1)
		if (writes_mem[i] !== reads_mem[i])
			begin
			$display ("ERROR!!! - write != Read at transaction number:", i," write = ",writes_mem[i] ," read = ",reads_mem[i]); 
			pass_fail = `FAIL;
			end
	if (pass_fail == `PASS)
		$display ("TEST PASSED :-)");
	else
		$display ("TEST FAILED :-(");
	#1 $stop;
 end
	
endmodule

