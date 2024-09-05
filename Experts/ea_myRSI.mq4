//+------------------------------------------------------------------+
//|                                                    4Sessions v2.3|
//|                                                   Andrew Kuptsov |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link "https://www.mql5.com"
#property version "1.00"
#property strict
#property indicator_chart_window

// define
#define MAGIC_NUMBER 123456

// input parameter
input int rsiPeriod = 14;          // RSI Period
input double rsiOverbought = 70.0; // Overbought level
input double rsiOversold = 30.0;   // Oversold level
input double lotSize = 0.1;        // Lot size for trades
input int TakeProfitPips = 15;     // Take Profit in pips
input int StopLossPips = 20;       // Stop Loss in pips

// const

// global
bool g_flg_sellOrderReset = false;
bool g_flg_buyOrderReset = false;

int OnInit()
{
   return (INIT_SUCCEEDED);
}

void OnTick()
{

   if (f_chkPosition()) // check if there's already a posision
   {
      return;
   }

   double rsiValue = iRSI(NULL, 0, rsiPeriod, PRICE_CLOSE, 0);
   double sl, tp;

   if (rsiValue < 50)
      g_flg_sellOrderReset = true;
   if (rsiValue > 50)
      g_flg_buyOrderReset = true;
   if ((rsiValue >= rsiOverbought) && (g_flg_sellOrderReset))
   { // RSIが70以上なら売りエントリー
      g_flg_sellOrderReset = false;
      sl = Ask + StopLossPips * 10 * Point;
      tp = Ask - TakeProfitPips * 10 * Point;
      Comment("Ask: ", Ask, " sl:", sl, "  tp: ", tp, " Point: ", Point);
      int ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, 2, sl, tp, "Sell Order", MAGIC_NUMBER, 0, Red);
      if (ticket < 0)
      {
         Print("Sell Order Failed: ", GetLastError());
      }
      else
      {
         Print("Sell Order Placed at RSI: ", rsiValue);
      }
   }
   else if ((rsiValue <= rsiOversold) && (g_flg_buyOrderReset))
   { // RSIが30以下なら買いエントリー
      g_flg_buyOrderReset = false;
      sl = Bid - StopLossPips * 10 * Point;
      tp = Bid + TakeProfitPips * 10 * Point;
      Comment("Bid: ", Bid, " sl:", sl, "  tp: ", tp, " Point: ", Point);
      int ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 2, sl, tp, "Buy Order", MAGIC_NUMBER, 0, Blue);
      if (ticket < 0)
      {
         Print("Buy Order Failed: ", GetLastError());
      }
      else
      {
         Print("Buy Order Placed at RSI: ", rsiValue);
      }
   }
}

bool f_chkPosition()
{
   bool positionExists = false;

   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if (OrderMagicNumber() == MAGIC_NUMBER && OrderSymbol() == Symbol())
         {
            return true;
         }
      }
   }
   return false;
}