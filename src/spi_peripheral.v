`default_nettype none

module spi_peripheral(
    input wire      clk,
    input wire      sCLK,
    input wire      COPI,
    input wire      nCS,
    input wire      rst_n,

    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

localparam REG_OUT_7_0_ADDR    = 8'h00;
localparam REG_OUT_15_8_ADDR   = 8'h01;
localparam REG_PWM_7_0_ADDR    = 8'h02;
localparam REG_PWM_15_8_ADDR   = 8'h03;
localparam PWM_DUTY_CYCLE_ADDR = 8'h04;
localparam MAX_ACCEPTED_ADDR   = 8'h04;


reg sCLK_sync_1, sCLK_sync_2;
reg COPI_sync_1, COPI_sync_2;
reg nCS_sync_1,  nCS_sync_2;

wire sCLK_pos_edge;
assign sCLK_pos_edge = !sCLK_sync_2 && sCLK_sync_1; 

reg [3:0] cycle_counter  = 4'h0;
reg [7:0] addr           = 8'h00;
reg [6:0] data           = 8'h00;
reg       op_valid       = 1'b0;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sCLK_sync_1 <= 1'b0;
        sCLK_sync_2 <= 1'b0;
        COPI_sync_1 <= 1'b0;
        COPI_sync_2 <= 1'b0;
        nCS_sync_1  <= 1'b1;
        nCS_sync_2  <= 1'b1;
    end else begin
        sCLK_sync_1 <= sCLK;
        sCLK_sync_2 <= sCLK_sync_1;
        COPI_sync_1 <= COPI;
        COPI_sync_2 <= COPI_sync_1;
        nCS_sync_1  <= nCS;
        nCS_sync_2  <= nCS_sync_1;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cycle_counter   <= 4'h0;
        addr            <= 8'h00;
        data            <= 7'h00;
        op_valid        <= 1'b0;
        en_reg_out_7_0  <= 8'h00; 
        en_reg_out_15_8 <= 8'h00;
        en_reg_pwm_7_0  <= 8'h00;
        en_reg_pwm_15_8 <= 8'h00;
        pwm_duty_cycle  <= 8'h00;
    end
    else if(!nCS_sync_2) begin
        
        if(sCLK_pos_edge) begin
            if(cycle_counter == 4'h0) begin
                op_valid <= COPI_sync_2;
            end
            else if(cycle_counter >= 4'h1 && cycle_counter <= 4'h7) begin
                addr[7 - cycle_counter] <= COPI_sync_2;
            end
            else if(cycle_counter >= 4'h8 && cycle_counter <= 4'hE) begin
                data[14 - cycle_counter] <= COPI_sync_2;
            end
            else if(cycle_counter == 4'hF) begin
                if(op_valid) begin 
                    if(addr == REG_OUT_7_0_ADDR) begin
                        en_reg_out_7_0 <= {data, COPI_sync_2};
                    end
                    else if(addr == REG_OUT_15_8_ADDR) begin
                        en_reg_out_15_8 <= {data, COPI_sync_2};
                    end
                    else if(addr == REG_PWM_7_0_ADDR) begin
                        en_reg_pwm_7_0 <= {data, COPI_sync_2};
                    end
                    else if(addr == REG_PWM_15_8_ADDR) begin
                        en_reg_pwm_15_8 <= {data, COPI_sync_2};
                    end
                    else if(addr == PWM_DUTY_CYCLE_ADDR) begin
                        pwm_duty_cycle <= {data, COPI_sync_2};
                    end
                end
            end
            cycle_counter <= cycle_counter + 1;
        end
    end
    else begin
        cycle_counter <= 4'h0;
    end
end

endmodule