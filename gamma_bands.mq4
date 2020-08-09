//+---------------------------------------------------------------------------+
//|                                                           gamma_bands.mq4 |
//|                                             www.twitter.com/zainuddinsidd |
//|                                                                           |
//|      Gamma bands explained: www.macrohedged.com/store/p4/gammamodule.html |
//+---------------------------------------------------------------------------+
#property version "1.00"
#property strict

//--- VWAP band params
// These values change daily and are based on options flow
extern double  Pos_SD1 = 0.00;
extern double  Pos_SD2 = 0.00;
extern double  Pos_SD3 = 0.00;
extern double  Neg_SD1 = 0.00;
extern double  Neg_SD2 = 0.00;
extern double  Neg_SD3 = 0.00;

//--- money management
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
//| Check How Many Bars Closed Above Upper Band                      |
//+------------------------------------------------------------------+
int SellCheck()
  {
   int above_band = 0;

   // Get gamma band value from VWAP indicator
   double PosBand3 = NormalizeDouble(iCustom(Symbol(), 5, "VWAP", Pos_SD1, Pos_SD2, Pos_SD3, Neg_SD1, Neg_SD2, Neg_SD3, 6, 1), 5);

   // Scan the previous bars
   for(int i = 2; i <= 12; i++)
     {
      if(Close[i] > PosBand3)
        {
         above_band += 1;
        }
     }
    
   return above_band;
  }

//+------------------------------------------------------------------+
//| Check How Many Bars Closed Below Lower Band                      |
//+------------------------------------------------------------------+
int BuyCheck()
  {
   int below_band = 0;

   // Get gamma band value from VWAP indicator
   double NegBand3 = NormalizeDouble(iCustom(Symbol(), 5, "VWAP", Pos_SD1, Pos_SD2, Pos_SD3, Neg_SD1, Neg_SD2, Neg_SD3, 7, 1), 5);

   // Scan the previous bars
   for(int i = 2; i <= 12; i++)
     {
      if(Close[i] < NegBand3)
        {
         below_band += 1;
        }
     }
    
   return below_band;
  }

//+------------------------------------------------------------------+
//| Determine if Any Orders Should Be Opened                         |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
   bool time_in_range = TimeCheck(TimeCurrent(), start_time_hour, start_time_minute, 16, 45, 2);

   if(time_in_range && OrdersTotal() < 1)
     {
      bool res;

      // Get gamma band values from VWAP indicator
      double VWAP = NormalizeDouble(iCustom(Symbol(), 5, "VWAP", Pos_SD1, Pos_SD2, Pos_SD3, Neg_SD1, Neg_SD2, Neg_SD3, 1, 1), 5);
      double PosBand3 = NormalizeDouble(iCustom(Symbol(), 5, "VWAP", Pos_SD1, Pos_SD2, Pos_SD3, Neg_SD1, Neg_SD2, Neg_SD3, 6, 1), 5);
      double NegBand3 = NormalizeDouble(iCustom(Symbol(), 5, "VWAP", Pos_SD1, Pos_SD2, Pos_SD3, Neg_SD1, Neg_SD2, Neg_SD3, 7, 1), 5);
      
      // Sell conditions
      if(SellCheck() < 1 && Close[1] < PosBand3 && (Bid + Ask) / 2 > PosBand3)
         {
          res = OrderSend(Symbol(), OP_SELL, mm(RISK_PERCENT, (CalcStopLoss(PosBand3, 200) - Bid) * 10, 0.005), Bid, 0, CalcStopLoss(PosBand3, 200), VWAP, NULL, 1);
         }
      
      // Buy conditions
      if(BuyCheck() < 1 && Close[1] > NegBand3 && (Bid + Ask) / 2 < NegBand3)
         {
          res = OrderSend(Symbol(), OP_BUY, mm(RISK_PERCENT, (Ask - CalcStopLoss(NegBand3, -200)) * 10, 0.005), Ask, 0, CalcStopLoss(NegBand3, -200), VWAP, NULL, 1);
         } 
     }
  }

//+------------------------------------------------------------------+
//| Modify SL to VWAP                                                |
//+------------------------------------------------------------------+
void ModifyStopLoss()
  {
   double VWAP =  NormalizeDouble(iCustom(Symbol(), 5, "VWAP", Pos_SD1, Pos_SD2, Pos_SD3, Neg_SD1, Neg_SD2, Neg_SD3, 1, 1), 5);
   if(OrdersTotal() != 0)
      {
       if(OrderSelect(0, SELECT_BY_POS, MODE_TRADES) == false)
          Print("ERROR - Unable to select the order - ", GetLastError());
                 
       if(OrderTakeProfit() != VWAP)
          {
           bool res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), VWAP, 0, CLR_NONE);
   
           // If there is an error log it
           if(res == false)
              Print("ERROR - Unable to modify the order - ", OrderTicket(), " - ", GetLastError());
          }
      }
  }

//+------------------------------------------------------------------+
//| Determine if Any Orders Should Be Closed                         |
//+------------------------------------------------------------------+
void CheckForClose()
  {
   bool time_in_range = TimeCheck(TimeCurrent(), start_time_hour, start_time_minute, end_time_hour, end_time_minute, 2);

   if(time_in_range == false)
     {
      // Update the exchange rates before closing the orders
      RefreshRates();

      // The loop starts from the most recent otherwise it would miss orders
      for(int i = (OrdersTotal() - 1); i >= 0; i--)
        {

         // If the order cannot be selected log an error
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false)
           {
            Print("ERROR - Unable to select the order - ", GetLastError());
            break;
           }

         // Create the required variables
         // Result variable to check if the operation is successful or not
         bool res = false;

         int Slippage = 0;

         double BidPrice = MarketInfo(OrderSymbol(), MODE_BID);
         double AskPrice = MarketInfo(OrderSymbol(), MODE_ASK);

         // Closing the order using the correct price depending on the order type
         if(OrderType() == OP_BUY)
           {
            res = OrderClose(OrderTicket(), OrderLots(), BidPrice, Slippage);
           }
         if(OrderType() == OP_SELL)
           {
            res = OrderClose(OrderTicket(), OrderLots(), AskPrice, Slippage);
           }

         // If there is an error log it
         if(res == false)
            Print("ERROR - Unable to close the order - ", OrderTicket(), " - ", GetLastError());
        }
     }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   CheckForOpen();
   CheckForClose();
   ModifyStopLoss();
  }
