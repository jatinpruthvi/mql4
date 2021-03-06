//+------------------------------------------------------------------+
//|                                          Risk / Reward Ratio.mq4 |
//|                                                   Bruno Gaiteiro |
//|                                              bgaiteiro@gmail.com |
//| 
//| volk versioning:
//|         1.00 lot size
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009, bgaiteiro"
#property link      "bgaiteiro@gmail.com"
#property version    "1.00"

#property indicator_chart_window

#include <volk_utils.mqh>

//---- input parameters
extern bool      UseBidValue=False; 
extern string    SLLevel="SLPrice";
extern string    TPLevel="TPPrice";
extern string    OpenPositionLevel="OpenPositionLevel";
extern string note2 = "Default Font Color";
extern color  FontColor = Black;
extern string note3 = "Font Size";
extern int    FontSize=20;
extern string note4 = "Font Type";
extern string FontType="Trebuchet MS";
extern string note5 = "Display the price in what corner?";
extern string note6 = "Upper left=0; Upper right=1";
extern string note7 = "Lower left=2; Lower right=3";
extern int    WhatCorner=2;

extern double Risk=1;//% on equity

int nDigits;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{

   if (ObjectFind(SLLevel)==-1)
     {
      ObjectCreate(SLLevel,OBJ_HLINE,0,0,Close[0]-100*Point);
      ObjectSet(SLLevel,OBJPROP_COLOR,Red);
      ObjectSet(SLLevel,OBJPROP_STYLE,STYLE_DASHDOT);
     }
   if (ObjectFind(TPLevel)==-1)
     {
      ObjectCreate(TPLevel,OBJ_HLINE,0,0,Close[0]+200*Point);
      ObjectSet(TPLevel,OBJPROP_COLOR,Blue);
      ObjectSet(TPLevel,OBJPROP_STYLE,STYLE_DASHDOT);
     }
   if(UseBidValue == false)
     {
      if (ObjectFind(OpenPositionLevel)==-1)
        {
         ObjectCreate(OpenPositionLevel,OBJ_HLINE,0,0,Close[0]);
         ObjectSet(OpenPositionLevel,OBJPROP_COLOR,Green);
         ObjectSet(OpenPositionLevel,OBJPROP_STYLE,STYLE_DASHDOT);
        }
     }
   return(0);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
  
//----
      ObjectDelete(SLLevel);
      ObjectDelete(TPLevel);
      ObjectDelete(OpenPositionLevel);
      ObjectDelete("SLLevel");
      ObjectDelete("TPLevel");
      ObjectDelete("OpenPositionLevel");
      ObjectDelete("RiskReward_ratio"); 
      Comment("");
//----
   return(0);
  }
  
   double LotsOptimizedPending(double price,int type,double stoploss)
  {
   //double lot = 0.01;
   double lot=0;

   if(type==OP_BUY)
   {  
     
      lot=volk_GetLotSize(price,stoploss,type,Risk);
   }
   else if(type==OP_SELL)
   {
      
      lot=volk_GetLotSize(price,stoploss,type,Risk);
   }

  // Print("Lot: ", lot, " Stop ", stoploss);
   return(lot);
  }
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   //----

   double   RiskReward_ratio=0, SL_price=0, TP_price=0, Open_Price=0;
   string   Text="";
   int i=0;
   double lots=0,lots_realtime=0;

   if(UseBidValue == true) {Open_Price = Bid;}
   if(UseBidValue == false) {if (ObjectFind(OpenPositionLevel)==-1) return(0);
   Open_Price = ObjectGet(OpenPositionLevel, OBJPROP_PRICE1);}

   if (ObjectFind(SLLevel)==-1) return(0);
   SL_price = ObjectGet(SLLevel, OBJPROP_PRICE1);
   if (ObjectFind(TPLevel)==-1) return(0);
   TP_price = ObjectGet(TPLevel, OBJPROP_PRICE1);
   

   if ((Open_Price - SL_price)!=0)
   RiskReward_ratio = (TP_price - Open_Price) / (Open_Price - SL_price);


   Text =   "Risk/Reward Ratio       1 : " + DoubleToStr(RiskReward_ratio,2) + "\n" ;

   //Comment(Text);
   //Comment(Bid + " " + Ask);
   if (Open_Price > SL_price)
   {
      lots=LotsOptimizedPending(Open_Price,OP_BUY,SL_price);
      lots_realtime=LotsOptimizedPending(Bid,OP_BUY,SL_price);
   }
   else
   {
      lots=LotsOptimizedPending(Open_Price,OP_SELL,SL_price);
      lots_realtime=LotsOptimizedPending(Ask,OP_SELL,SL_price);
   }

   string RiskReward_ratio2 = DoubleToStr(RiskReward_ratio,2);
   ObjectCreate("RiskReward_ratio", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("RiskReward_ratio",  "1 : " + RiskReward_ratio2 + " (" + DoubleToStr(Risk,2) + "% " + DoubleToStr(lots,2) +" real: " +DoubleToStr(lots_realtime,2) +")", FontSize, FontType, FontColor);
   ObjectSet("RiskReward_ratio", OBJPROP_CORNER, WhatCorner);
   ObjectSet("RiskReward_ratio", OBJPROP_XDISTANCE, 10);
   ObjectSet("RiskReward_ratio", OBJPROP_YDISTANCE, 10);

      if(ObjectFind("SLLevel") != 0)
      {
    //  ObjectCreate("SLLevel", OBJ_TEXT, 0, Time[10], SL_price);
    //  ObjectSetText("SLLevel", " StopLoss ", 8, "Arial", Black);
      }
      else
      {
      ObjectMove("SLLevel", 0, Time[10], SL_price);
      }

      if(ObjectFind("TPLevel") != 0)
      {
    //  ObjectCreate("TPLevel", OBJ_TEXT, 0, Time[10], TP_price);
    //  ObjectSetText("TPLevel", " TakeProfit ", 8, "Arial", Black);
      }
      else
      {
      ObjectMove("TPLevel", 0, Time[10], TP_price);
      }

      if(ObjectFind("Open_Price") != 0)
      {
    //  ObjectCreate("Open_Price", OBJ_TEXT, 0, Time[10], Open_Price);
    //  ObjectSetText("Open_Price", " Open ", 8, "Arial", Black);
      }
      else
      {
      ObjectMove("Open_Price", 0, Time[10], Open_Price);
      }

  
   return(0);
  }
//+------------------------------------------------------------------+//+------------------------------------------------------------------+