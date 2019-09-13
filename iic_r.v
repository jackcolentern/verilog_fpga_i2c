module iic_r(
	input clk,
	inout sda_pin,
	output scl_pin,
	input button,
	output[7:0] LED,
	
	output[3:0] LEDDEBUG

	);
	
	parameter IDLE = 3'b000;
	parameter TOSTART = 3'b001;
	parameter START = 3'b010;
	parameter ACK = 3'b011;
	parameter END = 3'b100;
	
	reg[2:0] state;
	reg[3:0] send_cnt;
	reg[7:0] data;

	reg[7:0] success;
	reg[1:0] cnt;
	reg[1:0] cnt_timeout;

	reg[15:0] cnt_resend;

	reg scl_out;	
	reg sda_out;
	
	reg sda;
	reg to_sda;
	
	reg tosend;
	reg failed;
	reg ended;
	
	reg write_read;
	
	wire byte_ok;
	wire clk_400k;
	reg[7:0] data_length;
	reg[7:0] data_received;
	
	initial begin
		write_read <= 1'b0;
		scl_out <= 1'b1;
		state <= IDLE;
		data_length <= 8'd2;
	end
	
	pll pll (
		.inclk0(clk),
		.c0(clk_400k)
		);
	
	//always @(sda_out) to_sda = (sda_out)?sda:1'bz;
	
	always @(posedge clk_400k) begin
		cnt <= cnt + 1'b1;
	end
	
		
	always @(posedge cnt[0]) begin //we reached a middle point
	
		if(state == TOSTART && success != 7'b0) state <= START;
		
		//if(state == TOSTART && success != 7'b1) state <= START;


		if(state == IDLE) begin
			cnt_timeout <= 2'b00;
			scl_out <= 1'b1;
			success <= 7'b00;
			failed <= 1'b0;
			ended <= 0;
			send_cnt <= 4'b1000;
			data <= 8'b01001111;
		end
		

		
		if(cnt[1] == 1'b0) begin //low middle point
			
			if(success == 7'b00) begin //sending address
				if(state == START) begin
					sda_out <= 1;
					sda <= data[7];
					send_cnt <= send_cnt - 1;
				end

				if(state == ACK) begin
					sda_out <= 1'b0;
				end
	
			end
			
			else begin //receiving
				
				if(state == START) begin
					scl_out <= 1'b1;
					sda_out <= 1'b0;
					if (send_cnt == 8'b0) begin
						state <= ACK;
							sda_out <= 1'b1;
							sda <= 1'b0;
					end
					else data_received <= data_received << 1'b1;
				end
				

				
				if(state == ACK) begin
					if(success != data_length) begin
						success <= success + 1'b1;
						send_cnt <= 4'b1000;
						state <= TOSTART;
					end
					else state <= END;
				end		

				
				
			end
			
		end
		
		else begin //high middle point
			
			if(success == 7'b00) begin //sending address

				if(state == IDLE) begin
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
					success <= success + 1'b1;
					sda_out <= 1'b0;
					send_cnt <= 4'b1001;
					//state <= TOSTART;
					
				end
				
				if(sda_pin == 1'b0) begin
					success <= success + 1'b1;
					sda_out <= 1'b0;
					send_cnt <= 4'b1001;
					state <= TOSTART;
				end
					
			//	if(success == 2'b01) begin
			//		sda <= 1'b0;
			//		state <= END;
			//	end
				
				if(state == END) begin
					sda <= 1'b1;
					ended <= 1'b1;
				end
			end
		end
		
		else begin //receiving
		
			if(state == START) begin
				data_received[0] <= sda_pin;
				send_cnt <= send_cnt - 1;			
			end
			
			if(state == START && sda_out == 1'b1) begin
				state <= ACK;
			end
			
		end
	end
		
	end
			
	
	assign sda_pin =  (sda_out)?sda:1'bz;//to_sda;
	assign scl_pin = (scl_out)?cnt[1]:1'bz;
	assign LED = data_received;
	assign LEDDEBUG = ~{1'b0,state};
	//assign LED = ~cnt_resend;
endmodule