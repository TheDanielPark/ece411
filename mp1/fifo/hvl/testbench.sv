`ifndef testbench
`define testbench

import fifo_types::*;

module testbench(fifo_itf itf);

fifo_synch_1r1w dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),

    // valid-ready enqueue protocol
    .data_i    ( itf.data_i  ),
    .valid_i   ( itf.valid_i ),
    .ready_o   ( itf.rdy     ),

    // valid-yumi deqeueue protocol
    .valid_o   ( itf.valid_o ),
    .data_o    ( itf.data_o  ),
    .yumi_i    ( itf.yumi    )
);

// Clock Synchronizer for Student Use
default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    ##(10);
    itf.reset_n <= 1'b1;
    ##(1);
endtask : reset

function automatic void report_error(error_e err); 
    itf.tb_report_dut_error(err);
endfunction : report_error

// DO NOT MODIFY CODE ABOVE THIS LINE

initial begin
    reset();
    /************************ Your Code Here ***********************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
	 //Check if ready_o is high at pos clock edge
	 //@(posedge itf.clk)
	 assert (itf.rdy)
		else begin
			$error ("0d: %0t: %s error detected", `__LINE__, $time, RESET_DOES_NOT_CAUSE_READY_O);
			report_error (RESET_DOES_NOT_CAUSE_READY_O);
		end
	 // Enqueue
	 itf.valid_i <= 1'b1;
	 
	 for (int i = 0; i < cap_p; i++) begin
		//itf.valid_i <= 1'b1; // Set valid_i to 1 in order to enqueue data_i
		//##1
		itf.data_i <= i;
		//$display (itf.data_i);
		##1;
		//itf.valid_i <= 1'b0; // Set valid_i back to 0 because enqueue is finished
	 end
	 
	 itf.valid_i <= 1'b0;
	 //##1;
	 // Dequeue
	 if (itf.valid_o) begin // Check if there is something to dequeue
		itf.yumi <= 1'b1; 
		//##1;
		for (int i = 0; i < cap_p; i++) begin
			//itf.yumi <= 1'b1; // Signal there is something to dequeue
			//##1
			assert (itf.data_o == i) //Make sure the correct value is dequeued else error
				else begin
					$error ("0d: %0t: %s error detected", `__LINE__, $time, INCORRECT_DATA_O_ON_YUMI_I);
					report_error (INCORRECT_DATA_O_ON_YUMI_I);
				end
			##1;
			//itf.yumi <= 1'b0; // Signal dequeue off
		end
		//##1;
		itf.yumi <= 1'b0; 
	 end
	 for (int i = 1; i <= cap_p; i++) begin
		itf.valid_i <= 1'b1; // Enqueue data_i
		itf.data_i <= i;	// Set data
		//##1
		itf.yumi <= 1'b0;	// Send dequeue signal low
		##1;
		itf.yumi <= 1'b1; // Send dequeue signal high
		
		//assert (itf.data_o == i)	// Check if dequeued is correct value else error
			//else begin
				//$error ("0d: %0t: %s error detected", `__LINE__, $time, INCORRECT_DATA_O_ON_YUMI_I);
				//report_error (INCORRECT_DATA_O_ON_YUMI_I);
			//end
		##1;
		//itf.valid_i <= 1'b0; // Stop Enqueueing Data
		//itf.yumi <= 1'b0; // Signal dequeue off
	 end
	 ##1;
	 itf.valid_i <= 1'b0; // Stop Enqueueing Data
	 //##1;
	 itf.yumi <= 1'b0; // Signal dequeue off

    /***************************************************************/
    // Make sure your test bench exits by calling itf.finish();
    itf.finish();
    $error("TB: Illegal Exit ocurred");
end

endmodule : testbench
`endif

