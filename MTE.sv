module MTE_E (clock,key,IN,OUT);
 parameter N = 256;
  input clock;
  input [N-1:0]key;
  input logic [N-1:0] IN;
  output logic [255:0] OUT[];

  logic [255:0] EnReg1[];
  logic [255:0] EnReg2[];
  logic [255:0]EMAC,en_out;
  genvar i;
  
  macgen M1(clock, key, EnReg1[255:0], 1'b1, EMAC); // Generate MAC for Encryption 
  assign EnReg2 = {EnReg1,EMAC};

always_ff @(posedge clock) begin 
    EnReg1.append(IN);
    OUT.append(en_out); // add current data_out value to the dynamic array
end

    for(i = 0; i <= (EnReg2.size()/256); i++)
      encryption #(.N(N)) EN(i)(clock,key,EnReg2[i+255:i],en_out);

  //encryption #(.N(N)) EN1(clock,key,EnReg2[255:0],OUT[255:0]); // Encrypt MAC part of the input
 // encryption #(.N(N)) EN2(clock,key,EnReg[511:256],OUT[511:256]); // Encrypt data part of the input

endmodule

module MTE_D (clock,key,IN,OUT,valid_key);
  parameter N = 256;
  input clock;
  input [255:0]key;
  input [255:0]IN;
  output logic valid_key;
  output logic [255:0] OUT[];

  logic [255:0] DeReg1[];
  logic [255:0] DeReg2[];
  logic [255:0] OutDe[];
  logic [255:0]DMAC,de_out;

  genvar i;

always_ff @(posedge clock) begin 
    DeReg1.append(IN);
    DeReg2.append(de_out); // add current data_out value to the dynamic array
end  

    for(i = 0; i <= (DeReg.size()/256); i++)
      decryption #(.N(N)) DE1(clock,key,DeReg1[i+255:i],de_out);

  //decryption #(.N(N)) DE1(clock,key,IN[255:0],OutDe[255:0]); // Decrypting the MAC part of the cypher text 
  //decryption #(.N(N)) DE2(clock,key,IN[511:256],OutDe[511:256]); // Decrypting the data part of the cipher text
initial begin  
  foreach(OutDe[i]) begin
    OutDe[i] = DeReg2[511+(i*256):256+(i*256)];
  end
end
  macgen #(.N(N)) M2(clock, key, DeReg2[511:256], 1'b1, DMAC); // generate MAC for comparison during decryption
  mac_compare #(.N(N)) C1(clock, DeReg2[255:0], DMAC, valid_key);  // compare MAC generated during decrption and the MAC that is decrypted from the cipher text
  //assign OUT = OutDe[15:8]; // plain text output
  Muxnto1 #(.N(OutDe.size()-1)) FM(OUT,'0,OutDe,valid_key);

endmodule


module MTE(clock,key,IN,sel,OUT,valid_key);
  parameter N = 256;
  input clock;
  input [255:0]key;
  input [255:0]IN;
  input sel;
  output logic valid_key;
  output logic [255:0] OUT[];
  
//  wire [255:0]R1_out;
  //reg [511:0]EnReg;
 // reg [511:0] DeReg;
 // reg [511:0] OutEn;
 // reg [511:0] OutDe;
 // reg [255:0]EMAC;
//  reg [255:0]DMAC;
//  reg EQ;
//  reg and_out;
//  reg [511:0] out1;
 // reg [511:0] OutEn1;

    logic [255:0] OUTE[];
    logic [255:0] OUTD[];

    MTE_D #(.N(N)) DE1(clock,key,IN,OUTD,valid_key);
    MTE_E #(.N(N)) EN1(clock,key,IN,OUTE);

always @(posedge clock)
begin
  if(sel)
      OUT = OUTE;
  else
      OUT = OUTD;
end
  
   initial begin
	  for(int i = 0; i < $clog2(256); i++) begin
		//if character is eof
		if(IN[8*i+:7] == 3)
			begin
			$display("Found eof");
			$finish;
			end
	$display("didn't find eof");
        end
        end
       //endgenerate

endmodule

// MAC Compare
module mac_compare #(parameter N=256)(clock, mac1, mac2, EQ);
input clock;
input [N-1:0] mac1;
input [N-1:0] mac2;
output reg EQ;

always_comb
 begin
   EQ = (mac1 === mac2) ? 1'b1 : 1'b0;
 end
endmodule

// MUX 
module Muxnto1(Y, V0, V1, S);
parameter N = 8;
output [N-1:0] Y;
input [N-1:0] V0;
input [N-1:0] V1;
input S;

assign Y = S ? V1 : V0;
endmodule
