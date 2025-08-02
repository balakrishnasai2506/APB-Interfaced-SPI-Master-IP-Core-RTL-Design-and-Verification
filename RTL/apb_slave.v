module apb_slave(
    	// APB Interface Inputs
    	input Pclk,
    	input Presetn,
    	input [2:0] PADDR,
    	input PWRITE,
    	input PSEL,
    	input PENABLE,
    	input [7:0] PWDATA,

    	// SPI Data/Status Inputs
    	input ss,
    	input [7:0] miso_data,
    	input receive_data,
    	input tip,

    	// APB Interface Outputs
    	output reg [7:0] PRDATA,
   	output PREADY,
    	output PSLVERR,

    	// Control Outputs to SPI Core
    	output mstr,
    	output cpol,
    	output cpha,
    	output lsbfe,
    	output spiswai,
    	output [2:0] sppr,
    	output [2:0] spr,
    	output [1:0] spi_mode,
    	output reg spi_interrupt_request,

    	// Data Outputs to SPI Core
    	output reg send_data,
    	output reg [7:0] mosi_data
);

	reg [7:0] SPI_CR_1;
	reg [7:0] SPI_CR_2;
	reg [7:0] SPI_BR;
	reg [7:0] SPI_SR;
	reg [7:0] SPI_DR;

	//APB FSM
	reg [1:0] apb_state, apb_next_state;
	parameter APB_IDLE = 2'b00;
	parameter APB_SETUP = 2'b01;
	parameter APB_ENABLE = 2'b10;
	
	always@(posedge Pclk or negedge Presetn) begin
		if(!Presetn)
			apb_state <= APB_IDLE;
		else
			apb_state <= apb_next_state;
	end
	
	always@(*) begin
		case(apb_state)
			APB_IDLE: 	if(PSEL && !PENABLE)
						apb_next_state <= APB_SETUP;
					else
						apb_next_state <= APB_IDLE;
			APB_SETUP:	if(PSEL && PENABLE)
						apb_next_state <= APB_ENABLE;
					else if(PSEL && !PENABLE)
						apb_next_state <= APB_SETUP;
					else
						apb_next_state <= APB_IDLE;
			APB_ENABLE:	if(PSEL)
						apb_next_state <= APB_SETUP;
					else
						apb_next_state <= APB_IDLE;
			default: apb_next_state <= APB_IDLE;
		endcase
	end
	
	wire enable_state = (apb_state == APB_ENABLE);
	wire wr_enb = enable_state && PWRITE;
	wire rd_enb = enable_state && ~PWRITE;
	
	assign PREADY = enable_state;
	assign PSLVERR = (enable_state) ? tip : 1'b0;
	
	//SPI FSM
	reg [1:0] spi_state, spi_next_state;
	parameter SPI_RUN = 2'b00;
	parameter SPI_WAIT = 2'b01;
	parameter SPI_STOP = 2'b10;
	
	wire spe = SPI_CR_1[6];
	
	always@(posedge Pclk or negedge Presetn) begin
		if(!Presetn)
			spi_state <= SPI_RUN;
		else
			spi_state <= spi_next_state;
	end
	
	always@(*) begin
		case(spi_state)
			SPI_RUN:	if(!spe)
						spi_next_state <= SPI_WAIT;
					else
						spi_next_state <= SPI_RUN;
			SPI_WAIT:	if(spe)
						spi_next_state <= SPI_RUN;
					else if(spiswai)
						spi_next_state <= SPI_STOP;
					else
						spi_next_state <= SPI_WAIT;
			SPI_STOP:	if(!spiswai)
						spi_next_state <= SPI_WAIT;
					else if(spe)
						spi_next_state <= SPI_RUN;
					else
						spi_next_state <= SPI_STOP;
			default:	spi_next_state <= SPI_RUN;
		endcase
	end
	
	wire cr_2_mask = 8'b0001_1011;
	wire br_mask = 8'b0111_0111;
	
	//SPI_CR_1 logic
	always@(posedge Pclk or negedge Presetn) begin
		if(!Presetn)
			SPI_CR_1 <= 8'h04;
		else if(wr_enb && PADDR == 3'b000)
			SPI_CR_1 <= PWDATA;
	end
	
	//SPI_CR_2 logic
	always@(posedge Pclk or negedge Presetn) begin
		if(!Presetn)
			SPI_CR_2 <= 8'h00;
		else if(wr_enb && PADDR == 3'b001)
			SPI_CR_2 <= PWDATA && cr_2_mask;
	end
	
	//SPI_BR logic
	always@(posedge Pclk or negedge Presetn) begin
		if(!Presetn)
			SPI_BR <= 8'h00;
		else if(wr_enb && PADDR == 3'b010)
			SPI_BR <= PWDATA && br_mask;
	end
	
	//SPI_DR logic
	always@(posedge Pclk or negedge Presetn) begin
		if(!Presetn)
			SPI_DR <= 8'b0;
		else if(wr_enb) begin
			if(PADDR == 3'b101)
				SPI_DR <= PWDATA;
			else
				SPI_DR <= SPI_DR;
		end
		else begin
			if(!(SPI_DR == PWDATA && SPI_DR != miso_data && (spi_state == SPI_RUN || spi_state == SPI_WAIT))) begin
				if((spi_state == SPI_RUN || spi_state == SPI_WAIT) && receive_data)
					SPI_DR <= miso_data;
				else
					SPI_DR <= SPI_DR;
			end
		end
	end
	
	//send_data logic
	always@(posedge Pclk or negedge Presetn) begin
		if(!Presetn)
			send_data <= 1'b0;
		else if(!wr_enb) begin
			if(!(SPI_DR == PWDATA && SPI_DR != miso_data && (spi_state == SPI_RUN || spi_state == SPI_WAIT))) begin
				if(receive_data && (spi_state == SPI_RUN || spi_state == SPI_WAIT))
					send_data <= 1'b0;
				else
					send_data <= 1'b0;
			end
			else begin
				send_data <= 1'b1;
			end
		end
		else begin
			send_data <= send_data;
		end
	end
	
	assign mstr = SPI_CR_1[4];
	assign cpol = SPI_CR_1[3];
	assign cpha = SPI_CR_1[2];
	assign lsbfe = SPI_CR_1[0];
	assign spie = SPI_CR_1[7];
	assign ssoe = SPI_CR_1[1];
	assign spe = SPI_CR_1[6];
	assign sptie = SPI_CR_1[5];
	assign modfen = SPI_CR_2[4];
	assign spiswai = SPI_CR_2[1];
	assign sppr = SPI_BR[6:4];
	assign spr = SPI_BR[2:0];
	assign modf = modfen && mstr && ~ss && ~ssoe;
	assign sptef = (SPI_DR == 8'b0) ? 1'b1 : 1'b0;
	assign spif = (SPI_DR != 8'b0) ? 1'b1 : 1'b0;

	always @(posedge Pclk or negedge Presetn) begin
		if (!Presetn)
			SPI_SR <= 8'b00100000;
		else
			SPI_SR <= {spif, 1'b0, sptef, modf, 4'b0000};
	end

	
	//PRDATA logic
	always@(*) begin
		if(rd_enb) begin
			case(PADDR)
				3'b000 : PRDATA <= SPI_CR_1;
				3'b001 : PRDATA <= SPI_CR_2;
				3'b010 : PRDATA <= SPI_BR;
				3'b011 : PRDATA <= SPI_SR;
				3'b101 : PRDATA <= SPI_DR;
				default : PRDATA <= 8'b0;
			endcase
		end else begin
			PRDATA <= 8'b0;
		end
	end
	
	assign spi_mode = spi_state;
	
	//spi_interrupt_request logic
	always@(*) begin
		if(!(~spie && ~sptie)) begin
			if(!(~sptie && spie)) begin
				if(sptie && ~spie)
					spi_interrupt_request <= sptef;
				else
					spi_interrupt_request <= (sptef || modf || spif);
			end else begin
				spi_interrupt_request <= (spif || modf);
			end
		end else begin
			spi_interrupt_request <= 1'b0;
		end
	end
	
	//mosi_data logic
	always @(posedge Pclk or negedge Presetn) begin
        if (!Presetn) mosi_data<=1'b0;
        else if (((SPI_DR==PWDATA) && (SPI_DR != miso_data)) && 
                ((spi_mode==SPI_RUN) || (spi_mode==SPI_WAIT)) && 
                ~wr_enb) begin
            mosi_data<=lsbfe ? SPI_DR[0] : SPI_DR[7];
        end
    end
endmodule
