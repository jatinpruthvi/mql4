
#property copyright   "volk"
#property link        "www.volk.cloud"
#property description "media 75 100 175"
#property strict
#property version "1.04"

#include <MovingAverages.mqh>

#property indicator_chart_window
#property indicator_buffers 6
#property indicator_color1 Red
#property indicator_color2 Blue
#property indicator_color3 Green

input int    InpBandsShift=0;        // Bands Shift
//input double InpBandsDeviations=2.0; // Bands Deviations

input int Inp01Period=70;
input int Inp02Period=100;
input int Inp03Period=175;
//--- buffers
double ExtMoving01Buffer[];
double ExtMoving02Buffer[];
double ExtMoving03Buffer[];

double Derivata01Buffer[];
double Derivata02Buffer[];
double Derivata03Buffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//--- 1 additional buffer used for counting.
   IndicatorBuffers(6);
   IndicatorDigits(Digits);
//--- set delle 3 bande
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,ExtMoving01Buffer);
   SetIndexShift(0,InpBandsShift);
   SetIndexLabel(0,"SMA " + IntegerToString(Inp01Period));

   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1,ExtMoving02Buffer);
   SetIndexShift(1,InpBandsShift);
   SetIndexLabel(1,"SMA " + IntegerToString(Inp02Period));

   SetIndexStyle(2,DRAW_LINE);
   SetIndexBuffer(2,ExtMoving03Buffer);
   SetIndexShift(2,InpBandsShift);
   SetIndexLabel(2,"SMA " + IntegerToString(Inp03Period));



   SetIndexBuffer(3,Derivata01Buffer);
   SetIndexLabel(3,"D V " + IntegerToString(Inp01Period));
      
   SetIndexBuffer(4,Derivata02Buffer);
   SetIndexLabel(4,"D M " + IntegerToString(Inp02Period));
   
   SetIndexBuffer(5,Derivata03Buffer);
   SetIndexLabel(5,"D L " + IntegerToString(Inp03Period));
      
   if(Inp01Period<=0)
     {
      Print("Wrong input parameter Bands Period=",Inp01Period);
      return(INIT_FAILED);
     }
//---
   SetIndexDrawBegin(0,Inp01Period+InpBandsShift);
   SetIndexDrawBegin(1,Inp02Period+InpBandsShift);
   SetIndexDrawBegin(2,Inp03Period+InpBandsShift);
   
 //  SetIndexDrawBegin(3,Inp03Period+InpBandsShift);
 //--- initialization done
   return(INIT_SUCCEEDED);
  }
  
  
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   for(int i=ObjectsTotal()-1; i>=0; i--)
     {
      string label=ObjectName(i);
      if(StringSubstr(label,0,8)!="volkSign")
         continue;
      ObjectDelete(label);
     }
   return(0);
  }
  
  
  
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int i,pos;
   int numPos,numNeg;
   int numOldPos=0,numOldNeg=0;
   bool isMod;
//---
   if(rates_total<=Inp01Period || Inp01Period<=0)
      return(0);
   if(rates_total==prev_calculated)
      return(rates_total);
//--- counting from 0 to rates_total
   ArraySetAsSeries(ExtMoving01Buffer,false);
   ArraySetAsSeries(ExtMoving02Buffer,false);
   ArraySetAsSeries(ExtMoving03Buffer,false);
   
   ArraySetAsSeries(Derivata01Buffer,false);
   ArraySetAsSeries(Derivata02Buffer,false);
   ArraySetAsSeries(Derivata03Buffer,false);
   
   ArraySetAsSeries(close,false);
   
//--- initial zero
   if(prev_calculated<1)
     {
      for(i=0; i<Inp01Period; i++)
        {
         ExtMoving01Buffer[i]=EMPTY_VALUE;       
        }
       for(i=0; i<Inp02Period; i++)
        {
         ExtMoving02Buffer[i]=EMPTY_VALUE;       
        }
      for(i=0; i<Inp03Period; i++)
        {
         ExtMoving03Buffer[i]=EMPTY_VALUE;       
        }
     }
//--- starting calculation
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
      pos=0;
//--- main cycle:attenzione all'ordine della sequenza
   for(i=pos; i<rates_total && !IsStopped(); i++)
     {
      
         ExtMoving01Buffer[i]=NormalizeDouble(SimpleMA(i,Inp01Period,close),Digits);
         ExtMoving02Buffer[i]=NormalizeDouble(SimpleMA(i,Inp02Period,close),Digits);
         ExtMoving03Buffer[i]=NormalizeDouble(SimpleMA(i,Inp03Period,close),Digits);
   /*      if((ExtMoving01Buffer[i]!=0) &&
          (MathAbs(ExtMoving01Buffer[i]-ExtMoving02Buffer[i])/ExtMoving01Buffer[i]<0.0001))
         {
                DrawSimbol(Time[rates_total-i-1],high[rates_total-i-1],
                                  Green,STYLE_DOT,1,i);
   
         }
        */
        if (i>Inp03Period)
        {
            
            Derivata01Buffer[i]=CalculateDerivate(ExtMoving01Buffer,i);
            Derivata02Buffer[i]=CalculateDerivate(ExtMoving02Buffer,i);
            Derivata03Buffer[i]=CalculateDerivate(ExtMoving03Buffer,i);
            
            GetNumSign(Derivata01Buffer[i],Derivata02Buffer[i],Derivata03Buffer[i],numPos, numNeg);
            GetNumSign(Derivata01Buffer[i-1],Derivata02Buffer[i-1],Derivata03Buffer[i-1],numOldPos, numOldNeg);
 
            isMod=false;    
            if((numNeg!=numOldNeg)||(numPos!=numOldPos))
            {
              
               isMod=true;
            }  
                

            //if ((numPos<3)&&(numOldPos==3)&& isMod)
            int cambi=0;
            if(SignChanged(Derivata01Buffer,i))  
            {
               cambi=2;
            }
            if(SignChanged(Derivata02Buffer,i))  
            {
               cambi=cambi | 4;
            }           
            //if(SignChanged(Derivata01Buffer,i))      
            if (cambi >0)      
            {
                 // DrawSimbol(Time[rates_total-i-1],low[rates_total-i-1],  Blue,STYLE_DOT,2,i);
                 DrawSimbol(Time[rates_total-i-1],low[rates_total-i-1],  Blue,STYLE_DOT,cambi,i);
      
            }
            /*if ((numNeg<3)&&(numOldNeg==3)&& isMod)
            {
                  DrawSimbol(Time[rates_total-i-1],low[rates_total-i-1],
                               Blue,STYLE_DOT,2,i);
      
            }*/
         
            if ((numPos==3)&& isMod)//allineamento crescente
            {
                  DrawSimbol(Time[rates_total-i-1],low[rates_total-i-1],
                               Green,STYLE_DOT,1,i);
      
            }
            if ((numNeg==3)&& isMod)//allineamento decrescente
            {
                  DrawSimbol(Time[rates_total-i-1],low[rates_total-i-1],
                               Red,STYLE_DOT,0,i);
      
            }
            
        }
     }
//---- OnCalculate done. Return new prev_calculated.
     return(rates_total);
  }




  
  void DrawSimbol(datetime x1,double y1,
                  color lineColor,double style,int direction,int idx)
  {
   int indicatorWindow=0;//WindowFind(indicatorName);
   if(indicatorWindow<0) return;
   bool created;

   string labelArrow="volkSign#"+DoubleToStr(x1,0)+"-"+DoubleToStr(y1,0);// IntegerToString(idx);  
  
   if(direction==1)
   {
      created=ObjectCreate(labelArrow,OBJ_ARROW,indicatorWindow,x1,y1,0,0);
      ObjectSet(labelArrow,OBJPROP_COLOR,lineColor);
      ObjectSet(labelArrow,OBJPROP_ARROWCODE,SYMBOL_ARROWUP);
   }
   else if(direction==0)
   {
      created=ObjectCreate(labelArrow,OBJ_ARROW,indicatorWindow,x1,y1);
      ObjectSet(labelArrow,OBJPROP_COLOR,lineColor);
      ObjectSet(labelArrow,OBJPROP_ARROWCODE,SYMBOL_ARROWDOWN);
   }
    else if((direction & 2)!=0)
   {
      created=ObjectCreate(labelArrow,OBJ_ARROW,indicatorWindow,x1,y1);
      ObjectSet(labelArrow,OBJPROP_COLOR,indicator_color1);
      ObjectSet(labelArrow,OBJPROP_ARROWCODE,SYMBOL_STOPSIGN);
   }
   else if((direction & 4)!=0)
   {
      created=ObjectCreate(labelArrow,OBJ_ARROW,indicatorWindow,x1,y1);
      ObjectSet(labelArrow,OBJPROP_COLOR,indicator_color2);
      ObjectSet(labelArrow,OBJPROP_ARROWCODE,SYMBOL_STOPSIGN);
   }  
 
  }
  
  
  
  
  double CalculateDerivate(double &arr[] ,int idx)
  {
      return (NormalizeDouble(arr[idx]-arr[idx-1],Digits));
  }
  
  //considerato positivo anche i nulli
   bool SignChanged(double &arr[] ,int idx)
  {
      if (arr[idx]>=0 )
      {
         if (arr[idx-1]<0)
            return (true);
      }
      else
      {
         if (arr[idx-1]>=0)
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
  