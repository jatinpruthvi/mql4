//+------------------------------------------------------------------+
//|                                                volk_random.mq4   |
//|                                                             volk |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "volk"
#property link      ""
#property version   "1.06"
#property strict

input int TakeProfit       = 150; // The take profit level (0 disable)
input int StopLoss         = 100; // The default stop loss (0 disable)
input double Risk          =0.5;//%on equity

#define MAGICNUM  2712793

#include <volk_utils.mqh>

static datetime oldTime; 

int OffsetHorizontal = 5;
int OffsetVertical = 20;
color LabelColor = Black;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   //EventSetTimer(60);
    MathSrand(GetTickCount());   

  
   
   ObjectCreate("lineopl", OBJ_LABEL, 0, 0, 0);
   ObjectSet("lineopl", OBJPROP_CORNER, 1);
   ObjectSet("lineopl", OBJPROP_YDISTANCE, OffsetVertical + 30);
   ObjectSet("lineopl", OBJPROP_XDISTANCE, OffsetHorizontal);
   ObjectSetText("lineopl", "Open P/L: -", 8, "Tahoma", LabelColor);


   ObjectCreate("linerisk", OBJ_LABEL, 0, 0, 0);
   ObjectSet("linerisk", OBJPROP_CORNER, 1);
   ObjectSet("linerisk", OBJPROP_YDISTANCE, OffsetVertical + 10);
   ObjectSet("linerisk", OBJPROP_XDISTANCE, OffsetHorizontal);
   ObjectSetText("linerisk", "Risk ", 8, "Tahoma", LabelColor);


   ObjectCreate("linetime", OBJ_LABEL, 0, 0, 0);
   ObjectSet("linetime", OBJPROP_CORNER, 1);
   ObjectSet("linetime", OBJPROP_YDISTANCE, OffsetVertical + 20);
   ObjectSet("linetime", OBJPROP_XDISTANCE, OffsetHorizontal);
   ObjectSetText("linetime", "Time ", 8, "Tahoma", LabelColor);


   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
  // EventKillTimer();
     ObjectDelete("lineopl"); 
     ObjectDelete("linerisk"); 
     ObjectDelete("linetime"); 
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(oldTime != Time[0] )
   {
      CheckMarket();
      oldTime = Time[0];
   }
   
   textFillOpens();
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

int CheckMarket()
{
  int cnt, ticket, total;
  double  ShortSL, ShortTP, LongSL, LongTP;
  bool ordinePresente;
  int orderType;
  
  double minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);
  string ticketTp ;//Tipo di ordine aperto (per cancellare il pendente)
  int ticketPendente;
  
  // Get the current total orders
  total = OrdersTotal();
 
  /* / Calculate Stop Loss and Take profit
  if(StopLoss > 0){
    ShortSL = NormalizeDouble(Ask+(StopLoss*Point)+(minstoplevel*Point),Digits);
    LongSL =  NormalizeDouble(Bid-(StopLoss*Point)-(minstoplevel*Point),Digits);
  }
  if(TakeProfit > 0){
    ShortTP =  NormalizeDouble(Ask-(TakeProfit*Point)-(minstoplevel*Point),Digits);
    LongTP =  NormalizeDouble(Bid+(TakeProfit*Point) +(minstoplevel*Point),Digits);
  }*/
 /*   double price=Ask;
//--- calculated SL and TP prices must be normalized
   double stoploss=NormalizeDouble(Bid-minstoplevel*Point,Digits);
   double takeprofit=NormalizeDouble(Bid+minstoplevel*Point,Digits);
//--- place market order to buy 1 lot
   int ticket=OrderSend(Symbol(),OP_BUY,1,price,3,stoploss,takeprofit,"My order",16384,0,clrGreen);
*/
 ordinePresente=false;
 ticketTp="";
 ticketPendente=0;
 for(cnt = 0; cnt < total; cnt++)
  {
     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
     if(OrderMagicNumber() ==MAGICNUM && OrderSymbol() == Symbol())
     {
   
      ordinePresente=true;//evita il sollevamento di un nuovo ordine
     // break;
     
      
      if(OrderType()==OP_BUY)
      {ticketTp="B";}
      else if(OrderType()==OP_SELL)
      {ticketTp="S";}
      else if(OrderType()==OP_SELLSTOP)
      {ticketPendente=OrderTicket();}  
      else if(OrderType()==OP_BUYSTOP)
      {ticketPendente=OrderTicket();}         
    
    
        
     }
 } 
 
 
   
  // Only open one trade at a time..
  if(!ordinePresente){
  
      RefreshRates();
      
      double MaxSpreadInPoints = 50; 
      double Spread = Ask - Bid;
      if(Spread>MaxSpreadInPoints*Point)
         return(0);
         
      
      // Print("Minimum Stop Level=",minstoplevel," points");

       
       orderType=placeOrder();
       // Buy - Long position
       if(orderType == 1){
         LongSL=0;
         LongTP=0;
           if(TakeProfit > 0)
           {
               LongTP = NormalizeDouble(Ask+TakeProfit*Point,Digits);
           }
           if(StopLoss > 0)
           {
               LongSL = NormalizeDouble(Bid-StopLoss*Point,Digits);
           }
           ticket = OrderSend(Symbol(), OP_BUY, LotsOptimized(OP_BUY,LongSL),Ask,5, LongSL, LongTP, "VOLK random",MAGICNUM,0,Blue);
           if(ticket > 0){
             if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
               Print("BUY Order Opened: ", OrderOpenPrice(), " SL:", LongSL, " TP: ", LongTP);
             }
             else
             {
               Print("Error Opening BUY  Order: ", GetLastError());
               return(1);
             }
           }
       // Sell - Short position
       if(orderType == 2){
           ShortSL=0;
           ShortTP=0;
           if(TakeProfit > 0)
           {
               ShortTP = NormalizeDouble(Bid-TakeProfit*Point,Digits);
           }
           if(StopLoss > 0)
           {
               ShortSL = NormalizeDouble(Ask+StopLoss*Point,Digits);
           }

            ticket = OrderSend(Symbol(), OP_SELL, LotsOptimized(OP_SELL,ShortSL),Bid,5, ShortSL, ShortTP, "VOLK random",MAGICNUM,0,Red);
            if(ticket > 0){
              if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
                Print("SELL Order Opened: ", OrderOpenPrice(), " SL:", ShortSL, " TP: ", ShortTP);
              }
              else
              {
                Print("Error Opening SELL Order: ", GetLastError());
                return(1);
              }
            }
 
 
  }
 
  return(0);
}

double LotsOptimized(int type,double stoploss)
  {
   //double lot = 0.01;
   double lot=0;

   if(type==OP_BUY)
   {  
     
      lot=volk_GetLotSize(Bid,stoploss,type,Risk);
   }
   else if(type==OP_SELL)
   {
      
      lot=volk_GetLotSize(Ask,stoploss,type,Risk);
   }

   
   return(lot);
  }
  
int placeOrder()
{
  
  //---
  // MathSrand(GetTickCount());
   int r=MathRand();
 
   //if(r<(32767+1)/2)
   if(r % 2 == 0)
   {  
      Print("random 1: ", r);
      return(1);
   }
   else
   {
      Print("random 2: ", r);
      return (2);
   }   
   

}



void textFillOpens() {


   ObjectSetText("lineopl", "Open P/L: "+DoubleToStr(getOpenPLInMoney(), 2) + " Magic: "+IntegerToString(MAGICNUM), 8, "Tahoma", LabelColor);
   ObjectSetText("linerisk", "Risk: "+DoubleToStr(Risk, 1) + "% " , 8, "Tahoma", LabelColor);
   string TimeLeft=TimeToStr(Time[0]+Period()*60-TimeCurrent(),TIME_MINUTES|TIME_SECONDS);
   ObjectSetText("linetime", "Time: "+ TimeLeft , 8, "Tahoma", LabelColor);
}

//+------------------------------------------------------------------+

double getOpenPLInMoney() {
   double pl = 0;

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--) {
      if (!OrderSelect(cc, SELECT_BY_POS) ) continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
      if(OrderSymbol() != Symbol()) continue;
      if(OrderMagicNumber() != MAGICNUM) continue;

      pl += OrderProfit();
   }

   return(pl);
}
