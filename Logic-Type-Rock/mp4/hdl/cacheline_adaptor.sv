module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);


// logic [255:0]       line_lp_r;      // Temp storage of the cache line
logic [2:0]         read_counter;   // Used for counting up to 4 loads from the memory
logic [2:0]         write_counter;  // Used for counting up to 4 loads to memory
logic               read_state;   // Used for keeping track of reads
logic               write_state;  // Used for keeping track of writes
assign address_o[31:0] = address_i[31:0];       // Always assign the input address to the output

// Two cases. Load from memory until burst is complete, then send to LLC. Or store b

always @(posedge clk) begin
    if (~reset_n) begin
        line_o          <= 256'd0;
        // line_lp_r       <= 256'd0;
        resp_o          <= 1'd0;
        burst_o         <= 64'd0;
        read_o          <= 1'd0;
        write_o         <= 1'd0;
        read_counter    <= 3'd0;
        write_counter   <= 3'd0;
        read_state      <= 1'd0;
        write_state     <= 1'd0;
    end
    else begin
        if (write_i || write_state) begin
            if (write_state == 1'd0)     write_counter <= 3'd0;
            write_o         <= 1'd1;
            read_o          <= 1'd0;
            write_state     <= 1'd1;
            burst_o         <= line_i[63:0];    // 1st write
            // If the memory is ready, begin writing the memory
            case(write_counter)
                    3'b000   :   begin      // 2nd write
                        if (resp_i) begin
                            write_counter   <= write_counter + 1;
                            burst_o         <= line_i[127:64];
                        end 
                end 3'b001   :   begin      // 3rd write
                        if (resp_i) begin
                            write_counter   <= write_counter + 1;
                            burst_o         <= line_i[191:128];
                        end 
                end 3'b010   :   begin      // 4th write
                        if (resp_i) begin
                            write_counter   <= write_counter + 1;
                            burst_o         <= line_i[255:192];
                        end 
                end 3'b011   :   begin      // end of write
                        write_counter       <= write_counter + 1;
                        resp_o              <= 1'b1;
                end 3'b100   :   begin      // Clean up
                        resp_o              <= 1'b0;
                        write_state         <= 1'd0;
                        write_o             <= 1'd0;
                end
                default      :   begin
                        write_counter       <= 3'd0;
                        write_state         <= 1'd0;
                        resp_o              <= 1'd0;
                        write_o             <= 1'd0;                    
                end
            endcase
        end
        else if (read_i || read_state) begin
            write_o         <= 1'd0;
            read_o          <= 1'd1;
            read_state      <= 1'd1;
            // If the memory is ready, begin reading the memory
            case(read_counter)
                    3'b000   :   begin      // 1st read
                        if (resp_i) begin
                            read_counter    <= read_counter + 1;
                            line_o[63:0]    <= burst_i;
                        end
                end 3'b001   :   begin      // 2nd read
                        if (resp_i) begin
                            read_counter    <= read_counter + 1;
                            line_o[127:64]  <= burst_i;
                        end
                end 3'b010   :   begin      // 3rd read
                        if (resp_i) begin 
                            read_counter    <= read_counter + 1;
                            line_o[191:128] <= burst_i;
                        end
                end 3'b011   :   begin      // 4th read
                        if (resp_i) begin 
                            read_counter    <= read_counter + 1;
                            line_o[255:192] <= burst_i;
                            resp_o          <= 1'd1;
                        end
                end 3'b100   :   begin      // clean up
                        read_counter        <= 0;
                        resp_o              <= 1'd0;
                        // line_o          <= line_lp_r;
                        read_state          <= 1'd0;
                        read_counter        <= 3'd0;
                        resp_o              <= 1'd0;
                        line_o              <= 256'd0;
                        read_o              <= 1'd0;

                end
                default      :   begin
                        read_state          <= 1'd0;
                        read_counter        <= 3'd0;
                        resp_o              <= 1'd0;
                        line_o              <= 256'd0;
                        read_o              <= 1'd0;                        
                end
            endcase
        end
        // else begin  // Idle state
        //     line_o <= 256'd0;
        //     // line_lp_r <= 256'd0;
        //     resp_o <= 1'd0;
        //     burst_o <= 64'd0;
        //     read_o <= 1'd0;
        //     write_o <= 1'd0;
        //     read_counter <= 3'd0;
        //     write_counter <= 3'd0;
        //     read_state <= 1'd0;
        //     write_state <= 1'd0;
        // end
    end
end
endmodule : cacheline_adaptor
