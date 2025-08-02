module baud_gen(Pclk, Presetn, spi_mode, spiswai, sppr, spr, cpol, cpha, ss, sclk, miso_receive_sclk0, miso_receive_sclk, mosi_send_sclk, mosi_send_sclk0, BaudRateDivisor);
	input Pclk, Presetn, spiswai, cpol, cpha, ss;
	input [1:0] spi_mode;
	input [2:0] sppr, spr;
	
	output reg sclk, mosi_send_sclk, mosi_send_sclk0, miso_receive_sclk0, miso_receive_sclk;
	output [11:0] BaudRateDivisor;
	
	assign BaudRateDivisor = (sppr+1) * (1<<(spr+1));
	
	reg [11:0] count;
	wire pre_sclk;
	
	assign pre_sclk = cpol;
	
	//Count logic
	always @(posedge Pclk or negedge Presetn) begin
	if(!Presetn)
		count <= 12'b0;
	else if(!((spi_mode == 2'b00 || spi_mode == 2'b01) && ~ss && ~spiswai))
		count <= 12'b0;
	else if(count == (BaudRateDivisor - 1'b1))
		count <= 12'b0;
	else 
		count <= count + 1'b1;
	end

	//SCLK logic
	always @(posedge Pclk or negedge Presetn) begin
	if(!Presetn)
		sclk <= pre_sclk;
	else if(!((spi_mode == 2'b00 || spi_mode == 2'b01) && ~ss && ~spiswai))
		sclk <= pre_sclk;
	else if(count == (BaudRateDivisor - 1'b1))
		sclk <= ~sclk;
	else sclk <= sclk;
	end
	
	//Flag_low logic
	always @(posedge Pclk or negedge Presetn) begin
	if(!Presetn)
		miso_receive_sclk <= 1'b0;
	else if((~cpha && cpol) || (cpha && ~cpol))
		miso_receive_sclk <= miso_receive_sclk;
	else if(sclk)
		miso_receive_sclk <= 1'b0;
	else if(count == (BaudRateDivisor - 1'b1))
		miso_receive_sclk <= 1'b1;
	else
		miso_receive_sclk <= 1'b0;
	end
	
	//Flag_high logic
	always @(posedge Pclk or negedge Presetn) begin
	if(!Presetn)
		miso_receive_sclk0 <= 1'b0;
	else if((~cpha && cpol) || (cpha && ~cpol))
		miso_receive_sclk0 <= miso_receive_sclk0;
	else if(~sclk)
		miso_receive_sclk0 <= 1'b0;
	else if(count == (BaudRateDivisor - 1'b1))
		miso_receive_sclk0 <= 1'b1;
	else
		miso_receive_sclk0 <= 1'b0;
	end
		
	//Flags_low logic
	always @(posedge Pclk or negedge Presetn) begin
	if(!Presetn)
		mosi_send_sclk0 <= 1'b0;
	else if((~cpha && cpol) || (cpha && ~cpol))
		mosi_send_sclk0 <= mosi_send_sclk0;
	else if(sclk)
		mosi_send_sclk0 <= 1'b0;
	else if(count == (BaudRateDivisor - 2'b10))
		mosi_send_sclk0 <= 1'b1;
	else
		mosi_send_sclk0 <= 1'b0;
	end
	//Flags_high logic
	always @(posedge Pclk or negedge Presetn) begin
	if(!Presetn)
		mosi_send_sclk <= 1'b0;
	else if((~cpha && cpol) || (cpha && ~cpol))
		mosi_send_sclk <= mosi_send_sclk;
	else if(~sclk)
		mosi_send_sclk <= 1'b0;
	else if(count == (BaudRateDivisor - 2'b10))
		mosi_send_sclk <= 1'b1;
	else
		mosi_send_sclk <= 1'b0;
	end
	
endmodule
