//+------------------------------------------------------------------+
//|                                                volk_longbody.mq4 |
//|                                                             volk |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "volk"
#property link      ""
#property version   "1.02"
#property strict

input int TakeProfit       = 300; // The take profit level (0 disable)
input int StopLoss         = 250; // The default stop loss (0 disable)
input int PipDeltaShoot    = 200;
#define MAGICNUM  2712792

static datetime oldTime; 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   //EventSetTimer(60);
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
  // EventKillTimer();
      
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
           ticket = OrderSend(Symbol(), OP_BUY, LotsOptimized(),Ask,5, LongSL, LongTP, "VOLK LongBody",MAGICNUM,0,Blue);
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

            ticket = OrderSend(Symbol(), OP_SELL, LotsOptimized(),Bid,5, ShortSL, ShortTP, "VOLK LongBody",MAGICNUM,0,Red);
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
 
         if(orderType == 3){
           double sellPrice;
           double buyPrice;
           //datetime expire = TimeCurrent() + 60 * (1* 60);//1h 
           datetime expire = TimeCurrent() + 60 * (0.5* 60);//0.5h 
           
           //sellPrice=NormalizeDouble(Ask-40*Point,Digits); 
           LongSL=0;
           LongTP=0;
           ShortSL=0;
           ShortTP=0;

           sellPrice=Low[1];
           if(Low[2]<Low[1])
           {
            sellPrice=Low[2];
           }
           //sellPrice=NormalizeDouble(sellPrice-20*Point,Digits);
           
           
           if(TakeProfit > 0)
           {
               ShortTP = NormalizeDouble(sellPrice-TakeProfit*Point+Spread,Digits);
           }
           if(StopLoss > 0)
           {
               ShortSL = NormalizeDouble(sellPrice+StopLoss*Point+Spread,Digits);
           }

         ticket = OrderSend(Symbol(), OP_SELLSTOP, LotsOptimized(),sellPrice,5, ShortSL, ShortTP, "VOLK LongBody SS",MAGICNUM,expire,Green);
         if(ticket > 0){
           if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
             Print("SELLSTOP Order Opened: ", OrderOpenPrice(), " SL:", ShortSL, " TP: ", ShortTP," su ",Time[3]);
           }
           else{
             Print("Error Opening SELLSTOP Order: ", GetLastError());
            // return(1);
            }
        
            
           //buyPrice=NormalizeDouble(Ask+40*Point,Digits); 
           buyPrice=High[1];
           if(High[2]>High[1])
           {
            buyPrice=High[2];
           }
           //buyPrice=NormalizeDouble(buyPrice+30*Point,Digits);


           if(TakeProfit > 0)
           {
               LongTP = NormalizeDouble(buyPrice+TakeProfit*Point+Spread,Digits);
           }
           if(StopLoss > 0)
           {
               LongSL = NormalizeDouble(buyPrice-StopLoss*Point+Spread,Digits);
           }
           ticket = OrderSend(Symbol(), OP_BUYSTOP, LotsOptimized(),buyPrice,5, LongSL, LongTP, "VOLK LongBody BS",MAGICNUM,expire,Black);
           if(ticket > 0)
           {
             if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
               Print("BUYSTOP Order Opened: ", OrderOpenPrice(), " SL:", LongSL, " TP: ", LongTP," su ",Time[3]); 
           }
             else
             {
               Print("Error Opening BUYSTOP  Order: ", GetLastError());
             //  return(1);
             
             
             
             
             
             
  /*          
              if(TakeProfit > 0)
              {
                  LongTP = NormalizeDouble(Ask+TakeProfit*Point,Digits);
              }
              if(StopLoss > 0)
              {
                  LongSL = NormalizeDouble(Ask-StopLoss*Point,Digits);
              }
              ticket = OrderSend(Symbol(), OP_BUY, LotsOptimized(),Ask,5, LongSL, LongTP, "VOLK LongBody B",MAGICNUM,0,Blue);
              if(ticket > 0)
              {
                if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
                  Print("BUY Order Opened: ", OrderOpenPrice(), " SL:", LongSL, " TP: ", LongTP);
                }
                else
                {
                  Print("Error Opening BUY  Order: ", GetLastError());
                  return(1);
                }
 */                 
          }
         }
                     
       }
       else
       {//ordine presente (potrebbero essere entrambi pendenti)
         if (ticketTp!="")
         {

               
               if (ticketTp=="B")
               {
                   OrderDelete(ticketPendente,clrBlack);
                   Print("Delete");
               }
               
               if (ticketTp=="S")
               {
                   OrderDelete(ticketPendente,clrBlack);
                   Print("Delete");
               }

         }
       
       }
 
 
 
  
  
 /*
  // Manage open orders for exit criteria
  for(cnt = 0; cnt < total; cnt++){
    OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
    if(OrderType() <= OP_SELL && OrderSymbol() == Symbol()){
      // Look for long positions
      if(OrderType() == OP_BUY){
        // Check for Exit criteria on buy - change of direction
        if(isCrossed == 2){
          OrderClose(OrderTicket(), OrderLots(), Bid, 3, Violet); // Close the position
          return(0);
        }
      }
      else //Look for short positions - inverse of prior conditions
      {
        // Check for Exit criteria on sell - change of direction
        if(isCrossed == 1){
          OrderClose(OrderTicket(), OrderLots(), Ask, 3, Violet); // Close the position
          return(0);
        }
      }
      // If we are in a loss - Try to BreakEven
      Print("Current Unrealized Profit on Order: ", OrderProfit());
      if(OrderProfit() < 0){
        BreakEven(MAGICNUM);
      }
    }
 
  }
 */
  return(0);
}

double LotsOptimized()
  {
   double lot = 0.01;
  
   return(lot);
  }
  
int placeOrder()
{
   double delta;
   int pipDelta;
   pipDelta=PipDeltaShoot;
   
   delta=Close[3]-Open[3];
   delta=delta/Point;

/*
   if(delta>pipDelta)
   {
      return(1);
   
   }else if(delta<-pipDelta)
   {
      return(2);
   
   }
   */
   if(MathAbs(delta)>pipDelta )
   {
      return(3);
   }   
   return (0);

}