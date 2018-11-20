module mult_amplitude_alpha #(parameter complex_bit = 24)(
input signed [1:0] alpha_r, input signed [1:0] alpha_i,
input signed [complex_bit-1:0] amplitude_in_r, input signed [complex_bit-1:0] amplitude_in_i,
output reg signed [complex_bit-1:0] amplitude_out_r, output reg signed [complex_bit-1:0] amplitude_out_i 
);

//Multiplication mechanism
//alpha: +1, -1. +i, or -i
integer i;

always@(*)
begin
	i=0;
	if(alpha_r == 2'd1) 		//+1 => a + bi
	begin
		amplitude_out_r <= amplitude_in_r;
		amplitude_out_i <= amplitude_in_i;
	end
	else if(alpha_r == -2'd1) 	//-1 => -a + -bi
	begin	
		amplitude_out_r <= -amplitude_in_r;
		amplitude_out_i <= -amplitude_in_i;
	end
	else if(alpha_i == 2'd1) 	//i => -b + ai
	begin
		amplitude_out_r <= -amplitude_in_i;
		amplitude_out_i <= amplitude_in_r;
	end
	else if(alpha_i == -2'd1) 	//-i => b + -ai
	begin
		amplitude_out_r <= amplitude_in_i;
		amplitude_out_i <= -amplitude_in_r;
	end
	else				        //Shouldn't get here
	begin
		for(i=0;i<complex_bit;i++)
		begin
			amplitude_out_r[i] <= 1'b0;
			amplitude_out_i[i] <= 1'b0;
		end	
	end
end

endmodule
