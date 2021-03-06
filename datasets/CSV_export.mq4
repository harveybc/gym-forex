//+------------------------------------------------------------------+
//|                                                   CSV_export.mq4 |
//| Calculate a CSV with the given variables, indicators or training
//| signals.
//+------------------------------------------------------------------+
#property copyright "Harvey D. Bastidas C."
#property link      "https://github.com/harveybc" 
#property version   "0.1"
#property strict
#property script_show_inputs
// #include <WaveEncoding.mqh>
//+------------------------------------------------------------------+
// script input parameters
//+------------------------------------------------------------------+
//0 = HighBid, 1 = Low, 2 = Close, 3 = NextOpen, 4 = v, 5 = MoY, 6 = DoM, 7 = DoW, 8 = HoD, 9 = MoH, ..<num_co
input string   filename="d_2015_2018.CSV";   // output filename
input string   symbol="EURUSD"; // symbol , usar EURUSD, un top 5(YEN?) y un top 10(OTRO)
input int      tf_base=PERIOD_D1;    // base short-term period
input int      mid_multiplier=6; // Multiplier for the mid-term  (6*4H = 1 Día)
input int      lon_multiplier=42; // Multiplier for the long-term (7*1Dia = 1week)          
input int      num_ticks=1;    // number of ticks of prices and indicators
input datetime date_start=D'2015.01.01 00:00'; // start date of the exported indicators
input datetime date_end=D'2018.12.15 23:59';   // end date of the exported indicators
input int      indicator_period=14;   //  period for all indicator calculations 14
                                      // TODO: Verificar si el use_return está funcionando solo para training o también para HLC
input bool     use_return=false; // export return values=(Vf-Vi)/Vi
input bool     use_return_indicators=false; // exports returns for indicators
input bool     use_return_volume=false; // exports returns for volume
input bool     use_return_candle=false; // exports returns for candles
input int      train_signal=0;  // 0= No training signal, 1=H,2=L,3=C,4=H-L, 5=(C-L)/(H-L),6=(C-O)/(H-L)
input bool     hlc=true; // export High,Low, And Close for price
input bool     volumen=true; //export the volume
input bool     candle=true; // export (H-L),(C-L)/(H-L) y (C-O)/(H-L)
input bool     indicators=true; // The RSI, MACD, and CCI indicators 
input bool     time_signals=true; // HoD=Hour of Day,DoW=DayOfWeek,WoM,WoQ=WeekOfQuarter,QoY=QuarterOfYear,MoY
input bool     sml_tf=false; // TODO: NOT IMPLEMENTED Exports short-mid-long term data en everything 
input string   newc=","; // separador de columnas de CSV
input string   newl="\n"; // separador de nueva fila en CSV
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   int handle;
// open file with write access
   handle=FileOpen(filename,FILE_BIN|FILE_WRITE);
// check for error
   if(handle==INVALID_HANDLE)
     {
      Print("OnStart: Can't open file -",GetLastError());
      return;
     }
// write values to the array
   WriteCSV(handle);
// close file
   FileClose(handle);

  }
//+--- // genera train_signal de 1 tick en el futuro---------------------------------------------------------------+
string training_return(int i,bool &sep_flag)
  {
   string text="";
   double vf=0;
   double vi=0;// valores inicial y final
   int j=i+1;// usado para el tick anterior en return
   double denom;// for division by zero watch
   sep_flag=true;
   if(train_signal==1)
     {
      vi=iHigh(symbol,tf_base,j-1);
      vf=iHigh(symbol,tf_base,i-1);
     }
   if(train_signal==2)
     {
      vi=iLow(symbol,tf_base,j-1);
      vf=iLow(symbol,tf_base,i-1);
     }
   if(train_signal==3)
     {
      vi=iClose(symbol,tf_base,j-1);
      vf=iClose(symbol,tf_base,i-1);
     }
   if(train_signal==4)
     {

      // vi=iHigh(symbol,tf_base,j-1)-iLow(symbol,tf_base,j-1);
      // vf=iHigh(symbol,tf_base,i-1)-iLow(symbol,tf_base,i-1);
     }
   if(train_signal==5)
     {
      // denom=iHigh(symbol,tf_base,j-1)-iLow(symbol,tf_base,j-1);if(denom==0.0f) denom=0.00000001;
      //  vi=(iClose(symbol,tf_base,j-1)-iLow(symbol,tf_base,j-1))/denom;
      //  denom=(iHigh(symbol,tf_base,i-1)-iLow(symbol,tf_base,i-1));if(denom==0.0f) denom=0.00000001;
      // vf=(iClose(symbol,tf_base,i-1)-iLow(symbol,tf_base,i-1))/denom;
     }
   if(train_signal==6)
     {
      //denom=(iHigh(symbol,tf_base,j-1)-iLow(symbol,tf_base,j-1));if(denom==0.0f) denom=0.00000001;
      // vi=(iClose(symbol,tf_base,j-1)-iOpen(symbol,tf_base,j-1))/denom;
      // denom=(iHigh(symbol,tf_base,i-1)-iLow(symbol,tf_base,i-1));if(denom==0.0f) denom=0.00000001;
      // vf=(iClose(symbol,tf_base,i-1)-iOpen(symbol,tf_base,i-1))/denom;
     }
   if(train_signal==4)
     {
      vf=iHigh(symbol,tf_base,i-1)-iLow(symbol,tf_base,i-1);
      vi=1;
      vf=vf+1;
     }
   if(train_signal==5)
     {
      denom=(iHigh(symbol,tf_base,i-1)-iLow(symbol,tf_base,i-1));if(denom==0.0f) denom=0.00000001f;
      vf=(iClose(symbol,tf_base,i-1)-iLow(symbol,tf_base,i-1))/denom;
      vi=1;
      vf=vf+1;
     }
   if(train_signal==6)
     {
      denom=(iHigh(symbol,tf_base,i-1)-iLow(symbol,tf_base,i-1));if(denom==0.0f) denom=0.00000001f;
      vf=(iClose(symbol,tf_base,i-1)-iOpen(symbol,tf_base,i-1))/denom;
      vi=1;
      vf=vf+1;
     }
   if(train_signal>0)
     {
      denom=vi;if(denom==0.0f) denom=0.00000001f;
      text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8));
     }
   return text;
  }
//+------------------------------------------------------------------+
string training_no_return(int i,bool &sep_flag)
  {
   double denom;// for division by zero watch
   string text="";
// genera train_signal de 1 tick en el futuro
   if(train_signal==1) text=StringConcatenate(text, DoubleToStr(iHigh(symbol,tf_base,i-1),8));
   if(train_signal==2) text=StringConcatenate(text, DoubleToStr(iLow(symbol,tf_base,i-1),8));
   if(train_signal==3) text=StringConcatenate(text, DoubleToStr(iClose(symbol,tf_base,i-1),8));
   if(train_signal==4) text=StringConcatenate(text, DoubleToStr(iHigh(symbol,tf_base,i-1)-iLow(symbol,tf_base,i-1),8));
   if(train_signal==5)
     {
      denom=(iHigh(symbol,tf_base,i-1)-iLow(symbol,tf_base,i-1));if(denom==0.0f) denom=0.00000001f;
      text=StringConcatenate(text,DoubleToStr((iClose(symbol,tf_base,i-1)-iLow(symbol,tf_base,i-1))/denom,8));
     }
   if(train_signal==6)
     {
      denom=(iHigh(symbol,tf_base,i-1)-iLow(symbol,tf_base,i-1));if(denom==0.0f) denom=0.00000001f;
      text=StringConcatenate(text,DoubleToStr((iClose(symbol,tf_base,i-1)-iOpen(symbol,tf_base,i-1))/denom,8));
     }
   return text;
  }
//+------------------------------------------------------------------+
string returned(int i,bool &sep_flag)
  {
// para fila de CSV
   double denom;// for division by zero watch
   string text="";
   double vi,vf; // valores inicial y final para return
   int j=i+1;// usado para el tick anterior en return
             // genera hlc
   if(hlc)
     {
      if(sep_flag) text=StringConcatenate(text,newc);
      sep_flag=true;
      vi=iHigh(symbol,tf_base,j);
      vf=iHigh(symbol,tf_base,i);
      denom=vi;if(denom==0.0f) denom=0.00000001;
      text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8)+newc);
      vi=iLow(symbol,tf_base,j);
      vf=iLow(symbol,tf_base,i);
      denom=vi;if(denom==0.0f) denom=0.00000001;
      text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8)+newc);
      vi=iClose(symbol,tf_base,j);
      vf=iClose(symbol,tf_base,i);
      denom=vi;if(denom==0.0f) denom=0.00000001;
      text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8)+newc);
      // Open of the next tick
      vi=iOpen(symbol,tf_base,j-1);
      if(i>0)
        {
         vf=iOpen(symbol,tf_base,i-1);
        }
      else
        {
         vf=vi;
        }
      denom=vi;if(denom==0.0f) denom=0.00000001;
      text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8));
     }
//volumen
   if(volumen)
     {
      if(sep_flag) text=StringConcatenate(text,newc);
      sep_flag=true;
      if(use_return_volume)
        {

         vi=(double)iVolume(symbol,tf_base,j);
         vf=(double)iVolume(symbol,tf_base,i);
         denom=vi;if(denom==0.0f) denom=0.00000001;
         text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8));
        }
      else
        {
         text=StringConcatenate(text,DoubleToStr(iVolume(symbol,tf_base,i),8));
        }
     }
// genera candles
   if(candle)
     {
      if(use_return_candle)
        {
         if(sep_flag) text=StringConcatenate(text,newc);
         sep_flag=true;
         vi=iHigh(symbol,tf_base,j)-iLow(symbol,tf_base,j);
         vf=iHigh(symbol,tf_base,i)-iLow(symbol,tf_base,i);
         denom=vi;if(denom==0.0f) denom=0.00000001;
         text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8)+newc);
         denom=(iHigh(symbol,tf_base,j)-iLow(symbol,tf_base,j));if(denom==0.0f) denom=0.00000001;
         vi=(iClose(symbol,tf_base,j)-iLow(symbol,tf_base,j))/denom;
         denom=(iHigh(symbol,tf_base,i)-iLow(symbol,tf_base,i));if(denom==0.0f) denom=0.00000001;
         vf=(iClose(symbol,tf_base,i)-iLow(symbol,tf_base,i))/denom;
         denom=vi;if(denom==0.0f) denom=0.00000001;
         text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8)+newc);
         denom=(iHigh(symbol,tf_base,j)-iLow(symbol,tf_base,j));if(denom==0.0f) denom=0.00000001;
         vi=(iClose(symbol,tf_base,j)-iOpen(symbol,tf_base,j))/denom;
         denom=(iHigh(symbol,tf_base,i)-iLow(symbol,tf_base,i));if(denom==0.0f) denom=0.00000001;
         vf=(iClose(symbol,tf_base,i)-iOpen(symbol,tf_base,i))/denom;
         denom=vi;if(denom==0.0f) denom=0.00000001;
         text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8));
        }
      else
        {
         if(sep_flag) text=StringConcatenate(text,newc);
         sep_flag=true;
         text=StringConcatenate(text,DoubleToStr(iHigh(symbol,tf_base,i)-iLow(symbol,tf_base,i),8)+newc);
         text=StringConcatenate(text, DoubleToStr((iClose(symbol,tf_base,i)-iLow(symbol,tf_base,i))/(iHigh(symbol,tf_base,i)-iLow(symbol,tf_base,i)),8)+newc);
         text=StringConcatenate(text, DoubleToStr((iClose(symbol,tf_base,i)-iOpen(symbol,tf_base,i))/(iHigh(symbol,tf_base,i)-iLow(symbol,tf_base,i)),8));

        }
     }
// genera tech indicators
   if(indicators)
     {
      if(sep_flag) text=StringConcatenate(text,newc);
      sep_flag=true;
      if(use_return_indicators)
        {
         vi=iRSI(symbol,tf_base,indicator_period,PRICE_WEIGHTED,j);
         vf=iRSI(symbol,tf_base,indicator_period,PRICE_WEIGHTED,i);
         denom=vi;if(denom==0.0f) denom=0.00000001;
         text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8)+newc);
         vi=iMACD(symbol,tf_base,indicator_period,indicator_period*2,(int)MathFloor(indicator_period*0.6f),PRICE_WEIGHTED,MODE_SIGNAL,j);
         vf=iMACD(symbol,tf_base,indicator_period,indicator_period*2,(int)MathFloor(indicator_period*0.6f),PRICE_WEIGHTED,MODE_SIGNAL,i);
         denom=vi;if(denom==0.0f) denom=0.00000001;
         text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8)+newc);
         vi=iADX(symbol,tf_base,indicator_period,PRICE_WEIGHTED,MODE_MAIN,j);
         vf=iADX(symbol,tf_base,indicator_period,PRICE_WEIGHTED,MODE_MAIN,i);
         denom=vi;if(denom==0.0f) denom=0.00000001;
         text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8)+newc);
         vi=iCCI(symbol,tf_base,indicator_period,PRICE_WEIGHTED,j);
         vf=iCCI(symbol,tf_base,indicator_period,PRICE_WEIGHTED,i);
         denom=vi;if(denom==0.0f) denom=0.00000001;
         text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8)+newc);
         vi=iATR(symbol,tf_base,indicator_period,j);
         vf=iATR(symbol,tf_base,indicator_period,i);
         denom=vi;if(denom==0.0f) denom=0.00000001;
         text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8)+newc);
         vi=iStochastic(symbol,tf_base,indicator_period,(int)MathFloor(indicator_period*0.6f),(int)MathFloor(indicator_period*0.6f),MODE_EMA,0, MODE_SIGNAL,j);
         vf=iStochastic(symbol,tf_base,indicator_period,(int)MathFloor(indicator_period*0.6f),(int)MathFloor(indicator_period*0.6f),MODE_EMA,0, MODE_SIGNAL,i);
         denom=vi;if(denom==0.0f) denom=0.00000001;
         text=StringConcatenate(text,DoubleToStr((vf-vi)/denom,8));
        }
      else
        {
         text=StringConcatenate(text,DoubleToStr(iRSI(symbol,tf_base,indicator_period,PRICE_WEIGHTED,i),8)+newc);
         text=StringConcatenate(text, DoubleToStr(iMACD(symbol,tf_base,indicator_period,indicator_period*2,(int)MathFloor(indicator_period*0.6f),PRICE_WEIGHTED,MODE_SIGNAL,i),8)+newc);
         text=StringConcatenate(text, DoubleToStr(iADX(symbol,tf_base,indicator_period,PRICE_WEIGHTED,MODE_MAIN,i),8)+newc);
         text=StringConcatenate(text, DoubleToStr(iCCI(symbol,tf_base,indicator_period,PRICE_WEIGHTED,i),8)+newc);
         text=StringConcatenate(text, DoubleToStr(iATR(symbol,tf_base,indicator_period,i),8)+newc);
         text=StringConcatenate(text, DoubleToStr(iStochastic(symbol,tf_base,indicator_period,(int)MathFloor(indicator_period*0.6f),(int)MathFloor(indicator_period*0.6f),MODE_EMA,0, MODE_SIGNAL,i),8));

        }
     }
   return text;
  }
//+------------------------------------------------------------------+
string non_returned(int i,bool &sep_flag)
  {
// para fila de CSV
   double denom;// for division by zero watch
   string text="";
// genera hlc
   if(hlc)
     {
      if(sep_flag) text=StringConcatenate(text,newc);
      sep_flag=true;       
      text=StringConcatenate(text,DoubleToStr(iHigh(symbol,tf_base,i),8)+newc+DoubleToStr(iLow(symbol,tf_base,i),8)+newc+DoubleToStr(iClose(symbol,tf_base,i),8));
     }
//volumen
   if(volumen)
     {
      if(sep_flag) text=StringConcatenate(text,newc);
      sep_flag=true;
      text=StringConcatenate(text,DoubleToStr(iVolume(symbol,tf_base,i),8));
     }
// genera candles
   if(candle)
     {
      if(sep_flag) text=StringConcatenate(text,newc);
      sep_flag=true;
      text=StringConcatenate(text, DoubleToStr(iHigh(symbol,tf_base,i)-iLow(symbol,tf_base,i),8)+newc);
      text=StringConcatenate(text, DoubleToStr((iClose(symbol,tf_base,i)-iLow(symbol,tf_base,i))/(iHigh(symbol,tf_base,i)-iLow(symbol,tf_base,i)),8)+newc);
      text=StringConcatenate(text, DoubleToStr((iClose(symbol,tf_base,i)-iOpen(symbol,tf_base,i))/(iHigh(symbol,tf_base,i)-iLow(symbol,tf_base,i)),8));
     }
// genera tech indicators
   if(indicators)
     {
      if(sep_flag) text=StringConcatenate(text,newc);
      sep_flag=true;
      text=StringConcatenate(text, DoubleToStr(iRSI(symbol,tf_base,indicator_period,PRICE_WEIGHTED,i),8)+newc);
      text=StringConcatenate(text, DoubleToStr(iMACD(symbol,tf_base,indicator_period,indicator_period*2,(int)MathFloor(indicator_period*0.6f),PRICE_WEIGHTED,MODE_SIGNAL,i),8)+newc);
      text=StringConcatenate(text, DoubleToStr(iADX(symbol,tf_base,indicator_period,PRICE_WEIGHTED,MODE_MAIN,i),8)+newc);
      text=StringConcatenate(text, DoubleToStr(iCCI(symbol,tf_base,indicator_period,PRICE_WEIGHTED,i),8)+newc);
      text=StringConcatenate(text, DoubleToStr(iATR(symbol,tf_base,indicator_period,i),8)+newc);
      text=StringConcatenate(text, DoubleToStr(iStochastic(symbol,tf_base,indicator_period,(int)MathFloor(indicator_period*0.6f),(int)MathFloor(indicator_period*0.6f),MODE_EMA,0, MODE_SIGNAL,i),8));
     }
   return text;
  }
//+------------------------------------------------------------------+
//| WriteCSV                                   |
//+------------------------------------------------------------------+
void WriteCSV(int handle)
  {
// obtiene en candlestick index de inicio(mayor index) y fin (menor index)
   int ini_candle=iBarShift(symbol,tf_base,date_start,false);
   int end_candle=iBarShift(symbol,tf_base,date_end,false);
   if((ini_candle==-1) || (end_candle==-1))
     {
      Print("Error, tf_base_=",tf_base,",date_start_=",date_start,", candle_ini=",ini_candle,"candle_end=",end_candle,"  for symbol ",symbol," not found. 2");
     }
   Print("tf_base=",tf_base,",date_start=",date_start,", candle_ini=",ini_candle,"candle_end=",end_candle,"  for symbol ",symbol);
// para i desde inicio hasta fin,
   string text="";
   for(int i=ini_candle; i>=end_candle;i--)
     {
      // flag para indicar si debe prrfijar un newc separator antes del prox valor
      bool sep_flag=false;
      text="";
      if(train_signal>0) sep_flag=true;
      if(use_return)
        {
         text=StringConcatenate(text,training_return(i,sep_flag));
        }
      else
        {
         text=StringConcatenate(text,training_no_return(i,sep_flag));
        }
      for(int j=0;j<num_ticks;j++)
        {
         if(use_return)
           {
            text=StringConcatenate(text,returned(i+j,sep_flag));
           }
         else
           {
            text=StringConcatenate(text,non_returned(i+j,sep_flag));
           }// end if use_return
        }
      // genera time_signals HoD=Hour of Day,DoW=DayOfWeek,DoM,DoY,MoY
      // 5 = MoY, 6 = DoM, 7 = DoW, 8 = HoD, 9 = MoH
      if(time_signals)
        {
         if(sep_flag) text=StringConcatenate(text,newc);
         sep_flag=true;
         datetime i_time=iTime(symbol,tf_base,i);
         text=StringConcatenate(text, IntegerToString(TimeMonth(i_time))+newc);
         text=StringConcatenate(text, IntegerToString(TimeDay(i_time))+newc);
         text=StringConcatenate(text, IntegerToString(TimeDayOfWeek(i_time))+newc);
         text=StringConcatenate(text, IntegerToString(TimeHour(i_time))+newc);
         text=StringConcatenate(text,IntegerToString(TimeMinute(i_time)));


        }
      // si i!=fin, escribe newl
      if(i!=end_candle)
        {
         text=StringConcatenate(text,newl);
        }
      FileWriteString(handle,text);
     }
  }
//+------------------------------------------------------------------+
