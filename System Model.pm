mdp


//// states and transitions
//// st: 11557 tr: 30984 


/// For IEEE-3bus system with three DOCRs only
/// Three lines two gen and each line has one DOCR
/// Three fault points Primary and backup DOCRs
/// FC1: main: R1: R3 backup
/// FC2: main: R2: R1 backup
/// FC3: main: R3: R2 backup




// PROBABILITITES
const double IED;  // Relay failure
const double BRK;  // Circuit breaker failure
const double COM;      // Communication failure
const double WD;   // Internal error
const double WDR2;
const double IEDR2; 
const double WDR3;
const double IEDR3;  // Relay failure
const int Safe_state =4;  //Fault cleared successfully
const int Unsafe_state =5; //Fault persist in system



//////////////////////////// Formulas to be used //////////////////////////////////////

    formula sup_R1_cond1 =  FC2=1 & (R2=2|cb2=2) & Request2=true & c2=2 & R1=3;
    formula sup_R1_cond2 =  FC2=1 & (R2=2|cb2=2)& (R1=2);
    formula sup_R2_cond1 =  FC3=1 & (R3=2|cb3=2) & Request3=true & c3=2 & R2=3;
    formula sup_R2_cond2 =  FC3=1 & (R3=2|cb3=2)& (R2=2);
    formula sup_R3_cond1 =  FC1=1 & (R1=2|cb1=2) & Request1=true & c1=2 & R3=3;
    formula sup_R3_cond2 =  FC1=1 & (R1=2|cb1=2)& (R3=2);

    formula opr_R1_bkp   = FC2=1 & (R1=4|R1=5|R1=6) & Request2=true & c2=2;///Adding R1=5 new
    formula opr_R2_bkp   = FC3=1 & (R2=4|R2=5|R2=6) & Request3=true & c3=2; ///Adding R2=5 new
    formula opr_R3_bkp   = FC1=1 & (R3=4|R3=5|R3=6) & Request1=true & c1=2; ///Adding R3=5 new

   formula standby_R1 = FC2=1 & R1=5 & R2=1 & Lock2=true & c2=2 & t2=1& Request2=false; ///New commands
   formula standby_R2 = FC3=1 & R2=5 & R3=1 & Lock3=true & c3=2 & t3=1& Request3=false; ///New commands
   formula standby_R3 = FC1=1 & R3=5 & R1=1 & Lock1=true & c1=2 & t1=1& Request1=false; ///New commands
    
    formula fail_R1_cond1 = FC1=1 & sv3=1 & (CU=1|CU=2|CU=3)& cb3=2 ;
    formula fail_R1_cond2 = FC1=1 & (CU=0|CU=2|CU=3) & cb3=2 ;
    formula fail_R2_cond1 = FC2=1 & sv1=1 & (CU=1|CU=2|CU=3)  &  cb1=2;
    formula fail_R2_cond2 = FC2=1 & (CU=0|CU=2|CU=3)   & cb1=2;
    formula fail_R3_cond1 = FC3=1 & sv2=1 & (CU=1|CU=2|CU=3)& cb2=2;
    formula fail_R3_cond2 = FC3=1 &(CU=0|CU=2|CU=3) & cb2=2;
  
    formula FC1_clear_cond = (Break1=true & cb1=1)|(Break3=true&cb3=1); 
    formula FC2_clear_cond = (Break2=true & cb2=1)|(Break1=true&cb1=1);
    formula FC3_clear_cond = (Break3=true & cb3=1)|(Break2=true&cb2=1);
   

module Fault
	FC1:[0..2];
	FC2:[0..2];
        FC3:[0..2];
  	//0: No fault
 	//1: Fault 
        [Int_err]  (FC1=0)&(FC2=0)&(FC3=0)  -> 1/3:(FC1'=1)
                                             + 1/3:(FC2'=1)
                                             + 1/3:(FC3'=1);     
	[FC1_clrd] FC1=1   -> (FC1'=2); //synced with CU
        [FC2_clrd] FC2=1   -> (FC2'=2);
        [FC3_clrd] FC3=1   -> (FC3'=2);

endmodule


module Relay_R1

	R1:[0..6];
	// 0: Idle
	// 1: Trip      
        // 2: Fail     
	// 3: Lockout
	// 4: Reset
	// 5: Operation  
	// 6: standby state 
	 WD1:[0..2];  ///initial error or integration check of relay
  	//0: idle
 	//1: Error
	//2: No Error
         
        [Int_err] WD1=0  -> 1-WD:(WD1'=2)+ WD:(WD1'=1); //syncd R2
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
        [r1] (R1=0)&(WD1=2)  -> 1:(R1'=5);
        
	[Trp_prm1] R1=5 & FC1=1 & R3>0->  1-IED:(R1'=1)+IED:(R1'=2);//syncd with signal disp

        [r1] (R1=0|R1=5)& (WD1=1)  -> (R1'=2);  
	
        
//As Backup for R2 for FC2
	 [Lock_r1]  R1=5 & Lock2=true & c2=1 & FC2=1  & t2=1 ->  (R1'=3); 
	 [Reset_r1](R1=3)& Reset2=true & c2=1 & FC2=1 & t2=2 ->  (R1'=4);  
         [r1] R1=5 & FC2=1 & Lock2=true & c2=2 & CU=3   ->  (R1'=6); 
         [Trp_bkp1] (R1=4)& Request2=true  & c2=1 & FC2=1 & WD2=2 & R2=2 &(t2=2)   ->  1-IED:(R1'=1)+IED:(R1'=2); //syncd other modules
         [Trp_bkp1] (R1=4)& Request2 =true & c2=1 & FC2=1 & cb2=2 & R2=1 &(t2=3)  ->  1-IED:(R1'=1)+IED:(R1'=2); //syncd other modules
         [Trp_bkp1] (R1=5)& Request2=true  & c2=1 & FC2=1 & WD2=1 & R2=2 &(t2=4) ->  1-IED:(R1'=1)+IED:(R1'=2); //syncd other modules
         [Trp_bkp1] (CU=2)& FC2=1 & (R1=4|R1=5|R1=6) & Request2=true & c2=2 -> 1-IED:(R1'=1) + IED:(R1'=2); ///Adding R1=5 new
    
endmodule

module Relay_R2 = Relay_R1[R1=R2,R3=R1,R2=R3,WD1=WD2,WD2=WD3,Lock2=Lock3,t2=t3,Reset2=Reset3,WD=WDR2,IED=IEDR2,   
			 Request2=Request3,c2=c3, cb2=cb3, FC1=FC2,FC2=FC3,r1=r2,Trp_prm1=Trp_prm2
                        ,Trp_bkp1=Trp_bkp2,stndby1=stndby2, Lock_r1 =Lock_r2, Reset_r1=Reset_r2]
endmodule

module Relay_R3 = Relay_R1[R1=R3,R3=R2,R2=R1,WD1=WD3,WD2=WD1,Lock2=Lock1,t2=t1,Reset2=Reset1,WD=WDR3,IED=IEDR3, 
			 Request2=Request1,c2=c1, cb2=cb1, FC1=FC3,FC2=FC1,r1=r3,Trp_prm1=Trp_prm3
                        ,Trp_bkp1=Trp_bkp3,stndby1=stndby3, Lock_r1 =Lock_r3, Reset_r1=Reset_r3]
endmodule


module Signal_Disp_R1
        Lock1:bool init false;
        Reset1:bool init false;
        Request1:bool init false;
	Break1:bool init false;
	
	[Trp_prm1] Lock1=false & FC1=1 -> (Lock1'=true); 
        [Trp_bkp1] (R1=4|R1=5|R1=6) & FC2=1 -> (Lock1'=true); 

	//Reset and Brk sent once relay operated
	[Sig1] Reset1=false   & Break1=false & (FC1=1|FC2=1) & R1=1 -> (Reset1'=true)&(Break1'=true);
        [Sig1] Request1=false & Reset1=false & (FC1=1|FC2=1) & R1=2 & WD1=1-> (Request1'=true);
        [Sig1] Request1=false & Reset1=false & (FC1=1|FC2=1) & R1=2 & WD1=2 -> (Request1'=true)&(Reset1'=true);
	[Sig1] Request1=false & cb1=2 & (FC1=1|FC2=1)& R1=1 -> (Request1'=true); 
	[Sup1] sv1=1 &(Break1=false)  -> (Break1'=true); 
                
endmodule


module Signal_Disp_R2 = Signal_Disp_R1[Lock1=Lock2, Reset1=Reset2, Request1=Request2,Break1=Break2,
                                      cb1=cb2,R1=R2,FC1=FC2,FC2=FC3,WD1=WD2,Sig1=Sig2,Trp_prm1=Trp_prm2,
                                       Trp_bkp1=Trp_bkp2,Sup1=Sup2,sv1=sv2]
                                  
endmodule

module Signal_Disp_R3 = Signal_Disp_R1[Lock1=Lock3,Reset1=Reset3,Request1=Request3,Break1=Break3,
                                       cb1=cb3,R1=R3,FC1=FC3,FC2=FC1,WD1=WD3,Sig1=Sig3,Trp_prm1=Trp_prm3,
                                       Trp_bkp1=Trp_bkp3,Sup1=Sup3,sv1=sv3]
                                  
endmodule

module comm1_R1

	c1:[0..2] init 0;
	t1:[0..4] init 0;

        [] c1=0 & t1=0 & Lock1=true -> 1-COM:(c1'=1)&(t1'=1)+COM:(c1'=2)&(t1'=1); 
       
	//// new conds synched with Signal dispatching
       [Rst1_cond1] c1=1 & R1=1 & R3=3  & Reset1=true  &  t1=1 -> 1-COM:(c1'=1)&(t1'=t1+1)+COM:(c1'=2)&(t1'=t1+1); 
       [Rqst1_cond1]c1=0 & R1=2 & WD1=1 & Request1=true & t1=0 -> 1-COM:(c1'=1)&(t1'=4)+COM:(c1'=2)&(t1'=4);
       [Rst1_Rqst1_cond2]c1=1 &  R1=2 & WD1=2 & R3=3 & (Reset1=true|Request1=true)& t1=1-> 1-COM:(c1'=1)&(t1'=t1+1)+COM:(c1'=2)&(t1'=t1+1);
       [Rqst1_cond3]c1=1 & R1=1 & R3=4 & cb1=2 & Request1=true & t1=2 -> 1-COM:(c1'=1)&(t1'=t1+1)+COM:(c1'=2)&(t1'=t1+1);
  
endmodule

module comm1_R2 = comm1_R1[c1=c2,Request1=Request2,Lock1=Lock2,Reset1=Reset2,t1=t2,cb1=cb2,
                           R1=R2,R3=R1,WD1=WD2,Trp_prm1=Trp_prm2,Trp_bkp1=Trp_bkp2,
                           Rqst1_cond1= Rqst2_cond1,Rqst1_cond3= Rqst2_cond3,
                           Rst1_cond1= Rst2_cond1,Rst1_Rqst1_cond2=Rst2_Rqst2_cond2]                         
endmodule


module comm1_R3 = comm1_R1[c1=c3,Request1=Request3,Lock1=Lock3,Reset1=Reset3,t1=t3,cb1=cb3,
                           R1=R3,R3=R2,WD1=WD3,Trp_prm1=Trp_prm3,Trp_bkp1=Trp_bkp3,
                           Rqst1_cond1= Rqst3_cond1,Rqst1_cond3= Rqst3_cond3,
                           Rst1_cond1= Rst3_cond1,Rst1_Rqst1_cond2=Rst3_Rqst3_cond2]                          
endmodule



module comm_B1

	cb1:[0..2] init 0;

	[Com_b1] cb1=0& Break1=true -> 1-COM:(cb1'=1)+COM:(cb1'=2); 
	[Sup1] cb1=0 -> 1-COM:(cb1'=1)+COM:(cb1'=2); 

endmodule

module comm_B2= comm_B1[cb1=cb2,Break1=Break2,Com_b1=Com_b2,Sup1=Sup2]endmodule
module comm_B3= comm_B1[cb1=cb3,Break1=Break3,Com_b1=Com_b3,Sup1=Sup3]endmodule



module Sup_SV1
	 sv1:[0..1];
	// 0: idle
	// 1: Supervisory service activated

       [CU1]sv1=0 -> (sv1'=1); 

endmodule

module Sup_SV2= Sup_SV1[sv1=sv2,CU1=CU2]endmodule
module Sup_SV3= Sup_SV1[sv1=sv3,CU1=CU3]endmodule



module Central_Unit

 CU:[0..5] init 0;
// CU =1 : Activates supervisory  // 2: sends BR to operate  
// 3: sends BR to wait             // 4: Success
// 5: Fail
     
     [CU1] (CU=0|CU=2|CU=3) & sup_R1_cond1 -> (CU'=1);     // Activate SV1  
     [CU1] (CU=0|CU=2|CU=3) & sup_R1_cond2 -> (CU'=1);    // Activate SV1  
     [CU2] (CU=0|CU=2|CU=3) & sup_R2_cond1 -> (CU'=1);    // Activate SV2  
     [CU2] (CU=0|CU=2|CU=3) & sup_R2_cond2 -> (CU'=1);   // Activate SV2   
     [CU3] (CU=0|CU=2|CU=3) & sup_R3_cond1 -> (CU'=1);   // Activate SV3  
     [CU3] (CU=0|CU=2|CU=3) & sup_R3_cond2 -> (CU'=1);   // Activate SV3  

     [opr1] (CU=0|CU=3) & opr_R1_bkp -> (CU'=2); // Commands Backup Relay to operate
     [opr2] (CU=0|CU=3) & opr_R2_bkp -> (CU'=2); // Commands BR to operate
     [opr3] (CU=0|CU=3) & opr_R3_bkp -> (CU'=2); // Commands Backup Relay to operate
 
     [stndby1]CU=0  & standby_R1 -> (CU'=3); // CU Commands R1 to wait till request
     [stndby2]CU=0  & standby_R2  -> (CU'=3); // Commands R2 to wait till request
     [stndby3]CU=0  & standby_R3   -> (CU'=3); // CU Commands R3 to wait till request
      

     [Fail_R1]fail_R1_cond1 ->   (CU'=Unsafe_state); //Fault persist so risk
     [Fail_R1]fail_R1_cond2 ->   (CU'=Unsafe_state); //Fault persist so risk
     [Fail_R2]fail_R2_cond1 ->   (CU'=Unsafe_state); //Fault persist so failure
     [Fail_R2]fail_R2_cond2 ->   (CU'=Unsafe_state); //Fault persist so risk
     [Fail_R3]fail_R3_cond1 ->   (CU'=Unsafe_state); //Fault persist so risk
     [Fail_R3]fail_R3_cond2 ->   (CU'=Unsafe_state); //Fault persist so risk

     [FC1_clrd]  (CU=0|CU=1|CU=2|CU=3)& FC1_clear_cond  -> (CU'= Safe_state);
     [FC2_clrd]  (CU=0|CU=1|CU=2|CU=3)& FC2_clear_cond  -> (CU'= Safe_state);
     [FC3_clrd]  (CU=0|CU=1|CU=2|CU=3)& FC3_clear_cond  -> (CU'= Safe_state);
     
endmodule

label "Fault" = (FC1=1|FC2=1|FC3=1);
label "R1_operation" = (FC1=1|FC2=1)& (WD1=2)&(R1=1|R1=2);
label "R2_operation" = (FC2=1|FC3=1)& (WD2=2)&(R2=1|R2=2);
label "R3_operation" = (FC3=1|FC1=1)& (WD3=2)&(R3=1|R3=2);
label "R1_fail" = (FC1=1)& R1=2;
label "Fault_clr_R1" = FC1=1 & R1=1 & Break1=true & cb1=1;
label "Fault_clr_R2" = FC2=1 & R2=1 & Break2=true & cb2=1;
label "Fault_clr_R3" = FC3=1 & R3=1 & Break2=true & cb3=1;
label "Sup_cond_R1" = sup_R1_cond1 | sup_R1_cond2;
label "Sup_cond_R2" = sup_R2_cond1 | sup_R2_cond2;
label "Sup_cond_R3" = sup_R3_cond1 | sup_R3_cond2;


