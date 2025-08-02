module spi_sr(PCLK,PRESETn,ss_i,send_data_i,lsbfe_i,cpha_i,cpol_i,
                        miso_receive_sclk_i,miso_receive_sclk0_i,mosi_send_sclk_i,mosi_send_sclk0_i,
                        data_mosi_i,miso_i,receive_data_i,mosi_o,data_miso_o);
                       
input PCLK,PRESETn;
input ss_i,send_data_i,lsbfe_i,cpha_i,cpol_i;
input miso_receive_sclk_i,miso_receive_sclk0_i;
input mosi_send_sclk_i,mosi_send_sclk0_i;
input [7:0]data_mosi_i;
input miso_i;
input receive_data_i;
output reg mosi_o;
output [7:0]data_miso_o;
reg [7:0]temp_reg;
reg [7:0]shift_register;
reg [7:0]count,count1,count2,count3;
//reg [7:0]temp_count2,temp_count3;

//FOR DATA_MISO
assign data_miso_o = receive_data_i ? temp_reg : 8'h00;

//FOR SHIFT REGISTER

always@(posedge PCLK or negedge PRESETn)
begin
if(!PRESETn)
    shift_register <= 8'h00;
else if(send_data_i)
    shift_register <= data_mosi_i;
else
    shift_register <= shift_register;
end

//FOR COUNT
always@(posedge PCLK or negedge PRESETn)
begin
if(!PRESETn)
  begin
    count <= 8'h00;
    count <= 8'h07;
  end
else if(ss_i)
  begin
    count <= count;
    count1 <= count1;
  end
else if((~cpha_i&&cpol_i)||(~cpol_i&&cpha_i))
    begin
        if(lsbfe_i)
            begin
                if(count<=3'd7)
                    begin
                        if(mosi_send_sclk_i)
                            count <= count+3'b001;
                        else
                            count <= count;
                    end
                else
                    count <= 3'd0;
            end
        else
            begin
                if(!(count1>=3'd0))
                    count1 <= 3'd7;
                 else
                    begin
                        if(mosi_send_sclk_i)
                            count1 <= count1-3'b001;
                        else
                            count1 <= count1;
                    end
            end
      end
else
    begin
        if(lsbfe_i)
            begin
                if(count<=3'd7)
                    begin
                        if(mosi_send_sclk0_i)
                            count <= count+3'b001;
                        else
                            count <= count;
                    end
                else
                    count <= 3'd0;
            end
         else
            begin
                if(count1>=3'd0)
                    begin
                        if(mosi_send_sclk0_i)
                            count1 <= count1-3'b001;
                        else
                            count1 <= count1;
                   end
                else
                    count1 <= 3'd7;
            end
      end
end


//FOR COUNT2/COUNT3

always@(posedge PCLK or negedge PRESETn)
begin
if(!PRESETn)
  begin
    count2 <= 8'h00;
    count3 <= 8'h07;
  end
else if(ss_i)
  begin
    count2 <= count2;
    count3 <= count3;
  end
else if((~cpha_i&&cpol_i)||(~cpol_i&&cpha_i))
    begin
        if(lsbfe_i)
            begin
                if(count2<=3'd7)
                    begin
                        if(miso_receive_sclk0_i)
                            count2 <= count2+3'b001;
                        else
                            count2 <= count2;
                   end
                else
                    count2 <= 3'd0;
            end
        else
            if(count3>=3'd0)
                begin
                    if(miso_receive_sclk0_i)
                        count3 <= count3-3'b001;
                    else
                        count3 <= count3;
                end
            else
                count3 <= 3'd7;                  
    end
else
    begin
        if(lsbfe_i)
            begin
                if(count2<=3'd7)
                    begin
                        if(miso_receive_sclk_i)
                            count2 <= count2+3'b001;
                        else
                            count2 <= count2;
                    end
                else
                    count2 <= 3'd0;
            end
         else
            begin
                if(count3>=3'd0)
                    begin
                        if(miso_receive_sclk_i)
                            count3 <= count3-3'b001;
                        else
                            count3 <= count3;
                    end
                 else
                    count3 <= 3'd7;
            end
    end
end



//FOR TEMP REGISTER

always@(posedge PCLK or negedge PRESETn)
begin
if(!PRESETn)
    temp_reg <= 8'h00;
else if(ss_i)
    temp_reg <= 8'h00;
else if((~cpha_i&&cpol_i)||(~cpol_i&&cpha_i))
    begin
        if(lsbfe_i)
            begin
                if(count2<=3'd7)
                    begin
                        if(miso_receive_sclk0_i)
                            temp_reg[count2] <= miso_i;
                        else
                            temp_reg <= temp_reg;
                    end
                else
                    temp_reg <= 8'd0;
            end
         else
            begin
                if(count3<=3'd7)
                    begin
                        if(miso_receive_sclk0_i)
                            temp_reg[count3] <= miso_i;
                        else
                            temp_reg <= temp_reg;
                    end
                else
                    temp_reg <= 8'd0;
            end
    end
else
    begin
        if(lsbfe_i)
            begin
                if(count2<=3'd7)
                    begin
                        if(miso_receive_sclk_i)
                            temp_reg[count2] <= miso_i;
                        else
                            temp_reg <= temp_reg;
                    end
                else
                    temp_reg <= 8'd0;
            end
         else
            begin
                if(count3<=3'd7)
                    begin
                        if(miso_receive_sclk_i)
                            temp_reg[count2] <= miso_i;
                         else
                            temp_reg <= temp_reg;
                    end
                else
                    temp_reg <= 8'd0;
            end      
    end
end


//FOR MOSI

always@(posedge PCLK or negedge PRESETn)
begin
if(!PRESETn)
     mosi_o <= 1'b0;
else if(ss_i)
    mosi_o <= 1'b0;
else if((~cpha_i&&cpol_i)||(~cpol_i&&cpha_i))
    begin
        if(lsbfe_i)
            begin
                if(count<=3'd7)
                    begin
                        if(mosi_send_sclk_i)
                            mosi_o <= shift_register[count];
                        else
                            mosi_o <= 3'd0;
                    end
                else
                    mosi_o <= 1'd0;
            end
         else
            begin
                if(count1>=3'd0)
                    begin
                        if(mosi_send_sclk_i)
                            mosi_o <= shift_register[count1];
                        else
                            mosi_o <= 1'b0;
                    end
                else
                    mosi_o <= 1'd0;
            end
    end      
else
    begin
        if(lsbfe_i)
            begin
                if(count<=3'd7)
                    begin
                        if(mosi_send_sclk0_i)
                            mosi_o <= shift_register[count];
                         else
                            mosi_o <= 1'b0;
                    end
                else
                    mosi_o <= 1'd0;
            end
         else
            begin
                if(count1>=3'd0)
                    begin
                        if(mosi_send_sclk0_i)
                            mosi_o <= shift_register[count1];
                        else
                            mosi_o <= 1'b0;
                    end
                else
                    mosi_o <= 1'd0;
            end
    end
end
endmodule
