//+------------------------------------------------------------------+
//|                                             myRSINotification.mq4|
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                              https://www.mql5.com|
//+------------------------------------------------------------------+
#property indicator_chart_window

// input parameter
input int rsiPeriod = 14;          // RSI Period
input double rsiOverbought = 70.0; // Overbought level
input double rsiOversold = 30.0;   // Oversold level

// global
bool g_flg_sellOrderReset = true;
bool g_flg_buyOrderReset = true;

int OnInit()
  {
   return(INIT_SUCCEEDED);
  }

int DeInit()
  {
    Comment("");
   return(INIT_SUCCEEDED);
  }

void start()
  {
   // calculation RSI
   double rsiValue = iRSI(NULL, 0, rsiPeriod, PRICE_CLOSE, 0);
   string now = TimeToString(TimeCurrent() + (6 * 60 * 60), TIME_SECONDS);
   Comment("RSI: ", rsiValue);

   // Reset flg 
   if (rsiValue < 50)
      g_flg_sellOrderReset = true;
   if (rsiValue > 50)
      g_flg_buyOrderReset = true;

   if ((rsiValue >= rsiOverbought) && (g_flg_sellOrderReset)) //  Notify when RSI is 70 or Over 
     {
      g_flg_sellOrderReset = false;
      SendNotification(now + ": RSI Over " + rsiOverbought);
     }
   else if ((rsiValue <= rsiOversold) && (g_flg_buyOrderReset)) //  Notify when RSI is 30 or below 
     {
      g_flg_buyOrderReset = false;
      SendNotification(now + ": RSI Under " + rsiOversold);
     }

   return;
  }
