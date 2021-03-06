//+------------------------------------------------------------------+
//|                                                volk_postnews.mq4 |
//|                                                             volk |
//|                                                                  |
//| 1.01 180622 sistemato size ordini pending
//| 1.02 180719 magic variabile
//|             before strategia
//+------------------------------------------------------------------+
#property copyright "volk"
#property link      ""
#property version   "1.03"
#property strict
#property description "nel file di configurazione introdurre gli orari effettivi del calendario:gestisce  automaticamente quando attivare gli ordini"

#include <volk_utils.mqh>


input int TakeProfit       = 30; // The take profit level (0 disable)
input int StopLoss         = 25; // The default stop loss (0 disable)
input double Risk          = 0.5;//%on equity
input int MaxSpreadInPIP   = 5;//Disable orders on wide spread cross
input bool ShowAlerts      = false;//Alerts  
input double MinBalance    =400.0;//Limit that stop sending more trading to preserve money
input string CommentString ="volk_postnews";
input bool ExitAtEndOfRange = true;
input string TimeRangeTo = "15:50";

input int MaxSlippage=5;
input bool DebugToFile=true;

input int MAGICNUM  =2712790;
input bool AfterStrat =true;     // if true, trades after 3 candles 
input bool BeforeStrat=false;    //if true, trades before 1 candle
input int TakeProfitBefore       = 30; // Before strat. take profit level (0 disable)
input int StopLossBefore         = 10; // Before strat. default stop loss (0 disable)

//#include <MovingAverages.mqh>

static datetime oldTime; 

double PIPCoef;//moltiplicatore per ottenere un valore dai PIP, tiene conto dei decimali del broker

//parametri label di indicazione
int OffsetHorizontal = 5;
int OffsetVertical = 20;
color LabelColor = Black;

bool oneAlarmOnBalanceReach=false;

//xml
#define MAX_EVENTS 10
string xmlFileName;
string sData;
string Event[MAX_EVENTS][8];//8 il numero di tag
string eTitle[10],eCountry[10],eImpact[10],eForecast[10],ePrevious[10],eActive[10];
int eMinutes[10];
datetime eTime[10];
double MinuteBuffer[];

#define TITLE		0
#define COUNTRY	1
#define DATE		2
#define TIME		3
#define IMPACT		4
#define FORECAST	5
#define PREVIOUS	6
#define ACTIVE	   7

string sCommentString;
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
   if (_Period != PERIOD_M5)
   {
      Alert("**** ONLY TIMEFRAME M5 ****");
      return(INIT_FAILED);
      
   }
   sCommentString=CommentString + "(" + IntegerToString(MAGICNUM) +")";
   double realDigits;
   if(Digits < 2) {
      realDigits = 0;
   } else if (Digits < 4) {
      realDigits = 2;
   } else {
      realDigits = 4;
   }
   SetIndexBuffer(0,MinuteBuffer);
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


   //xmlFileName=StringConcatenate(TerminalInfoString(TERMINAL_DATA_PATH),"\\MQL4\\files\\","volk_postnews.xml");
   xmlFileName="volk_postnews.xml";
   if(!FileIsExist(xmlFileName,0))
   {
   //   if (ShowAlerts )     
      Alert("Not found ", xmlFileName);           
   }
   else
   {
      PrintFormat(" %s file with records!",xmlFileName);
      xmlRead();
      xmlDecode();
      DrawEvents();
   }

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
      CheckMarket();
      oldTime = Time[0];
      changed=true;
   }
   
    
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
  int orderType;
  
  double minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);
 
  

  ticketFst=GetFirstOrder();
 
  ordinePresente=(ticketFst != -1);

  if(!ordinePresente){//non riapre se c'è un ordine andato a remengo(evita circolo in negativo)
     
  // apre un solo trade alla volta
  
      if ( AccountBalance()<MinBalance)
      {
         //blocca se il saldo è già sceso
         Print("Balance limit: ", MinBalance);
         if (ShowAlerts && !oneAlarmOnBalanceReach)
            {
               Alert("Balance limit: ", MinBalance);
               oneAlarmOnBalanceReach=true;
            }
     
         return (0);
      }
  
      RefreshRates();
      

      double Spread = Ask - Bid;
      if(Spread>MaxSpreadInPIP*PIPCoef) //non effettua operazioni per spread troppo alti
         return(0);
         
      
      // Print("Minimum Stop Level=",minstoplevel," points");

       
       orderType=placeOrder();
      
       if((orderType >=0)&&(orderType<1000)){
          buildOrders(Spread);
       }
       if(orderType >=1000){
          buildOrdersBefore(Spread);
       }
     
 
  }
  else
  {
   //ordine già presente
   
       // we are out of allowed trading hours
      if(ExitAtEndOfRange) {
         if(TimeCurrent() > TimeStringToDateTime(TimeRangeTo)) {
            closeActiveOrders();
            closePendingOrders();
         } 
      }
     
    
  
  }
 
  return(0);
}


void buildOrders( double spread)
{
        double ShortSL, ShortTP, LongSL, LongTP;
        int ticket;
        double sellPrice;
        double buyPrice;
        RefreshRates();
        //datetime expire = TimeCurrent() + 60 * (1* 60);//1h 
        //datetime expire = TimeCurrent() + 60 * (0.5* 60);//0.5h 
        datetime expire = TimeStringToDateTime("20:00");
        //int NrOfDigits = MarketInfo(Symbol(),MODE_DIGITS);   // Nr. of decimals used by Symbol
        //int PipAdjust;                                       // Pips multiplier for value adjustment
        //if(NrOfDigits == 5 || NrOfDigits == 3)            // If decimals = 5 or 3
        //    PipAdjust = 10;                                // Multiply pips by 10
        //else
        //   if(NrOfDigits == 4 || NrOfDigits == 2)            // If digits = 4 or 3 (normal)
        //      PipAdjust = 1;            
         
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
            ShortTP = NormalizeDouble(sellPrice-TakeProfit*PIPCoef,Digits);
        }
        if(StopLoss > 0)
        {
            ShortSL = NormalizeDouble(sellPrice+StopLoss*PIPCoef+spread,Digits);
        }

        ticket = OrderSend(Symbol(), OP_SELLSTOP, LotsOptimizedPending(sellPrice,OP_SELL,ShortSL),sellPrice,MaxSlippage, ShortSL, ShortTP,sCommentString,MAGICNUM,expire,Green);
        if(ticket > 0)
        {
           if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
             Print("SELLSTOP Order Opened: ", OrderOpenPrice(), " SL:", ShortSL, " TP: ", ShortTP," RIFERITO A ",Time[3]);
        }
        else
        {
             Print("Error Opening SELLSTOP Order: ", GetLastError());
           
            //se c'è errore col pending prova con l'ordine diretto
            
             sellPrice=Bid;
             if(TakeProfit > 0)
              {
                  ShortTP = NormalizeDouble(sellPrice-TakeProfit*PIPCoef,Digits);
              }
              if(StopLoss > 0)
              {
                  ShortSL = NormalizeDouble(sellPrice+StopLoss*PIPCoef+spread,Digits);
              }
      
              ticket = OrderSend(Symbol(), OP_SELL, LotsOptimized(OP_SELL,ShortSL),sellPrice,MaxSlippage, ShortSL, ShortTP,sCommentString,MAGICNUM,0,Green);
              if(ticket > 0)
              {
                 if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
                   Print("SELL Order Opened: ", OrderOpenPrice(), " SL:", ShortSL, " TP: ", ShortTP," RIFERITO A ",Time[3]);
              }
              else
              {
                   Print("Error Opening SELL Order: ", GetLastError());
                 
                  //se c'è errore col pending prova con l'ordine diretto
                  
                  
      
              }
        }
     
         
        //buyPrice=NormalizeDouble(Ask+40*Point,Digits); 
        buyPrice=High[1];
        if(High[2]>High[1])
        {
         buyPrice=High[2];
        }
        //buyPrice=0.98;
        //buyPrice=NormalizeDouble(buyPrice+30*Point,Digits);


        if(TakeProfit > 0)
        {
            LongTP = NormalizeDouble(buyPrice+TakeProfit*PIPCoef+spread,Digits);
        }
        if(StopLoss > 0)
        {
            LongSL = NormalizeDouble(buyPrice-StopLoss*PIPCoef,Digits);
        }
        ticket = OrderSend(Symbol(), OP_BUYSTOP, LotsOptimizedPending(buyPrice,OP_BUY,LongSL),buyPrice,MaxSlippage, LongSL, LongTP, sCommentString,MAGICNUM,expire,Black);
        if(ticket > 0)
        {
          if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
            Print("BUYSTOP Order Opened: ", OrderOpenPrice(), " SL:", LongSL, " TP: ", LongTP," RIFERITO A ",Time[3]); 
        }
        else
        {
              Print("Error Opening BUYSTOP  Order: ", GetLastError());
              //se c'è errore col pending prova con l'ordine diretto
              buyPrice=Ask; 
              if(TakeProfit > 0)
              {
                  LongTP = NormalizeDouble(buyPrice+TakeProfit*PIPCoef+spread,Digits);
              }
              if(StopLoss > 0)
              {
                  LongSL = NormalizeDouble(buyPrice-StopLoss*PIPCoef,Digits);
              }
              ticket = OrderSend(Symbol(), OP_BUY, LotsOptimized(OP_BUY,LongSL),buyPrice,MaxSlippage, LongSL, LongTP, sCommentString,MAGICNUM,0,Black);
              if(ticket > 0)
              {
                if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
                  Print("BUY Order Opened: ", OrderOpenPrice(), " SL:", LongSL, " TP: ", LongTP," RIFERITO A ",Time[3]); 
              }
              else
              {
                  Print("Error Opening BUY  Order: ", GetLastError());
                      
              }              
        }
}


void buildOrdersBefore( double spread)
{
        double ShortSL, ShortTP, LongSL, LongTP;
        int ticket;
        double sellPrice;
        double buyPrice;
        RefreshRates();
        datetime expire = TimeCurrent() + 60 * (1* 60);//1h
        //datetime expire = TimeCurrent() + 60 * (0.5* 60);//0.5h 
        //datetime expire = TimeStringToDateTime("20:00");
        LongSL=0;
        LongTP=0;
        ShortSL=0;
        ShortTP=0;

        sellPrice=Low[1]-1*PIPCoef;              
        
        if(TakeProfitBefore > 0)
        {
            ShortTP = NormalizeDouble(sellPrice-TakeProfitBefore*PIPCoef,Digits);
        }
        if(StopLossBefore > 0)
        {
            ShortSL = NormalizeDouble(sellPrice+StopLossBefore*PIPCoef+spread,Digits);
        }

        ticket = OrderSend(Symbol(), OP_SELLSTOP, LotsOptimizedPending(sellPrice,OP_SELL,ShortSL),sellPrice,MaxSlippage, ShortSL, ShortTP,sCommentString,MAGICNUM,expire,Green);
        if(ticket > 0)
        {
           if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
             Print("SELLSTOP Order Opened: ", OrderOpenPrice(), " SL:", ShortSL, " TP: ", ShortTP," BEFORE RIFERITO A ",Time[0]);
        }
        else
        {
             Print("Error Opening SELLSTOP Order: ", GetLastError());   
  
             sellPrice=Bid;
             if(TakeProfitBefore > 0)
              {
                  ShortTP = NormalizeDouble(sellPrice-TakeProfitBefore*PIPCoef,Digits);
              }
              if(StopLossBefore > 0)
              {
                  ShortSL = NormalizeDouble(sellPrice+StopLossBefore*PIPCoef+spread,Digits);
              }
      
              ticket = OrderSend(Symbol(), OP_SELL, LotsOptimized(OP_SELL,ShortSL),sellPrice,MaxSlippage, ShortSL, ShortTP,sCommentString,MAGICNUM,0,Green);
              if(ticket > 0)
              {
                 if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
                   Print("SELL Order Opened: ", OrderOpenPrice(), " SL:", ShortSL, " TP: ", ShortTP," RIFERITO A ",Time[3]);
              }
              else
              {
                   Print("Error Opening SELL Order: ", GetLastError());
                 
                  //se c'è errore col pending prova con l'ordine diretto
        
              }

        }
     
         
     
        buyPrice=High[1]+1*PIPCoef;
      

        if(TakeProfitBefore > 0)
        {
            LongTP = NormalizeDouble(buyPrice+TakeProfitBefore*PIPCoef+spread,Digits);
        }
        if(StopLossBefore > 0)
        {
            LongSL = NormalizeDouble(buyPrice-StopLossBefore*PIPCoef,Digits);
        }
        ticket = OrderSend(Symbol(), OP_BUYSTOP, LotsOptimizedPending(buyPrice,OP_BUY,LongSL),buyPrice,MaxSlippage, LongSL, LongTP, sCommentString,MAGICNUM,expire,Black);
        if(ticket > 0)
        {
          if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
            Print("BUYSTOP Order Opened: ", OrderOpenPrice(), " SL:", LongSL, " TP: ", LongTP," BEFORE RIFERITO A ",Time[3]); 
        }
        else
        {
              Print("Error Opening BUYSTOP  Order: ", GetLastError());
              buyPrice=Ask; 
              if(TakeProfitBefore > 0)
              {
                  LongTP = NormalizeDouble(buyPrice+TakeProfitBefore*PIPCoef+spread,Digits);
              }
              if(StopLossBefore > 0)
              {
                  LongSL = NormalizeDouble(buyPrice-StopLossBefore*PIPCoef,Digits);
              }
              ticket = OrderSend(Symbol(), OP_BUY, LotsOptimized(OP_BUY,LongSL),buyPrice,MaxSlippage, LongSL, LongTP, sCommentString,MAGICNUM,0,Black);
              if(ticket > 0)
              {
                if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
                  Print("BUY Order Opened: ", OrderOpenPrice(), " SL:", LongSL, " TP: ", LongTP," RIFERITO A ",Time[3]); 
              }
              else
              {
                  Print("Error Opening BUY  Order: ", GetLastError());
                      
              }              
                
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


//cerca il primo ordine aperto(più vecchio cronologicamente), filtrando per SYMBOL, MAGIC 
//e ordinando per data inserimento
//esclusi gli ordini pensenti limit e stop
int GetFirstOrder()
{
  int cnt;
  int ticket=-1;
  datetime opened=D'01.01.2100';// salva la data di apertura per considerare il più vecchio
 
  for(cnt = 0; cnt < OrdersTotal(); cnt++)
  {
     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
    //  Print("* ", OrderTicket()," " ,OrderMagicNumber(), " ",OrderSymbol());
      if(OrderMagicNumber() ==MAGICNUM && OrderSymbol() == Symbol())//anche pendenti
    // if(OrderMagicNumber() ==MAGICNUM && OrderSymbol() == Symbol() && (OrderType()==OP_BUY || OrderType()==OP_SELL ))
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
//non valido per i pending!
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
  
//da usare per i pending
//
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

   Print("Lot: ", lot, " Stop ", stoploss);
   return(lot);
  }
 
//determina se piazzare gli ordini leggendo i record dal file
// >=0 <1000      piazza su 3 candele dopo
// >=1000         piazza su 1 candela prima
// <0             no 
int placeOrder()
{
 //return 0;
  // datetime t; 
   int m;
   string sTooltip;
   for (int i =0 ; i< MAX_EVENTS;i++)
   {
      if(Event[i][TITLE]=="")
      {
         break;
      }
   
   //   t=datetime(MakeDateTime(Event[i][DATE],Event[i][TIME]));
      m=datetime(MakeDateTime(Event[i][DATE],Event[i][TIME]))-TimeLocal();
      m=m/60;
      
      if (AfterStrat)
      { 
         if (m >=-16 && m <= -14) 
            return i;
      }
      if (BeforeStrat)
      { 
         if (m >=0 && m < 1) 
            return i+1000;
      }
   }
   return -1;
}

//+------------------------------------------------------------------+

void closePendingOrders() {
   int orderType;

   for(int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MAGICNUM && OrderSymbol() == Symbol()) {
         orderType = OrderType();

         if (orderType == OP_BUYSTOP || orderType == OP_SELLSTOP) {
            closePendingOrder();
         }

        
      }
   }
}


bool closePendingOrder() {
   int ticket = OrderTicket();

   if(OrderDelete(ticket)) {

      return(true);
   }
   
   return(false);
}
//+------------------------------------------------------------------+

void closeActiveOrders() {
   int orderType;

   for(int i=0; i<OrdersTotal(); i++) {
      if (OrderSelect(i,SELECT_BY_POS)==true && OrderMagicNumber() == MAGICNUM && OrderSymbol() == Symbol()) {
         orderType = OrderType();

         if (orderType == OP_BUY || orderType == OP_SELL) {
            ClosePositionAtMarket();
         }
      }
   }
}
//*********************************************************************************************************
// SEZIONE XML
//*********************************************************************************************************

//+------------------------------------------------------------------+
//| Read the XML file                                                |
//+------------------------------------------------------------------+
void xmlRead()
  {
//---
   ResetLastError();
   int FileHandle=FileOpen(xmlFileName,FILE_BIN|FILE_READ);
   if(FileHandle!=INVALID_HANDLE)
     {
      //--- receive the file size 
      ulong size=FileSize(FileHandle);
      //--- read data from the file
      while(!FileIsEnding(FileHandle))
         sData=FileReadString(FileHandle,(int)size);
      //--- close
      FileClose(FileHandle);
     }
//--- check for errors   
    else PrintFormat("failed to open %s file, Error code = %d",xmlFileName,GetLastError());
//---
  }
  
  //data la stringa sData che contiene l'xml, estrae i tag e li memorizza in array
  void xmlDecode()
  {
   //---
   //--- BY AUTHORS WITH SOME MODIFICATIONS
   //--- define the XML Tags, Vars
      string sTags[8]={"<title>","<country>","<date><![CDATA[","<time><![CDATA[","<impact><![CDATA[","<forecast><![CDATA[","<previous><![CDATA[","<active>"};
      string eTags[8]={"</title>","</country>","]]></date>","]]></time>","]]></impact>","]]></forecast>","]]></previous>","</active>"};
      int index=0;
      int next=-1;
      int BoEvent=0,begin=0,end=0;
      string myEvent="";
   //--- Minutes calculation
      datetime EventTime=0;
      int EventMinute=0;
   //--- split the currencies into the two parts 
      string MainSymbol=StringSubstr(Symbol(),0,3);
      string SecondSymbol=StringSubstr(Symbol(),3,3);
   //--- loop to get the data from xml tags
      while(true)
        {
         BoEvent=StringFind(sData,"<event>",BoEvent);
         Event[index][TITLE]="";
         if(BoEvent==-1) break;
         BoEvent+=7;
         next=StringFind(sData,"</event>",BoEvent);
         if(next == -1) break;
         myEvent = StringSubstr(sData,BoEvent,next-BoEvent);
         BoEvent = next;
         begin=0;
         for(int i=0; i<8; i++)
         {
            Event[index][i]="";
            next=StringFind(myEvent,sTags[i],begin);
            //--- Within this event, if tag not found, then it must be missing; skip it
            if(next==-1) continue;
            else
              {
               //--- We must have found the sTag okay...
               //--- Advance past the start tag
               begin=next+StringLen(sTags[i]);
               end=StringFind(myEvent,eTags[i],begin);
               //---Find start of end tag and Get data between start and end tag
               if(end>begin && end!=-1)
                  Event[index][i]=StringSubstr(myEvent,begin,end-begin);
              }
         }
           
           
         ////--- filters that define whether we want to skip this particular currencies or events
         //if(ReportActive && MainSymbol!=Event[index][COUNTRY] && SecondSymbol!=Event[index][COUNTRY])
         //   continue;
         //if(!IsCurrency(Event[index][COUNTRY]))
         //   continue;
         //if(!IncludeHigh && Event[index][IMPACT]=="High")
         //   continue;
         //if(!IncludeMedium && Event[index][IMPACT]=="Medium")
         //   continue;
         //if(!IncludeLow && Event[index][IMPACT]=="Low")
         //   continue;
         //if(!IncludeSpeaks && StringFind(Event[index][TITLE],"Speaks")!=-1)
         //   continue;
         //if(!IncludeHolidays && Event[index][IMPACT]=="Holiday")
         //   continue;
         //if(Event[index][TIME]=="All Day" ||
         //   Event[index][TIME]=="Tentative" ||
         //   Event[index][TIME]=="")
         //   continue;
         //if(FindKeyword!="")
         //  {
         //   if(StringFind(Event[index][TITLE],FindKeyword)==-1)
         //      continue;
         //  }
         //if(IgnoreKeyword!="")
         //  {
         //   if(StringFind(Event[index][TITLE],IgnoreKeyword)!=-1)
         //      continue;
         //  }
         
         //--- sometimes they forget to remove the tags :)
         if(StringFind(Event[index][TITLE],"<![CDATA[")!=-1)
            StringReplace(Event[index][TITLE],"<![CDATA[","");
         if(StringFind(Event[index][TITLE],"]]>")!=-1)
            StringReplace(Event[index][TITLE],"]]>","");
         if(StringFind(Event[index][TITLE],"]]>")!=-1)
            StringReplace(Event[index][TITLE],"]]>","");
         //---
         if(StringFind(Event[index][FORECAST],"&lt;")!=-1)
            StringReplace(Event[index][FORECAST],"&lt;","");
         if(StringFind(Event[index][PREVIOUS],"&lt;")!=-1)
            StringReplace(Event[index][PREVIOUS],"&lt;","");
   
         //--- set some values (dashes) if empty
         if(Event[index][FORECAST]=="") Event[index][FORECAST]="---";
         if(Event[index][PREVIOUS]=="") Event[index][PREVIOUS]="---";
         //--- Convert Event time to MT4 time
         EventTime=datetime(MakeDateTime(Event[index][DATE],Event[index][TIME]));
         //--- calculate how many minutes before the event (may be negative)
         // EventMinute=int(EventTime-TimeGMT())/60;
         EventMinute=int(EventTime-TimeLocal())/60; //contiene i minuti di differenza
         ////--- only Alert once
         //if(EventMinute==0 && AlertTime!=EventTime)
         //  {
         //   FirstAlert =false;
         //   SecondAlert=false;
         //   AlertTime=EventTime;
         //  }
         //--- Remove the event after x minutes
         // if(EventMinute+EventDisplay<0) continue;
         //--- Set buffers
         //   MinuteBuffer[index]=EventMinute;
         // ImpactBuffer[index]=ImpactToNumber(Event[index][IMPACT]);
         index++;
        }
   //--- loop to set arrays/buffers that uses to draw objects and alert
      for(int i=0; i<index; i++)
        {
         for(int n=i; n<10; n++)
           {
            eTitle[n]    = Event[i][TITLE];
            eCountry[n]  = Event[i][COUNTRY];
            eImpact[n]   = Event[i][IMPACT];
            eForecast[n] = Event[i][FORECAST];
            ePrevious[n] = Event[i][PREVIOUS];
           // eTime[n]     = datetime(MakeDateTime(Event[i][DATE],Event[i][TIME]))-TimeGMTOffset();
            eTime[n]     = datetime(MakeDateTime(Event[i][DATE],Event[i][TIME]))-TimeLocal();//contiene l'orario di differenza
     //       eMinutes[n]  = (int)MinuteBuffer[i];
            //--- Check if there are any events
           // if(ObjectFind(eTitle[n])!=0) IsEvent=true;
           }
        }
  }
  
//+------------------------------------------------------------------+
//| Converts ff time & date into yyyy.mm.dd hh:mm - by deVries       |
//+------------------------------------------------------------------+
string MakeDateTime(string strDate,string strTime)
  {
//---
   int n1stDash=StringFind(strDate, "-");
   int n2ndDash=StringFind(strDate, "-", n1stDash+1);

   string strMonth=StringSubstr(strDate,0,2);
   string strDay=StringSubstr(strDate,3,2);
   string strYear=StringSubstr(strDate,6,4);

   int nTimeColonPos=StringFind(strTime,":");
   string strHour=StringSubstr(strTime,0,nTimeColonPos);
   string strMinute=StringSubstr(strTime,nTimeColonPos+1,2);
   string strAM_PM=StringSubstr(strTime,StringLen(strTime)-2);

   int nHour24=StrToInteger(strHour);
   if((strAM_PM=="pm" || strAM_PM=="PM") && nHour24!=12) nHour24+=12;
   if((strAM_PM=="am" || strAM_PM=="AM") && nHour24==12) nHour24=0;
   string strHourPad="";
   if(nHour24<10) strHourPad="0";
   return(StringConcatenate(strYear, ".", strMonth, ".", strDay, " ", strHourPad, nHour24, ":", strMinute));
//---
  }
  
  datetime TimeStringToDateTime(string time) {
   string date = TimeToStr(TimeCurrent(),TIME_DATE);//"yyyy.mm.dd"
   return (StrToTime(date + " " + time));
}
//+------------------------------------------------------------------+
//| draw vertical lines                                              |
//+------------------------------------------------------------------+
void DrawLine(string name,datetime time,color clr,string tooltip)
  {
//---
   ObjectDelete(name);
   ObjectCreate(name,OBJ_VLINE,0,time,0);
   ObjectSet(name,OBJPROP_COLOR,clr);
   ObjectSet(name,OBJPROP_STYLE,2);
   ObjectSet(name,OBJPROP_WIDTH,0);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,tooltip);
//---
  }
 
//disegna gli eventi sul grafico ++++++++++++++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
void DrawEvents()
{
   datetime t; 
   int m;
   string sTooltip;
   for (int i =0 ; i< MAX_EVENTS;i++)
   {
      if(Event[i][TITLE]=="")
      {
         break;
      }
   
      t=datetime(MakeDateTime(Event[i][DATE],Event[i][TIME]));
      m=datetime(MakeDateTime(Event[i][DATE],Event[i][TIME]))-TimeLocal();
      m=m/60;
      
      sTooltip=Event[i][TITLE] + " Time left: "+(string)(m)+" Minutes";
         
      DrawLine("Event_"+(string)i,t,C'217,83,79',sTooltip);
   }
}


//*********************************************************************************************************
// SEZIONE ETICHETTE DI DIAGNOSTICA
//*********************************************************************************************************




//aggiorna il testo delle etichette di diagnostica
//alsobig: se true aggiorna anche le label che richiedono calcoli dispoendiosi
//
void textFillOpens(bool alsobig ) {
   int lvr=AccountLeverage();
    
  //  RefreshRates();
  //  ObjectSetText("linerisk", "Ask: "+DoubleToStr(Ask, 6) + " Bid: " + DoubleToStr(Bid, 6) , 8, "Tahoma", LabelColor);
 
   //PROFITTO ATTUALE E MAGIC(PER EVITARE DUPLICATI)
   ObjectSetText("lineopl", "Open P/L: "+DoubleToStr(GetOpenPLInMoney(), 2) , 8, "Tahoma", LabelColor);
   //% DEL RISCHIO, PER VERIFICARE COERENZA MONEYMANAGEMENT
   //ObjectSetText("linerisk", "Risk: "+DoubleToStr(Risk, 1) + "% update " +TimeToStr(Time[0]) + "(Lvrg " + IntegerToString(lvr) +")" , 8, "Tahoma", LabelColor);
   ObjectSetText("linerisk", "Risk: "+DoubleToStr(Risk, 1) + "% range " + TimeRangeTo  , 8, "Tahoma", LabelColor);
   //TEMPO PER LA CHIUSUSRA DELL'ATTUALE CANDELA
   string TimeLeft=TimeToStr(Time[0]+Period()*60-TimeCurrent(),TIME_MINUTES|TIME_SECONDS);
   ObjectSetText("linetime", "Time: "+ TimeLeft + " Magic: "+IntegerToString(MAGICNUM), 6, "Tahoma", LabelColor);
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

//ritorna il numero di trade storico che hanno portato un profitto,filtrando per SYMBOL e MAGIC
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

//ritorna il numero di trade storico che hanno portato una perdita,filtrando per SYMBOL e MAGIC
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

//ritorna il profitto totale storico,filtrando per SYMBOL e MAGIC
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


