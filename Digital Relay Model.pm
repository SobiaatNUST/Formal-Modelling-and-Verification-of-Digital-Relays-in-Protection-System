mdp

// PROBABILITITES
const double IED=0;  // Relay failure
const double BRK=0;  // Circuit breaker failure
const double COM=0;      // Communication failure
const double WD=0;   // Internal error
const int Safe_state =4;  //Fault cleared successfully
const int Unsafe_state =5; //Fault persist in system


  
module Fault
	FC1:[0..2];
        FC2:[0..2];
  	//0: No fault
 	//1: Fault 
        [Int_err]  (FC1=0)&(FC2=0)  -> 1/3:(FC1'=1)&(FC2'=0) 
                                     + 1/3: (FC1'=0)&(FC2'=1)
                                     + 1/3:(FC1'=0)&(FC2'=0);                                
	
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
	 WD1:[0..2];  ///initial error 
  	//0: idle
 	//1: Error
	//2: No Error
         
        [Int_err] WD1=0  -> 1-WD:(WD1'=2)+ WD:(WD1'=1);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
        [r1] (R1=0)&(WD1=2)  -> 1:(R1'=5); 
	[Trp_prm1] R1=5 & FC1=1 ->  1-IED:(R1'=1)+IED:(R1'=2);
        [r1] (R1=0|R1=5)& (WD1=1)  -> (R1'=2);  
	
        
//As Backup for R2 for FC2
	 [Lock_r1]  R1=5 & Lock2=true & FC2=1  ->  (R1'=3); 
	 [Reset_r1](R1=3)& Reset2=true & FC2=1 ->  (R1'=4);      
         [Trp_bkp1] (R1=4|R1=5)& Request2=true  & FC2=1    ->  1-IED:(R1'=1)+IED:(R1'=2); 
         
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
        [Sig1] Request1=false  & (FC1=1|FC2=1) & R1=2 & WD1=1-> (Request1'=true);
        [Sig1] Request1=false & Reset1=false & (FC1=1|FC2=1) & R1=2 & WD1=2 -> (Request1'=true)&(Reset1'=true);
	
                   
endmodule





module Signal_Disp2
        Lock2:bool init false;
        Reset2:bool init false;
        Request2:bool init false;
	//Break2:bool init false;

	[] Lock2=false&Reset2=false&Request2=false&FC2=1 ->(Lock2'=true);
        [] Lock2=true&Reset2=false&Request2=false&FC2=1 ->(Reset2'=true);
        [] Reset2=true&Request2=false&FC2=1 -> 1:(Request2'=true);
                   
endmodule


module comm1_R1

	c1:[0..2] init 0;
        t1:[0..3]init 0;
        [] c1=0 & Lock1=true & t1=0 -> 1-COM:(c1'=1)&(t1'=1)+COM:(c1'=2)&(t1'=1); 
       [Rst1_cond1] c1=1 & R1=1 & Reset1=true & t1<2   -> 1-COM:(c1'=1)&(t1'=2)+COM:(c1'=2)&(t1'=2); 
       [Rqst1_cond1]c1=0 & R1=2 & WD1=1 & Request1=true -> 1-COM:(c1'=1)+COM:(c1'=2);
       [Rst1_Rqst1_cond2]c1=1 &  R1=2 & WD1=2 & (Reset1=true|Request1=true)&(t1<3)
                         -> 1-COM:(c1'=1)&(t1'=3)+COM:(c1'=2)&(t1'=3);
endmodule





















