// CSE140L  
// see Structural Diagram in Lab2 assignment writeup
// fill in missing connections and parameters
module top_level_lab2_part2(
  input Reset,
        Timeset, 	  // manual buttons
        Alarmset,	  //	(five total)
	Minadv,
	Hrsadv,
        Dayadv,
	Alarmon,
	Pulse,		  // assume 1/sec.			   
// 6 decimal digit display (7 segment)
  output[6:0] S1disp, S0disp, 	   // 2-digit seconds display
              M1disp, M0disp, 
              H1disp, H0disp,
              DayLED,
  output logic AMorPM,            // Added by Arpita 
  output logic Buzz);	           // alarm sounds
  
  //old code
     logic [6:0] TSec, TMin, THrs;   // time 
   logic       TPm;                // time PM
   logic [6:0] AMin, AHrs;         // alarm setting
   logic       APm;                // alarm PM
   
     
  logic[6:0] Min, Hrs;                     // drive Min and Hr displays
  logic Smax, Mmax, Hmax,          // "carry out" from sec -> min, min -> hrs, hrs -> days
        TMen, THen, TPmen, AMen, AHen, AHmax, AMmax, APmen;    // respective counter enables
  logic         Buzz1;             // intermediate Buzz signal

   // be sure to set parameters on ct_mod_N modules
   // seconds counter runs continuously, but stalls when Timeset is on 
   ct_mod_N #(.N(60)) Sct(
        .clk(Pulse), .rst(Reset), .en(!Timeset), .ct_out(TSec), .z(Smax)
   );

   // minutes counter -- runs at either 1/sec or 1/60sec
   // make the appropriate connections. Make sure you use
   // a consistent clock signal. Do not use logic signals as clocks 
   // (EVER IN THIS CLASS)
   ct_mod_N #(.N(60)) Mct(
    .clk(Pulse), .rst(Reset), .en(TMen), .ct_out(TMin), .z(Mmax)
   );

   // hours counter -- runs at either 1/sec or 1/60min
   ct_mod_N #(.N(12)) Hct(                          
        .clk(Pulse), .rst(Reset), .en(THen), .ct_out(THrs), .z(Hmax)
   );

   // AM/PM state  --  runs at 1/12 sec or 1/12hrs
   regce TPMct(.out(TPm), .inp(!TPm), .en(TPmen),
               .clk(Pulse), .rst(Reset));


// alarm set registers -- either hold or advance 1/sec
  ct_mod_N #(.N(60)) Mreg(
    .clk(Pulse), .rst(Reset), .en(AMen), .ct_out(AMin), .z(AMmax)
   ); 

  ct_mod_N #(.N(60)) Hreg(          
    .clk(Pulse), .rst(Reset), .en(AHen), .ct_out(AHrs), .z(AHmax)
  ); 

   // alarm AM/PM state 
   regce APMReg(.out(APm), .inp(!APm), .en(APmen),
               .clk(Pulse), .rst(Reset));


   // display drivers (2 digits each, 6 digits total)
	
   lcd_int Sdisp(
    .bin_in    (TSec)  ,
        .Segment1  (S1disp),
        .Segment0  (S0disp)
   );
	
   lcd_int Mdisp(
    .bin_in    (Min) ,
        .Segment1  (M1disp),
        .Segment0  (M0disp)
        );
		  
  lcd_int Hdisp(
    .bin_in    (Hrs),
        .Segment1  (H1disp),
        .Segment0  (H0disp)
        );

   // counter enable control logic
   // create some logic for the various *en signals (e.g. TMen)
	
	
		assign TMen = Timeset ? Minadv : Smax;
		assign THen = Timeset ? Hrsadv : (Mmax && Smax);
		assign TPmen = Timeset ? (Hrsadv && Hmax) : (Hmax && Mmax && Smax);
		
		assign AMen = Alarmset && Minadv;
		assign AHen = Alarmset && Hrsadv;
		assign APmen = Alarmset && Hrsadv && AHmax;
		
		
		assign Min = Alarmset ? AMin : TMin;
		assign Hrs = Alarmset ? (AHrs == 0 ? 12 : AHrs) : (THrs == 0 ? 12 : THrs);
		
		assign AMorPM = Alarmset ? APm : TPm;


   // display select logic (decide what to send to the seven segment outputs) 

   alarm a1(
           .tmin(TMin), .amin(AMin), .thrs(THrs), .ahrs(AHrs), .tpm(TPm), .apm(APm), .buzz(Buzz1)
           );

        logic state;
        assign state = Alarmon ? Buzz1 : 0;

        always_ff @(posedge Pulse)
            if(Alarmon) begin
                if(state) begin
                    Buzz <= Buzz1;
                end else
                    Buzz <= Buzz;
            end else
                Buzz <= 0;
		
	
  
   // generate AMorPM signal (what are the sources for this LED?)/
 
  
//... Fill in the logic to display part 2 requrements
	logic [2:0] TDay;
	logic [6:0] temp;
	logic TDen;
	logic Dmax;
	
	 ct_mod_N #(.N(7)) Dct(                          
        .clk(Pulse), .rst(Reset), .en(TDen), .ct_out(TDay), .z(Dmax)
   );
	assign TDen = Timeset ? Dayadv : (Hmax && Mmax && Smax && AMorPM);

        always_comb 
     case(TDay) 
    3'b000 : temp = 7'b1000000;
    3'b001 : temp = 7'b0100000;
     3'b010 : temp = 7'b0010000;
     3'b011 : temp = 7'b0001000;
     3'b100 : temp = 7'b0000100;
    3'b101 : temp = 7'b0000010;
     3'b110 : temp = 7'b0000001;
     default : temp = 7'b1000000;
    endcase
	
	assign DayLED = temp;
	
endmodule
