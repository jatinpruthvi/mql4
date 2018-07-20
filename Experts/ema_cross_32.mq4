//+------------------------------------------------------------------+
//|                                                EMA_CROSS_3.2.mq4 |
//|                                                      Coders Guru |
//|                                         http://www.forex-tsd.com |
//+------------------------------------------------------------------+

#property copyright "Coders Guru"
#property link      "http://www.forex-tsd.com"

//For best results attach to M5

//---- Trades limits
extern double    TakeProfit    =160;
extern double    TrailingStop  =40;
extern double    StopLoss      =120;
extern bool      UseStopLoss   =false;

extern int        MagicNo          = 288;         // Magic number for the orders placed
extern const string     EAName           = "EMA_CROSS_3.2";

//---- EMAs paris
extern int ShortEma = 3; 
extern int LongEma  = 5;
extern int TrendEma = 50;

//---- Crossing options
extern bool immediate_trade = false; //Open trades immediately or wait for cross.

//---- Money Management
extern double Lots = 1;
extern bool MM = true; //Use Money Management or not
extern int Risk = 3; //

//---- Global varaibles
static int TimeFrame;
string   MyText = "";
string   M5TrendString = "";
string   M15TrendString = "";
string   M30TrendString = "";
string   H1TrendString = "";
string ResultText = "";

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---- 
   TimeFrame=Period(); //Prevent counting the cross while the user changing the timeframe
   MagicNo = GenerateMagicNumber(MagicNo, Symbol(), Period());
	//EAName = GenerateComment(EAName, MagicNo, Period()); 
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//---- 
   
//----
   return(0);
  }
  
bool isNewSumbol(string current_symbol)
  {
   //loop through all the opened order and compare the symbols
   int total  = OrdersTotal();
   for(int cnt = 0 ; cnt < total ; cnt++)
   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      string selected_symbol = OrderSymbol();
      if (current_symbol == selected_symbol)
      return (False);
    }
    return (True);
}
//
int FreshCross ()
   {
      double slowerEMAnow, slowerEMAprevious, slowerEMAthisbar, 
             fasterEMAnow, fasterEMAprevious, fasterEMAthisbar;
//
      fasterEMAnow      = iMA(NULL, 0, ShortEma, 0, MODE_EMA, PRICE_CLOSE, 1);
      fasterEMAprevious = iMA(NULL, 0, ShortEma, 0, MODE_EMA, PRICE_CLOSE, 2);
      fasterEMAthisbar  = iMA(NULL, 0, ShortEma, 0, MODE_EMA, PRICE_CLOSE, 0);

      slowerEMAnow      = iMA(NULL, 0, LongEma, 0, MODE_EMA, PRICE_CLOSE, 1);
      slowerEMAprevious = iMA(NULL, 0, LongEma, 0, MODE_EMA, PRICE_CLOSE, 2);
      slowerEMAthisbar  = iMA(NULL, 0, LongEma, 0, MODE_EMA, PRICE_CLOSE, 0);
      
      if ((fasterEMAnow > slowerEMAnow) && (fasterEMAprevious < slowerEMAprevious) && (fasterEMAthisbar > slowerEMAthisbar)) {
         return(1); //up
      }
      else if ((fasterEMAnow < slowerEMAnow) && (fasterEMAprevious > slowerEMAprevious) && (fasterEMAthisbar < slowerEMAthisbar)) {
         return(2); //down
      }
     
      return (0); //not changed 
   }

//--- Based on Alex idea! More ideas are coming
double LotSize()
{
     double lotMM = MathCeil(AccountFreeMargin() * Risk / 10000) / 10;
	  if (lotMM < 0.1) lotMM = Lots;
	  if (lotMM > 1.0) lotMM = MathCeil(lotMM);
	  if  (lotMM > 100) lotMM = 100;
	  return (lotMM);
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//---- 
   MyText = "The Trend is "+EmaTrend()+"  "+ResultText;
   Comment (MyText);
   int cnt, ticket, total;
   double SEma, LEma;

   if(Bars<100)
     {
      Print("bars less than 100");
      return(0);  
     }
   if(TakeProfit<10)
     {
      Print("TakeProfit less than 10");
      return(0);  // check TakeProfit
     }
   
   static int isCrossed  = 0;
   isCrossed = FreshCross ();
   
   if(MM==true) Lots = LotSize(); //Adjust the lot size
  
   
   total  = OrdersTotal();

   if(total < 1 || isNewSumbol(Symbol())) 
     {
       if(isCrossed == 1 && EmaTrend()==1)
         {
            
            if(UseStopLoss)
               ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,EAName, MagicNo, 0,Green);
            else
               ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,Ask+TakeProfit*Point,EAName, MagicNo, 0,Green);
            
            if(ticket>0) 
              {
               if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("BUY order opened : ",OrderOpenPrice());
              }
            else Print("Error opening BUY order : ",GetLastError()); 
            return(0);
         }
         if(isCrossed == 2 && EmaTrend()==-1)
         {
            if(UseStopLoss)
               ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+StopLoss*Point,Bid-TakeProfit*Point,EAName, MagicNo, 0,Red);
            else
               ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0,Bid-TakeProfit*Point,EAName, MagicNo, 0,Red);
            
            if(ticket>0)
              {
               if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)) Print("SELL order opened : ",OrderOpenPrice());
              }
            else Print("Error opening SELL order : ",GetLastError()); 
            return(0);
         }
         return(0);
     }
     
     
   for(cnt=0;cnt<total;cnt++)
     {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

      if(OrderType()<=OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNo)
        {
         if(OrderType()==OP_BUY)   // long position is opened
           {
            // check for trailing stop
            if(TrailingStop>0)  
              {                 
               if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);
                     return(0);
                    }
                 }
              }
           }
         else // go to short position
           {
            // check for trailing stop
            if(TrailingStop>0)  
              {                 
               if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                 {
                  if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red);
                     return(0);
                    }
                 }
              }
           }
        }
     }
   return(0);
  }
//+------------------------------------------------------------------+
int EmaTrend() 
{
int UpTrend = 0;  
int M5UpTrend = 0;   
int M15UpTrend = 0;
int M30UpTrend = 0;
int H1UpTrend = 0;
ResultText = "";

double M5EmaPrevious =  iMA(NULL,PERIOD_M5,TrendEma,0,MODE_EMA,PRICE_CLOSE,2);    
double M5EmaLast     =  iMA(NULL,PERIOD_M5,TrendEma,0,MODE_EMA,PRICE_CLOSE,1);         
double M5EmaNow      =  iMA(NULL,PERIOD_M5,TrendEma,0,MODE_EMA,PRICE_CLOSE,0);   
 
double M15EmaPrevious =  iMA(NULL,PERIOD_M15,TrendEma,0,MODE_EMA,PRICE_CLOSE,2);    
double M15EmaLast     =  iMA(NULL,PERIOD_M15,TrendEma,0,MODE_EMA,PRICE_CLOSE,1);         
double M15EmaNow      =  iMA(NULL,PERIOD_M15,TrendEma,0,MODE_EMA,PRICE_CLOSE,0); 

double M30EmaPrevious =  iMA(NULL,PERIOD_M30,TrendEma,0,MODE_EMA,PRICE_CLOSE,2);    
double M30EmaLast     =  iMA(NULL,PERIOD_M30,TrendEma,0,MODE_EMA,PRICE_CLOSE,1);         
double M30EmaNow      =  iMA(NULL,PERIOD_M30,TrendEma,0,MODE_EMA,PRICE_CLOSE,0);   

double H1EmaPrevious =  iMA(NULL,PERIOD_H1,TrendEma,0,MODE_EMA,PRICE_CLOSE,2);    
double H1EmaLast     =  iMA(NULL,PERIOD_H1,TrendEma,0,MODE_EMA,PRICE_CLOSE,1);         
double H1EmaNow      =  iMA(NULL,PERIOD_H1,TrendEma,0,MODE_EMA,PRICE_CLOSE,0);

M5TrendString = "M5 = FLAT; ";
M15TrendString = "M15 = FLAT; ";
M30TrendString = "M30 = FLAT; "; 
H1TrendString = "H1 = FLAT; ";
    
if (M5EmaLast>M5EmaPrevious) { M5TrendString = "M5 = UP; ";   M5UpTrend =  1; } //up trend    
if (M5EmaLast<M5EmaPrevious) { M5TrendString = "M5 = DOWN; "; M5UpTrend = -1; } //down trend 
 
if (M15EmaLast>M15EmaPrevious) { M15TrendString = "M15 = UP; ";   M15UpTrend =  1; } //up trend    
if (M15EmaLast<M15EmaPrevious) { M15TrendString = "M15 = DOWN; "; M15UpTrend = -1; } //down trend 

if (M30EmaLast>M30EmaPrevious) { M30TrendString = "M30 = UP; ";   M30UpTrend =  1; } //up trend    
if (M30EmaLast<M30EmaPrevious) { M30TrendString = "M30 = DOWN; "; M30UpTrend = -1; } //down trend 

if (H1EmaLast>H1EmaPrevious) { H1TrendString = "H1 = UP; ";   H1UpTrend =  1; } //up trend    
if (H1EmaLast<H1EmaPrevious) { H1TrendString = "H1 = DOWN; "; H1UpTrend = -1; } //down trend 

if (M5UpTrend==1 && M15UpTrend==1 && M30UpTrend==1 && H1UpTrend==1 ) UpTrend=1; 
if (M5UpTrend==-1 && M15UpTrend==-1 && M30UpTrend==-1 && H1UpTrend==-1 ) UpTrend=-1;
ResultText = ResultText+M5TrendString+M15TrendString+M30TrendString+H1TrendString;
return (UpTrend);      
}
int GenerateMagicNumber(int seed, string symbol, int timeFrame)
{
   int isymbol = 0;
   if (symbol == "EURUSD") isymbol = 1;
   else if (symbol == "GBPUSD") isymbol = 2;
   else if (symbol == "USDJPY") isymbol = 3;
   else if (symbol == "USDCHF") isymbol = 4;
   else if (symbol == "AUDUSD") isymbol = 5;
   else if (symbol == "USDCAD") isymbol = 6;
   else if (symbol == "EURGBP") isymbol = 7;
   else if (symbol == "EURJPY") isymbol = 8;
   else if (symbol == "EURCHF") isymbol = 9;
   else if (symbol == "EURAUD") isymbol = 10;
   else if (symbol == "EURCAD") isymbol = 11;
   else if (symbol == "GBPUSD") isymbol = 12;
   else if (symbol == "GBPJPY") isymbol = 13;
   else if (symbol == "GBPCHF") isymbol = 14;
   else if (symbol == "GBPAUD") isymbol = 15;
   else if (symbol == "GBPCAD") isymbol = 16;
   return (StrToInteger(StringConcatenate(seed, isymbol, timeFrame)));
}
//
string GenerateComment(string EAName, int magic, int timeFrame)
{
   return (StringConcatenate(EAName, "-", magic, "-", timeFrame));
}