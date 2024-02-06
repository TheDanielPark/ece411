module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i, // Value stored in write
    output logic [255:0] line_o, // Value stored in read
    input logic [31:0] address_i, // Address for both read/write
    input read_i, // Signal it is a read
    input write_i, // Signal it is a write
    output logic resp_o, // Operation done sent by adapter

    // Port to memory
    input logic [63:0] burst_i, // Send adapter info 
    output logic [63:0] burst_o, // Send memory info
    output logic [31:0] address_o, // Address
    output logic read_o, // Signal it is a read
    output logic write_o, // Signal it is a write
    input resp_i // Operation done sent by memory
);
	
	logic [3:0] counter;
	logic reading;
	logic writing;
	
	// READ
	always_ff @(posedge clk) begin
		// If reset set, set the values back to original
		if (~reset_n) begin
			read_o <= 1'b0;
			resp_o <= 1'b0;
			write_o <= 1'b0;
			//line_o <= 0;
			counter <= 0;

			reading <= 0;
			writing <= 0;
		end
		if (reset_n && read_i && ~reading) begin
			read_o <= 1'b1;
			write_o <= 1'b0;
			address_o <= address_i;
			counter <= 0;
			reading <= 1;
		end
		if (reading) begin
			if (counter == 0) begin
				if (resp_i) begin
					line_o [63:0] <= burst_i;
					counter <= counter + 1;
				end
			end
			else if (counter == 1) begin
				if (resp_i) begin
					line_o [127:64] <= burst_i;
					counter <= counter + 1;
				end
			end
			else if (counter == 2) begin
				if (resp_i) begin
					line_o [191:128] <= burst_i;
					counter <= counter + 1;
				end
			end
			else if (counter == 3) begin
				if (resp_i) begin
					line_o [255:192] <= burst_i;
					counter <= counter + 1;
					resp_o <= 1'b1;
				end
			end
			else if (counter == 4) begin
				read_o = 1'b0;
				resp_o <= 1'b0;
				counter <= 0;
				reading <= 0;
			end
		end
		
		//Write
		if (reset_n && write_i == 1 && ~writing) begin
			read_o <= 1'b0;
			write_o <= 1'b1;
			address_o <= address_i;
			counter <= 0;
			writing <= 1;
			burst_o <= line_i[63:0];
		end
		if (writing) begin
			if (counter == 0) begin
				if (resp_i) begin
					burst_o <= line_i [127:64];
					counter <= counter + 1;
				end
			end
			else if (counter == 1) begin
				if (resp_i) begin
					burst_o <= line_i [191:128];
					counter <= counter + 1;
				end
			end
			else if (counter == 2) begin
				if (resp_i) begin
					burst_o <= line_i [255:192];
					counter <= counter + 1;
				end
			end
			else if (counter == 3) begin
				resp_o <= 1'b1;
				counter <= counter + 1;
			end
			else if (counter == 4) begin
				write_o = 1'b0;
				resp_o <= 1'b0;
				counter <= 4;
				writing <= 0;
			end
		end
	end
	




endmodule : cacheline_adaptor
