mdp

//// IEEE 9-bus system protection model
//// Built by EXTENDING the 3-bus template in "System Model.pm".
//// Relay / Signal_Disp / Channel / comm_B / Sup_SV modules are the SAME
//// templates as the 3-bus model, instantiated 12x via PRISM module renaming.
//// New logic (topology-driven, see notes in the accompanying summary):
////   - Fault module: 6 fault points, 1/6 branching
////   - Two-sided clearance/failure: each fault FCx has TWO primary/backup
////     pairs (one per line end); a fault CLEARS only when BOTH sides isolate,
////     and FAILS if EITHER side fails  -> Lx_Isol (AND) and Lx_Fail (OR)
////   - Central_Unit: tracks supervisory need SEPARATELY per side (12 P-flags),
////     with side-A-only / side-B-only / both-sides transitions per fault
////
//// PAIRING TABLE (primary -> backup, channel):
////   FC1: R1->R11 (c111) , R2->R4  (c24)
////   FC2: R3->R1  (c31)  , R4->R6  (c46)
////   FC3: R5->R3  (c53)  , R6->R8  (c68)
////   FC4: R7->R5  (c75)  , R8->R10 (c810)
////   FC5: R9->R7  (c97)  , R10->R12(c1012)
////   FC6: R11->R9 (c119) , R12->R2 (c122)
//// Each Ri is primary for one fault and backup for a different fault.


// ---- PROBABILITIES (per-relay, as in the 3-bus model; supply via -const) ----
const double COM;      // Communication failure (shared)

const double IED;      const double WD;      // R1
const double IEDR2;    const double WDR2;    // R2
const double IEDR3;    const double WDR3;    // R3
const double IEDR4;    const double WDR4;    // R4
const double IEDR5;    const double WDR5;    // R5
const double IEDR6;    const double WDR6;    // R6
const double IEDR7;    const double WDR7;    // R7
const double IEDR8;    const double WDR8;    // R8
const double IEDR9;    const double WDR9;    // R9
const double IEDR10;   const double WDR10;   // R10
const double IEDR11;   const double WDR11;   // R11
const double IEDR12;   const double WDR12;   // R12

const int Safe_state   = 4;  // Fault cleared successfully
const int Unsafe_state = 5;  // Fault persists in system


//////////////////////////// Formulas //////////////////////////////////////

// ---- Supervisory-activation conditions (2 per backup relay, as 3-bus) ----
// sup_Ri_cond1 : backup Ri in lockout (Ri=3), its primary failed, request sent
//                but the request channel is down
// sup_Ri_cond2 : backup Ri itself failed (Ri=2), primary already failed
    formula sup_R1_cond1  = FC2=1 & (R3=2|cb3=2)   & Request3=true  & c31=2  & R1=3;
    formula sup_R1_cond2  = FC2=1 & (R3=2|cb3=2)   & (R1=2);
    formula sup_R2_cond1  = FC6=1 & (R12=2|cb12=2) & Request12=true & c122=2 & R2=3;
    formula sup_R2_cond2  = FC6=1 & (R12=2|cb12=2) & (R2=2);
    formula sup_R3_cond1  = FC3=1 & (R5=2|cb5=2)   & Request5=true  & c53=2  & R3=3;
    formula sup_R3_cond2  = FC3=1 & (R5=2|cb5=2)   & (R3=2);
    formula sup_R4_cond1  = FC1=1 & (R2=2|cb2=2)   & Request2=true  & c24=2  & R4=3;
    formula sup_R4_cond2  = FC1=1 & (R2=2|cb2=2)   & (R4=2);
    formula sup_R5_cond1  = FC4=1 & (R7=2|cb7=2)   & Request7=true  & c75=2  & R5=3;
    formula sup_R5_cond2  = FC4=1 & (R7=2|cb7=2)   & (R5=2);
    formula sup_R6_cond1  = FC2=1 & (R4=2|cb4=2)   & Request4=true  & c46=2  & R6=3;
    formula sup_R6_cond2  = FC2=1 & (R4=2|cb4=2)   & (R6=2);
    formula sup_R7_cond1  = FC5=1 & (R9=2|cb9=2)   & Request9=true  & c97=2  & R7=3;
    formula sup_R7_cond2  = FC5=1 & (R9=2|cb9=2)   & (R7=2);
    formula sup_R8_cond1  = FC3=1 & (R6=2|cb6=2)   & Request6=true  & c68=2  & R8=3;
    formula sup_R8_cond2  = FC3=1 & (R6=2|cb6=2)   & (R8=2);
    formula sup_R9_cond1  = FC6=1 & (R11=2|cb11=2) & Request11=true & c119=2 & R9=3;
    formula sup_R9_cond2  = FC6=1 & (R11=2|cb11=2) & (R9=2);
    formula sup_R10_cond1 = FC4=1 & (R8=2|cb8=2)   & Request8=true  & c810=2 & R10=3;
    formula sup_R10_cond2 = FC4=1 & (R8=2|cb8=2)   & (R10=2);
    formula sup_R11_cond1 = FC1=1 & (R1=2|cb1=2)   & Request1=true  & c111=2 & R11=3;
    formula sup_R11_cond2 = FC1=1 & (R1=2|cb1=2)   & (R11=2);
    formula sup_R12_cond1 = FC5=1 & (R10=2|cb10=2) & Request10=true & c1012=2 & R12=3;
    formula sup_R12_cond2 = FC5=1 & (R10=2|cb10=2) & (R12=2);

// ---- Operate-backup conditions (CU directly commands an active backup to
//      trip when its request channel is down) : one per backup relay ----
    formula opr_R1_bkp   = FC2=1 & (R1=4|R1=5|R1=6)    & Request3=true  & c31=2;
    formula opr_R2_bkp   = FC6=1 & (R2=4|R2=5|R2=6)    & Request12=true & c122=2;
    formula opr_R3_bkp   = FC3=1 & (R3=4|R3=5|R3=6)    & Request5=true  & c53=2;
    formula opr_R4_bkp   = FC1=1 & (R4=4|R4=5|R4=6)    & Request2=true  & c24=2;
    formula opr_R5_bkp   = FC4=1 & (R5=4|R5=5|R5=6)    & Request7=true  & c75=2;
    formula opr_R6_bkp   = FC2=1 & (R6=4|R6=5|R6=6)    & Request4=true  & c46=2;
    formula opr_R7_bkp   = FC5=1 & (R7=4|R7=5|R7=6)    & Request9=true  & c97=2;
    formula opr_R8_bkp   = FC3=1 & (R8=4|R8=5|R8=6)    & Request6=true  & c68=2;
    formula opr_R9_bkp   = FC6=1 & (R9=4|R9=5|R9=6)    & Request11=true & c119=2;
    formula opr_R10_bkp  = FC4=1 & (R10=4|R10=5|R10=6) & Request8=true  & c810=2;
    formula opr_R11_bkp  = FC1=1 & (R11=4|R11=5|R11=6) & Request1=true  & c111=2;
    formula opr_R12_bkp  = FC5=1 & (R12=4|R12=5|R12=6) & Request10=true & c1012=2;

// ---- Standby conditions (CU tells an active backup to wait for a request) ----
    formula standby_R1   = FC2=1 & R1=5  & R3=1  & Lock3=true  & c31=2  & t3=1  & Request3=false;
    formula standby_R2   = FC6=1 & R2=5  & R12=1 & Lock12=true & c122=2 & t12=1 & Request12=false;
    formula standby_R3   = FC3=1 & R3=5  & R5=1  & Lock5=true  & c53=2  & t5=1  & Request5=false;
    formula standby_R4   = FC1=1 & R4=5  & R2=1  & Lock2=true  & c24=2  & t2=1  & Request2=false;
    formula standby_R5   = FC4=1 & R5=5  & R7=1  & Lock7=true  & c75=2  & t7=1  & Request7=false;
    formula standby_R6   = FC2=1 & R6=5  & R4=1  & Lock4=true  & c46=2  & t4=1  & Request4=false;
    formula standby_R7   = FC5=1 & R7=5  & R9=1  & Lock9=true  & c97=2  & t9=1  & Request9=false;
    formula standby_R8   = FC3=1 & R8=5  & R6=1  & Lock6=true  & c68=2  & t6=1  & Request6=false;
    formula standby_R9   = FC6=1 & R9=5  & R11=1 & Lock11=true & c119=2 & t11=1 & Request11=false;
    formula standby_R10  = FC4=1 & R10=5 & R8=1  & Lock8=true  & c810=2 & t8=1  & Request8=false;
    formula standby_R11  = FC1=1 & R11=5 & R1=1  & Lock1=true  & c111=2 & t1=1  & Request1=false;
    formula standby_R12  = FC5=1 & R12=5 & R10=1 & Lock10=true & c1012=2 & t10=1 & Request10=false;

// ---- Two-sided ISOLATION: fault clears only when BOTH line ends isolate ----
    formula L1_Isol = FC1=1 & (((Break1=true & cb1=1) | (Break11=true & cb11=1))
                           &  ((Break2=true & cb2=1) | (Break4=true & cb4=1))
                           &  (!(sv11=0 & cb11=2) & !(sv4=0 & cb4=2)));
    formula L2_Isol = FC2=1 & (((Break3=true & cb3=1) | (Break1=true & cb1=1))
                           &  ((Break4=true & cb4=1) | (Break6=true & cb6=1))
                           &  (!(sv1=0 & cb1=2) & !(sv6=0 & cb6=2)));
    formula L3_Isol = FC3=1 & (((Break5=true & cb5=1) | (Break3=true & cb3=1))
                           &  ((Break6=true & cb6=1) | (Break8=true & cb8=1))
                           &  (!(sv3=0 & cb3=2) & !(sv8=0 & cb8=2)));
    formula L4_Isol = FC4=1 & (((Break7=true & cb7=1) | (Break5=true & cb5=1))
                           &  ((Break8=true & cb8=1) | (Break10=true & cb10=1))
                           &  (!(sv5=0 & cb5=2) & !(sv10=0 & cb10=2)));
    formula L5_Isol = FC5=1 & (((Break9=true & cb9=1) | (Break7=true & cb7=1))
                           &  ((Break10=true & cb10=1) | (Break12=true & cb12=1))
                           &  (!(sv7=0 & cb7=2) & !(sv12=0 & cb12=2)));
    formula L6_Isol = FC6=1 & (((Break11=true & cb11=1) | (Break9=true & cb9=1))
                           &  ((Break12=true & cb12=1) | (Break2=true & cb2=1))
                           &  (!(sv9=0 & cb9=2) & !(sv2=0 & cb2=2)));

// ---- Two-sided FAILURE (BROADENED)

    formula L1_Fail = (FC1=1) & ((cb11=2) | (cb4=2));
    formula L2_Fail = (FC2=1) & ((cb1=2)  | (cb6=2));
    formula L3_Fail = (FC3=1) & ((cb3=2)  | (cb8=2));
    formula L4_Fail = (FC4=1) & ((cb5=2)  | (cb10=2));
    formula L5_Fail = (FC5=1) & ((cb7=2)  | (cb12=2));
    formula L6_Fail = (FC6=1) & ((cb9=2)  | (cb2=2));


//////////////////////////// Fault module //////////////////////////////////
module Fault
	FC1:[0..2];
	FC2:[0..2];
	FC3:[0..2];
	FC4:[0..2];
	FC5:[0..2];
	FC6:[0..2];
	//0: No fault   //1: Fault active   //2: Fault cleared

	[Int_err] (FC1=0)&(FC2=0)&(FC3=0)&(FC4=0)&(FC5=0)&(FC6=0)
	          -> 1/6:(FC1'=1) + 1/6:(FC2'=1) + 1/6:(FC3'=1)
	           + 1/6:(FC4'=1) + 1/6:(FC5'=1) + 1/6:(FC6'=1);

	[FC1_clrd] FC1=1 -> (FC1'=2);
	[FC2_clrd] FC2=1 -> (FC2'=2);
	[FC3_clrd] FC3=1 -> (FC3'=2);
	[FC4_clrd] FC4=1 -> (FC4'=2);
	[FC5_clrd] FC5=1 -> (FC5'=2);
	[FC6_clrd] FC6=1 -> (FC6'=2);
endmodule


//////////////////////////// Relay modules /////////////////////////////////
//// Same state machine as the 3-bus Relay_R1 template:
////   R = 0:Idle 1:Trip 2:Fail 3:Lockout 4:Reset 5:Operation 6:Standby
//// TOPOLOGY-DRIVEN CHANGE (flagged): the WD draw + activation is GATED on the
//// relay being involved in the active fault (its own primary fault FC1 or the
//// fault it backs up FC2), and is NOT globally synchronized on [Int_err].
//// In the 3-bus model all relays drew WD in lock-step with the fault pick;
//// syncing 12 WD draws with a 1/6 fault pick is intractable, so each relay
//// draws its own WD only when its fault is present (same effect, far smaller
//// state space). All other relay logic is byte-for-byte the 3-bus template.
//// For Relay_R1: own backup = R11 ; backed-up primary = R3 (fault FC2),
////               R3's channel = c31 (timer t3), R3's breaker = cb3.

module Relay_R1
	R1:[0..6];
	WD1:[0..2];   // 0:idle 1:Error 2:No-Error

	// gated WD draw (replaces the 3-bus synchronized [Int_err] draw)
	[] (WD1=0) & (FC1=1|FC2=1) -> 1-WD:(WD1'=2) + WD:(WD1'=1);

	[r1] (R1=0) & (WD1=2) -> (R1'=5);
	[Trp_prm1] R1=5 & FC1=1 & R11>0 -> 1-IED:(R1'=1)+IED:(R1'=2);   // R11 = own backup
	[r1] (R1=0|R1=5) & (WD1=1) -> (R1'=2);

	// R1 as backup for R3 at FC2
	[Lock_r1]  R1=5 & Lock3=true & c31=1 & FC2=1 & t3=1 -> (R1'=3);
	[Reset_r1] (R1=3) & Reset3=true & c31=1 & FC2=1 & t3=2 -> (R1'=4);
	[r1] R1=5 & FC2=1 & Lock3=true & c31=2 & CU=3 -> (R1'=6);
	[Trp_bkp1] (R1=4) & Request3=true & c31=1 & FC2=1 & WD3=2 & R3=2 & (t3=2) -> 1-IED:(R1'=1)+IED:(R1'=2);
	[Trp_bkp1] (R1=4) & Request3=true & c31=1 & FC2=1 & cb3=2 & R3=1 & (t3=3) -> 1-IED:(R1'=1)+IED:(R1'=2);
	[Trp_bkp1] (R1=5) & Request3=true & c31=1 & FC2=1 & WD3=1 & R3=2 & (t3=4) -> 1-IED:(R1'=1)+IED:(R1'=2);
	[Trp_bkp1] (CU=2) & FC2=1 & (R1=4|R1=5|R1=6) & Request3=true & c31=2 -> 1-IED:(R1'=1)+IED:(R1'=2);
endmodule

module Relay_R2 = Relay_R1[ R1=R2, WD1=WD2, R11=R4, FC2=FC6, R3=R12, WD3=WD12, cb3=cb12,
	c31=c122, t3=t12, Lock3=Lock12, Reset3=Reset12, Request3=Request12, IED=IEDR2, WD=WDR2,
	r1=r2, Trp_prm1=Trp_prm2, Trp_bkp1=Trp_bkp2, Lock_r1=Lock_r2, Reset_r1=Reset_r2 ] endmodule

module Relay_R3 = Relay_R1[ R1=R3, WD1=WD3, R11=R1, FC1=FC2, FC2=FC3, R3=R5, WD3=WD5, cb3=cb5,
	c31=c53, t3=t5, Lock3=Lock5, Reset3=Reset5, Request3=Request5, IED=IEDR3, WD=WDR3,
	r1=r3, Trp_prm1=Trp_prm3, Trp_bkp1=Trp_bkp3, Lock_r1=Lock_r3, Reset_r1=Reset_r3 ] endmodule

module Relay_R4 = Relay_R1[ R1=R4, WD1=WD4, R11=R6, FC1=FC2, FC2=FC1, R3=R2, WD3=WD2, cb3=cb2,
	c31=c24, t3=t2, Lock3=Lock2, Reset3=Reset2, Request3=Request2, IED=IEDR4, WD=WDR4,
	r1=r4, Trp_prm1=Trp_prm4, Trp_bkp1=Trp_bkp4, Lock_r1=Lock_r4, Reset_r1=Reset_r4 ] endmodule

module Relay_R5 = Relay_R1[ R1=R5, WD1=WD5, R11=R3, FC1=FC3, FC2=FC4, R3=R7, WD3=WD7, cb3=cb7,
	c31=c75, t3=t7, Lock3=Lock7, Reset3=Reset7, Request3=Request7, IED=IEDR5, WD=WDR5,
	r1=r5, Trp_prm1=Trp_prm5, Trp_bkp1=Trp_bkp5, Lock_r1=Lock_r5, Reset_r1=Reset_r5 ] endmodule

module Relay_R6 = Relay_R1[ R1=R6, WD1=WD6, R11=R8, FC1=FC3, R3=R4, WD3=WD4, cb3=cb4,
	c31=c46, t3=t4, Lock3=Lock4, Reset3=Reset4, Request3=Request4, IED=IEDR6, WD=WDR6,
	r1=r6, Trp_prm1=Trp_prm6, Trp_bkp1=Trp_bkp6, Lock_r1=Lock_r6, Reset_r1=Reset_r6 ] endmodule

module Relay_R7 = Relay_R1[ R1=R7, WD1=WD7, R11=R5, FC1=FC4, FC2=FC5, R3=R9, WD3=WD9, cb3=cb9,
	c31=c97, t3=t9, Lock3=Lock9, Reset3=Reset9, Request3=Request9, IED=IEDR7, WD=WDR7,
	r1=r7, Trp_prm1=Trp_prm7, Trp_bkp1=Trp_bkp7, Lock_r1=Lock_r7, Reset_r1=Reset_r7 ] endmodule

module Relay_R8 = Relay_R1[ R1=R8, WD1=WD8, R11=R10, FC1=FC4, FC2=FC3, R3=R6, WD3=WD6, cb3=cb6,
	c31=c68, t3=t6, Lock3=Lock6, Reset3=Reset6, Request3=Request6, IED=IEDR8, WD=WDR8,
	r1=r8, Trp_prm1=Trp_prm8, Trp_bkp1=Trp_bkp8, Lock_r1=Lock_r8, Reset_r1=Reset_r8 ] endmodule

module Relay_R9 = Relay_R1[ R1=R9, WD1=WD9, R11=R7, FC1=FC5, FC2=FC6, R3=R11, WD3=WD11, cb3=cb11,
	c31=c119, t3=t11, Lock3=Lock11, Reset3=Reset11, Request3=Request11, IED=IEDR9, WD=WDR9,
	r1=r9, Trp_prm1=Trp_prm9, Trp_bkp1=Trp_bkp9, Lock_r1=Lock_r9, Reset_r1=Reset_r9 ] endmodule

module Relay_R10 = Relay_R1[ R1=R10, WD1=WD10, R11=R12, FC1=FC5, FC2=FC4, R3=R8, WD3=WD8, cb3=cb8,
	c31=c810, t3=t8, Lock3=Lock8, Reset3=Reset8, Request3=Request8, IED=IEDR10, WD=WDR10,
	r1=r10, Trp_prm1=Trp_prm10, Trp_bkp1=Trp_bkp10, Lock_r1=Lock_r10, Reset_r1=Reset_r10 ] endmodule

module Relay_R11 = Relay_R1[ R1=R11, WD1=WD11, R11=R9, FC1=FC6, FC2=FC1, R3=R1, WD3=WD1, cb3=cb1,
	c31=c111, t3=t1, Lock3=Lock1, Reset3=Reset1, Request3=Request1, IED=IEDR11, WD=WDR11,
	r1=r11, Trp_prm1=Trp_prm11, Trp_bkp1=Trp_bkp11, Lock_r1=Lock_r11, Reset_r1=Reset_r11 ] endmodule

module Relay_R12 = Relay_R1[ R1=R12, WD1=WD12, R11=R2, FC1=FC6, FC2=FC5, R3=R10, WD3=WD10, cb3=cb10,
	c31=c1012, t3=t10, Lock3=Lock10, Reset3=Reset10, Request3=Request10, IED=IEDR12, WD=WDR12,
	r1=r12, Trp_prm1=Trp_prm12, Trp_bkp1=Trp_bkp12, Lock_r1=Lock_r12, Reset_r1=Reset_r12 ] endmodule


//////////////////////////// Signal-dispatch modules ///////////////////////
//// Identical to the 3-bus Signal_Disp_R1 template, instantiated 12x.
//// For Ri: FC1 = own primary fault, FC2 = fault it backs up.

module Signal_Disp_R1
	Lock1:bool init false;
	Reset1:bool init false;
	Request1:bool init false;
	Break1:bool init false;

	[Trp_prm1] Lock1=false & FC1=1 -> (Lock1'=true);
	[Trp_bkp1] (R1=4|R1=5|R1=6) & FC2=1 -> (Lock1'=true);
	[Sig1] Reset1=false & Break1=false & (FC1=1|FC2=1) & R1=1 -> (Reset1'=true)&(Break1'=true);
	[Sig1] Request1=false & Reset1=false & (FC1=1|FC2=1) & R1=2 & WD1=1 -> (Request1'=true);
	[Sig1] Request1=false & Reset1=false & (FC1=1|FC2=1) & R1=2 & WD1=2 -> (Request1'=true)&(Reset1'=true);
	[Sig1] Request1=false & cb1=2 & (FC1=1|FC2=1) & R1=1 -> (Request1'=true);
	[Sup1] sv1=1 & (Break1=false) -> (Break1'=true);
endmodule

module Signal_Disp_R2 = Signal_Disp_R1[ Lock1=Lock2, Reset1=Reset2, Request1=Request2, Break1=Break2,
	FC2=FC6, R1=R2, WD1=WD2, cb1=cb2, sv1=sv2, Sig1=Sig2, Trp_prm1=Trp_prm2, Trp_bkp1=Trp_bkp2, Sup1=Sup2 ] endmodule
module Signal_Disp_R3 = Signal_Disp_R1[ Lock1=Lock3, Reset1=Reset3, Request1=Request3, Break1=Break3,
	FC1=FC2, FC2=FC3, R1=R3, WD1=WD3, cb1=cb3, sv1=sv3, Sig1=Sig3, Trp_prm1=Trp_prm3, Trp_bkp1=Trp_bkp3, Sup1=Sup3 ] endmodule
module Signal_Disp_R4 = Signal_Disp_R1[ Lock1=Lock4, Reset1=Reset4, Request1=Request4, Break1=Break4,
	FC1=FC2, FC2=FC1, R1=R4, WD1=WD4, cb1=cb4, sv1=sv4, Sig1=Sig4, Trp_prm1=Trp_prm4, Trp_bkp1=Trp_bkp4, Sup1=Sup4 ] endmodule
module Signal_Disp_R5 = Signal_Disp_R1[ Lock1=Lock5, Reset1=Reset5, Request1=Request5, Break1=Break5,
	FC1=FC3, FC2=FC4, R1=R5, WD1=WD5, cb1=cb5, sv1=sv5, Sig1=Sig5, Trp_prm1=Trp_prm5, Trp_bkp1=Trp_bkp5, Sup1=Sup5 ] endmodule
module Signal_Disp_R6 = Signal_Disp_R1[ Lock1=Lock6, Reset1=Reset6, Request1=Request6, Break1=Break6,
	FC1=FC3, R1=R6, WD1=WD6, cb1=cb6, sv1=sv6, Sig1=Sig6, Trp_prm1=Trp_prm6, Trp_bkp1=Trp_bkp6, Sup1=Sup6 ] endmodule
module Signal_Disp_R7 = Signal_Disp_R1[ Lock1=Lock7, Reset1=Reset7, Request1=Request7, Break1=Break7,
	FC1=FC4, FC2=FC5, R1=R7, WD1=WD7, cb1=cb7, sv1=sv7, Sig1=Sig7, Trp_prm1=Trp_prm7, Trp_bkp1=Trp_bkp7, Sup1=Sup7 ] endmodule
module Signal_Disp_R8 = Signal_Disp_R1[ Lock1=Lock8, Reset1=Reset8, Request1=Request8, Break1=Break8,
	FC1=FC4, FC2=FC3, R1=R8, WD1=WD8, cb1=cb8, sv1=sv8, Sig1=Sig8, Trp_prm1=Trp_prm8, Trp_bkp1=Trp_bkp8, Sup1=Sup8 ] endmodule
module Signal_Disp_R9 = Signal_Disp_R1[ Lock1=Lock9, Reset1=Reset9, Request1=Request9, Break1=Break9,
	FC1=FC5, FC2=FC6, R1=R9, WD1=WD9, cb1=cb9, sv1=sv9, Sig1=Sig9, Trp_prm1=Trp_prm9, Trp_bkp1=Trp_bkp9, Sup1=Sup9 ] endmodule
module Signal_Disp_R10 = Signal_Disp_R1[ Lock1=Lock10, Reset1=Reset10, Request1=Request10, Break1=Break10,
	FC1=FC5, FC2=FC4, R1=R10, WD1=WD10, cb1=cb10, sv1=sv10, Sig1=Sig10, Trp_prm1=Trp_prm10, Trp_bkp1=Trp_bkp10, Sup1=Sup10 ] endmodule
module Signal_Disp_R11 = Signal_Disp_R1[ Lock1=Lock11, Reset1=Reset11, Request1=Request11, Break1=Break11,
	FC1=FC6, FC2=FC1, R1=R11, WD1=WD11, cb1=cb11, sv1=sv11, Sig1=Sig11, Trp_prm1=Trp_prm11, Trp_bkp1=Trp_bkp11, Sup1=Sup11 ] endmodule
module Signal_Disp_R12 = Signal_Disp_R1[ Lock1=Lock12, Reset1=Reset12, Request1=Request12, Break1=Break12,
	FC1=FC6, FC2=FC5, R1=R12, WD1=WD12, cb1=cb12, sv1=sv12, Sig1=Sig12, Trp_prm1=Trp_prm12, Trp_bkp1=Trp_bkp12, Sup1=Sup12 ] endmodule


//////////////////////////// Relay-relay channels //////////////////////////
//// Same template as the 3-bus comm1_R1 channel, instantiated once per
//// primary/backup pair. Channel_RaRb: c = channel var, t = phase counter,
//// Ra = primary, Rb = backup on that channel. Internal commands are left
//// unlabeled (they synchronize with nothing, exactly as in the 3-bus model).

module Channel_R1R11
	c111:[0..2] init 0;
	t1:[0..4] init 0;

	[] c111=0 & t1=0 & Lock1=true -> 1-COM:(c111'=1)&(t1'=1)+COM:(c111'=2)&(t1'=1);
	[] c111=1 & R1=1 & R11=3 & Reset1=true & t1=1 -> 1-COM:(c111'=1)&(t1'=t1+1)+COM:(c111'=2)&(t1'=t1+1);
	[] c111=0 & R1=2 & WD1=1 & Request1=true & t1=0 -> 1-COM:(c111'=1)&(t1'=4)+COM:(c111'=2)&(t1'=4);
	[] c111=1 & R1=2 & WD1=2 & R11=3 & (Reset1=true|Request1=true) & t1=1 -> 1-COM:(c111'=1)&(t1'=t1+1)+COM:(c111'=2)&(t1'=t1+1);
	[] c111=1 & R1=1 & R11=4 & cb1=2 & Request1=true & t1=2 -> 1-COM:(c111'=1)&(t1'=t1+1)+COM:(c111'=2)&(t1'=t1+1);
endmodule

module Channel_R2R4  = Channel_R1R11[ c111=c24,   t1=t2,  R1=R2,  R11=R4,  WD1=WD2,  cb1=cb2,  Lock1=Lock2,  Reset1=Reset2,  Request1=Request2 ] endmodule
module Channel_R3R1  = Channel_R1R11[ c111=c31,   t1=t3,  R1=R3,  R11=R1,  WD1=WD3,  cb1=cb3,  Lock1=Lock3,  Reset1=Reset3,  Request1=Request3 ] endmodule
module Channel_R4R6  = Channel_R1R11[ c111=c46,   t1=t4,  R1=R4,  R11=R6,  WD1=WD4,  cb1=cb4,  Lock1=Lock4,  Reset1=Reset4,  Request1=Request4 ] endmodule
module Channel_R5R3  = Channel_R1R11[ c111=c53,   t1=t5,  R1=R5,  R11=R3,  WD1=WD5,  cb1=cb5,  Lock1=Lock5,  Reset1=Reset5,  Request1=Request5 ] endmodule
module Channel_R6R8  = Channel_R1R11[ c111=c68,   t1=t6,  R1=R6,  R11=R8,  WD1=WD6,  cb1=cb6,  Lock1=Lock6,  Reset1=Reset6,  Request1=Request6 ] endmodule
module Channel_R7R5  = Channel_R1R11[ c111=c75,   t1=t7,  R1=R7,  R11=R5,  WD1=WD7,  cb1=cb7,  Lock1=Lock7,  Reset1=Reset7,  Request1=Request7 ] endmodule
module Channel_R8R10 = Channel_R1R11[ c111=c810,  t1=t8,  R1=R8,  R11=R10, WD1=WD8,  cb1=cb8,  Lock1=Lock8,  Reset1=Reset8,  Request1=Request8 ] endmodule
module Channel_R9R7  = Channel_R1R11[ c111=c97,   t1=t9,  R1=R9,  R11=R7,  WD1=WD9,  cb1=cb9,  Lock1=Lock9,  Reset1=Reset9,  Request1=Request9 ] endmodule
module Channel_R10R12= Channel_R1R11[ c111=c1012, t1=t10, R1=R10, R11=R12, WD1=WD10, cb1=cb10, Lock1=Lock10, Reset1=Reset10, Request1=Request10 ] endmodule
module Channel_R11R9 = Channel_R1R11[ c111=c119,  t1=t11, R1=R11, R11=R9,  WD1=WD11, cb1=cb11, Lock1=Lock11, Reset1=Reset11, Request1=Request11 ] endmodule
module Channel_R12R2 = Channel_R1R11[ c111=c122,  t1=t12, R1=R12, R11=R2,  WD1=WD12, cb1=cb12, Lock1=Lock12, Reset1=Reset12, Request1=Request12 ] endmodule


//////////////////////////// Breaker channels //////////////////////////////
//// Same template as the 3-bus comm_B1, instantiated once per breaker.

module comm_B1
	cb1:[0..2] init 0;
	[Com_b1] cb1=0 & Break1=true -> 1-COM:(cb1'=1)+COM:(cb1'=2);
	[Sup1]   cb1=0 -> 1-COM:(cb1'=1)+COM:(cb1'=2);
endmodule

module comm_B2  = comm_B1[ cb1=cb2,  Break1=Break2,  Com_b1=Com_b2,  Sup1=Sup2 ]  endmodule
module comm_B3  = comm_B1[ cb1=cb3,  Break1=Break3,  Com_b1=Com_b3,  Sup1=Sup3 ]  endmodule
module comm_B4  = comm_B1[ cb1=cb4,  Break1=Break4,  Com_b1=Com_b4,  Sup1=Sup4 ]  endmodule
module comm_B5  = comm_B1[ cb1=cb5,  Break1=Break5,  Com_b1=Com_b5,  Sup1=Sup5 ]  endmodule
module comm_B6  = comm_B1[ cb1=cb6,  Break1=Break6,  Com_b1=Com_b6,  Sup1=Sup6 ]  endmodule
module comm_B7  = comm_B1[ cb1=cb7,  Break1=Break7,  Com_b1=Com_b7,  Sup1=Sup7 ]  endmodule
module comm_B8  = comm_B1[ cb1=cb8,  Break1=Break8,  Com_b1=Com_b8,  Sup1=Sup8 ]  endmodule
module comm_B9  = comm_B1[ cb1=cb9,  Break1=Break9,  Com_b1=Com_b9,  Sup1=Sup9 ]  endmodule
module comm_B10 = comm_B1[ cb1=cb10, Break1=Break10, Com_b1=Com_b10, Sup1=Sup10 ] endmodule
module comm_B11 = comm_B1[ cb1=cb11, Break1=Break11, Com_b1=Com_b11, Sup1=Sup11 ] endmodule
module comm_B12 = comm_B1[ cb1=cb12, Break1=Break12, Com_b1=Com_b12, Sup1=Sup12 ] endmodule


//////////////////////////// Supervisory services //////////////////////////
//// Same template as the 3-bus Sup_SV1. Each backup relay's supervisory
//// listens on its own CU label AND on the combined "both-sides" label of the
//// fault it protects (so both sides can be activated in a single CU step).

module Sup_SV1
	sv1:[0..1];   // 0:idle 1:activated
	[CU1]    sv1=0 -> (sv1'=1);
	[CU1CU6] sv1=0 -> (sv1'=1);
endmodule

module Sup_SV2  = Sup_SV1[ sv1=sv2,  CU1=CU2,  CU1CU6=CU2CU9 ]  endmodule
module Sup_SV3  = Sup_SV1[ sv1=sv3,  CU1=CU3,  CU1CU6=CU3CU8 ]  endmodule
module Sup_SV4  = Sup_SV1[ sv1=sv4,  CU1=CU4,  CU1CU6=CU4CU11 ] endmodule
module Sup_SV5  = Sup_SV1[ sv1=sv5,  CU1=CU5,  CU1CU6=CU5CU10 ] endmodule
module Sup_SV6  = Sup_SV1[ sv1=sv6,  CU1=CU6 ] endmodule
module Sup_SV7  = Sup_SV1[ sv1=sv7,  CU1=CU7,  CU1CU6=CU7CU12 ] endmodule
module Sup_SV8  = Sup_SV1[ sv1=sv8,  CU1=CU8,  CU1CU6=CU3CU8 ]  endmodule
module Sup_SV9  = Sup_SV1[ sv1=sv9,  CU1=CU9,  CU1CU6=CU2CU9 ]  endmodule
module Sup_SV10 = Sup_SV1[ sv1=sv10, CU1=CU10, CU1CU6=CU5CU10 ] endmodule
module Sup_SV11 = Sup_SV1[ sv1=sv11, CU1=CU11, CU1CU6=CU4CU11 ] endmodule
module Sup_SV12 = Sup_SV1[ sv1=sv12, CU1=CU12, CU1CU6=CU7CU12 ] endmodule


//////////////////////////// Central Unit //////////////////////////////////
//// CU state meaning kept from the 3-bus model:
////   0: idle              1: supervisory activated
////   2: commands backup to operate    3: commands backup to wait (standby)
////   4 (Safe_state):  fault cleared    5 (Unsafe_state): fault persists
////
//// EXTENSION for two sides: each fault FCx has two backups
//// (side A, side B). Twelve boolean flags P1..P12 record, per backup relay,
//// whether that side's supervisory need has already been registered, so the
//// CU can handle: only-A, only-B, both-simultaneous, both-sequential, none.
//// Per fault the supervisory block therefore has 5 transitions:
////   [CU_A]      A needs sup, B does not          (fires from CU 0/2/3 -> 1)
////   [CU_A]      A needs sup, B already registered (fires from CU 1     -> 1)
////   [CU_B]      B needs sup, A does not          (fires from CU 0/2/3 -> 1)
////   [CU_B]      B needs sup, A already registered (fires from CU 1     -> 1)
////   [CU_A_B]    both need sup simultaneously      (fires from CU 0/2/3 -> 1)
//// Sup activation is allowed from CU 0/2/3 (as in the 3-bus model) so a
//// transient opr/standby state on one side never blocks the other side's
//// supervisory. The 3-bus "both-sides" case did not exist; the reference
//// 9-bus model used a dedicated CU=4 for it -- here it is folded back into
//// CU=1 (supervisory activated) via the P-flags, so no new CU state is added.

module Control_Unit
	CU:[0..5] init 0;

	P1:bool init false;   P2:bool init false;   P3:bool init false;
	P4:bool init false;   P5:bool init false;   P6:bool init false;
	P7:bool init false;   P8:bool init false;   P9:bool init false;
	P10:bool init false;  P11:bool init false;  P12:bool init false;

	//////////////////// FC1 : side A = R11 (P11), side B = R4 (P4) ////////////////////
	[CU11]    (CU=0|CU=2|CU=3) & ((sup_R11_cond1|sup_R11_cond2)&P11=false) & (!(sup_R4_cond1|sup_R4_cond2)&P4=false)  -> (CU'=1)&(P11'=true);
	[CU11]    (CU=1|CU=2) & ((sup_R11_cond1|sup_R11_cond2)&P11=false) & P4=true  -> (CU'=1)&(P11'=true);
	[CU4]     (CU=0|CU=2|CU=3) & ((sup_R4_cond1|sup_R4_cond2)&P4=false) & (!(sup_R11_cond1|sup_R11_cond2)&P11=false)  -> (CU'=1)&(P4'=true);
	[CU4]     (CU=1|CU=2) & ((sup_R4_cond1|sup_R4_cond2)&P4=false) & P11=true   -> (CU'=1)&(P4'=true);
	[CU4CU11] (CU=0|CU=2|CU=3) & ((sup_R11_cond1|sup_R11_cond2)&P11=false) & ((sup_R4_cond1|sup_R4_cond2)&P4=false) -> (CU'=1)&(P11'=true)&(P4'=true);

	//////////////////// FC2 : side A = R1 (P1), side B = R6 (P6) ////////////////////
	[CU1]    (CU=0|CU=2|CU=3) & ((sup_R1_cond1|sup_R1_cond2)&P1=false) & (!(sup_R6_cond1|sup_R6_cond2)&P6=false)  -> (CU'=1)&(P1'=true);
	[CU1]    (CU=1|CU=2) & ((sup_R1_cond1|sup_R1_cond2)&P1=false) & P6=true  -> (CU'=1)&(P1'=true);
	[CU6]    (CU=0|CU=2|CU=3) & ((sup_R6_cond1|sup_R6_cond2)&P6=false) & (!(sup_R1_cond1|sup_R1_cond2)&P1=false)  -> (CU'=1)&(P6'=true);
	[CU6]    (CU=1|CU=2) & ((sup_R6_cond1|sup_R6_cond2)&P6=false) & P1=true  -> (CU'=1)&(P6'=true);
	[CU1CU6] (CU=0|CU=2|CU=3) & ((sup_R1_cond1|sup_R1_cond2)&P1=false) & ((sup_R6_cond1|sup_R6_cond2)&P6=false) -> (CU'=1)&(P1'=true)&(P6'=true);

	//////////////////// FC3 : side A = R3 (P3), side B = R8 (P8) ////////////////////
	[CU3]    (CU=0|CU=2|CU=3) & ((sup_R3_cond1|sup_R3_cond2)&P3=false) & (!(sup_R8_cond1|sup_R8_cond2)&P8=false)  -> (CU'=1)&(P3'=true);
	[CU3]    (CU=1|CU=2) & ((sup_R3_cond1|sup_R3_cond2)&P3=false) & P8=true  -> (CU'=1)&(P3'=true);
	[CU8]    (CU=0|CU=2|CU=3) & ((sup_R8_cond1|sup_R8_cond2)&P8=false) & (!(sup_R3_cond1|sup_R3_cond2)&P3=false)  -> (CU'=1)&(P8'=true);
	[CU8]    (CU=1|CU=2) & ((sup_R8_cond1|sup_R8_cond2)&P8=false) & P3=true  -> (CU'=1)&(P8'=true);
	[CU3CU8] (CU=0|CU=2|CU=3) & ((sup_R3_cond1|sup_R3_cond2)&P3=false) & ((sup_R8_cond1|sup_R8_cond2)&P8=false) -> (CU'=1)&(P3'=true)&(P8'=true);

	//////////////////// FC4 : side A = R5 (P5), side B = R10 (P10) ////////////////////
	[CU5]     (CU=0|CU=2|CU=3) & ((sup_R5_cond1|sup_R5_cond2)&P5=false) & (!(sup_R10_cond1|sup_R10_cond2)&P10=false)  -> (CU'=1)&(P5'=true);
	[CU5]     (CU=1|CU=2) & ((sup_R5_cond1|sup_R5_cond2)&P5=false) & P10=true  -> (CU'=1)&(P5'=true);
	[CU10]    (CU=0|CU=2|CU=3) & ((sup_R10_cond1|sup_R10_cond2)&P10=false) & (!(sup_R5_cond1|sup_R5_cond2)&P5=false)  -> (CU'=1)&(P10'=true);
	[CU10]    (CU=1|CU=2) & ((sup_R10_cond1|sup_R10_cond2)&P10=false) & P5=true  -> (CU'=1)&(P10'=true);
	[CU5CU10] (CU=0|CU=2|CU=3) & ((sup_R5_cond1|sup_R5_cond2)&P5=false) & ((sup_R10_cond1|sup_R10_cond2)&P10=false) -> (CU'=1)&(P5'=true)&(P10'=true);

	//////////////////// FC5 : side A = R7 (P7), side B = R12 (P12) ////////////////////
	[CU7]     (CU=0|CU=2|CU=3) & ((sup_R7_cond1|sup_R7_cond2)&P7=false) & (!(sup_R12_cond1|sup_R12_cond2)&P12=false)  -> (CU'=1)&(P7'=true);
	[CU7]     (CU=1|CU=2) & ((sup_R7_cond1|sup_R7_cond2)&P7=false) & P12=true  -> (CU'=1)&(P7'=true);
	[CU12]    (CU=0|CU=2|CU=3) & ((sup_R12_cond1|sup_R12_cond2)&P12=false) & (!(sup_R7_cond1|sup_R7_cond2)&P7=false)  -> (CU'=1)&(P12'=true);
	[CU12]    (CU=1|CU=2) & ((sup_R12_cond1|sup_R12_cond2)&P12=false) & P7=true  -> (CU'=1)&(P12'=true);
	[CU7CU12] (CU=0|CU=2|CU=3) & ((sup_R7_cond1|sup_R7_cond2)&P7=false) & ((sup_R12_cond1|sup_R12_cond2)&P12=false) -> (CU'=1)&(P7'=true)&(P12'=true);

	//////////////////// FC6 : side A = R9 (P9), side B = R2 (P2) ////////////////////
	[CU9]    (CU=0|CU=2|CU=3) & ((sup_R9_cond1|sup_R9_cond2)&P9=false) & (!(sup_R2_cond1|sup_R2_cond2)&P2=false)  -> (CU'=1)&(P9'=true);
	[CU9]    (CU=1|CU=2) & ((sup_R9_cond1|sup_R9_cond2)&P9=false) & P2=true  -> (CU'=1)&(P9'=true);
	[CU2]    (CU=0|CU=2|CU=3) & ((sup_R2_cond1|sup_R2_cond2)&P2=false) & (!(sup_R9_cond1|sup_R9_cond2)&P9=false)  -> (CU'=1)&(P2'=true);
	[CU2]    (CU=1|CU=2) & ((sup_R2_cond1|sup_R2_cond2)&P2=false) & P9=true  -> (CU'=1)&(P2'=true);
	[CU2CU9] (CU=0|CU=2|CU=3) & ((sup_R9_cond1|sup_R9_cond2)&P9=false) & ((sup_R2_cond1|sup_R2_cond2)&P2=false) -> (CU'=1)&(P9'=true)&(P2'=true);

	//////////////////// Operate-backup commands (one per backup relay) ////////////////////
	[opr1]  (CU=0|CU=1|CU=3) & opr_R1_bkp  -> (CU'=2);
	[opr2]  (CU=0|CU=1|CU=3) & opr_R2_bkp  -> (CU'=2);
	[opr3]  (CU=0|CU=1|CU=3) & opr_R3_bkp  -> (CU'=2);
	[opr4]  (CU=0|CU=1|CU=3) & opr_R4_bkp  -> (CU'=2);
	[opr5]  (CU=0|CU=1|CU=3) & opr_R5_bkp  -> (CU'=2);
	[opr6]  (CU=0|CU=1|CU=3) & opr_R6_bkp  -> (CU'=2);
	[opr7]  (CU=0|CU=1|CU=3) & opr_R7_bkp  -> (CU'=2);
	[opr8]  (CU=0|CU=1|CU=3) & opr_R8_bkp  -> (CU'=2);
	[opr9]  (CU=0|CU=1|CU=3) & opr_R9_bkp  -> (CU'=2);
	[opr10] (CU=0|CU=1|CU=3) & opr_R10_bkp -> (CU'=2);
	[opr11] (CU=0|CU=1|CU=3) & opr_R11_bkp -> (CU'=2);
	[opr12] (CU=0|CU=1|CU=3) & opr_R12_bkp -> (CU'=2);

	//////////////////// Standby commands (one per backup relay) ////////////////////
	[stndby1]  CU=0 & standby_R1  -> (CU'=3);
	[stndby2]  CU=0 & standby_R2  -> (CU'=3);
	[stndby3]  CU=0 & standby_R3  -> (CU'=3);
	[stndby4]  CU=0 & standby_R4  -> (CU'=3);
	[stndby5]  CU=0 & standby_R5  -> (CU'=3);
	[stndby6]  CU=0 & standby_R6  -> (CU'=3);
	[stndby7]  CU=0 & standby_R7  -> (CU'=3);
	[stndby8]  CU=0 & standby_R8  -> (CU'=3);
	[stndby9]  CU=0 & standby_R9  -> (CU'=3);
	[stndby10] CU=0 & standby_R10 -> (CU'=3);
	[stndby11] CU=0 & standby_R11 -> (CU'=3);
	[stndby12] CU=0 & standby_R12 -> (CU'=3);

	//////////////////// Terminal: two-sided clearance / failure ////////////////////
	[FC1_clrd] (CU=0|CU=1|CU=2|CU=3) & L1_Isol -> (CU'=Safe_state);
	[FC2_clrd] (CU=0|CU=1|CU=2|CU=3) & L2_Isol -> (CU'=Safe_state);
	[FC3_clrd] (CU=0|CU=1|CU=2|CU=3) & L3_Isol -> (CU'=Safe_state);
	[FC4_clrd] (CU=0|CU=1|CU=2|CU=3) & L4_Isol -> (CU'=Safe_state);
	[FC5_clrd] (CU=0|CU=1|CU=2|CU=3) & L5_Isol -> (CU'=Safe_state);
	[FC6_clrd] (CU=0|CU=1|CU=2|CU=3) & L6_Isol -> (CU'=Safe_state);

	[Fail_L1] (CU=0|CU=1|CU=2|CU=3) & L1_Fail -> (CU'=Unsafe_state);
	[Fail_L2] (CU=0|CU=1|CU=2|CU=3) & L2_Fail -> (CU'=Unsafe_state);
	[Fail_L3] (CU=0|CU=1|CU=2|CU=3) & L3_Fail -> (CU'=Unsafe_state);
	[Fail_L4] (CU=0|CU=1|CU=2|CU=3) & L4_Fail -> (CU'=Unsafe_state);
	[Fail_L5] (CU=0|CU=1|CU=2|CU=3) & L5_Fail -> (CU'=Unsafe_state);
	[Fail_L6] (CU=0|CU=1|CU=2|CU=3) & L6_Fail -> (CU'=Unsafe_state);
endmodule


//////////////////////////// Labels ////////////////////////////////////////
label "Fault" = (FC1=1|FC2=1|FC3=1|FC4=1|FC5=1|FC6=1);

label "L1_Isol" = L1_Isol;   label "L2_Isol" = L2_Isol;   label "L3_Isol" = L3_Isol;
label "L4_Isol" = L4_Isol;   label "L5_Isol" = L5_Isol;   label "L6_Isol" = L6_Isol;

label "L1_Fail" = L1_Fail;   label "L2_Fail" = L2_Fail;   label "L3_Fail" = L3_Fail;
label "L4_Fail" = L4_Fail;   label "L5_Fail" = L5_Fail;   label "L6_Fail" = L6_Fail;

// A fault is at risk if either backup breaker is down while its supervisory is active
label "L1_Risk" = FC1=1 & ((sv11=1 & cb11=2) | (sv4=1 & cb4=2));
label "L2_Risk" = FC2=1 & ((sv1=1 & cb1=2)   | (sv6=1 & cb6=2));
label "L3_Risk" = FC3=1 & ((sv3=1 & cb3=2)   | (sv8=1 & cb8=2));
label "L4_Risk" = FC4=1 & ((sv5=1 & cb5=2)   | (sv10=1 & cb10=2));
label "L5_Risk" = FC5=1 & ((sv7=1 & cb7=2)   | (sv12=1 & cb12=2));
label "L6_Risk" = FC6=1 & ((sv9=1 & cb9=2)   | (sv2=1 & cb2=2));

// Per-relay operation (relay involved in the active fault has reached Trip/Fail)
label "R1_operation"  = (FC1=1|FC2=1) & (WD1=2)  & (R1=1|R1=2);
label "R2_operation"  = (FC1=1|FC6=1) & (WD2=2)  & (R2=1|R2=2);
label "R3_operation"  = (FC2=1|FC3=1) & (WD3=2)  & (R3=1|R3=2);
label "R4_operation"  = (FC2=1|FC1=1) & (WD4=2)  & (R4=1|R4=2);
label "R5_operation"  = (FC3=1|FC4=1) & (WD5=2)  & (R5=1|R5=2);
label "R6_operation"  = (FC3=1|FC2=1) & (WD6=2)  & (R6=1|R6=2);
label "R7_operation"  = (FC4=1|FC5=1) & (WD7=2)  & (R7=1|R7=2);
label "R8_operation"  = (FC4=1|FC3=1) & (WD8=2)  & (R8=1|R8=2);
label "R9_operation"  = (FC5=1|FC6=1) & (WD9=2)  & (R9=1|R9=2);
label "R10_operation" = (FC5=1|FC4=1) & (WD10=2) & (R10=1|R10=2);
label "R11_operation" = (FC6=1|FC1=1) & (WD11=2) & (R11=1|R11=2);
label "R12_operation" = (FC6=1|FC5=1) & (WD12=2) & (R12=1|R12=2);


