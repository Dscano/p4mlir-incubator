// RUN: p4mlir-translate --typeinference-only %s | FileCheck %s

// Check basic types of selects & autogenerated transition to reject
parser p1(in bit<10> foo, out bool matches) {
    state start {
        transition select(foo) {
          1 : drop;
          10..20 : next;
          0 &&& 0 : next;
        }
    }

    state drop {
    }

    state next {
        matches = true;
        transition accept;
    }
}

// CHECK-LABEL:  p4hir.parser @p1
// CHECK-LABEL: p4hir.state @start
// CHECK: p4hir.transition_select %{{.*}} : !b10i
// CHECK:        p4hir.select_case {
// CHECK:          %[[c1_b10i:.*]] = p4hir.const #int1_b10i
// CHECK:          %[[set:.*]] = p4hir.set (%[[c1_b10i]]) : !p4hir.set<!b10i>
// CHECK:          p4hir.yield %[[set]] : !p4hir.set<!b10i>
// CHECK:        } to @p1::@drop
// CHECK:        p4hir.select_case {
// CHECK:          %[[c10_b10i:.*]] = p4hir.const #int10_b10i
// CHECK:          %[[c20_b10i:.*]] = p4hir.const #int20_b10i
// CHECK:          %[[range:.*]] = p4hir.range(%[[c10_b10i]], %[[c20_b10i]]) : !p4hir.set<!b10i>
// CHECK:          p4hir.yield %[[range]] : !p4hir.set<!b10i>
// CHECK:        } to @p1::@next
// CHECK:        p4hir.select_case {
// CHECK:          %[[c0_b10i:.*]] = p4hir.const #int0_b10i
// CHECK:          %[[c0_b10i_0:.*]] = p4hir.const #int0_b10i
// CHECK:          %[[mask:.*]] = p4hir.mask(%[[c0_b10i:.*]], %[[c0_b10i_0:.*]]) : !p4hir.set<!b10i>
// CHECK:          p4hir.yield %[[mask:.*]] : !p4hir.set<!b10i>
// CHECK:        } to @p1::@next
// CHECK:        p4hir.select_case {
// CHECK:          %[[everything:.*]] = p4hir.const #everything
// CHECK:          p4hir.yield %[[everything]] : !p4hir.set<!p4hir.dontcare>
// CHECK:        } to @p1::@reject
// CHECK:      }
// CHECK-LABEL: p4hir.state @drop {
// CHECK:      p4hir.transition to @p1::@reject
// CHECK-LABEL: p4hir.state @next {
// CHECK:      p4hir.transition to @p1::@accept
// CHECK-LABEL:    p4hir.state @accept {
// CHECK:      p4hir.parser_accept
// CHECK-LABEL    p4hir.state @reject {
// CHECK:      p4hir.parser_reject
// CHECK:    p4hir.transition to @p1::@start

parser p2(in bit<10> foo, out bool matches) {
    state start {
        transition select(foo, true) {
          (1, false) : drop;
          (10..20, true) : next;
          (0 &&& 0, _) : next;
          (_, _) : reject;
          _ : reject;
        }
    }

    state drop {
    }

    state next {
        matches = true;
        transition accept;
    }
}

// Check more complex set product operations
// CHECK-LABEL: p4hir.parser @p2
// CHECK-LABEL:    p4hir.state @start {
// CHECK:      p4hir.transition_select %{{.*}} : tuple<!b10i, !p4hir.bool> {
// CHECK:        p4hir.select_case {
// CHECK:          %[[c1_b10i:.*]] = p4hir.const #int1_b10i
// CHECK:          %[[set:.*]] = p4hir.set (%[[c1_b10i]]) : !p4hir.set<!b10i>
// CHECK:          %[[false:.*]] = p4hir.const #false
// CHECK:          %[[set_0:.*]] = p4hir.set (%[[false]]) : !p4hir.set<!p4hir.bool>
// CHECK:          %[[setproduct:.*]] = p4hir.set_product (%[[set]], %[[set_0]]) : !p4hir.set<tuple<!b10i, !p4hir.bool>>
// CHECK:          p4hir.yield %[[setproduct]] : !p4hir.set<tuple<!b10i, !p4hir.bool>>
// CHECK:        } to @p2::@drop
// CHECK:        p4hir.select_case {
// CHECK:          %[[c10_b10i:.*]] = p4hir.const #int10_b10i
// CHECK:          %[[c20_b10i:.*]] = p4hir.const #int20_b10i
// CHECK:          %[[range:.*]] = p4hir.range(%[[c10_b10i]], %[[c20_b10i]]) : !p4hir.set<!b10i>
// CHECK:          %[[true_0:.*]] = p4hir.const #true
// CHECK:          %[[set:.*]] = p4hir.set (%true_0) : !p4hir.set<!p4hir.bool>
// CHECK:          %[[setproduct:.*]] = p4hir.set_product (%[[range]], %[[set]]) : !p4hir.set<tuple<!b10i, !p4hir.bool>>
// CHECK:          p4hir.yield %[[setproduct]] : !p4hir.set<tuple<!b10i, !p4hir.bool>>
// CHECK:        } to @p2::@next
// CHECK:        p4hir.select_case {
// CHECK:          %[[c0_b10i:.*]] = p4hir.const #int0_b10i
// CHECK:          %[[c0_b10i_0:.*]] = p4hir.const #int0_b10i
// CHECK:          %[[mask:.*]] = p4hir.mask(%[[c0_b10i]], %[[c0_b10i_0]]) : !p4hir.set<!b10i>
// CHECK:          %[[everything:.*]] = p4hir.const #everything
// CHECK:          %[[setproduct:.*]] = p4hir.set_product (%[[mask]], %[[everything]]) : !p4hir.set<tuple<!b10i, !p4hir.dontcare>>
// CHECK:          p4hir.yield %[[setproduct]] : !p4hir.set<tuple<!b10i, !p4hir.dontcare>>
// CHECK:        } to @p2::@next
// CHECK:        p4hir.select_case {
// CHECK:          %[[everything:.*]] = p4hir.const #everything
// CHECK:          %[[everything_0:.*]] = p4hir.const #everything
// CHECK:          %[[setproduct:.*]] = p4hir.set_product (%[[everything]], %[[everything_0]]) : !p4hir.set<tuple<!p4hir.dontcare, !p4hir.dontcare>>
// CHECK:          p4hir.yield %[[setproduct]] : !p4hir.set<tuple<!p4hir.dontcare, !p4hir.dontcare>>
// CHECK:        } to @p2::@reject
// CHECK:        p4hir.select_case {
// CHECK:          %[[everything:.*]] = p4hir.const #everything
// CHECK:          p4hir.yield %[[everything]] : !p4hir.set<!p4hir.dontcare>
// CHECK:        } to @p2::@reject
// CHECK-LABEL:    p4hir.state @drop {
// CHECK:      p4hir.transition to @p2::@reject
// CHECK-LABEL:    p4hir.state @next {
// CHECK:      p4hir.transition to @p2::@accept
// CHECK-LABEL:    p4hir.state @accept {
// CHECK:      p4hir.parser_accept
// CHECK-LABEL:    p4hir.state @reject {
// CHECK:      p4hir.parser_reject
// CHECK:    p4hir.transition to @p2::@start

// Do not check the output, just ensure this compiles :)
parser weird(in int<32> arg1, inout int<32> arg2) {
    bit<32> val1 = 2;
    bool flag;

    state start {
        transition select (arg1, {val1, val1, val1}) {
                   (arg1, {1, 2, 3}): foo1;
                   (3..7, _): foo2;
                   (arg1 &&& (arg2 + 42), _) : foo3;
                   (_ , _): accept;
        }
    }

    state foo1 {
        transition select (arg1) {
                   4..10: foo2;
                   (4..10): foo2;
                   2..(arg2+arg1*7): foo3;
                   (2..(arg2-3)): foo3;
                   1: reject;
                   _: accept;
        }
    }

    state foo2 {
        transition select (arg1, val1) {
                   (1, 3..4): foo2;
                   _: accept;
        }
    }

    state foo3 {
        bool local_flag = flag;
        if (flag == false) {
            local_flag = false;
        } else {
            local_flag = true;
        }
        transition select (local_flag) {
                   false: foo2;
                   true: foo1;
        }
    }
}
