
/*
 * File: ucsbece154b_fifo.sv
 * Description: Starter file for fifo.

 * data_o:  the head of the queue. It's always there
 * pop_i:   instruction to pop an item off.
 * data_i:  data to insert into the queue.
 * push_i:  instruction to insert an item
 * full_o:  flag bits signaling that the queue is full
 * valid_o: flag bits signaling that the queue is not empty
 */

module ucsbece154b_fifo #(
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned NR_ENTRIES = 4
) (
    input   logic                   clk_i,
    input   logic                   rst_i,

    output  logic [DATA_WIDTH-1:0]  data_o,
    input   logic                   pop_i,

    input   logic [DATA_WIDTH-1:0]  data_i,
    input   logic                   push_i,

    output  logic                   full_o,
    output  logic                   valid_o
);

// TODO
   // Internal registers and wire declarations
    logic [DATA_WIDTH-1:0] queue [0:NR_ENTRIES-1];
    localparam POINTER_WIDTH = $clog2(NR_ENTRIES);
    logic [POINTER_WIDTH-1:0] head_q, tail_q;
    logic [POINTER_WIDTH:0] count_q;

    // Output assign
    assign data_o = queue[head_q];
    assign full_o = (count_q == NR_ENTRIES);
    assign valid_o = (count_q != 0);

    // always_ff block
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            head_q <= 0;
            tail_q <= 0;
            count_q <= 0;
        end else begin
            // Pop logic
            if (pop_i && (count_q != 0)) begin
                if(head_q ==(NR_ENTRIES - 1))
                    head_q <= 0;
                else
                    head_q <= head_q + 1;
                count_q <= count_q - 1;
            end

            // Push logic
            if (push_i && (count_q != NR_ENTRIES)) begin
                queue[tail_q] <= data_i;
                if(tail_q ==(NR_ENTRIES - 1))
                    tail_q <= 0;
                else
                    tail_q <= tail_q + 1;
                count_q <= count_q + 1;
            end
        end
    end

endmodule
