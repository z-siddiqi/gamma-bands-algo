//+---------------------------------------------------------------------------+
//|                                                                  vwap.mq4 |
//|                                             www.twitter.com/zainuddinsidd |
//|                                                                           |
//|                VWAP implementation is based on Market_Statistics_v4_2.mq4 |
//+---------------------------------------------------------------------------+
#property version   "1.00"
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
