module compute_global_phase #(parameter num_qubit = 4)(
//General:
input clk, input rst_new,
//Input:
input ld_global_phase, input [1:0] reg_gate_type, input alpha_beta, //0: alpha; 1: beta
input signed [31:0] alpha_r, input signed [31:0] alpha_i, input signed [31:0] beta_r, input signed [31:0] beta_i, 
input ld_measure_update,
//Output:
output reg signed [31:0] global_phase_r, output reg signed [31:0] global_phase_i, output reg [31:0] count_H
);

/**************************************GLOBAL PHASE MAINTENANCE***************************************/
//Global Phase Update: global_phase * alpha / beta

always@(posedge clk or posedge rst_new)
begin
	if(rst_new)
	begin
		global_phase_r <= 32'd1; 
		global_phase_i <= 32'd0; 
		count_H <= 32'd0;
	end
	else
	begin
		if(ld_global_phase)
		begin
			//Keep track of the number of Hadamard gate in the circuit for the computation of 0.707107 factor
			//Update when global phase is updated for beta
			if(reg_gate_type == 2'd0 && alpha_beta == 1'd1)//Hadamard 
			begin
				count_H <= count_H + 32'd1;
			end
			//alpha: Could have both nonzero element for real and imaginary (for Hadamard gate with summation) 
			if(alpha_beta == 1'd0) 
			begin
				//c->r = (a.r * b.r) - (a.i * b.i)
				global_phase_r <= (global_phase_r * alpha_r) - (global_phase_i * alpha_i); 
				//c->i = (a.i * b.r) + (a.r * b.i);
				global_phase_i <= (global_phase_i * alpha_r) + (global_phase_r * alpha_i); 
			end
			//beta: Would only have one nonzero element of either real or imaginary (+1, -1, +i, or -i)
			else
			begin
				//These cases should be mutually exclusive
				if(beta_r == 1'd1)          //divide by +1: Remain Unchanged
				begin
					global_phase_r <= global_phase_r; global_phase_i <= global_phase_i;
				end
				else if(beta_r == -1'd1)    //divide by -1: Multiply by -1
				begin
					global_phase_r <= -global_phase_r; global_phase_i <= -global_phase_i;
				end
				else if(beta_i == 1'd1)     //divide by i: Multiply by -i
				begin
					//(global_phase_r * alpha_r) - (global_phase_i * alpha_i);  
					global_phase_r <= global_phase_i;//-(global_phase_i * -32'd1); 
					//(global_phase_i * alpha_r) + (global_phase_r * alpha_i); 
					global_phase_i <= -global_phase_r;//(global_phase_r * -32'd1); 
				end
				else if(beta_i == -1'd1)    //divide by -i: Multiply by i
				begin
					//(global_phase_r * alpha_r) - (global_phase_i * alpha_i); 
					global_phase_r <= -global_phase_i; //-(global_phase_i * 32'd1)
					//(global_phase_i * alpha_r) + (global_phase_r * alpha_i); 
					global_phase_i <= global_phase_r;//(global_phase_r * 32'd1); 
				end
			end
		end
		else if(ld_measure_update)
		begin
			global_phase_r <= global_phase_r; global_phase_i <= global_phase_i; count_H <= count_H-1;
		end
		else
		begin
			global_phase_r <= global_phase_r; global_phase_i <= global_phase_i; count_H <= count_H;
		end
	end
end
endmodule
