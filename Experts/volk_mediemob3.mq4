//+------------------------------------------------------------------+
//|                                               volk_mediemob3.mq4 |
//|                                                             volk |
//|                                                   www.volk.cloud |
//+------------------------------------------------------------------+
#property copyright "volk"
#property link      "www.volk.cloud"
#property version   "1.02"
#property strict
#define MAGICNUM  2712791

//#include <WinUser32.mqh>

input int Inp01Period=70;
input int Inp02Period=100;
input int Inp03Period=175;

input int TakeProfit       = 0;//30; // The take profit level (0 disable)
input int StopLoss         = 0;//25; // The default stop loss (0 disable)
input int Slippage         = 5;

//--- global variable
double MyPoint;
int    MySlippage;
static datetime oldTime; 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

      MyPoint = MyPoint();
      MySlippage = MySlippage();     
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

      
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

void BreakPoint()
{
   //It is expecting, that this function should work
   //only in tester
   if (!IsVisualMode()) return;
   
   //Preparing a data for printing
   //Comment() function is used as 
   //it give quite clear visualisation
   string Comm="";
   Comm=Comm+"Bid="+Bid+"\n";
   Comm=Comm+"Ask="+Ask+"\n";
   
   Comment(Comm);
   
   //Press/release Pause button
   //19 is a Virtual Key code of "Pause" button
   //Sleep() is needed, because of the probability
   //to misprocess too quick pressing/releasing
   //of the button
  // keybd_event(19,0,0,0);
  // Sleep(10);
  // keybd_event(19,0,2,0);
}


// Get My Points   
double MyPoint()
{
   double CalcPoint = 0;
   
   if(_Digits == 2 || _Digits == 3) CalcPoint = 0.01;
   else if(_Digits == 4 || _Digits == 5) CalcPoint = 0.0001;
   
   return(CalcPoint);
}


// Get My Slippage
double MySlippage()
{
   double CalcSlippage = 0;
   
   if(_Digits == 2 || _Digits == 4) CalcSlippage = Slippage;
   else if(_Digits == 3 || _Digits == 5) CalcSlippage = Slippage * 10;
   
   return(CalcSlippage);
}


int CheckMarket()
{
    int cnt, ticket, total;
    total = OrdersTotal();
    bool ordinePresente=false;
 
    double maV,maVOld,maM,maMOld,maL,maLOld,maMOldOld,maVOldOld,maLOldOld;
     
    int numPos,numNeg;
    int numOldPos=0,numOldNeg=0;
    bool isMod;
    string ticketTp;
    
    ticket=0;
   // BreakPoint();
   // Print("CheckMarket.",Time[0]);
      
    for(cnt = 0; cnt < total; cnt++)
     {
        OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
        if(OrderMagicNumber() ==MAGICNUM && OrderSymbol() == Symbol())
        {
      
         ticket=OrderTicket();
         if(OrderType()==OP_BUY)
         {ticketTp="B";}
         else if(OrderType()==OP_SELL)
         {ticketTp="S";}
         ordinePresente=true;
         break;
        }
     }
     
     
     
 
         RefreshRates();
    
     
         maV=NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,0),Digits);
         maVOld=NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,1),Digits);
         maVOldOld=NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,2),Digits);
        
         maM=NormalizeDouble(iMA(NULL,0,Inp02Period,0,MODE_SMA,PRICE_CLOSE,0),Digits);
         maMOld=NormalizeDouble(iMA(NULL,0,Inp02Period,0,MODE_SMA,PRICE_CLOSE,1),Digits);
         maMOldOld=NormalizeDouble(iMA(NULL,0,Inp02Period,0,MODE_SMA,PRICE_CLOSE,2),Digits);
 
         maL=NormalizeDouble(iMA(NULL,0,Inp03Period,0,MODE_SMA,PRICE_CLOSE,0),Digits);
         maLOld=NormalizeDouble(iMA(NULL,0,Inp03Period,0,MODE_SMA,PRICE_CLOSE,1),Digits);
         maLOldOld=NormalizeDouble(iMA(NULL,0,Inp03Period,0,MODE_SMA,PRICE_CLOSE,2),Digits);
 
 
 
         GetNumSign(CalculateDerivate(maV,maVOld),CalculateDerivate(maM,maMOld),CalculateDerivate(maL,maLOld),numPos, numNeg);
         GetNumSign(CalculateDerivate(maVOld,maVOldOld),CalculateDerivate(maMOld,maMOldOld),CalculateDerivate(maLOld,maLOldOld),numOldPos, numOldNeg);
         //Print(maV,maM,maL,Time[0]);
         isMod=false;    
         if((numNeg!=numOldNeg)||(numPos!=numOldPos))
         {
           
            isMod=true;
           // Print("IsMod ",Time[0]);
         }
     
     
 
   
     // Only open one trade at a time..
     if(!ordinePresente)
     {
     
   
         
            if ((numPos==3)&& isMod)
            {
               DoOrder(1);
            }
            
            if ((numNeg==3)&& isMod)
            {
               DoOrder(2);
            }
      
     } 
     else
     {
        
        if (ticket>0)
         {
            if (SignChanged(CalculateDerivate(maV,maVOld),CalculateDerivate(maVOld,maVOldOld)))
            {
               if (ticketTp=="B")
               {
                   OrderClose(ticket,0.01,Bid,5,White);
               }
               
               if (ticketTp=="S")
               {
                    OrderClose(ticket,0.01,Ask,5,White);
               }
            }
         }  
           
     }
  
  return(0);
}


 double CalculateDerivate(double recente ,double passato)
  {
      return (NormalizeDouble(recente-passato,Digits));
  }
  
 //considerato positivo anche i nulli
// bool SignChanged(double &arr[] ,int idx)
bool SignChanged(double d1 ,double d2)
  {
      if (d1>=0 )
      {
         if (d2<0)
            return (true);
      }
      else
      {
         if (d2>=0)
            return (true);
     
      }
      return(false);
  }
  
  void GetNumSign(double b1 ,double b2 ,double b3 ,int &nPos,int &nNeg)
  {
         nNeg=0;
         nPos=0;
         if(b1>=0)
         {
            nPos+=1;
         }
         else
         {
            nNeg+=1;
         }
         
         if(b2>=0)
         {
            nPos+=1;
         }
         else
         {
            nNeg+=1;
         }           
         if(b3>=0)
         {
            nPos+=1;
         }
         else
         {
            nNeg+=1;
         }
  }
  
  
double LotsOptimized()
  {
   return 0.01;
  }  
  
int DoOrder(int orderType)
{
      double TP,SL;
      int ticket;
      TP=0;
      SL=0;
   
      if(orderType == 1)
      {
           if(TakeProfit > 0)
           {
               TP = NormalizeDouble(Ask+TakeProfit*Point,Digits);
           }
           if(StopLoss > 0)
           {
               SL = NormalizeDouble(Bid-StopLoss*Point,Digits);
           }
           ticket = OrderSend(Symbol(), OP_BUY, LotsOptimized(),Ask,5, SL, TP, "VOLK media B",MAGICNUM,0,Green);
           if(ticket > 0){
             if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
               Print("BUY Order Opened: ", OrderOpenPrice(), " SL?:", SL, " TP: ", TP);
             }
             else
             {
               Print("Error Opening BUY  Order: ", GetLastError());
               return(1);
             }
       }
       // Sell - Short position
       if(orderType == 2)
       {
           if(TakeProfit > 0)
           {
               TP = NormalizeDouble(Bid-TakeProfit*Point,Digits);
           }
           if(StopLoss > 0)
           {
               SL = NormalizeDouble(Ask+StopLoss*Point,Digits);
           }

            ticket = OrderSend(Symbol(), OP_SELL, LotsOptimized(),Bid,5, SL, TP, "VOLK media S",MAGICNUM,0,Red);
            if(ticket > 0){
              if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
                Print("SELL Order Opened: ", OrderOpenPrice(), " SL?:", SL, " TP: ", TP);
              }
              else
              {
                Print("Error Opening SELL Order: ", GetLastError());
                return(1);
              }
       }
       return(0);
}