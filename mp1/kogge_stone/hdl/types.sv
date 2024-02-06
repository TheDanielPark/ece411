package ks_types;
// Generate and Propagate Signals
typedef struct {
    logic G;
    logic P;

    // USED FOR RUN-TIME TYPE CHECKING
    int lidx;
    int ridx;
} gp_t;
endpackage
