import cam_types::*;

module testbench(cam_itf itf);

cam dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),
    .rw_n_i    ( itf.rw_n    ),
    .valid_i   ( itf.valid_i ),
    .key_i     ( itf.key     ),
    .val_i     ( itf.val_i   ),
    .val_o     ( itf.val_o   ),
    .valid_o   ( itf.valid_o )
);

default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask

// DO NOT MODIFY CODE ABOVE THIS LINE

task write(input key_t key, input val_t val);
	itf.key <= key;
	itf.val_i <= val;
	itf.rw_n <= 1'b0;
	itf.valid_i <= 1'b1;
	##1;
	//itf.valid_i <= 1'b0;
endtask

task read(input key_t key, output val_t val);
	itf.key <= key;
	itf.rw_n <= 1'b1;
	itf.valid_i <= 1'b1;
	##1;
	assert (itf.valid_o)
		else begin
		itf.tb_report_dut_error(READ_ERROR);
		$error("%0t TB: Read %0d, expected %0d", $time, itf.valid_o, "1");
		end
endtask

initial begin
    $display("Starting CAM Tests");

    reset();
    /************************** Your Code Here ****************************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Consider using the task skeltons above
    // To report errors, call itf.tb_report_dut_error in cam/include/cam_itf.sv

	 itf.key <= 0;
	 itf.val_i <= 0;
	 // Fill CAM
	 for (int i = 0; i < 8; i++) begin
		write(i,i);
	 end
	 // Evict Key-value
	 // Read-hit
	 // Write then read on the same key
	 for (int i = 0; i < 8; i++) begin
		//read(i,i);
		itf.rw_n <= 1'b0;
		itf.valid_i <= 1'b1;
		##1;
		itf.valid_i <= 1'b0;
		itf.rw_n <= 1'b1;
		itf.valid_i <= 1'b1;
		##1;
		assert (itf.val_o == itf.val_i) 
			else begin
				itf.tb_report_dut_error(READ_ERROR);
				$error("%0t TB: Read %0d, expected %0d", $time, itf.valid_o, itf.val_i);
			end
		itf.valid_i <= 1'b0;
		itf.key <= itf.key + 1;
		itf.val_i <= itf.val_i + 1;
	 end
	 // Write on same key
	 for (int i = 0; i < 8; i++) begin
		write (i,i);
		##1;
		write (i,i+1);
		##1;
	 end

    /**********************************************************************/

    itf.finish();
end

endmodule : testbench
