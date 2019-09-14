module iic_w(
	input clk,
	input[7:0] address_in,
	input[127:0] data_tosend_in,
	input[7:0] data_length_in,
	inout sda_pin,
	input wire start,
	output scl_pin,
	output busy,
	input wire do_not_end_in
	);
	
	parameter TOSTART = 3'b000;
	parameter START = 3'b001;
	parameter ACK = 3'b010;
	parameter TOEND = 3'b011;
	parameter END = 3'b100;
	parameter ENDED = 3'b101;
	parameter FAILED = 3'b110;
	
	reg[2:0] state;
	reg[3:0] send_cnt;
	reg[7:0] data;
	reg[7:0] success;
	reg[1:0] cnt;
	reg[1:0] cnt_timeout;

	reg[127:0] data_tosend;
	reg[7:0] data_length;
	
	reg scl_out;	
	reg sda_out;
	
	reg failed;
	
	reg sda;
	reg to_sda;
	
	reg tosend;
	
	reg locked;
	reg read_write;
	
	wire byte_ok;
	wire clk_400k;	
		
	initial begin
		state <= ENDED;
		scl_out <= 1'b1;
		state <= END;
		data_length <= 7;
	end
	
	pll pll (
		.inclk0(clk),
		.c0(clk_400k)
		);
	
	always @(sda_out) to_sda = (sda_out)?sda:1'bz;

	
	always @(posedge clk_400k) begin
		cnt <= cnt + 1'b1;
	end
	
		
	always @(posedge cnt[0]) begin //we reached a middle point
		
		if (start == 1'b0)begin
			locked <= 1'b0;
		end
		
		if(state == ENDED)begin
			data_tosend <= data_tosend_in;
			data_length <= data_length_in;
			scl_out <= 1'b0;
			if (start == 1'b1 && locked == 1'b0) begin
				state <= TOSTART;
				locked <= 1'b1;
			end
		end 
		
		if(state == TOSTART) begin
			success <= 8'h00;
			cnt_timeout <= 2'b00;
			scl_out <= 1'b1;
			success <= 2'b00;
			failed <= 1'b0;
			sda <= 1'b1;
			sda_out <= 1'b1;
			send_cnt <= 4'b1000;
			data <= address_in;
		end
		
		if(cnt[1] == 1'b0) begin //low middle point
			
			if(state == START) begin
				sda_out <= 1;
				sda <= data[7];
				send_cnt <= send_cnt - 1;
			end

			if(state == ACK) begin
				sda_out <= 1'b0;
			end
			
			if(state == TOEND) begin
				sda <= 1'b0;
				state <= END;
			end  
			
		end
		
		else begin //high middle point
	
				
			if(state == END) begin
				sda <= 1'b1;
				state <= ENDED;
			end
	
			if(state == TOSTART) begin
				sda_out <= 1;
				sda <= 1'b0;
				state <= START;
			end
			
			if(state == START) begin
				data <= data << 1'b1;
				if (send_cnt == 8'b0) begin
					state <= ACK;
				end
			end
			
			if(state == ACK && sda_out == 1'b0) begin
				cnt_timeout <= cnt_timeout + 1;
				
				if(cnt_timeout == 2'b11)begin
					cnt_timeout <= 2'b00;
					failed <= 1'b1;
					state <= TOEND;
				end
				
				if(sda_pin == 1'b0) begin
					data <= data_tosend[7:0];
					data_tosend <= data_tosend >> 8;
					sda_out <= 1'b1;
					send_cnt <= 4'b1000;
					if(success != data_length) begin
						success <= success + 1'b1;
						state <= START;
					end
					else begin
						sda <= 1'b0;
						if(do_not_end_in == 1'b1)state <= ENDED;
						else state <= TOEND;
					end
				end
			end			
		end
			
	end
			
	assign busy = ~(state[2] & ~state[1] & state[0]);
	assign sda_pin = to_sda;
	assign scl_pin = (scl_out)?cnt[1]:1'b1;
endmodule