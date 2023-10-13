module queue
(input logic clock, reset_l,
input logic get, put,
output logic full, empty, dReady,
output logic [7:0] dOut,
input logic [7:0] dIn);
logic [7:0] Q [8]; // a memory array of 8 bytes
logic [2:0] putPtr, getPtr; // pointers wrap automatically
logic [3:0] count;
assign empty = (count == 0);
assign full = (count == 4'd8);
always_ff @(posedge clock, negedge reset_l) begin
if (~reset_l) begin
count <= 0;
getPtr <= 0;
putPtr <= 0;
end
else begin
dReady <= 0;
if (get && (!empty)) begin // not empty
dOut <= Q[getPtr];
getPtr <= getPtr + 1;
count <= count - 1;
dReady <= 1;
end
else if (put && (!full)) begin // not full
Q[putPtr] <= dIn;
putPtr <= putPtr + 1;
count <= count + 1;
end
end
end
endmodule: queue