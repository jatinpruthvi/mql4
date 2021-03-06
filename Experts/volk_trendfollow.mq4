//+------------------------------------------------------------------+
//|                                           volk_trendfollow.mq4   |
//|                                                             volk |
//|   versioning                                                     |
//|         1.03 trailing stop
//|         1.04 180726 evita circolo in negativo
//+------------------------------------------------------------------+
#property copyright "volk"
#property link      ""
#property version   "1.04"
#property strict

#include <volk_utils.mqh>


input int TakeProfitInPIP       = 35; // The take profit level (0 disable)
input int StopLossInPIP         = 20; // The default stop loss (0 disable)
input int TrailStopLimitInPIP   =5;
input double Risk          = 0.5;//%on equity
input int MaxSpreadInPIP   = 5;//Disable orders on wide spread cross
input bool ShowAlerts      = true;//Alerts  
input double MinBalance    =1000.0;//Limit that stop sending more trading to preserve money
input string CommentString ="";
input OrderPreference2 Type=OP2B;
input int MaxSlippage=3;
input bool DebugToFile=true;

input int MAGICNUM = 180724;

//#include <MovingAverages.mqh>

static datetime oldTime; 

double PIPCoef;//moltiplicatore per ottenere un valore dai PIP, tiene conto dei decimali del broker

//parametri label di indicazione
int OffsetHorizontal = 5;
int OffsetVertical = 20;
color LabelColor = Black;

bool oneAlarmOnBalanceReach=false;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   if (!IsDemo())
   {
      Alert("**** NOT IN DEMO ****");
   }
   double realDigits;
   if(Digits < 2) {
      realDigits = 0;
   } else if (Digits < 4) {
      realDigits = 2;
   } else {
      realDigits = 4;
   }

   PIPCoef = 1/ MathPow(10, realDigits);
                                                     
 
   //IL FONT VIENE SOVRASCRITTO, QUI NON HA TANTA IMPORTANZA
   ObjectCreate("lineopl", OBJ_LABEL, 0, 0, 0);
   ObjectSet("lineopl", OBJPROP_CORNER, 1);
   ObjectSet("lineopl", OBJPROP_YDISTANCE, OffsetVertical + 30);
   ObjectSet("lineopl", OBJPROP_XDISTANCE, OffsetHorizontal);
   ObjectSetText("lineopl", "Open P/L: -", 8, "Tahoma", LabelColor);


   ObjectCreate("linerisk", OBJ_LABEL, 0, 0, 0);
   ObjectSet("linerisk", OBJPROP_CORNER, 1);
   ObjectSet("linerisk", OBJPROP_YDISTANCE, OffsetVertical + 10);
   ObjectSet("linerisk", OBJPROP_XDISTANCE, OffsetHorizontal);
   ObjectSetText("linerisk", "Risk ???", 8, "Tahoma", LabelColor);


   ObjectCreate("linetime", OBJ_LABEL, 0, 0, 0);
   ObjectSet("linetime", OBJPROP_CORNER, 1);
   ObjectSet("linetime", OBJPROP_YDISTANCE, OffsetVertical + 20);
   ObjectSet("linetime", OBJPROP_XDISTANCE, OffsetHorizontal);
   ObjectSetText("linetime", "Time ???", 6, "Tahoma", LabelColor);

   ObjectCreate("linestats", OBJ_LABEL, 0, 0, 0);
   ObjectSet("linestats", OBJPROP_CORNER, 1);
   ObjectSet("linestats", OBJPROP_YDISTANCE, OffsetVertical + 40);
   ObjectSet("linestats", OBJPROP_XDISTANCE, OffsetHorizontal);
   ObjectSetText("linestats", "Stats ???", 8, "Tahoma", LabelColor);


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
     ObjectDelete("stats"); 
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   bool changed=false;
   if(oldTime != Time[0] )
   {
  //    CheckMarket();
      changed=true;
      oldTime = Time[0];
   }
   CheckMarket();
    
   textFillOpens(changed);
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
  int ticketFst   ;
  bool ordinePresente;
 
  

  ticketFst=GetFirstOrder();
 
  ordinePresente=(ticketFst != -1);
   
  // Only open one trade at a time..
   if((!ordinePresente)){
      if (OrdineChiusoInPerdita())//non riapre se c'è un ordine andato a remengo(evita circolo in negativo)
      {
         return(0);
      }
      
      if ( AccountBalance()<MinBalance)
      {
         Print("Balance reach: ", MinBalance);
         if (ShowAlerts && !oneAlarmOnBalanceReach)
            {
               Alert("Balance reach: ", MinBalance);
               oneAlarmOnBalanceReach=true;
            }
     
         return (0);
      }
  
      RefreshRates();
      

      double Spread = Ask - Bid;
      if(Spread>MaxSpreadInPIP*PIPCoef) //non effettua operazioni per spread troppo alti
         return(0);
         
      
     placeOrder(); 

       
       
 
 
  }
  else
  {//ordine presente:verifica per trailing stop
   
       if(OrderSelect(ticketFst,SELECT_BY_TICKET,MODE_TRADES)==true ) {
         
            if(borderlineOrder())
            {
               trailingstopOrder();
            }

      }
      else
      {
      
             if (ShowAlerts)
            {
               Alert("Not found #", ticketFst);
            }     
     }

  }
 
  return(0);
}


//ritorna true se un ordine per il MAGIC e cross è chiuso in negativo nello storico
bool OrdineChiusoInPerdita()
{
   double pl = 0;
   int count = 0;

   for(int i=OrdersHistoryTotal(); i>=0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true && OrderSymbol() == Symbol()) {
         if(OrderMagicNumber() == MAGICNUM) {
            if(OrderProfit()<0)
            {
               return (true);
            }
         }
      }
   }
   return (false);

}

//piazza l'ordine
void placeOrder()
{
  double  ShortSL, ShortTP, LongSL, LongTP,sellPrice,buyPrice;
  double spread = Ask - Bid;
  string sCommentString="tf " + CommentString + "(" + IntegerToString( MAGICNUM )  + ")";
  int ticket;
  
  
  LongSL=0;
  LongTP=0;
  ShortSL=0;
  ShortTP=0;

  
  if (Type==OP2S)
  //if (OrderType()==OP_SELL)
  {//SELL
        sellPrice=Bid;
        if(TakeProfitInPIP > 0)
        {
            ShortTP = NormalizeDouble(sellPrice-TakeProfitInPIP*PIPCoef,Digits);
        }
        if(StopLossInPIP > 0)
        {
            ShortSL = NormalizeDouble(sellPrice+StopLossInPIP*PIPCoef+spread,Digits);
        }

        ticket = OrderSend(Symbol(), OP_SELL, LotsOptimized(OP_SELL,ShortSL),sellPrice,MaxSlippage, ShortSL, ShortTP,sCommentString,MAGICNUM,0,Red);
        if(ticket > 0)
        {
           if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
             Print("SELL Order Opened: ", OrderOpenPrice(), " SL:", ShortSL, " TP: ", ShortTP);
        }
        else
        {
             Print("Error Opening SELL Order: ", GetLastError());
            if (ShowAlerts)
            {
               Alert("Error Opening SELL Order: ", GetLastError());
            }               
        } 
  }
  else
  {//BUY
        buyPrice=Ask; 
        if(TakeProfitInPIP > 0)
        {
            LongTP = NormalizeDouble(buyPrice+TakeProfitInPIP*PIPCoef+spread,Digits);
        }
        if(StopLossInPIP > 0)
        {
            LongSL = NormalizeDouble(buyPrice-StopLossInPIP*PIPCoef,Digits);
        }
        ticket = OrderSend(Symbol(), OP_BUY, LotsOptimized(OP_BUY,LongSL),buyPrice,MaxSlippage, LongSL, LongTP, sCommentString,MAGICNUM,0,Blue);
        if(ticket > 0)
        {
          if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
            Print("BUY Order Opened: ", OrderOpenPrice(), " SL:", LongSL, " TP: ", LongTP); 
        }
        else
        {
           Print("Error Opening BUY  Order: ", GetLastError());
           if (ShowAlerts)
            {
               Alert("Error Opening BUY  Order: ", GetLastError());
            }                
        }              
 
  }//...if Type==OP_BUY
}




//indica se il take proffit è prossimo al prezzo attuale
bool borderlineOrder()
{
 //  RefreshRates();
   double priceCP;
  
   if(OrderType() == OP_BUY) {
      priceCP = Bid;
      if(priceCP > OrderTakeProfit()-TrailStopLimitInPIP*PIPCoef)
         return true;
   } else {
      priceCP = Ask;
      if(priceCP < OrderTakeProfit()+TrailStopLimitInPIP*PIPCoef)
         return true;
   }
   return false;
}




//modifica l'ordine
void trailingstopOrder()
{
   double SL    =OrderStopLoss();
   double TP    =OrderTakeProfit();    // TP of the selected order
   double Price =OrderOpenPrice();     // Price of the selected order
   int    Ticket=OrderTicket();        // Ticket of the selected order

   if(OrderType() == OP_BUY) {
      SL=NormalizeDouble(OrderStopLoss() + PIPCoef * TrailStopLimitInPIP,Digits);
      TP=NormalizeDouble(OrderTakeProfit() + PIPCoef * TrailStopLimitInPIP,Digits);
   }
   else {
      SL=NormalizeDouble(OrderStopLoss() - PIPCoef * TrailStopLimitInPIP,Digits);
      TP=NormalizeDouble(OrderTakeProfit() - PIPCoef * TrailStopLimitInPIP,Digits);
 
   }
 

    bool res=OrderModify(Ticket,Price,SL,TP,0);
   //-----------------------------------------------------------------------
   if (res==true)                      
   {
       Print("MODIFY Order: #", Ticket, " SL:", SL, " TP: ", TP);
       
   }
   else
   {
      if (ShowAlerts)
      {
         Alert("Error modify #", Ticket," ",GetLastError());
      }     
      Print("Error modify #", Ticket," ",GetLastError());
   }
}



void ClosePositionAtMarket() {
   RefreshRates();
   double priceCP;
   bool rettmp;

   if(OrderType() == OP_BUY) {
      priceCP = Bid;
   } else {
      priceCP = Ask;
   }
   Print("*** Close ", OrderTicket());
   rettmp = OrderClose(OrderTicket(), OrderLots(), priceCP, MaxSlippage);
}


//cerca il primo ordine aperto, filtrando per SYMBOL, MAGIC 
//e ordinando per data inserimento
//
int GetFirstOrder()
{
  int cnt;
  int ticket=-1;
  datetime opened=D'01.01.2100';// salva la data di apertura per considerare il più vecchio
 
  for(cnt = 0; cnt < OrdersTotal(); cnt++)
  {
     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
     if(OrderMagicNumber() ==MAGICNUM && OrderSymbol() == Symbol())
     {
         if (OrderOpenTime() < opened )
         {
            ticket=OrderTicket();  
            opened=OrderOpenTime();
         }
     }
  } 
  return(ticket);
}

//determina il numero di lotti da utilizzare in base al money management
//type: BUY, SELL ..
//stoploss: valore dello stop loss (NON i pip di differenza)
//
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

   Print("Lot: ", lot, " Stop ", stoploss);
   return(lot);
  }
 










//aggiorna il testo delle etichette di diagnostica
//alsobig: se true aggiorna anche le label che richiedono calcoli dispoendiosi
//
void textFillOpens(bool alsobig ) {
   int lvr=AccountLeverage();
   
   //PROFITTO ATTUALE E MAGIC(PER EVITARE DUPLICATI)
   ObjectSetText("lineopl", "Open P/L: "+DoubleToStr(GetOpenPLInMoney(), 2) , 8, "Tahoma", LabelColor);
   //% DEL RISCHIO, PER VERIFICARE COERENZA MONEYMANAGEMENT
   ObjectSetText("linerisk", "Risk: "+DoubleToStr(Risk, 1) + "% update " +TimeToStr(Time[0]) + "(Lvrg " + IntegerToString(lvr) +")" , 9, "Tahoma", LabelColor);
   //TEMPO PER LA CHIUSUSRA DELL'ATTUALE CANDELA
   string TimeLeft=TimeToStr(Time[0]+Period()*60-TimeCurrent(),TIME_MINUTES|TIME_SECONDS);
   ObjectSetText("linetime", "Time: "+ TimeLeft + " Magic: "+IntegerToString(MAGICNUM), 9, "Tahoma", LabelColor);
   //STATISTICHE DI STRATEGIA
   
   if (alsobig)
   {
      string statistiche="P/L: "+DoubleToStr(GetTotalClosedPLInMoney(1000),2) +
                         "  P#: "+IntegerToString(GetTotalProfits(1000)) +
                         "  L#: "+IntegerToString(GetTotalLosses(1000))  ;
      ObjectSetText("linestats", "Stats: "+ statistiche , 8, "Tahoma", LabelColor);
   }
}

//OTTIENE dagli ordini aperti il profitto,filtrando per SYMBOL e MAGIC
//..
double GetOpenPLInMoney() {
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

//ritorna il numero di trade che hanno portato un profitto
//..
int GetTotalProfits(int numberOfLastOrders) {
   double pl = 0;
   int count = 0;
   int profits = 0;

   for(int i=OrdersHistoryTotal(); i>=0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true && OrderSymbol() == Symbol()) {

         if(OrderMagicNumber() == MAGICNUM) {
            // return the P/L of last order
            // or return the P/L of last order with given Magic Number
            count++;

            if(OrderType() == OP_BUY) {
               pl = (OrderClosePrice() - OrderOpenPrice());
            } else {
               pl = (OrderOpenPrice() - OrderClosePrice());
            }

            if(pl > 0) {
               profits++;
            }

            if(count >= numberOfLastOrders) break;
         }
      }
   }

   return(profits);
}

//ritorna il numero di trade che hanno portato una perdita
//..
int GetTotalLosses(int numberOfLastOrders) {
   double pl = 0;
   int count = 0;
   int losses = 0;

   for(int i=OrdersHistoryTotal(); i>=0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true && OrderSymbol() == Symbol()) {

         if(OrderMagicNumber() == MAGICNUM) {
            // return the P/L of last order
            // or return the P/L of last order with given Magic Number
            count++;

            if(OrderType() == OP_BUY) {
               pl = (OrderClosePrice() - OrderOpenPrice());
            } else {
               pl = (OrderOpenPrice() - OrderClosePrice());
            }

            if(pl < 0) {
               losses++;
            }

            if(count >= numberOfLastOrders) break;
         }
      }
   }

   return(losses);
}

//ritorna il profitto totale
//..
double GetTotalClosedPLInMoney(int numberOfLastOrders) {
   double pl = 0;
   int count = 0;

   for(int i=OrdersHistoryTotal(); i>=0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true && OrderSymbol() == Symbol()) {
         if(OrderMagicNumber() == MAGICNUM) {
            // return the P/L of last order or the P/L of last order with given Magic Number

            count++;
            pl = pl + OrderProfit();

            if(count >= numberOfLastOrders) break;
         }
      }
   }

   return(pl);
}
