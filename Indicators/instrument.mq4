//+------------------------------------------------------------------+
//|                                                   Instrument.mq4 |
//|                                 Copyright © 2012 by Mike Zhitnev |
//|                                           http://Forex-Robots.ru |
//|        Создание торговых роботов, индикаторов, скриптов для Вас! |
//|      Expert advisors, indicators, scripts: admin@forex-robots.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2012 Mike Zhitnev"
#property link      "http://Forex-Robots.ru"

#include <stdlib.mqh>
#include <WinUser32.mqh>

#property indicator_chart_window
#property indicator_buffers 4

#property indicator_color1 Aqua
#property indicator_color2 Red
#property indicator_color3 Aqua
#property indicator_color4 Red

#property  indicator_width1 2
#property  indicator_width2 2

double Line1[], Line2[], Line3[], Line4[];

extern string Instrument="GBPUSD";       
extern int HistBars=10000;
extern int Diffr=0;

datetime LastTime, LastTime2;

int TimeFrame=0;
int Transf=0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {

   SetIndexStyle(0,DRAW_HISTOGRAM,0,3);
   SetIndexBuffer(0,Line1);
   SetIndexShift( 0, 0); 
     
   SetIndexStyle(1,DRAW_HISTOGRAM,0,3);
   SetIndexBuffer(1,Line2);  
   SetIndexShift( 1, 0);
   
   SetIndexStyle(2,DRAW_HISTOGRAM,0,1);
   SetIndexBuffer(2,Line3);
   SetIndexShift( 2, 0);
   
   SetIndexStyle(3,DRAW_HISTOGRAM,0,1);
   SetIndexBuffer(3,Line4);
   SetIndexShift( 3, 0);
   
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
     int Counted_bars=IndicatorCounted();
     int i=Bars-Counted_bars-1;           
     if (HistBars>0 && i>HistBars)        
       
     i=HistBars; 
     i = Bars-1;  
       
      while(i>=0)                         
      {                 
                        
        double H, L, O, C, Delta;
        int Index;
        
        Index = iBarShift(Instrument, TimeFrame, Time[i]);
        
        H = iHigh (Instrument, TimeFrame, Index);
        L = iLow  (Instrument, TimeFrame, Index);
        O = iOpen (Instrument, TimeFrame, Index); 
        C = iClose(Instrument, TimeFrame, Index);
                        
        if (TimeDay(Time[i])!=TimeDay(Time[i+1]))
        {
          Delta= iOpen(Instrument, TimeFrame, Index) - Open[i];             
        }  
          
        H = H - Delta;
        O = O - Delta;
        C = C - Delta;
        L = L - Delta;
           
        if(C>O)
        {
          Line1[i]=C; Line2[i]=O;
          Line3[i]=H; Line4[i]=L; 
        }
        else
        if(C<O)
        {
          Line1[i]=C; Line2[i]=O;            
          Line3[i]=L; Line4[i]=H; 
        }
        else
        if(C==O)
        {
          Line1[i]=O; Line2[i]=Line1[i]+0.01*Point;
          Line3[i]=L; Line4[i]=H; 
        }                            
      i--;
    }
   
    
   double RZM = High[0]-Low[0];
   if (Diffr!=0 && RZM>Diffr*Point && Time[0]!=LastTime) 
   {
     Alert("Внимание! Движение по " + Symbol());     
     LastTime=Time[0];     
   } 
   
   double RZ = iHigh(Instrument, TimeFrame, 0)-iLow(Instrument, TimeFrame, 0);
   if (Diffr!=0 && RZ>Diffr*MarketInfo(Instrument, MODE_POINT)  && iTime(Instrument, TimeFrame, 0)!=LastTime2) 
   {
     Alert("Внимание! Движение по " + Instrument);     
     LastTime2=iTime(Instrument, TimeFrame, 0);   
   }  
   
   
   return(0);
  }