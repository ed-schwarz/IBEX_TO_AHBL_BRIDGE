`timescale 1ns/10ps

module ibex2ahbl_bridge #(
	parameter WIDTH = 32 // functional IRQ lines
) (
	input  logic                rst_n,
	input logic                 clk,
	// Instruction memory interface
	input   logic               instr_req,
	output  logic               instr_gnt,
	output  logic               instr_rvalid,
	input   logic [31:0]        instr_addr,
	output  logic [31:0]        instr_rdata,
	output  logic [6:0]         instr_rdata_intg,
	output  logic               instr_err,
	
	// Data memory interface
	input   logic               data_req,
	output  logic               data_gnt,
	output  logic               data_rvalid,
	input   logic               data_we,
	input   logic [4 - 1:0]     data_be,
	input   logic [WIDTH - 1:0] data_addr,
	input   logic [WIDTH - 1:0] data_wdata,
	input   logic [6:0]         data_wdata_intg,
	output  logic [31:0]        data_rdata,
	output  logic [6:0]         data_rdata_intg,
	output  logic               data_err,
	
	// AHB Instruction Memory Interface
	output  logic [3:0]         imem_hprot,
	output  logic [2:0]         imem_hburst,
	output  logic [2:0]         imem_hsize,
	output  logic [1:0]         imem_htrans,
	output  logic               imem_hmastlock,
	output  logic [WIDTH-1:0]   imem_haddr,
	input   logic               imem_hready,
	input   logic [WIDTH-1:0]   imem_hrdata,
	input   logic               imem_hresp,
	
	// AHB Data Memory Interface
	output  logic [3:0]         dmem_hprot,
	output  logic [2:0]         dmem_hburst,
	output  logic [2:0]         dmem_hsize,
	output  logic [1:0]         dmem_htrans,
	output  logic               dmem_hmastlock,
	output  logic [WIDTH-1:0]   dmem_haddr,
	output  logic               dmem_hwrite,
	output  logic [WIDTH-1:0]   dmem_hwdata,
	input   logic               dmem_hready,
	input   logic [WIDTH-1:0]   dmem_hrdata,
	input   logic               dmem_hresp
);
logic drvalid_next;
logic drvalid;
logic [WIDTH-1:0] wdata_reg;
logic [2:0]  dmem_size;
logic [31:0]  data_wdata_temp;
logic [31:0]  data_addr_temp;
logic irvalid_next;
logic irvalid;


always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		drvalid <= 1'b0;
		wdata_reg <= '0;
		
	end else begin
		if(drvalid && !dmem_hready) begin
			drvalid <= drvalid;
		end else begin
			drvalid <= drvalid_next;
		end
		wdata_reg <= data_wdata_temp;
	end
	
end



always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		irvalid <= 1'b0;
		
	end else begin
		if(irvalid && !imem_hready) begin
			irvalid <= irvalid;
		end else begin
			irvalid <= irvalid_next;
		end
	end
end

always_comb begin
	drvalid_next = data_req & dmem_hready;
end
always_comb begin
	irvalid_next = instr_req & imem_hready;
end



always_comb begin
	data_wdata_temp = data_wdata;
	data_addr_temp = data_addr;
	if(!rst_n) begin
		data_wdata_temp = '0;
	end
	else begin
		case(data_be)
			4'b0001: dmem_size = 3'd0;
			4'b0011: dmem_size = 3'd1;
			4'b1111: dmem_size = 3'd2;
			4'b1100 : begin
				dmem_size = 3'd1;
				data_wdata_temp[15:0] = data_wdata[31:16];
				data_addr_temp[31:2] = data_addr[31:2];
				data_addr_temp[1:0] = 2'd2;
			end
			default : dmem_size = 3'd2;
		endcase
	end
end



assign imem_haddr = instr_addr;
assign instr_rdata = imem_hrdata;
assign imem_htrans = instr_req ? 2'd2 : 2'd0;
assign imem_hprot = 4'b0010;
assign imem_hburst = '0;
assign imem_hmastlock = 0;
assign instr_rvalid = (irvalid & imem_hready);
assign instr_gnt = imem_hready;
assign instr_err = imem_hresp;
assign instr_rdata_intg = '0;
assign imem_hsize = 3'd2;


assign dmem_haddr = data_addr_temp;
assign data_rdata = dmem_hrdata;
assign dmem_htrans = data_req ? 2'd2 : 2'd0;
assign dmem_hwdata = wdata_reg;
assign dmem_hprot = 4'b0011;
assign dmem_hburst = '0;
assign dmem_hmastlock = 0;
assign dmem_hwrite = data_req ? data_we : '0;
assign data_rvalid = (drvalid & dmem_hready);
assign data_gnt = dmem_hready;
assign data_err = dmem_hresp;
assign data_rdata_intg = '0;
assign dmem_hsize = dmem_size;



endmodule
