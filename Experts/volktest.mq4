//+------------------------------------------------------------------+
//|                                                     volktest.mq4 |
//|                                                             volk |
//|                                            http://www.volk.cloud |
//+------------------------------------------------------------------+
#property copyright "volk"
#property link      "http://www.volk.cloud"
#property version   "1.00"
#property strict
//--- input parameters
input int      Input1=0;
input string   Input2="A";
input color    Input3=clrDarkBlue;
input datetime Input4=D'2017.12.20 10:37:04';
input double   Input5=0.0;

// Define our Parameters
input double Lots          = 0.1;
input int PeriodOne        = 75; // The period for the first SMA
input int PeriodTwo        = 100; // The period for the second SMA
input int TakeProfit       = 40; // The take profit level (0 disable)
input int StopLoss         = 0; // The default stop loss (0 disable)

#define MAGICNUM  20171220
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
//   EventSetTimer(60);
   Print("Symbol name of the current chart=",_Symbol);
   Print("Timeframe of the current chart=",_Period);
   Print("The latest known seller's price (ask price) for the current symbol=",Ask);
   Print("The latest known buyer's price (bid price) of the current symbol=",Bid);   
   Print("Number of decimal places=",Digits);
   Print("Number of decimal places=",_Digits);
   Print("Size of the current symbol point in the quote currency=",_Point);
   Print("Size of the current symbol point in the quote currency=",Point);   
   Print("Number of bars in the current chart=",Bars);
   Print("Open price of the current bar of the current chart=",Open[0]);
   Print("Close price of the current bar of the current chart=",Close[0]);
   Print("High price of the current bar of the current chart=",High[0]);
   Print("Low price of the current bar of the current chart=",Low[0]);
   Print("Time of the current bar of the current chart=",Time[0]);
   Print("Tick volume of the current bar of the current chart=",Volume[0]);
   Print("Last error code=",_LastError);
   Print("Random seed=",_RandomSeed);
   Print("Stop flag=",_StopFlag);
   Print("Uninitialization reason code=",_UninitReason); 
   Print(" *** Account free margin = ",AccountFreeMargin());
   
 
     
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
//   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if( IsTradeAllowed()==false)
      Print("**TRADE DISABLED");
   //else
   //   Print("** BARRE=",Bars);
   startAlg();
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
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+ Run the algorithm                                               |
//+------------------------------------------------------------------+
int startAlg()
{
  int cnt, ticket, total;
  double shortSma, longSma, ShortSL, ShortTP, LongSL, LongTP;
 
  // Parameter Sanity checking
  if(PeriodTwo < PeriodOne){
    Print("Please check settings, Period Two is lesser then the first period");
    return(0);
    
  }
 
  if(Bars < PeriodTwo){
    Print("Please check settings, less then the second period bars available for the long SMA");
    return(0);
  
  }
 
  // Calculate the SMAs from the iMA indicator in MODE_SMMA using the close price
  shortSma = iMA(NULL, 0, PeriodOne, 0, MODE_EMA, PRICE_CLOSE, 0);
  longSma = iMA(NULL, 0, PeriodTwo, 0, MODE_EMA, PRICE_CLOSE, 0);
 
  // Check if there has been a cross on this tick from the two SMAs
  int isCrossed = CheckForCross(shortSma, longSma);
 
  // Get the current total orders
  total = OrdersTotal();
 
  // Calculate Stop Loss and Take profit
  if(StopLoss > 0){
    ShortSL = Bid+(StopLoss*Point);
    LongSL = Ask-(StopLoss*Point);
  }
  if(TakeProfit > 0){
    ShortTP = Bid-(TakeProfit*Point);
    LongTP = Ask+(TakeProfit*Point);
  }
 
  // Only open one trade at a time..
  //if(total < 1){
    // Buy - Long position
    if(isCrossed == 1){
        ticket = OrderSend(Symbol(), OP_BUY, LotsOptimized(),Ask,5, LongSL, LongTP, "Double SMA Crossover",MAGICNUM,0,Blue);
        if(ticket > 0){
          if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
            Print("BUY Order Opened: ", OrderOpenPrice(), " SL:", LongSL, " TP: ", LongTP);
             Alert("BUY Order Opened: ", OrderOpenPrice(), " SL:", LongSL, " TP: ", LongTP);
          }
          else
            Print("Error Opening BUY  Order: ", GetLastError());
            return(0);
        }
    // Sell - Short position
    if(isCrossed == 2){
      ticket = OrderSend(Symbol(), OP_SELL, LotsOptimized(),Bid,5, ShortSL, ShortTP, "Double SMA Crossover",MAGICNUM,0,Red);
      if(ticket > 0){
        if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
          Print("SELL Order Opened: ", OrderOpenPrice(), " SL:", ShortSL, " TP: ", ShortTP);
            Alert("SELL Order Opened: ", OrderOpenPrice(), " SL:", ShortSL, " TP: ", ShortTP);
        }
        else
          Print("Error Opening SELL Order: ", GetLastError());
          return(0);
      }
   // }
 
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
  
 return (1);
 }

//+------------------------------------------------------------------+
//| Check for cross over of SMA                                      |
//+------------------------------------------------------------------+
int CheckForCross(double input1, double input2)
{
  static int previous_direction = 0;
  static int current_direction  = 0;
 
  // Up Direction = 1
  if(input1 > input2){
    current_direction = 1;
  }
 
  // Down Direction = 2
  if(input1 < input2){
    current_direction = 2;
  }
 
  // Detect a direction change
  if(current_direction != previous_direction){
    previous_direction = current_direction;
    return (previous_direction);
  } else {
    return (0);
  }
}

 
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot = Lots;
   // Calculate Lot size as a fifth of available free equity.
   lot = NormalizeDouble((AccountFreeMargin()/5)/1000.0,2);
   if(lot<Lots) lot=Lots; //Ensure the minimal amount is xx lots
   return(lot);
  }
 
 
//+------------------------------------------------------------------+
//+ Break Even                                                       |
//+------------------------------------------------------------------+
bool BreakEven(int MN){
  int Ticket;
 
  for(int i = OrdersTotal() - 1; i >= 0; i--) {
    OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
 
    if(OrderSymbol() == Symbol() && OrderMagicNumber() == MN){
      Ticket = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, Green);
      if(Ticket < 0) Print("Error in Break Even : ", GetLastError());
        break;
      }
    }
 
  return(Ticket);
}