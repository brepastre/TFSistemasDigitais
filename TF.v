module fsm_genius (
  input SW0, clk, rst, btn_pressionado, fim_ent, fim_ex, resultado_comparado, timeout, led_final,
  input [3:0] nivel_atual, 
  output reg enable, write_enable, sel_read_addr, clr_nivel, inc_nivel, clr_cnt_ex, inc_cnt_ex, clr_cnt_ent, inc_cnt_ent, clr_timer, timer_enable,
  output reg [3:0] write_adress,
  output reg [2:0] estado_atual
);
    parameter IDLE = 3'd0;
    parameter EXIBICAO = 3'd1;  
  	parameter ENTRADA = 3'd2; 
  	parameter VITORIA = 3'd3; 
    parameter DERROTA = 3'd4; 

    reg [2:0] estadoA, estadoP;
  	always @(*) begin
        estado_atual = estadoA;
    end
  
  // Lógica de transição de estados
    always @(posedge clk or posedge rst) begin
        if(rst)
            estadoA <= IDLE;
        else
            estadoA <= estadoP;
    end
    
  // Lógica de próximo estado
    always @(*) begin
        estadoP = estadoA;
        case(estadoA)
            IDLE:
              if(SW0) 
                estadoP = EXIBICAO; 
          	  else
                estadoP = IDLE;                  
            EXIBICAO:
              if(led_final && fim_ex)      
                estadoP = ENTRADA; 
              else if(led_final && !fim_ex)   
                estadoP = EXIBICAO;
	          else
                estadoP = EXIBICAO;   	
            ENTRADA:
              if(btn_pressionado && resultado_comparado && fim_ent && (nivel_atual < 4'd15))    
                estadoP = EXIBICAO;
                 else if(timeout && !btn_pressionado)         					estadoP = ENTRADA;
                 else if(btn_pressionado && resultado_comparado && !fim_ent)
                estadoP = ENTRADA;
                 else if(btn_pressionado && resultado_comparado && fim_ent && (nivel_atual == 4'd15))
                estadoP = VITORIA;
                 else if(timeout || (btn_pressionado && !resultado_comparado))
                 estadoP = DERROTA;
            VITORIA:
              if(SW0)
                estadoP = VITORIA;
          	  else
                estadoP = IDLE; 
            DERROTA:
              if(SW0)
                estadoP = DERROTA;
          	  else
          		estadoP = IDLE;
            default:
                estadoP = IDLE;
        endcase
    end
    
  //Lógica de saídas
    always @(*) begin
        enable = 1'b0;
        write_enable = 1'b0;
        sel_read_addr = 1'b0;
        clr_nivel = 1'b0; 
        inc_nivel = 1'b0; 
        clr_cnt_ex = 1'b0;
        inc_cnt_ex = 1'b0;
        clr_cnt_ent = 1'b0;
        inc_cnt_ent = 1'b0;
        clr_timer = 1'b0;
        timer_enable = 1'b0;
        write_adress = 4'b0000;
        estado_atual = 3'b000;
        
        case(estadoA)
            IDLE: begin
				clr_nivel = 1'b1;
              	clr_cnt_ex = 1'b1;
              clr_cnt_ent = 1'b1;
              clr_timer = 1'b1;
              timer_enable = 1'b0;
            end
            EXIBICAO: begin
              timer_enable = 1'b1;
              sel_read_addr = 1'b0;
              clr_cnt_ent   = 1'b1;
              if(led_final) begin
                inc_cnt_ex = 1'b1;
                clr_timer = 1'b1;
              end              
            end
            ENTRADA: begin
              timer_enable = 1'b1;
              sel_read_addr = 1'b1;
              clr_cnt_ex = 1'b1;
              
              //Jogador apertou o botão certo e a rodada ainda não acabou
              if(btn_pressionado && resultado_comparado && !fim_ent) begin
                inc_cnt_ent = 1'b1;
                clr_timer = 1'b1;
              end
              //Jogador acertou o último botão do nível atual e o jogo deve continuar
              if(btn_pressionado && resultado_comparado && fim_ent && (nivel_atual < 4'd15)) begin
                    inc_nivel    = 1'b1; 
                    enable       = 1'b1; 
                    write_enable = 1'b1; 
                    write_adress = nivel_atual; 
                    clr_cnt_ent  = 1'b1; 
                    clr_timer    = 1'b1;
                end
            end
            VITORIA: begin
              clr_cnt_ex = 1'b1;
              clr_timer = 1'b1;
              clr_cnt_ent = 1'b1;
              timer_enable = 1'b0;
            end
            DERROTA: begin
              clr_cnt_ex = 1'b1;
              clr_timer = 1'b1;
              clr_cnt_ent = 1'b1;
              timer_enable = 1'b0;
            end
        endcase
    end
endmodule
                 
module temporizador(
  input rst, clk, clr_timer, timer_enable,
  output reg timeout, led_final
  );
  //Parâmetros de tempo baseados no clock de 50MHz
    parameter SEG1 = 26'd50_000_000;  // 50 milhões de ciclos = 1 segundo
    parameter MS250 = 26'd12_500_000; // 12.5 milhões de ciclos = 250 ms

    // Registradores para as bases de clock e contadores de eventos
    reg [25:0] cnt_clk_seg;
    reg [25:0] cnt_clk_led;
    reg [5:0]  cnt_seg;             // Conta de 0 a 60 segundos
    reg [1:0]  estagio_led;                // Conta os estágios de 250ms do LED

    // Lógica do tempo de jogada (60 segundos)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_clk_seg <= 26'd0;
            cnt_seg <= 6'd0;
            timeout <= 1'b0;
        end 
        else if (clr_timer) begin
            cnt_clk_seg <= 26'd0;
            cnt_seg <= 6'd0;
            timeout <= 1'b0;
        end 
        else if (timer_enable) begin
            if (cnt_seg >= 6'd60) begin // Passou dos 60 segundos, ativa timeout
                timeout <= 1'b1;
            end 
            else begin
                // Detectação da passagem de 1 segundo
                if (cnt_clk_seg >= (SEG1 - 1)) begin
                    cnt_clk_seg <= 26'd0;
                    cnt_seg <= cnt_seg + 6'd1; // Incrementa 1 segundo
                end 
                else begin
                    cnt_clk_seg <= cnt_clk_seg + 26'd1;
                end
            end
        end
        else begin
            // Trava se timer_enable desativado
            cnt_clk_seg <= 26'd0;
        end
    end

    // Lógica de controle do tempo do LED
    // - Estágio 0 e 1 (0ms a 500ms) com LED aceso
    // - Estágio 2 (500ms a 750ms) com LED apagado
    // - 750ms por símbolo antes de ativar led_final
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_clk_led <= 26'd0;
            estagio_led <= 2'd0;
            led_final <= 1'b0;
        end 
        else if (clr_timer) begin
            cnt_clk_led <= 26'd0;
            estagio_led <= 2'd0;
            led_final <= 1'b0;
        end 
        else if (timer_enable) begin
            led_final <= 1'b0; // Sinal de apenas um pulso de 1 clock
            
            // Detectação da passagem de 250 milissegundos
            if (cnt_clk_led >= (MS250 - 1)) begin
                cnt_clk_led <= 26'd0;
                
                if (estagio_led == 2'd2) begin
                    estagio_led <= 2'd0;
                    led_final   <= 1'b1; // Pulso de fim de ciclo para a FSM avançar
                end 
                else begin
                    estagio_led <= estagio_led + 2'd1;
                end
            end 
            else begin
                cnt_clk_led <= cnt_clk_led + 26'd1;
            end
        end
        else begin
            cnt_clk_led <= 26'd0;
            estagio_led <= 2'd0;
            led_final <= 1'b0;
        end
    end
endmodule

module lfsr(
  input enable, clk, rst,
  output [1:0] simbolo_randomico
);
  //
  reg [3:0] d_reg;
  wire realimenta;
  //
  assign realimenta = d_reg[3]^d_reg[2];
  //
  always @(posedge clk or posedge rst)begin
    if (rst) begin
      d_reg <=4'b0001;
    end else begin
      d_reg <={d_reg[2:0], realimenta};
    end
  end
  assign simbolo_randomico = d_reg[1:0];
  endmodule

module debouncer(
  input clk, rst, 
  input [3:0] KEY,
  output btn_pressionado,
  output [1:0] simbolo_jogado
);

// Inverte a entrada para ativo em alto
  wire [3:0] btn_ativo_alto = ~KEY;
  //
  reg [19:0] contador;
  reg [3:0]  estado_estavel;
  //
  always @(posedge clk or posedge rst) begin
      if (rst) begin
          contador <= 0;
          estado_estavel <= 0;
      end else begin
          //
          if (btn_ativo_alto != estado_estavel) begin
              contador <= contador + 1;
              //
              if (contador == 1000000) begin
                  estado_estavel <= btn_ativo_alto;
                  contador <= 0;
              end
          end else begin
              // Se voltou a ser igual zera o contador
              contador <= 0;
          end
      end
  end

  // Detector a borda pra garantir um pulso só
  reg [3:0] estado_anterior;
  always @(posedge clk or posedge rst) begin
      if (rst) begin
          estado_anterior <= 0;
      end else begin
          estado_anterior <= estado_estavel;
      end
  end
  // o pulso vira 1 só quando o ciclo de clock do botão passa de 0 pra 1
  wire [3:0] pulso_btn = estado_estavel & ~estado_anterior;
  //
  assign btn_pressionado = (pulso_btn != 0);
  // encontra qual botão gerou o pulso
  always @(posedge clk or posedge rst) begin
      if (rst) begin
          simbolo_jogado <= 0;
      end else begin
          if (pulso_btn[0]) simbolo_jogado <= 0;
          else if (pulso_btn[1]) simbolo_jogado <= 1;
          else if (pulso_btn[2]) simbolo_jogado <= 2;
          else if (pulso_btn[3]) simbolo_jogado <= 3;
      end
  end
endmodule

module reg_nivel(
  input inc_nivel, clr_nivel, clk, rst,
  output [3:0] nivel_atual
);
endmodule

module comp_seq(
  input [1:0] simbolo_esperado, simbolo_jogado,
  output resultado_comparado
);
endmodule

module mem_seq(
  input write_enable,
  input [3:0] write_adress, read_adress,
  input [1:0] simbolo_randomico,
  output [1:0] simbolo_esperado // read_data
)
endmodule

module cnt_exib(
  input clk, rst, inc_cnt_ex, clr_cnt_ex,
  input [3:0] nivel_atual,
  output fim_ex,
  output reg [3:0] ex_adress
);
    //Lógica do contador 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_adress <= 4'b0000;
        end 
        else if (clr_cnt_ex) begin
            ex_adress <= 4'b0000;
        end 
        else if (inc_cnt_ex) begin
            if (ex_adress == 4'd15) // Trava ao chegar em 15 e evitar overflow
                ex_adress <= 4'd15;
            else
                ex_adress <= ex_adress + 4'd1;
        end
    end

    assign fim_ex = (ex_adress == nivel_atual); //Detecção do fim da exibição da rodada (ativa quando o contador chega no nível atual)
endmodule

module cnt_ent(
  input clk, rst, inc_cnt_ent, clr_cnt_ent,
  input [3:0] nivel_atual,
  output fim_ent,
  output reg [3:0] ent_adress
);

    //Lógica do contador 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ent_adress <= 4'b0000;
        end 
        else if (clr_cnt_ent) begin
            ent_adress <= 4'b0000;
        end 
        else if (inc_cnt_ent) begin
            if (ent_adress == 4'd15)
                ent_adress <= 4'd15;
            else
                ent_adress <= ent_adress + 4'd1;
        end
    end

    assign fim_ent = (ent_adress == nivel_atual); //Detecção do fim das jogadas obrigatórias (ativa quando o contador chega no nível atual)
endmodule

module decod_display_7seg(
  input [3:0] SW, nivel_atual,
  input [2:0] estado_atual,
  input [1:0] simbolo_esperado,
  output reg [6:0] seg, HEX0, HEX3,
  output reg LEDR0, LEDR1, LEDR2, LEDR3
);
  //Decodificador 7 seguimentos
  always @(*) begin
        case (SW)
            4'h0: seg = 7'b1000000; 
            4'h1: seg = 7'b1111001; 
            4'h2: seg = 7'b0100100; 
            4'h3: seg = 7'b0110000; 
            4'h4: seg = 7'b0011001; 
            4'h5: seg = 7'b0010010; 
            4'h6: seg = 7'b0000010; 
            4'h7: seg = 7'b1111000; 
            4'h8: seg = 7'b0000000; 
            4'h9: seg = 7'b0010000; 
            4'hA: seg = 7'b0001000; 
            4'hB: seg = 7'b0000011; 
            4'hC: seg = 7'b1000110; 
            4'hD: seg = 7'b0100001; 
            4'hE: seg = 7'b0000110; 
            4'hF: seg = 7'b0001110; 
            default: seg = 7'b1111111;
        endcase
    end

    // Decodificador de estados
    always @(*) begin
        case (estado_atual)
            3'd0: HEX3 = 7'b1000000; // IDLE 
            3'd1: HEX3 = 7'b1111001; // EXIBICAO 
            3'd2: HEX3 = 7'b0100100; // ENTRADA 
            3'd3: HEX3 = 7'b0110000; // VITORIA 
            3'd4: HEX3 = 7'b0011001; // DERROTA 
            default: HEX3 = 7'b1111111; // Estado inválido
        endcase
    end

    // Decodificador do nível atual (0 à F)
    always @(*) begin
        case (nivel_atual)
            4'h0: HEX0 = 7'b1000000; 4'h1: HEX0 = 7'b1111001; 
            4'h2: HEX0 = 7'b0100100; 4'h3: HEX0 = 7'b0110000; 
            4'h4: HEX0 = 7'b0011001; 4'h5: HEX0 = 7'b0010010; 
            4'h6: HEX0 = 7'b0000010; 4'h7: HEX0 = 7'b1111000; 
            4'h8: HEX0 = 7'b0000000; 4'h9: HEX0 = 7'b0010000; 
            4'hA: HEX0 = 7'b0001000; 4'hB: HEX0 = 7'b0000011; 
            4'hC: HEX0 = 7'b1000110; 4'hD: HEX0 = 7'b0100001; 
            4'hE: HEX0 = 7'b0000110; 4'hF: HEX0 = 7'b0001110; 
            default: HEX0 = 7'b1111111;
        endcase
    end

    always @(*) begin
        LEDR0 = 1'b0;
        LEDR1 = 1'b0;
        LEDR2 = 1'b0;
        LEDR3 = 1'b0;

        if (estado_atual == 3'd1) begin // Se estiver em EXIBICAO
            case (simbolo_esperado)
                2'b00: LEDR0 = 1'b1;
                2'b01: LEDR1 = 1'b1;                2'b10: LEDR2 = 1'b1;
                2'b11: LEDR3 = 1'b1;         
            endcase
        end
    end
endmodule

module top_genius()
endmodule
