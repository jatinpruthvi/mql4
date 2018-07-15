//------------------------------------------------------------------
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"
//------------------------------------------------------------------
#property indicator_chart_window

//
//
//
//
//

extern string FileName        = "Ticks.csv";
int fileHandle;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//

int init()   { fileHandle = FileOpen(Symbol()+" - "+FileName,FILE_WRITE|FILE_SHARE_READ|FILE_CSV); return(0); }
int deinit() {              FileClose(fileHandle);                                 return(0); }
int start()
{
   if (fileHandle <0)
   {
      static bool alerted = false;
         if (!alerted)
         {
            Alert("File : "+Symbol()+" - "+FileName+" could not be opened"); alerted = true;
         }
         return(0);
   }         
   if (FileSize(fileHandle) == 0)
         FileWriteString(fileHandle,"date and time,bid,ask,volume\n");
         FileWriteString(fileHandle,TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS)+","+DoubleToStr(Bid,Digits)+","+DoubleToStr(Ask,Digits)+","+DoubleToStr(Volume[0],0)+"\n");
         FileFlush(fileHandle);
   return(0);
}