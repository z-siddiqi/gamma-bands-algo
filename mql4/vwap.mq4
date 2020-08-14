//+---------------------------------------------------------------------------+
//|                                                                  vwap.mq4 |
//|                                             www.twitter.com/zainuddinsidd |
//|                                                                           |
//|                VWAP implementation is based on Market_Statistics_v4_2.mq4 |
//+---------------------------------------------------------------------------+
#property version "1.00"
#property strict

#property indicator_chart_window

#property indicator_buffers 7

#property indicator_color1 Black       // VWAP
#property indicator_width1 1

#property indicator_color2 Black       // SD1Pos
#property indicator_width2 1
#property indicator_style2 2

#property indicator_color3 Black       // SD1Neg
#property indicator_width3 1
#property indicator_style3 2

#property indicator_color4 Black       // SD2Pos
#property indicator_width4 1
#property indicator_style4 2

#property indicator_color5 Black       // SD2Neg
#property indicator_width5 1
#property indicator_style5 2

#property indicator_color6 Black       // SD3Pos
#property indicator_width6 1
#property indicator_style6 2

#property indicator_color7 Black       // SD3Neg
#property indicator_width7 1
#property indicator_style7 2

//---- input parameters
extern double  Pos_SD1 = 0.00;
extern double  Pos_SD2 = 0.00;
extern double  Pos_SD3 = 0.00;
extern double  Neg_SD1 = 0.00;
extern double  Neg_SD2 = 0.00;
extern double  Neg_SD3 = 0.00;
extern int     days_back = 1;
extern int     start_hour = 22;
extern int     start_minute = 00;

//---- visualisation parameters
bool           Show_VWAP = true;
bool           Show_SD1 = true;
bool           Show_SD2 = true;
bool           Show_SD3 = true;

//---- buffers
double VWAP[];
double SD1Pos[];
double SD1Neg[];
double SD2Pos[];
double SD2Neg[];
double SD3Pos[];
double SD3Neg[];
double Hist[];

double   open_time = 0;
string   OBJECT_PREFIX = "VolumeHistogram_";
int      items;
int      bars_back = 0;

//+------------------------------------------------------------------+
//| Find the Bar Number for the Given Date                           |
//+------------------------------------------------------------------+
int FindStartIndex()
  {
   int day_of_week_today = TimeDayOfWeek(Time[0]);
   int days = 0;

   for(int i = 1; i <= Bars; i++)
     {

      if((TimeDayOfWeek(Time[i]) != day_of_week_today) || (days_back == 0))
        {
         days++;
         day_of_week_today = TimeDayOfWeek(Time[i]);

         if((days_back == days) || (days_back == 0))
           {
            while((TimeHour(Time[i]) > start_hour) || (TimeMinute(Time[i]) > start_minute))
              {
               i++;
              }
            ObjectSet("Starting_Time", OBJPROP_TIME1, Time[i]);
            ObjectSet("Starting_Time", OBJPROP_COLOR, Black);
            ObjectCreate("Starting_Time", OBJ_VLINE, 0, Time[i], 0);
            return (i);
           }
        }
     }

   return(0);
  }

//+------------------------------------------------------------------+
//| Help Set Indicator Styling                                       |
//+------------------------------------------------------------------+
void StyleHelper(bool show, int index, string label, double& buffer[])
  {
   if(show == true)
      SetIndexStyle(index, DRAW_LINE);
   else
      SetIndexStyle(index, DRAW_NONE);
   
   SetIndexLabel(index, label);
   SetIndexBuffer(index, buffer);
  }

//+------------------------------------------------------------------+
//| Indicator Init Function                                          |
//+------------------------------------------------------------------+
int init()
  {
   OBJECT_PREFIX = OBJECT_PREFIX + DoubleToStr(Time[FindStartIndex()], 0) + "_";

   IndicatorBuffers(7);
   
   StyleHelper(Show_VWAP, 0, "VWAP", VWAP);
   StyleHelper(Show_SD1, 1, "SD1Pos", SD1Pos);
   StyleHelper(Show_SD1, 2, "SD1Neg", SD1Neg);
   StyleHelper(Show_SD2, 3, "SD2Pos", SD2Pos);
   StyleHelper(Show_SD2, 4, "SD2Neg", SD2Neg);
   StyleHelper(Show_SD3, 5, "SD3Pos", SD3Pos);
   StyleHelper(Show_SD3, 6, "SD3Neg", SD3Neg);

   string short_name = "VWAP";
   IndicatorShortName(short_name);

   return(0);
  }

//+------------------------------------------------------------------+
//| Delete All Objects With Given Prefix                             |
//+------------------------------------------------------------------+
void DeleteObjectsByPrefix(string Prefix)
  {
   int L = StringLen(Prefix);
   int i = 0;
   while(i < ObjectsTotal())
     {
      string object_name = ObjectName(i);
      if(StringSubstr(object_name, 0, L) != Prefix)
        {
         i++;
         continue;
        }
      ObjectDelete(object_name);
     }
  }

//+------------------------------------------------------------------+
//| Indicator Start Function                                         |
//+------------------------------------------------------------------+
int start()
  {
   double total_volume = 0;
   double total_pv = 0;
   int n;

   if(open_time != Time[0])
     {
      bars_back = FindStartIndex();
      if(bars_back != 0)
        {
         ObjectSet("Starting_Time", OBJPROP_TIME1, Time[bars_back]);
         ObjectSet("Starting_Time", OBJPROP_COLOR, Black);
         ObjectCreate("Starting_Time", OBJ_VLINE, 0, Time[bars_back], 0);
        }

      open_time = Time[0];

      double max = High[iHighest(NULL, 0, MODE_HIGH, bars_back, 0)];
      double min =  Low[iLowest(NULL, 0, MODE_LOW,  bars_back, 0)];
      items = MathRound((max - min) / Point);

      ArrayResize(Hist, items);
      ArrayInitialize(Hist, 0);

      total_volume = 0;
      total_pv = 0;
      for(int i = bars_back; i >= 1; i--)
        {
         double t1 = Low[i], t2 = Open[i], t3 = Close[i], t4 = High[i];
         if(t2 > t3)
           {
            t3 = Open[i];
            t2 = Close[i];
           }
         double total_range = 2 * (t4 - t1) - t3 + t2;

         if(total_range != 0.0)
           {
            for(double price_i = t1; price_i <= t4; price_i += Point)
              {
               n = MathRound((price_i - min) / Point);

               if(t1 <= price_i && price_i < t2)
                 {
                  Hist[n] += MathRound(Volume[i] * 2 * (t2 - t1) / total_range);
                 }
               if(t2 <= price_i && price_i <= t3)
                 {
                  Hist[n] += MathRound(Volume[i] * (t3 - t2) / total_range);
                 }
               if(t3 < price_i && price_i <= t4)
                 {
                  Hist[n] += MathRound(Volume[i] * 2 * (t4 - t3) / total_range);
                 }
              }
           }
         else
           {
            n = MathRound((t3 - min) / Point);
            Hist[n] += Volume[i];
           }

         // Use H + L + C / 3 as average price
         total_pv += Volume[i] * ((Low[i] + High[i] + Close[i]) / 3);
         total_volume += Volume[i];

         if(i == bars_back)
            VWAP[i] = Close[i];
         else
            VWAP[i] = total_pv / total_volume;

         SD1Pos[i] = VWAP[i] + (Pos_SD1 * Point * 10);
         SD1Neg[i] = VWAP[i] - (Neg_SD1 * Point * 10);
         SD2Pos[i] = VWAP[i] + (Pos_SD2 * Point * 10);
         SD2Neg[i] = VWAP[i] - (Neg_SD2 * Point * 10);
         SD3Pos[i] = VWAP[i] + (Pos_SD3 * Point * 10);
         SD3Neg[i] = VWAP[i] - (Neg_SD3 * Point * 10);
        }

      DeleteObjectsByPrefix(OBJECT_PREFIX);
     }

   return(0);
  }

//+------------------------------------------------------------------+
//| Indicator Deinit Function                                        |
//+------------------------------------------------------------------+
int deinit()
  {
   DeleteObjectsByPrefix(OBJECT_PREFIX);
   ObjectDelete("Starting_Time");

   return(0);
  }
  