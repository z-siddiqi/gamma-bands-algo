//+---------------------------------------------------------------------------+
//|                                                           gamma_bands.mq4 |
//|                                             www.twitter.com/zainuddinsidd |
//|                                                                           |
//|      Gamma bands explained: www.macrohedged.com/store/p4/gammamodule.html |
//+---------------------------------------------------------------------------+
#property version "1.00"
#property strict

//--- money management
extern double    takeprofit = 5;
enum MM
  {
   RISK_PERCENT
  };

//--- trading time params
input int start_time_hour = 08;
input int start_time_minute = 0;
input int end_time_hour = 17;
input int end_time_minute = 00;
input int gmt = 0;

//+------------------------------------------------------------------+
//| Check Time to Determine if Algo should run                       |
//+------------------------------------------------------------------+
bool TimeCheck(datetime time, int start_hour, int start_min, int end_hour, int end_min, int gmt_offset = 0)
  {
   if(gmt_offset != 0)
     {
      start_hour += gmt_offset;
      end_hour += gmt_offset;
     }
   
   if(start_hour > 23)
      start_hour = (start_hour - 23) - 1;
   else
      if(start_hour < 0)
         start_hour = 23 + start_hour + 1;
   
   if(end_hour > 23)
      end_hour = (end_hour - 23) - 1;
   else
      if(end_hour < 0)
         end_hour = 23 + end_hour + 1;
   
   int hour = TimeHour(time);
   int minute = TimeMinute(time);
   int t = (hour * 3600) + (minute * 60);
   int s = (start_hour * 3600) + (start_min * 60);
   int e = (end_hour * 3600) + (end_min * 60);
   
   if(s == e)
      return true;
   else
      if(s < e)
        {
         if(t >= s && t < e)
            return true;
        }
      else
         if(s > e)
           {
            if(t >= s || t < e)
               return true;
           }
   
   return false;
  }
 
//+------------------------------------------------------------------+
//| Calculate Order Stop Loss                                        |
//+------------------------------------------------------------------+
double CalcStopLoss(double band, int gap)
  {
   return(band + gap * Point);
  }

//+------------------------------------------------------------------+
//| Calculate Order Volume Based on Money Management Method          |
//+------------------------------------------------------------------+
double mm(MM method, int sl, double risk_mm1)
  {
   double balance = AccountBalance();
   double tick_value = MarketInfo(Symbol(), MODE_TICKVALUE);
   double volume = 0;
   switch(method)
     {
      case RISK_PERCENT:
         if(sl > 0)
            volume = ((balance * risk_mm1) / sl) / tick_value;
         break;
     }
   double min_lot = MarketInfo(Symbol(), MODE_MINLOT);
   double max_lot = MarketInfo(Symbol(), MODE_MAXLOT);
   int lot_digits = (int) -MathLog10(MarketInfo(Symbol(), MODE_LOTSTEP));
   volume = NormalizeDouble(volume, lot_digits);
   if(volume < min_lot)
      volume = min_lot;
   if(volume > max_lot)
      volume = max_lot;
   return volume;
  }
 
//+------------------------------------------------------------------+
//| Check For Open                                                   |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
  }

//+------------------------------------------------------------------+
//| Check For Close                                                  |
//+------------------------------------------------------------------+
void CheckForClose()
  {
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   CheckForOpen();
   CheckForClose();
  }
