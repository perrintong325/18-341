module TB();

logic [7:0] in;
logic clock, resetN, done, error;
logic [1:0] TBerrorSelect;

loadMem loadmem(.*);

initial begin
  clock = 0;
  forever #1 clock = ~clock;
end

class packet;
  rand bit [7:0] count;
  rand bit [7:0] address;
  rand bit [7:0] data[];

  constraint A {count inside {[0:19]};}
  constraint B {address inside {[0:255]};}
  constraint C {data.size == count;}
  constraint D { foreach (data[i]){
                    data[i] inside {[0:255]};
                  }
               }
endclass

logic [7:0] checkSum;
packet pkt = new;
packet pkt2 = new;
packet pkt3 = new;

task sendPkt;
//sending packets to in 8 bits at a time
//start->count->address->data->(negative)checksum
  checkSum = 0;
  if(!pkt.randomize()) $display(0, "Packet randomization failed");
  @(posedge clock);
  in <= 8'h01;
  @(posedge clock);
  in <= pkt.count;
  checkSum += pkt.count;
  @(posedge clock);
  in <= pkt.address;
  checkSum += pkt.address;
  for (int i = 0; i < pkt.count; i++) begin
    @(posedge clock);
    in <= pkt.data[i];
    checkSum += pkt.data[i];
  end
  @(posedge clock);
  in <= (~checkSum) + 8'h1;
endtask

task sendPktWrongChecksum;
//sending packets to in 8 bits at a time
//start->count->address->data->0
  checkSum = 0;
  if(!pkt3.randomize()) $display(0, "Packet randomization failed");
  @(posedge clock);
  in <= 8'h01;
  @(posedge clock);
  in <= pkt3.count;
  checkSum += pkt3.count;
  @(posedge clock);
  in <= pkt3.address;
  checkSum += pkt3.address;
  for (int i = 0; i < pkt3.count; i++) begin
    @(posedge clock);
    in <= pkt3.data[i];
    checkSum += pkt3.data[i];
  end
  @(posedge clock);
  in <= (~checkSum);
endtask

function void checkError;
//checking for incorrect error assertion
  if(error && (((checkSum + (~checkSum) + 8'h1)%'d256) == 8'h0)) begin
    $display("Error unexpectedly asserted");
  end else if (!error && (((checkSum + (~checkSum) + 8'h1)%'d256) != 8'h0))begin
    $display("Error not asserted");
  end else if (error && !done) begin
    $display("Error asserted before done");
  end
endfunction

function void checkWrongError;
//checking for incorrect error assertion with wrong checksum
  if(error && (((checkSum + (~checkSum))%'d256) == 8'h0)) begin
    $display("Error unexpectedly asserted");
  end else if (!error && (((checkSum + (~checkSum))%'d256) != 8'h0))begin
    $display("Error not asserted");
  end else if (error && !done) begin
    $display("Error asserted before done");
  end
endfunction

function void checkMemory
  (input logic whichPkt);
//checking for incorrect writes to memory
  if (whichPkt) begin
    for (int i = 0; i < pkt.count; i++) begin
      if(loadmem.M.M[pkt.address + i] != pkt.data[i]) begin
        $display("Memory mismatch at %h, %h at memory, expecting %h", 
                  pkt.address + i, loadmem.M.M[pkt.address + i], pkt.data[i]);
      end
    end
  end else begin
    for (int i = 0; i < pkt3.count; i++) begin
      if(loadmem.M.M[pkt3.address + i] != pkt3.data[i]) begin
        $display("Memory mismatch at %h, %h at memory, expecting %h", 
                  pkt3.address + i, loadmem.M.M[pkt3.address + i],pkt3.data[i]);
      end
    end
  end
endfunction

function void checkDone;
//checking for incorrect done assertion
  if(!done) begin
    $display("Done not asserted");
  end
endfunction

initial begin
  @(posedge clock);
  resetN <= 0;
  @(posedge clock);
  resetN <= 1;
  in <= 8'h00;
  for(int x = 0; x < 4; x++) begin
  //testing for all error cases
    @(posedge clock);
    TBerrorSelect <= x;
    $display("==============TBerrorSelect = %d==============", x[1:0]);
    $display("==============Correct Packet==============");
    @(posedge clock);
    for (int i = 0; i < 10; i++) begin
      //send correct packets
      sendPkt();
      //start checking for error once packet is sent
      @(posedge clock);
      checkDone();
      checkError();
      checkMemory('d1);
      @(posedge clock);
    end
    $display("==============Wrong Checksum==============");
    @(posedge clock);
    for (int k = 0; k < 10; k++) begin
      //send wrong checksum packets
      sendPktWrongChecksum();
      @(posedge clock);
      checkDone();
      checkWrongError();
      checkMemory('d0);
    end
    $display("==============================================");
  end
  @(posedge clock);
  $finish;
end

endmodule: TB