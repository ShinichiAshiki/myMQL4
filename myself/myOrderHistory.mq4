//+------------------------------------------------------------------+
//|                                               myOrderHIstory.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

#define BTN_O (79)

// input
input int in_TradeHistoryCount = 100; // 描画数
// const
const string c_objEntry= "Entry";
const string c_objLots= "Lots";
const string c_objExit= "Exit";
const string c_objTradeLine= "TradeLine";
const string c_objProfit= "Profit";
const string c_objNowEntry= "NowEntry";
const string c_objNowLots= "NowLots";
//global
bool g_flg_drawOnClick = false;

int OnInit(){
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
   
   string objEntry, objLots, objExit, objTrendline, objProfit, objNowEntry, objNowLots;
   
   for(int i = 0; i < OrdersHistoryTotal(); i++) {
      objEntry = StringConcatenate(c_objEntry,IntegerToString(i));
      objLots = StringConcatenate(c_objLots,IntegerToString(i));
      objExit = StringConcatenate(c_objExit,IntegerToString(i));
      objTrendline = StringConcatenate(c_objTradeLine,IntegerToString(i));
      objProfit = StringConcatenate(c_objProfit,IntegerToString(i));
      objNowEntry = StringConcatenate(c_objNowEntry,IntegerToString(i));
      objNowLots = StringConcatenate(c_objNowLots,IntegerToString(i));
      if(ObjectFind(objEntry) != -1)ObjectDelete(objEntry);
      if(ObjectFind(objLots) != -1)ObjectDelete(objLots);
      if(ObjectFind(objExit) != -1)ObjectDelete(objExit);
      if(ObjectFind(objTrendline) != -1)ObjectDelete(objTrendline);
      if(ObjectFind(objProfit) != -1)ObjectDelete(objProfit);
      if(ObjectFind(objNowEntry) != -1)ObjectDelete(objNowEntry);
      if(ObjectFind(objNowLots) != -1)ObjectDelete(objNowLots);
   }
}
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   double DrawPtLots;
   string objNowEntry, objNowLots;
   int i;
   Comment("");
   if(id == CHARTEVENT_KEYDOWN){
      if (lparam == BTN_O) g_flg_drawOnClick = true;
      else g_flg_drawOnClick = false;
   }else if(g_flg_drawOnClick && id == CHARTEVENT_CLICK){
      f_drawTradeHistory(in_TradeHistoryCount);
       g_flg_drawOnClick = false;  // Reset after drawing
   }else if(id == CHARTEVENT_CLICK){
      if(OrdersTotal() > 0){
         for(i = 0; i < OrdersTotal(); i++){// Draw position
            objNowEntry = StringConcatenate(c_objNowEntry,IntegerToString(i));
            objNowLots = StringConcatenate(c_objNowLots,IntegerToString(i));
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && (OrderSymbol() == Symbol())) {
               if(ObjectFind(objNowEntry) != 1){
                  // Draw entry arrow
                  objNowEntry = StringConcatenate(c_objNowEntry,IntegerToString(i));
                  ObjectCreate(0, objNowEntry, OBJ_ARROW, 0, OrderOpenTime(), OrderOpenPrice());
                  ObjectSetInteger(0, objNowEntry, OBJPROP_COLOR, clrMediumSpringGreen);
                  ObjectSetInteger(0, objNowEntry, OBJPROP_WIDTH, 2);
               }   
               // Draw entry lot
               if(ObjectFind(objNowLots) != 1){
                  // Calculate Y coordinate
                  DrawPtLots = ((double)(int)(OrderOpenPrice() * MathPow(10, Digits - 1) + 1.0)) / (MathPow(10, Digits - 1));
                  objNowLots = StringConcatenate(c_objLots,IntegerToString(i));
                  ObjectCreate(0, objNowLots, OBJ_TEXT, 0, OrderOpenTime(), DrawPtLots);
                  ObjectSetInteger(0, objNowLots, OBJPROP_COLOR, clrMediumSpringGreen);
                  ObjectSetInteger(0, objNowLots,OBJPROP_FONTSIZE,8);
                  ObjectSetInteger(0, objNowLots, OBJPROP_WIDTH, 2);
                  ObjectSetInteger(0, objNowLots,OBJPROP_BACK,true);
                  ObjectSetString(0, objNowLots,OBJPROP_TEXT, DoubleToString(OrderLots(),2));
               }   
            }
         }
      }else{
         for(i = 0; i < OrdersHistoryTotal(); i++){
            objNowEntry = StringConcatenate(c_objNowEntry,IntegerToString(i));
            objNowLots = StringConcatenate(c_objNowLots,IntegerToString(i));
            if(ObjectFind(objNowEntry) != -1)ObjectDelete(objNowEntry);
            if(ObjectFind(objNowLots) != -1)ObjectDelete(objNowLots);
         }
      }
   }else{
      ;
   }
}

void f_drawTradeHistory(int drawCount){
   int tradesDisplayed = 0;
   
   // Loop through the history to find past trades
   for(int i = OrdersHistoryTotal() - 1; i >= 0 && tradesDisplayed < drawCount; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
      {
         double entryPrice = OrderOpenPrice();
         double exitPrice = OrderClosePrice();
         datetime entryTime = OrderOpenTime();
         datetime exitTime = OrderCloseTime();
         color entryColor, exitColor;

         // Determine colors based on order type
         if(OrderType() == OP_BUY)
         {
            entryColor = clrRed;
            exitColor = clrBlue;
         }
         else if(OrderType() == OP_SELL)
         {
            entryColor = clrBlue;
            exitColor = clrRed;
         }
         else
            continue;

         // Draw entry arrow
         string objEntry = StringConcatenate(c_objEntry,IntegerToString(i));
         ObjectCreate(0, objEntry, OBJ_ARROW, 0, entryTime, entryPrice);
         ObjectSetInteger(0, objEntry, OBJPROP_COLOR, entryColor);
         ObjectSetInteger(0, objEntry, OBJPROP_WIDTH, 2);

         // Draw entry lot
         double DrawPtLots = ((double)(int)(OrderOpenPrice() * MathPow(10, Digits - 1) + 1.0)) / (MathPow(10, Digits - 1));
         string objLots = StringConcatenate(c_objLots,IntegerToString(i));
         ObjectCreate(0, objLots, OBJ_TEXT, 0, entryTime, DrawPtLots);
         ObjectSetInteger(0, objLots, OBJPROP_COLOR, entryColor);
         ObjectSetInteger(0, objLots,OBJPROP_FONTSIZE,8);
         ObjectSetInteger(0, objLots, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, objLots,OBJPROP_BACK,true);
         ObjectSetString(0, objLots,OBJPROP_TEXT, DoubleToString(OrderLots(), 2));
                
         // Draw exit arrow
         string objExit = StringConcatenate(c_objExit,IntegerToString(i));
         ObjectCreate(0, objExit, OBJ_ARROW, 0, exitTime, exitPrice);
         ObjectSetInteger(0, objExit, OBJPROP_COLOR, exitColor);
         ObjectSetInteger(0, objExit, OBJPROP_WIDTH, 2);
         
         // Draw dot trendline from entry to exit
         string objTrendline = StringConcatenate(c_objTradeLine,IntegerToString(i));
         ObjectCreate(0, objTrendline, OBJ_TREND, 0, entryTime, entryPrice, exitTime, exitPrice);
         ObjectSetInteger(0, objTrendline, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, objTrendline, OBJPROP_COLOR, exitColor);
         ObjectSetInteger(0, objTrendline, OBJPROP_RAY_LEFT, false);
         ObjectSetInteger(0, objTrendline, OBJPROP_RAY_RIGHT, false);
         ObjectSetInteger(0, objTrendline, OBJPROP_WIDTH, 1);

         // Draw pips
         string objProfit = StringConcatenate(c_objProfit,IntegerToString(i));
         double resultPips = MathAbs((OrderOpenPrice() - OrderClosePrice()) * MathPow(10, Digits - 1));
         double DrawPtProfit = ((double)(int)(OrderClosePrice() * MathPow(10, Digits - 1) + 1.0)) / (MathPow(10, Digits - 1));
         ObjectCreate(0, objProfit, OBJ_TEXT, 0, OrderCloseTime(), DrawPtProfit);
         if(OrderProfit() < 0)resultPips = resultPips * (-1);
         ObjectSetInteger(0, objProfit,OBJPROP_COLOR,clrRed);
         ObjectSetInteger(0, objProfit,OBJPROP_FONTSIZE,8);
         ObjectSetInteger(0, objProfit,OBJPROP_BACK,true);
         //ObjectSetString(0,objProfit,OBJPROP_TEXT, DoubleToString(OrderProfit(),0));//損益額
         ObjectSetString(0, objProfit,OBJPROP_TEXT, DoubleToString(resultPips, 2));

         tradesDisplayed++;
      }
   }
}

void start(){
}
