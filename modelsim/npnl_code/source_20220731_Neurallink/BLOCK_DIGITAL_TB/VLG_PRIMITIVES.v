//************************************************************************/
// Copyright        : (c) All Rights Reserved 
// Company          : X-FAB Global Services GmbH
// Address          : Haarbergstr. 67,  D-99097 Erfurt, Germany
//
// File             : VLG_PRIMITIVES.v
// Description      : Verilog simulation file: primitives & UDP's
//
// Lib_version      : V 1.1.0, Nov 19 2018
//
// #######################################################################
//
// Copyright (c) X-FAB Global Services GmbH. All rights reserved.
// This Design Kit data and the associated documentation are
// confidential and proprietary to X-FAB Global Services GmbH.
//
// DISCLAIMER
// The information furnished herein by X-FAB Global Services GmbH (X-FAB) 
// is substantially correct and accurate. However, X-FAB shall not be 
// liable to licensee or any third party for any damages, including but 
// not limited to property damage, loss of profits, loss of use, 
// interruption of business or indirect, special, incidental or 
// consequential damages, of any kind, in connection with or arising out 
// of the furnishing, performance or use of the technical data. 
// No obligation or liability to licensee or any third party shall arise 
// or flow out of X-FAB rendering technical or other services.
// 
// X-FAB makes no warranty, express, implied, statutory, or descriptive 
// of the information contained herein or of warranties of 
// merchantability, fitness for a particular purpose, or non-infringement.
// X-FAB reserves the right to change specifications and prices at any 
// time and without notice. Therefore, prior to designing this product 
// into a system, it is necessary to check with X-FAB for current 
// information. The products listed herein are intended for use in 
// standard commercial applications. Applications requiring extended 
// temperature range, unusual environmental requirements, or high 
// reliability applications, such as military, medical life-support 
// or life-sustaining equipment are specifically not recommended without 
// additional processing by X-FAB for each application.
//
// #######################################################################
// ***********************************************************************
// Remark:
// 
// If an ATPG tool is used then the compiler directive 
//   `define ATPG_RUN yes
// has to be set before reading this library.
//
// ***********************************************************************
//************************************************************************/

`timescale 1ns/10ps

// --------------------------------------------------------------------
// cell primitive section --- BEGIN ---

primitive u1_fd4  (Q, D, C, RN, SN, NOTIFY);

    output Q;
    input  D, C, RN, SN, NOTIFY;
    reg    Q;

// FUNCTION : POSITIVE EDGE TRIGGERED D FLIP-FLOP WITH 
//            ASYNCHRONOUS ACTIVE LOW SET AND CLEAR.

    table

//  D    C    RN    SN   NTFY : Qt  : Qt+1
// ---- ---- ----- ----- ---- : --- : ----
// data clk  rst_n set_n ntfy : Qi  : Q_out           
// ---- ---- ----- ----- ---- : --- : ----

    *	 b    1     1	  ?   :  ?  :  -  ; // data changes, clk stable
    ?  (?0)   1     1	  ?   :  ?  :  -  ; // clocks off


    1  (0x)   1     ?	  ?   :  1  :  1  ; // possible clk of D=1, but Q=1
    0  (0x)   ?     1	  ?   :  0  :  0  ; // possible clk of D=0, but Q=0

    ?	 ?    1     0	  ?   :  ?  :  1  ; // async set
    ?	 ?    0     1	  ?   :  ?  :  0  ; // async reset
//    ?	 ?    0     0	  ?   :  ?  :  0  ; // async reset and set - only by xlicdd models possible 

    0  (01)   ?     1	  ?   :  ?  :  0  ; // clocking D=0
    1  (01)   1     ?	  ?   :  ?  :  1  ; // clocking D=1

   					    // reduced pessimism: 
    ?    ?  (?1)    1     ?   :  ?  :  -  ; // ignore the edges on rst_n
    ?    ?    1   (?1)    ?   :  ?  :  -  ; // ignore the edges on set_n

    1  (x1)   1     ?     ?   :  1  :  1  ; // potential pos_edge clk, potential set_n, but D=1 && Qi=1
    0  (x1)   ?     1     ?   :  0  :  0  ; // potential pos_edge clk, potential rst_n, but D=0 && Qi=0

    1  (1x)   1     ?     ?   :  1  :  1  ; // to_x_edge clk, but D=1 && Qi=1
    0  (1x)   ?     1     ?   :  0  :  0  ; // to_x_edge clk, but D=0 && Qi=0

`ifdef    ATPG_RUN

    ?	 *    1     0	  ?   :  ?  :  1  ; // clk while async set	      // ATPG
    ?	 *    0     1	  ?   :  ?  :  0  ; // clk while async reset	      // ATPG
    ?	 ?    1     x	  ?   :  1  :  1  ; //   set=X, but Q=1		      // ATPG
    ?    ?    x     1	  ?   :  0  :  0  ; // reset=X, but Q=0		      // ATPG

`else
   					    // reduced pessimism: 
    1	 ?    1     x	  ?   :  1  :  1  ; //   set=X, but Q=1    	      // Vlg
    0	 b    1   (0x)	  ?   :  1  :  1  ; //   set=X, D=0, but Q=1   	      // Vlg
    0	 b    1   (1x)	  ?   :  1  :  1  ; //   set=X, D=0, but Q=1   	      // Vlg
   (??)	 b    1     ?	  ?   :  1  :  1  ; //   set=X, D=egdes, but Q=1      // Vlg
    ?  (?0)   1     x	  ?   :  1  :  1  ; //   set=X, neg_edge clk, but Q=1 // Vlg

    0    ?    x     1	  ?   :  0  :  0  ; // reset=X, but Q=0    	      // Vlg
    1    b  (0x)    1	  ?   :  0  :  0  ; // reset=X, D=1, but Q=0   	      // Vlg
    1    b  (1x)    1	  ?   :  0  :  0  ; // reset=X, D=1, but Q=0   	      // Vlg
   (??)  b    ?     1	  ?   :  0  :  0  ; // reset=X, D=egdes, but Q=0      // Vlg
    ?  (?0)   x     1	  ?   :  0  :  0  ; // reset=X, neg_edge clk, but Q=0 // Vlg

 
`endif // ATPG_RUN

    endtable

endprimitive


primitive u1_fd5  (Q, D, C, RN, SN, NOTIFY);

    output Q;
    input  D, C, RN, SN, NOTIFY;
    reg    Q;

// FUNCTION : POSITIVE EDGE TRIGGERED D FLIP-FLOP WITH 
//            ASYNCHRONOUS ACTIVE LOW SET AND CLEAR.
//            with the correct behavioral if set and reset Low
    table

//  D    C    RN    SN   NTFY : Qt  : Qt+1
// ---- ---- ----- ----- ---- : --- : ----
// data clk  rst_n set_n ntfy : Qi  : Q_out           
// ---- ---- ----- ----- ---- : --- : ----

    *	 ?    1     1	  ?   :  ?  :  -  ; // data changes, clk stable
    ?    n    1     1	  ?   :  ?  :  -  ; // clock falling edge


    1  (0x)   1     ?	  ?   :  1  :  1  ; // possible clk of D=1, but Q=1
    0  (0x)   ?     1	  ?   :  0  :  0  ; // possible clk of D=0, but Q=0

    ?	 ?    1     0	  ?   :  ?  :  1  ; // async set
    ?	 ?    0     ?	  ?   :  ?  :  0  ; // async reset, set 0,1,x

    0  (01)   ?     1	  ?   :  ?  :  0  ; // clocking D=0
    1  (01)   1     ?	  ?   :  ?  :  1  ; // clocking D=1

   					                        // reduced pessimism: 
    ?    ?  (?1)    1     ?   :  ?  :  -  ; // ignore the edges on rst_n
    ?    ?    1   (?1)    ?   :  ?  :  -  ; // ignore the edges on set_n

    1  (x1)   1     ?     ?   :  1  :  1  ; // potential pos_edge clk, potential set_n, but D=1 && Qi=1
    0  (x1)   ?     1     ?   :  0  :  0  ; // potential pos_edge clk, potential rst_n, but D=0 && Qi=0

//    1  (1x)   1     ?     ?   :  1  :  1  ; // to_x_edge clk, but D=1 && Qi=1
//    0  (1x)   ?     1     ?   :  0  :  0  ; // to_x_edge clk, but D=0 && Qi=0

`ifdef    ATPG_RUN

    ?	 *    1     0	  ?   :  ?  :  1  ; // clk while async set	      // ATPG
    ?	 *    0     1	  ?   :  ?  :  0  ; // clk while async reset	      // ATPG
    ?	 ?    1     x	  ?   :  1  :  1  ; //   set=X, but Q=1		      // ATPG
    ?    ?    x     1	  ?   :  0  :  0  ; // reset=X, but Q=0		      // ATPG

`else
   					    // reduced pessimism: 
    1	 ?    1     x	  ?   :  1  :  1  ; //   set=X, but Q=1    	      // Vlg
    0	 b    1   (0x)	  ?   :  1  :  1  ; //   set=X, D=0, but Q=1   	      // Vlg
    0	 b    1   (1x)	  ?   :  1  :  1  ; //   set=X, D=0, but Q=1   	      // Vlg
   (??)	 b    1     ?	  ?   :  1  :  1  ; //   set=X, D=egdes, but Q=1      // Vlg
    ?  (?0)   1     x	  ?   :  1  :  1  ; //   set=X, neg_edge clk, but Q=1 // Vlg

    0    ?    x     1	  ?   :  0  :  0  ; // reset=X, but Q=0    	      // Vlg
    1    b  (0x)    1	  ?   :  0  :  0  ; // reset=X, D=1, but Q=0   	      // Vlg
    1    b  (1x)    1	  ?   :  0  :  0  ; // reset=X, D=1, but Q=0   	      // Vlg
   (??)  b    ?     1	  ?   :  0  :  0  ; // reset=X, D=egdes, but Q=0      // Vlg
    ?  (?0)   x     1	  ?   :  0  :  0  ; // reset=X, neg_edge clk, but Q=0 // Vlg

 
`endif // ATPG_RUN

    endtable

endprimitive


primitive u_ld1 (Q, D, G, NOTI_REG);

    output Q;
    reg    Q;
    input  D,              // data
           G,              // clock
           NOTI_REG;

// FUNCTION : DLATCH, GATED  STANDARD DRIVE / ACTIVE HIGH ( Q OUTPUT UDP )
//


   table
     //  D       G    NOTI_REG        : Qtn :   Qtn+1

         *       0      ?             :  ?  :    -   ;

         ?      (?0)    ?             :  ?  :    -   ;
         0      (1x)    ?             :  0  :    -   ;
         1      (1x)    ?             :  1  :    -   ;

         0      (0x)    ?             :  0  :    0   ;
         1      (0x)    ?             :  1  :    1   ;
         0      (x1)    ?             :  ?  :    0   ;
         1      (x1)    ?             :  ?  :    1   ;

        (?0)     1      ?             :  ?  :    0   ;
        (?1)     1      ?             :  ?  :    1   ;
         0      (01)    ?             :  ?  :    0   ;
         1      (01)    ?             :  ?  :    1   ;

        (?1)     x      ?             :  1  :    1   ;    // Reducing pessimism.
        (?0)     x      ?             :  0  :    0   ;

         ?       ?      *             :  ?  :    x   ;
 
   endtable
endprimitive

primitive u_ld4 (Q,D,G,SN,RN,NOTI_REG);
	output Q;
	input D,G,SN,RN,NOTI_REG;
	reg Q;

// function: D latch active high with reset and set

table
//         D       G      SN    RN   NOTI_REG       : Qtn :   Qtn+1

         *       0      1     1     ?             :  ?  :    -   ;
         ?       ?      1     0     ?             :  ?  :    0   ; // asynchro clear
         ?       ?      0     1     ?             :  ?  :    1   ; // asynchro set

         ?      (?0)    1     1     ?             :  ?  :    -   ;
         0      (1x)    1     1     ?             :  0  :    -   ;
         1      (1x)    1     1     ?             :  1  :    -   ;

         0      (0x)    1     1     ?             :  0  :    0   ;
         1      (0x)    1     1     ?             :  1  :    1   ;
         0      (x1)    1     1     ?             :  ?  :    0   ;
         1      (x1)    1     1     ?             :  ?  :    1   ;

        (?0)     1      1     x     ?             :  ?  :    0   ;
        (?0)     1      1     1     ?             :  ?  :    0   ;
        (?1)     1      1     1     ?             :  ?  :    1   ;
         0      (01)    1     1     ?             :  ?  :    0   ;
         1      (01)    1     1     ?             :  ?  :    1   ;
         1      (01)    x     1     ?             :  ?  :    1   ;

         0      (01)    x     1     ?             :  ?  :    0   ;
         0       ?      x     1     ?             :  0  :    0   ;   // Reducing pessimism.
         1       ?      1     x     ?             :  1  :    1   ;   // Reducing pessimism.

         ?       0     (?1)   1     ?             :  ?  :    -   ;   // ignore edge on clear
         0       1     (?1)   1     ?             :  ?  :    0   ;   // pessimism .
         1       1     (?1)   1     ?             :  ?  :    1   ;
         ?       0      1     (?1)  ?             :  ?  :    -   ;   // ignore edge on set
         0       1      1     (?1)  ?             :  ?  :    0   ;   // pessimism .
         1       1      1     (?1)  ?             :  ?  :    1   ;
 
        (?1)     x      1     1     ?             :  1  :    1   ;   // Reducing pessimism.
        (?0)     x      1     1     ?             :  0  :    0   ;   // Reducing pessimism.
 
         ?       0      1     x     ?             :  0  :    0   ;   // Reducing pessimism.
         ?       0      x     1     ?             :  1  :    1   ;   // Reducing pessimism.

         ?       ?      ?     ?     *             :  ?  :    x   ;
           
endtable
endprimitive

primitive u_ld5 (Q,D,G,SN,RN,NOTI_REG);
	
    output Q;
	input D,G,SN,RN,NOTI_REG;
	reg Q;
	
//          function: D latch active high with reset and set
//          with the correct behavioral if set and reset Low

table
//         D       G      SN    RN   NOTI_REG       : Qtn :   Qtn+1

         *       0      1     1     ?             :  ?  :    -   ;
         ?       ?      1     0     ?             :  ?  :    0   ; // asynchro clear
         ?       ?      0     1     ?             :  ?  :    1   ; // asynchro set
         ?       ?      0     0     ?             :  ?  :    0   ; // set and clear

         ?      (?0)    1     1     ?             :  ?  :    -   ;
         0      (1x)    1     1     ?             :  0  :    -   ;
         1      (1x)    1     1     ?             :  1  :    -   ;

         0      (0x)    1     1     ?             :  0  :    0   ;
         1      (0x)    1     1     ?             :  1  :    1   ;
         0      (x1)    1     1     ?             :  ?  :    0   ;
         1      (x1)    1     1     ?             :  ?  :    1   ;

        (?0)     1      1     x     ?             :  ?  :    0   ;
        (?0)     1      1     1     ?             :  ?  :    0   ;
        (?1)     1      1     1     ?             :  ?  :    1   ;
         0      (01)    1     1     ?             :  ?  :    0   ;
         1      (01)    1     1     ?             :  ?  :    1   ;
         1      (01)    x     1     ?             :  ?  :    1   ;

         0      (01)    x     1     ?             :  ?  :    0   ;
         0       ?      x     1     ?             :  0  :    0   ;   // Reducing pessimism.
         1       ?      1     x     ?             :  1  :    1   ;   // Reducing pessimism.

         ?       0     (?1)   1     ?             :  ?  :    -   ;   // ignore edge on clear
         0       1     (?1)   1     ?             :  ?  :    0   ;   // pessimism .
         1       1     (?1)   1     ?             :  ?  :    1   ;
         ?       0      1     (?1)  ?             :  ?  :    -   ;   // ignore edge on set
         0       1      1     (?1)  ?             :  ?  :    0   ;   // pessimism .
         1       1      1     (?1)  ?             :  ?  :    1   ;
 
        (?1)     x      1     1     ?             :  1  :    1   ;   // Reducing pessimism.
        (?0)     x      1     1     ?             :  0  :    0   ;   // Reducing pessimism.
 
         ?       0      1     x     ?             :  0  :    0   ;   // Reducing pessimism.
         ?       0      x     1     ?             :  1  :    1   ;   // Reducing pessimism.

         ?       ?      ?     ?     *             :  ?  :    x   ;
           
endtable
endprimitive

primitive u_ld6 (Q,D,G,SN,RN,NOTI_REG);
	
    output Q;
	input D,G,SN,RN,NOTI_REG;
	reg Q;
	
//          function: D latch active high with reset and set
//          with the correct behavioral if set and reset Low

table
//         D       G      SN    RN   NOTI_REG       : Qtn :   Qtn+1

         *       0      1     1     ?             :  ?  :    -   ;
         ?       ?      1     0     ?             :  ?  :    0   ; // asynchro clear
         ?       ?      0     1     ?             :  ?  :    1   ; // asynchro set
         ?       ?      0     0     ?             :  ?  :    1   ; // set and clear

         ?      (?0)    1     1     ?             :  ?  :    -   ;
         0      (1x)    1     1     ?             :  0  :    -   ;
         1      (1x)    1     1     ?             :  1  :    -   ;

         0      (0x)    1     1     ?             :  0  :    0   ;
         1      (0x)    1     1     ?             :  1  :    1   ;
         0      (x1)    1     1     ?             :  ?  :    0   ;
         1      (x1)    1     1     ?             :  ?  :    1   ;

        (?0)     1      1     x     ?             :  ?  :    0   ;
        (?0)     1      1     1     ?             :  ?  :    0   ;
        (?1)     1      1     1     ?             :  ?  :    1   ;
         0      (01)    1     1     ?             :  ?  :    0   ;
         1      (01)    1     1     ?             :  ?  :    1   ;
         1      (01)    x     1     ?             :  ?  :    1   ;

         0      (01)    x     1     ?             :  ?  :    0   ;
         0       ?      x     1     ?             :  0  :    0   ;   // Reducing pessimism.
         1       ?      1     x     ?             :  1  :    1   ;   // Reducing pessimism.

         ?       0     (?1)   1     ?             :  ?  :    -   ;   // ignore edge on clear
         0       1     (?1)   1     ?             :  ?  :    0   ;   // pessimism .
         1       1     (?1)   1     ?             :  ?  :    1   ;
         ?       0      1     (?1)  ?             :  ?  :    -   ;   // ignore edge on set
         0       1      1     (?1)  ?             :  ?  :    0   ;   // pessimism .
         1       1      1     (?1)  ?             :  ?  :    1   ;
 
        (?1)     x      1     1     ?             :  1  :    1   ;   // Reducing pessimism.
        (?0)     x      1     1     ?             :  0  :    0   ;   // Reducing pessimism.
 
         ?       0      1     x     ?             :  0  :    0   ;   // Reducing pessimism.
         ?       0      x     1     ?             :  1  :    1   ;   // Reducing pessimism.

         ?       ?      ?     ?     *             :  ?  :    x   ;
           
endtable
endprimitive

primitive u_mx2 (Y,D0,D1,S);
          output Y;
          input D0,D1,S;
 
table
     //  D0    D1   S   :  Y ;
          0     ?   0   :  0 ;
          1     ?   0   :  1 ;
          ?     0   1   :  0 ;
          ?     1   1   :  1 ;
          0     0   x   :  0 ;
          1     1   x   :  1 ;
endtable
endprimitive

primitive check   (z, a, b);
    output z;
    input a, b ;

// FUNCTION :  Comparison cell

    table
    //  a   b       :   z
        1   0       :   1 ;
        0   1       :   1 ;
        x   0       :   1 ;
        x   1       :   1 ;
        0   x       :   1 ;
        1   x       :   1 ;
        0   0       :   0 ;
        1   1       :   0 ;

    endtable
endprimitive

primitive prejk   (z, a, b, c);
    output z;
    input a, b, c ;

// FUNCTION :  Pre Driver Of JK FF

    table
    //  a   b   c   :   z
        0   1   ?   :   0 ;
        1   0   ?   :   1 ;
        x   0   0   :   1 ;
        x   1   0   :   0 ;
        0   x   1   :   0 ;
        1   x   1   :   1 ;
        1   1   1   :   1 ;
        1   1   0   :   0 ;
        0   0   0   :   1 ;
        0   0   1   :   0 ;

    endtable
endprimitive

primitive checkjk   (z, a, b);
    output z;
    input a, b ;

// FUNCTION :  Comparison cell

    table
    //  a   b       :   z
        1   ?       :   1 ;
        x   1       :   1 ;
        x   0       :   0 ;
        0   ?       :   0 ;

    endtable
endprimitive

primitive checkrs   (z, a, b);
    output z;
    input a, b ;

// FUNCTION :  Comparison cell

    table
    //  a    b      :   z
        1    1      :   1 ;
        x    1      :   1 ;
        1    x      :   1 ;
        0    1      :   0 ;
        0    x      :   0 ;
        1    0      :   0 ;
        x    0      :   0 ;
        0    0      :   0 ;

    endtable
endprimitive

primitive check_buf   (z, a, b);
    output z;
    input a, b ;

// FUNCTION :  Comparison cell

    table
    //  a    b      :   z
        1    1      :   1 ;
        x    1      :   x ;
	    0    1      :   0 ;
        1    x      :   x ;
        x    x      :   x ;
	    0    x      :   x ;

    endtable
endprimitive

primitive check_vdd   (z, a);
    output z;
    input a;

// FUNCTION :  Comparison cell

    table
    // a      :   z
       1      :   1 ;

    endtable
endprimitive

primitive check_gnd   (z, a);
    output z;
    input a;

// FUNCTION :  Comparison cell

    table
    // a      :   z
       0      :   1 ;

    endtable
endprimitive


primitive diff_lshifter   (z, a, an);
    output z;
    input a, an;
    reg z;

// FUNCTION :  differrential level shifter

    table
    // a   an :  zt-1 :  z
       0    1 :   ?   :  0 ;
       1    0 :   ?   :  1 ;
       1    1 :   ?   :  1 ;
       0    0 :   0   :  0 ;
       0    0 :   1   :  1 ;

    endtable
endprimitive

module resistorswitch_ams (A, B, E, power_vdd, ground_gnd);

  input power_vdd,ground_gnd;
  inout A;
  input E;
  inout B;
parameter ron = 0.1 ;
parameter roff = 1e+12 ;

tranif1 TRAN(A,B,E);
endmodule

module resistor_ams (A, B);
  inout A;
  inout B;
parameter r = 1 ;
tran TRAN (B,A); 
endmodule

// cell primitive section --- END ---
// --------------------------------------------------------------------





