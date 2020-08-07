//+---------------------------------------------------------------------------+
//|                                                                  vwap.mq4 |
//|                                             www.twitter.com/zainuddinsidd |
//|                                                                           |
//|                VWAP implementation is based on Market_Statistics_v4_2.mq4 |
//+---------------------------------------------------------------------------+
#property version "1.00"
#property strict

#property indicator_chart_window

#property indicator_buffers 8

#property indicator_color1 Black       // PVP
#property indicator_width1 1

#property indicator_color2 Black       // VWAP
#property indicator_width2 1

#property indicator_color3 Black       // SD1Pos
#property indicator_width3 1
#property indicator_style3 2

#property indicator_color4 Black       // SD1Neg
#property indicator_width4 1
#property indicator_style4 2

#property indicator_color5 Black       // SD2Pos
#property indicator_width5 1
#property indicator_style5 2

#property indicator_color6 Black       // SD2Neg
#property indicator_width6 1
#property indicator_style6 2

#property indicator_color7 Black       // SD3Pos
#property indicator_width7 1
#property indicator_style7 2

#property indicator_color8 Black       // SD3Neg
#property indicator_width8 1
#property indicator_style8 2


//---- input parameters
extern double  Pos_SD1 = 0.00;
extern double  Pos_SD2 = 0.00;
extern double  Pos_SD3 = 0.00;
extern double  Neg_SD1 = 0.00;
extern double  Neg_SD2 = 0.00;
extern double  Neg_SD3 = 0.00;

//---- visualisation parameters
bool           Show_VWAP = true;
bool           Show_SD1 = true;
bool           Show_SD2 = true;
bool           Show_SD3 = true;
bool           Show_PVP = false;
bool           Show_Histogram = false;
int            HistogramAmplitude = 50;

//---- buffers
double PVP[];
double VWAP[];
double SD1Pos[];
double SD1Neg[];
double SD2Pos[];
double SD2Neg[];
double SD3Pos[];
double SD3Neg[];
double Hist[];

double   OpenTime = 0;
string   OBJECT_PREFIX = "VolumeHistogram_";
int      items;
int      Bars_Back = 0;

//+------------------------------------------------------------------+
//| Find the Bar Number for the Given Date                           |
//+------------------------------------------------------------------+
int FindStartIndex()
  {
   return(0);
  }

//+------------------------------------------------------------------+
//| Indicator Init Function                                          |
//+------------------------------------------------------------------+
int init()
  {
   OBJECT_PREFIX = OBJECT_PREFIX + DoubleToStr(Time[FindStartIndex()], 0) + "_";

   IndicatorBuffers(8);

   if(Show_PVP == true)
      SetIndexStyle(0, DRAW_LINE);
   else
      SetIndexStyle(0, DRAW_NONE);
   
   SetIndexLabel(0, "PVP");
   SetIndexBuffer(0, PVP);

   if(Show_VWAP == true)
      SetIndexStyle(1, DRAW_LINE);
   else
      SetIndexStyle(1, DRAW_NONE);
   
   SetIndexLabel(1, "VWAP");
   SetIndexBuffer(1, VWAP);

   if(Show_SD1 == true)
      SetIndexStyle(2, DRAW_LINE);
   else
      SetIndexStyle(2, DRAW_NONE);
   
   SetIndexLabel(2, "SD1Pos");
   SetIndexBuffer(2, SD1Pos);

   if(Show_SD1 == true)
      SetIndexStyle(3, DRAW_LINE);
   else
      SetIndexStyle(3, DRAW_NONE);
   
   SetIndexLabel(3, "SD1Neg");
   SetIndexBuffer(3, SD1Neg);

   if(Show_SD2 == true)
      SetIndexStyle(4, DRAW_LINE);
   else
      SetIndexStyle(4, DRAW_NONE);
   
   SetIndexLabel(4, "SD2Pos");
   SetIndexBuffer(4, SD2Pos);

   if(Show_SD2 == true)
      SetIndexStyle(5, DRAW_LINE);
   else
      SetIndexStyle(5, DRAW_NONE);
   
   SetIndexLabel(5, "SD2Neg");
   SetIndexBuffer(5, SD2Neg);

   if(Show_SD3 == true)
      SetIndexStyle(6, DRAW_LINE);
   else
      SetIndexStyle(6, DRAW_NONE);
   
   SetIndexLabel(6, "SD3Pos");
   SetIndexBuffer(6, SD3Pos);

   if(Show_SD3 == true)
      SetIndexStyle(7, DRAW_LINE);
   else
      SetIndexStyle(7, DRAW_NONE);
   
   SetIndexLabel(7, "SD3Neg");
   SetIndexBuffer(7, SD3Neg);

   string short_name = "VWAP";
   IndicatorShortName(short_name);

   return(0);
  }

//+------------------------------------------------------------------+
//| Delete All Objects With Given Prefix                             |
//+------------------------------------------------------------------+
void DeleteObjectsByPrefix(string Prefix)
  {
  }

//+------------------------------------------------------------------+
//| Indicator Start Function                                         |
//+------------------------------------------------------------------+
int start()
  {
   double TotalVolume = 0;
   double TotalPV = 0;
   int n;

   if(OpenTime != Time[0])
     {
      Bars_Back = FindStartIndex();
      if(Bars_Back != 0)
        {
         ObjectSet("Starting_Time", OBJPROP_TIME1, Time[Bars_Back]);
         ObjectSet("Starting_Time", OBJPROP_COLOR, Black);
         ObjectCreate("Starting_Time", OBJ_VLINE, 0, Time[Bars_Back], 0);
        }

      OpenTime = Time[0];

      double max = High[iHighest(NULL, 0, MODE_HIGH, Bars_Back, 0)];
      double min =  Low[iLowest(NULL, 0, MODE_LOW,  Bars_Back, 0)];
      items = MathRound((max - min) / Point);

      ArrayResize(Hist, items);
      ArrayInitialize(Hist, 0);

      TotalVolume = 0;
      TotalPV = 0;
      for(int i = Bars_Back; i >= 1; i--)
        {
         double t1 = Low[i], t2 = Open[i], t3 = Close[i], t4 = High[i];
         if(t2 > t3)
           {
            t3 = Open[i];
            t2 = Close[i];
           }
         double totalRange = 2 * (t4 - t1) - t3 + t2;

         if(totalRange != 0.0)
           {
            for(double Price_i = t1; Price_i <= t4; Price_i += Point)
              {
               n = MathRound((Price_i - min) / Point);

               if(t1 <= Price_i && Price_i <  t2)
                 {
                  Hist[n] += MathRound(Volume[i] * 2 * (t2 - t1) / totalRange);
                 }
               if(t2 <= Price_i && Price_i <= t3)
                 {
                  Hist[n] += MathRound(Volume[i] * (t3 - t2) / totalRange);
                 }
               if(t3 < Price_i && Price_i <= t4)
                 {
                  Hist[n] += MathRound(Volume[i] * 2 * (t4 - t3) / totalRange);
                 }
              }
           }
         else
           {
            n = MathRound((t3 - min) / Point);
            Hist[n] += Volume[i];
           }

         // Use H + L + C / 3 as average price
         TotalPV += Volume[i] * ((Low[i] + High[i] + Close[i]) / 3);
         TotalVolume += Volume[i];

         if(i == Bars_Back)
            PVP[i] = Close[i];
         else
            PVP[i] = min + ArrayMaximum(Hist) * Point;

         if(i == Bars_Back)
            VWAP[i] = Close[i];
         else
            VWAP[i] = TotalPV / TotalVolume;

         SD1Pos[i] = VWAP[i] + (Pos_SD3 * Point * 10);
         SD1Neg[i] = VWAP[i] - (Neg_SD3 * Point * 10);
         SD2Pos[i] = VWAP[i] + (Pos_SD2 * Point * 10);
         SD2Neg[i] = VWAP[i] - (Neg_SD2 * Point * 10);
         SD3Pos[i] = VWAP[i] + (Pos_SD1 * Point * 10);
         SD3Neg[i] = VWAP[i] - (Neg_SD1 * Point * 10);
        }

      DeleteObjectsByPrefix(OBJECT_PREFIX);

      if(Show_Histogram)
        {
         int MaxVolume = Hist[ArrayMaximum(Hist)];
         int multiplier;
         for(int i = 0; i <= items; i++)
           {
            if(Bars_Back < HistogramAmplitude)
               multiplier = Bars_Back;
            else
               multiplier = HistogramAmplitude;

            if(MaxVolume != 0)
               Hist[i] = MathRound(multiplier * Hist[i] / MaxVolume);

            if(Hist[i] > 0)
              {
               int time_i = Bars_Back - Hist[i];
               if(time_i >= 0)
                 {
                  ObjectCreate(OBJECT_PREFIX + i, OBJ_RECTANGLE, 0, Time[Bars_Back], min + i * Point, Time[time_i], min + (i + 1) * Point);
                  ObjectSet(OBJECT_PREFIX + i, OBJPROP_STYLE, DRAW_HISTOGRAM);
                  ObjectSet(OBJECT_PREFIX + i, OBJPROP_COLOR, Teal);
                  ObjectSet(OBJECT_PREFIX + i, OBJPROP_BACK, true);
                 }
              }
           }
        }
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
  