module literal_update #(parameter num_qubit = 4)(
//Input:
input control_target, //0: Control; 1: Target
input [2:0] gate_type, //0: Hadamard; 1: Phase; 2: CNOT
input [1:0] left_out [0:num_qubit-1],
input [1:0] c_reg [0:num_qubit-1],	//[row]
input [1:0] t_reg [0:num_qubit-1],	//[row]
//Output:
output reg [1:0] update_literal [0:num_qubit-1], 
output reg toggle_phase [0:num_qubit-1]
);

/****************************DETERMINE LITERAL-OF-INTEREST UPDATE ACCORDING TO LUT***********************************/
integer i;

always@(*)
begin
	case(gate_type)
		3'd0: //Hadamard
		begin
			for (i=0; i<num_qubit; i=i+1) //each row 
			begin
				toggle_phase[i] <= 1'd0;
				case(left_out[i])
					2'd0: //I -> I
					begin
						update_literal [i] <= 2'd0;
					end
					2'd1: //Z -> X
					begin
						update_literal [i] <= 2'd2;
					end
					2'd2: //X -> Z
					begin
						update_literal [i] <= 2'd1;
					end
					2'd3: //Y -> -Y
					begin
						update_literal [i] <= 2'd3;
						toggle_phase[i] <= 1'd1;
					end
				endcase
			end
		end
		3'd1: //Phase
		begin
			for (i=0; i<num_qubit; i=i+1) //each row 
			begin
				toggle_phase[i] <= 1'd0;
				case(left_out[i])
					2'd0: //I -> I
					begin
						update_literal [i] <= 2'd0;
					end
					2'd1: //Z -> Z
					begin
						update_literal [i] <= 2'd1;
					end
					2'd2: //X -> Y
					begin
						update_literal [i] <= 2'd3;
					end
					2'd3: //Y -> -X
					begin
						update_literal [i] <= 2'd2;
						toggle_phase[i] <= 1'd1;
					end
				endcase
			end
		end
		3'd2: //CNOT
		begin
			for (i=0; i<num_qubit; i=i+1) //each row 
			begin
				toggle_phase[i] <= 1'd0;
				if(control_target == 1'd0) //control_qubit
				begin
					case (c_reg[i])
						2'd0: //I
						begin
							case (t_reg[i])
								2'd0: //I
								begin
									update_literal [i] <= 2'd0; //II
								end
								2'd1: //Z
								begin
									update_literal [i] <= 2'd1; //ZZ
								end
								2'd2: //X
								begin
									update_literal [i] <= 2'd0; //IX
								end
								2'd3: //Y
								begin
									update_literal [i] <= 2'd1; //ZY
								end
							endcase
						end
						2'd1: //Z
						begin
							case (t_reg[i])
								2'd0: //I
								begin
									update_literal [i] <= 2'd1; //ZI
								end
								2'd1: //Z
								begin
									update_literal [i] <= 2'd0; //IZ
								end
								2'd2: //X
								begin
									update_literal [i] <= 2'd1; //ZX
								end
								2'd3: //Y
								begin
									update_literal [i] <= 2'd0; //IY
								end
							endcase
						end
						2'd2: //X
						begin
							case (t_reg[i])
								2'd0: //I
								begin
									update_literal [i] <= 2'd2; //XX
								end
								2'd1: //Z
								begin
									update_literal [i] <= 2'd3; //-YY
								end
								2'd2: //X
								begin
									update_literal [i] <= 2'd2; //XI
								end
								2'd3: //Y
								begin
									update_literal [i] <= 2'd3; //YZ
								end
							endcase
						end
						2'd3: //Y
						begin
							case (t_reg[i])
								2'd0: //I
								begin
									update_literal [i] <= 2'd3; //YX
								end
								2'd1: //Z
								begin
									update_literal [i] <= 2'd2; //XY
								end
								2'd2: //X
								begin
									update_literal [i] <= 2'd3; //YI
								end
								2'd3: //Y
								begin
									update_literal [i] <= 2'd2; //-XZ
								end
							endcase
						end
					endcase
				end
				else //target_qubit
				begin
					case (c_reg[i])
						2'd0: //I
						begin
							case (t_reg[i])
								2'd0: //I
								begin
									update_literal [i] <= 2'd0; //II
								end
								2'd1: //Z
								begin
									update_literal [i] <= 2'd1; //ZZ
								end
								2'd2: //X
								begin
									update_literal [i] <= 2'd2; //IX
								end
								2'd3: //Y
								begin
									update_literal [i] <= 2'd3; //ZY
								end
							endcase
						end
						2'd1: //Z
						begin
							case (t_reg[i])
								2'd0: //I
								begin
									update_literal [i] <= 2'd0; //ZI
								end
								2'd1: //Z
								begin
									update_literal [i] <= 2'd1; //IZ
								end
								2'd2: //X
								begin
									update_literal [i] <= 2'd2; //ZX
								end
								2'd3: //Y
								begin
									update_literal [i] <= 2'd3; //IY
								end
							endcase
						end
						2'd2: //X
						begin
							case (t_reg[i])
								2'd0: //I
								begin
									update_literal [i] <= 2'd2; //XX
								end
								2'd1: //Z
								begin
									update_literal [i] <= 2'd3; //-YY
									toggle_phase [i] <= 1'd1;
								end
								2'd2: //X
								begin
									update_literal [i] <= 2'd0; //XI
								end
								2'd3: //Y
								begin
									update_literal [i] <= 2'd1; //YZ
								end
							endcase
						end
						2'd3: //Y
						begin
							case (t_reg[i])
								2'd0: //I
								begin
									update_literal [i] <= 2'd2; //YX
								end
								2'd1: //Z
								begin
									update_literal [i] <= 2'd3; //XY
								end
								2'd2: //X
								begin
									update_literal [i] <= 2'd0; //YI
								end
								2'd3: //Y
								begin
									update_literal [i] <= 2'd1; //-XZ
									toggle_phase [i] <= 1'd1;
								end
							endcase
						end
					endcase
				end
			end
		end
		default:
		begin
			for (i=0; i<num_qubit; i=i+1) //each row 
			begin
				update_literal [i] <= 2'd0;
				toggle_phase [i] <= 1'd0;
			end
		end
	endcase
end

endmodule
