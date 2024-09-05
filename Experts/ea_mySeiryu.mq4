//+------------------------------------------------------------------+
//|                                                    my_Seiryu v1.0|
//|                                                   Shinichi Ashiki|
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link "https://www.mql4.com"
#property version "1.00"
#property strict
#property indicator_chart_window

// input parameter
input int in_tpPip = 8;           // 1段利確幅
input int in_maxNampin = 0;       // ナンピンの最大回数
input int in_nanpinPip = 18;      // ナンピン幅(pips)
input double in_nanpinTime = 1.6; // ナンピン倍率
input int in_nanpinInterval = 4;  // ナンピンインターバル(分)

// global
bool g_manualEntry = false; // 手動エントリーフラグ
int g_nampinCount = 0;      // 現在のナンピン回数
int g_latestTicket = 0;     // 最新のポジションチケット番号
int g_slPip = 0;
double g_initialSL;           // 最初のSL
datetime g_lastEntryTime = 0; // 最後のナンピン時間

int OnInit()
{
    g_slPip = in_nanpinPip * (in_maxNampin + 1);
    return (INIT_SUCCEEDED);
}

void OnTick()
{
    // 全ポジション決済するか確認
    if (OrdersTotal() >= 2)
    {
        f_closeAllPositions();
    }
    else if (OrdersTotal() == 0)
    {
        g_manualEntry = false;
        g_latestTicket = 0;
        g_nampinCount = 0;
        g_lastEntryTime = 0;
        // ↓ストラテジテスター用↓
        f_entryByRSI(); // RSIエントリー
        // ↑ストラテジテスター用↑
    }

    // 手動エントリーを検知
    // f_entryByManual();

    // ナンピン確認
    if ((OrdersTotal() > 0) &&
        OrderSelect(g_latestTicket, SELECT_BY_TICKET) &&
        (OrderType() == OP_BUY || OrderType() == OP_SELL))
    {
        double entryPrice = OrderOpenPrice();
        double currentPrice = (OrderType() == OP_BUY) ? Ask : Bid;

        // 価格がin_nanpinPip逆行したかを確認
        Comment("OrderType(): ", OrderType(), " rightValue: ", entryPrice - in_nanpinPip * 10 * Point, " g_latestTicket: ", g_latestTicket);
        if (((OrderType() == OP_BUY) && (currentPrice <= entryPrice - in_nanpinPip * 10 * Point)) ||
            ((OrderType() == OP_SELL) && (currentPrice >= entryPrice + in_nanpinPip * 10 * Point)))
        {
            // ナンピン条件の確認
            if ((g_nampinCount < in_maxNampin) &&
                (TimeCurrent() >= g_lastEntryTime + (in_nanpinInterval * 60)))
            {
                double newLots = OrderLots() * in_nanpinTime;

                // ナンピン注文
                if (OrderType() == OP_BUY)
                {
                    f_orderCheck(OrderSend(Symbol(), OP_BUY, newLots, Ask, 3, g_initialSL, 0, "", 0, 0, Blue), "Order Send");
                }
                else if (OrderType() == OP_SELL)
                {
                    f_orderCheck(OrderSend(Symbol(), OP_SELL, newLots, Bid, 3, g_initialSL, 0, "", 0, 0, Red), "Order Send");
                }

                // TPを解消
                for (int j = OrdersTotal() - 1; j >= 0; j--)
                {
                    if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES))
                    {
                        OrderModify(OrderTicket(), OrderOpenPrice(), g_initialSL, 0, 0, clrNONE);
                    }
                }
            }
        }
    }
}

void f_closeAllPositions()
{
    double totalProfit = 0;
    double totalLots = 0;
    double totalOpenPrice = 0.0;
    double currentPrice = (OrderType() == OP_BUY) ? Bid : Ask;

    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            totalProfit += OrderProfit();
            totalLots += OrderLots();
            totalOpenPrice += OrderOpenPrice() * OrderLots();
        }
    }

    double breakevenPrice = totalOpenPrice / totalLots;
    double targetPrice = (OrderType() == OP_BUY) ? breakevenPrice + (in_tpPip / 2) * 10 * Point : breakevenPrice - (in_tpPip / 2) * 10 * Point;

    if ((OrderType() == OP_BUY && currentPrice >= targetPrice) ||
        (OrderType() == OP_SELL && currentPrice <= targetPrice))
    {
        // すべてのポジションをクローズ
        for (int j = OrdersTotal() - 1; j >= 0; j--)
        {
            if (OrderSelect(j, SELECT_BY_POS, MODE_TRADES))
            {
                f_orderCheck(OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE), "Order Close");
            }
        }
    }
}

void f_orderCheck(int ticket, string orderKind)
{
    if (ticket < 0)
    {
        Print(orderKind + "Failed: ", GetLastError());
    }
    else
    {
        g_latestTicket = ticket;         // 最新のポジションチケット番号更新
        g_nampinCount++;                 // ナンピンカウントを増加
        g_lastEntryTime = TimeCurrent(); // 最新ナンピン時間を保存
        Print("nanpin ticket: ", ticket);
    }
}

void f_entryByManual()
{
    if (!g_manualEntry)
    {
        for (int i = OrdersTotal() - 1; i >= 0; i--)
        {
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                // 魔法数が設定されていない場合（手動エントリーと仮定）
                if (OrderMagicNumber() == 0)
                {
                    double lastEntryPrice = OrderOpenPrice();
                    double sl = 0.0, tp = 0.0;
                    // Buy/Sell ポジションに応じたSL/TP設定
                    if (OrderType() == OP_BUY)
                    {
                        sl = Ask - lastEntryPrice - g_slPip * 10 * Point;
                        tp = Ask + lastEntryPrice + in_tpPip * 10 * Point;
                    }
                    else if (OrderType() == OP_SELL)
                    {
                        sl = Bid + lastEntryPrice + g_slPip * 10 * Point;
                        tp = Bid - lastEntryPrice - in_tpPip * 10 * Point;
                    }

                    // SLとTPの設定
                    f_orderCheck(OrderModify(OrderTicket(), lastEntryPrice, sl, tp, 0, clrNONE), "Order Modify");
                    g_initialSL = sl;                // SLを保存
                    g_lastEntryTime = TimeCurrent(); // エントリー時間の保存
                    g_latestTicket = OrderTicket();  // チケット番号の保存
                    g_manualEntry = true;            // 手動エントリーを検知
                }
            }
        }
    }
}

// ↓ストラテジテスター用↓
bool g_flg_sellOrderReset = false;
bool g_flg_buyOrderReset = false;
#define MAGIC_NUMBER 123456

void f_entryByRSI()
{
    int rsiPeriod = 14;
    int rsiOverbought = 70;
    int rsiOversold = 30;
    double rsiValue = iRSI(NULL, 0, rsiPeriod, PRICE_CLOSE, 0);
    double sl, tp;
    double lotSize = 0.1;

    if (rsiValue < 50)
        g_flg_sellOrderReset = true;
    if (rsiValue > 50)
        g_flg_buyOrderReset = true;
    if ((rsiValue >= rsiOverbought) && (g_flg_sellOrderReset))
    { // RSIが70以上なら売りエントリー
        g_flg_sellOrderReset = false;
        sl = Bid + g_slPip * 10 * Point;
        tp = Bid - in_tpPip * 10 * Point;
        int ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, 2, sl, tp, "Sell Order", MAGIC_NUMBER, 0, Red);
        if (ticket < 0)
        {
            Print("Sell Order Failed: ", GetLastError());
        }
        else
        {
            Print("Sell Order Placed at Bid: ", Bid, " ticket: ", ticket, " sl: ", sl, " tp: ", tp);
            g_initialSL = sl;                // SLを保存
            g_lastEntryTime = TimeCurrent(); // エントリー時間の保存
            g_latestTicket = ticket;         // チケット番号の保存
        }
    }
    else if ((rsiValue <= rsiOversold) && (g_flg_buyOrderReset))
    { // RSIが30以下なら買いエントリー
        g_flg_buyOrderReset = false;
        sl = Ask - g_slPip * 10 * Point;
        tp = Ask + in_tpPip * 10 * Point;
        int ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 2, sl, tp, "Buy Order", MAGIC_NUMBER, 0, Blue);
        if (ticket < 0)
        {
            Print("Buy Order Failed: ", GetLastError());
        }
        else
        {
            Print("Buy Order Placed at Ask: ", Ask, " ticket: ", ticket, " sl: ", sl, " tp: ", tp);
            g_initialSL = sl;                // SLを保存
            g_lastEntryTime = TimeCurrent(); // エントリー時間の保存
            g_latestTicket = ticket;         // チケット番号の保存
        }
    }
}
// ↑ストラテジテスター用↑
