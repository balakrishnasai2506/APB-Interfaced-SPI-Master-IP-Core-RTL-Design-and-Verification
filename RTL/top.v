module top (
    input        Pclk,
    input   Presetn,
    input   [2:0]  PADDR,
    input  PWRITE,
    input   PSEL,
    input   PENABLE,
    input   [7:0]  PWDATA,
    output  [7:0]  PRDATA,
    output  PREADY,
    output  PSLVERR,
    input    miso,
    output  mosi,
    output  sclk,
    output  ss,
    output  spi_interrupt_request
);

    wire    [7:0] miso_data;
    wire    receive_data;
    wire    tip;
    wire    mstr, cpol,cpha,lsbfe,spiswai;
    wire    [2:0] sppr,spr;
    wire    send_data;
    wire    mosi_data;
    wire    [1:0]spi_mode;
    wire    [11:0]baudratedivisor;
    
    wire miso_receive_sclk0, miso_receive_sclk, mosi_send_sclk, mosi_send_sclk0; //flag_high, flag_low, flags_high, flags_low (order of naming)
    
    //APB_SL_IF instantiation
    apb_slave apb_if (
        .Pclk(Pclk),
        .Presetn(Presetn),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),
        .ss(ss),
        .miso_data(miso_data),
        .receive_data(receive_data),
        .tip(tip),
        .mstr(mstr),
        .cpol(cpol),
        .cpha(cpha),
        .lsbfe(lsbfe),
        .spiswai(spiswai),
        .sppr(sppr),
        .spr(spr),
        .spi_interrupt_request(spi_interrupt_request),
        .send_data(send_data),
        .mosi_data(mosi_data),
        .spi_mode(spi_mode)
    );
    
    //Baud_gen instantiation
    baud_gen bg (
    	.Pclk(Pclk),
        .Presetn(Presetn),
        .spi_mode(spi_mode),
        .spiswai(spiswai),
        .sppr(sppr),
        .spr(spr),
        .cpol(cpol),
        .cpha(cpha),
        .ss(ss),
        .sclk(sclk),
        .miso_receive_sclk(miso_receive_sclk),
        .miso_receive_sclk0(miso_receive_sclk0),
        .mosi_send_sclk0(mosi_send_sclk0),
        .mosi_send_sclk(mosi_send_sclk),
        .BaudRateDivisor(baudratedivisor)
    );
    
    //Slave_CTRL instantiation
    slave_ctrl slave_cntrl (
    	.Pclk(Pclk),
        .Presetn(Presetn),
        .mstr(mstr),
        .spiswai(spiswai),
        .spi_mode(spi_mode),
        .send_data(send_data),
        .receive_data(receive_data),
        .BaudRateDivisor(baudratedivisor),
        .tip(tip),
        .ss(ss)
    );
    
    //SPI_SR instantiation
    spi_sr u_spi_sr (
    	.PCLK(Pclk),
    	.PRESETn(Presetn),
    	.ss_i(ss),
    	.send_data_i(send_data),
    	.lsbfe_i(lsbfe),
    	.cpha_i(cpha),
    	.cpol_i(cpol),
    	.miso_receive_sclk_i(miso_receive_sclk),
    	.miso_receive_sclk0_i(miso_receive_sclk0),
    	.mosi_send_sclk_i(mosi_send_sclk),
    	.mosi_send_sclk0_i(mosi_send_sclk0),
    	.data_mosi_i(mosi_data),
    	.miso_i(miso),
    	.receive_data_i(receive_data),
    	.mosi_o(mosi),
    	.data_miso_o(miso_data)
    );

endmodule
