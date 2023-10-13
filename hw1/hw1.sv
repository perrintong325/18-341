module hw1();    
    logic a, b, c, d, e;
    initial begin: A1 // note the use of a label to identify a block
        $monitor("a=%b, b=%b, c=%b, d=%b, e=%b", a, b, c, d, e);
        a = 0;
        d = 0;
        @(posedge d);
        e = b;
        b = 0;
        #1 c = 0;
        #1;
    end
    initial begin: A2
        d <= #1 1;
        a = 1;
        b = 0;
        #1 c = 1;
        b = 1;
    end
endmodule: hw1

