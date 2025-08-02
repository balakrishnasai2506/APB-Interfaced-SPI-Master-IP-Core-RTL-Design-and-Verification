module slave_ctrl(Pclk, Presetn, spi_mode, spiswai, mstr, send_data, BaudRateDivisor, receive_data, ss, tip);
	input Pclk, Presetn, spiswai, mstr, send_data;
	input [2:0] spi_mode;
	input [11:0] BaudRateDivisor;
	output reg receive_data, ss;
	output tip;
	
	reg [15:0] count;
	reg rcv;
	wire [15:0] target;
	
	assign target = BaudRateDivisor * 16;
	
	//count logic
	always@(posedge Pclk or negedge Presetn) begin
		if(!Presetn)
			count <= 16'b0;
		else if(!(((~spiswai && (spi_mode == 2'b01)) || (spi_mode == 2'b00)) && mstr))
			count <= 16'hffff;
		else if(send_data)
			count <= 1'b0;
		else if(!(count <= target - 1'b1))
			count <= 16'hffff;
		else
			count <= count + 1'b1;
	end
	
	//rcv logic
	always@(posedge Pclk or negedge Presetn) begin
		if(!Presetn)
			rcv <= 1'b0;
		else if(!(((~spiswai && (spi_mode == 2'b01)) || (spi_mode == 2'b00)) && mstr))
			rcv <= 1'b0;
		else if(send_data)
			rcv <= 1'b0;
		else if(!(count <= target - 1'b1))
			rcv <= 1'b0;
		else if(count == target - 1'b1)
			rcv <= 1'b1;
		else
			rcv <= 1'b0;
	end
	
	//receive_data logic
	always@(posedge Pclk or negedge Presetn) begin
		if(!Presetn)
			receive_data <= 1'b0;
		else
			receive_data <= rcv;
	end
	
	//ss logic
	always@(posedge Pclk or negedge Presetn) begin
		if(!Presetn)
			ss <= 1'b0;
		else if(!(((~spiswai && (spi_mode == 2'b01)) || (spi_mode == 2'b00)) && mstr))
			ss <= 1'b1;
		else if(send_data)
			ss <= 1'b0;
		else if(!(count <= target - 1'b1))
			ss <= 1'b1;
		else
			ss <= 1'b0;
	end
	
	//tip logic
	assign tip = ~ss;

endmodule
