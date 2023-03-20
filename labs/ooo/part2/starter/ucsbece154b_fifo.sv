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
    struct packed {
		logic [DATA_WIDTH-1:0] data;
	} queue[NR_ENTRIES-1:0];
    
    //logic [DATA_WIDTH-1:0] queue [0:NR_ENTRIES-1];
    localparam POINTER_WIDTH = $clog2(NR_ENTRIES);
    logic [POINTER_WIDTH-1:0] head_d, head_q, tail_d, tail_q;
    logic [POINTER_WIDTH:0] count_d, count_q;
    logic push_valid;

    // Output assign
    assign data_o = queue[head_q].data;
    assign full_o = (count_q == NR_ENTRIES);
    assign valid_o = (count_q != 0);
    
    // init value
    initial begin
        head_q = 0;
        tail_q = 0;
        count_q = 0;
    end
    
    // always_comb block
    always_comb begin
        head_d = head_q;
        tail_d = tail_q;
        count_d = count_q;
        push_valid = 0;

        if (pop_i && (count_d != 0)) begin
            head_d = (head_d == (NR_ENTRIES - 1)) ? 0 : head_d + 1;
            count_d = count_d - 1;
        end

        if (push_i && (count_d != NR_ENTRIES)) begin
            tail_d = (tail_d == (NR_ENTRIES - 1)) ? 0 : tail_d + 1;
            count_d = count_d + 1;
            push_valid = 1'b1;
        end
    end

    // always_ff block
    always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            head_q <= 0;
            tail_q <= 0;
            count_q <= 0;
        end else begin
            head_q <= head_d;
            tail_q <= tail_d;
            count_q <= count_d;

            if (push_valid) begin
                queue[tail_q].data <= data_i;
            end
        end
    end

endmodule
