module main(
	input clk,
	inout wire sda_pin,
	output wire scl_pin,
	input button,
	output[3:0] LED
	);
	
wire busy;

reg[24:0]cnt;

reg button_prev;
	
reg button_debounced; 

wire start;

iic_w iic_w(
		.clk(clk),
		.address_in(8'b01001110),
		.data_tosend_in(128'hfffffffffffffff0),
		.data_length_in(8'd1),
		.sda_pin(sda_pin),
		.start(start),
		.scl_pin(scl_pin),
		.busy(busy),
		.do_not_end_in(1'b0)
	);

always @(posedge clk) begin
	if(button_prev != button) begin
		cnt <= cnt + 1'b1;
		if (cnt == 24'h0ffff) begin
			button_debounced <= ~button_debounced;
			button_prev <= button;
		end
	end
	else cnt <= 24'h000000;
end
	
	
assign start = ~button_debounced;
assign LED = ~{button,button_debounced,busy,busy};
endmodule


