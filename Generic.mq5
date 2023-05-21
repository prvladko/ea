//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Trade Like A Pro"
#property link      "http://tradelikeapro.ru"
#property version   "12.39.8"
#property strict
#define OP_BUY 0           //Покупка 
#define OP_SELL 1          //Продажа 
#include <Trade\Trade.mqh>
//---


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrade  trade;
CHistoryOrderInfo myhistory;
CPositionInfo myposition;
CDealInfo mydeal;
MqlDateTime tm;
MqlTick last_tick, prev_tick;
//---
enum     _EventLogs
  {
   ALL                        = 1,                 //ВСЕ
   MAIN                       = 2,                 //ОШИБКИ
   NONE                       = 3                  //НИЧЕГО
  };

enum     _MaxMin
  {
   MAX = 1,
   MIN = 2
  };

enum DstMode{
   DST_OFF        = 0,  //No DST
   DST_EUROPE     = 1,  //Europe (Alpari)
   DST_NEW_YORK   = 2,  //New-York (Tickmill)  
   DST_AUSTRALIA  = 3,  //Australia (Global Prime)
};
string dstStr[] = { "OFF", "Europe", "New-York", "Australia"};

//--------------------------------------
input   string S_11          = "<==== Grid ====>"; //
input   int                  Grid_Step                  = 0;
input   int                  Grid_max_orders            = 5;
input   int                  Grid_Profit_pips_for_close = 5;
input   double               Grid_Lot_multiplikator     = 2;
input    string S_1          = "<==== General settings ====>"; // >   >   >   >   >   >    >    >    >    >
input    string               SetName                    = "";                //Имя сет файла
input    bool                 ForbidTradeIfSetNameWarning= false;
input    ENUM_TIMEFRAMES      TimeFrame                  = PERIOD_CURRENT;    //TimeFrame for Bollinger Bands
input    bool                 every_tick                 = 1;                 //Trade every tick
input    int                  MagicNumber                = 1234321;
input    int                  Slippage                   = 5;
input    int                  VirtualDepo                = 0;
input    int                  trade_direction            = 0;                 //Trade direction: 0 - both, 1 - buy, 2 - sell
input    double               Lots                       = 0.01;
input    double               Auto_Risk                  = 0.0;               //Auto Risk
input    int                  MM_Depo                    = 0;                 //Depo per Lots
input    int                  MaxAmountCurrency          = 0;                 //MaxAmountCurrency
input    int                  MaxAmountCurrencyPair      = 0;                 //MaxAmountCurrencyPair
input    bool                 MaxAmount_SkipManualTrades = true;
input    bool                 CheckSpreadOnSellOpen      = true;
input    bool                 CheckSpreadOnBuyClose      = false;
input    double               Max_Spread                 = 0;                 //Max Spread
input    double               Max_Spread_On_Close        = 0;
input    double               MaxSpreadOnClose_Profit    = 10;
input    double               Stop_Loss                  = 30;                //Stop Loss
input    double               Take_Profit                = 35;                //Take Profit
input    int                  TP_perc                    = 0;                //%% TP от размера канала
input    int                  min_TP                     = 10;                //Минимальный ТП
input    int                  MaxDailyRange              = 1000;
input    bool                 MDRFromHiLo                = false;
input    int                  MDR_Toward                 = 1000;
input    bool                 MDR_Toward_FromHiLo        = false;
input    bool                 CheckMDRAfter0             = false;
input    bool                 Hedging                    = true;              //Хеджирования

input    string S_8          = "<==== MULTI ORDERS ====>";                    // >   >   >   >   >   >    >    >    >    >
input    int                  TotalOrders                = 1;
input    double               OrdersDistance             = 5;
input    int                  MinPause                   = 0;                 //Мин. время между сделками, сек
input    int                  MaxConsecutiveOrders       = 0;
input    double               MultLot                    = 1.0;               //Множитель следующего лота
input    bool                 OpenAfterTradeHours        = false;
input    bool                 DoNotCheckAfterFirst       = false;
input    bool                 CloseSimultaneously        = false;             //Закрывать одновременно

input    string S_2          = "<==== ENTER SETTINGS ====>";                  // >   >   >   >   >   >    >    >    >    >
/*input    string S_211        = "Настройки K1Band";                    //K1Band
input    bool                 Use_K1band               = false;
input    int                  K1_Period                  = 30;
input    double               K1_ModeEMA                 = 0;
input    double               K1_DeviationPeriodMult     = 10;
input    double               K1_Entry                   = -2;
input    double               K1_Exit                    = 0.5;
input    double               K1_Exit_Profit_Pips        = -1000;*/
input    string S_21         = "Настройки Bollinger Band";                    //Bollinger Band
//input    bool                 UseBBChannel               = true;
input    int                  BB_Period                  = 13;                //BB: Period
input    double               BB_Deviation               = 2;                 //BB: Deviation
input    int                  Entry_Break                = 1;                 //BB: Entry_Break
input    int                  Min_Volatility             = 20;                //BB: Минимальная ширина канала
input    int                  Max_Volatility             = 1000;
input    int                  BB_Shift                   = 1;
input    bool                 OnlyBid                    = true;              //BB: Проверять касание канала только по цене last_tick.bid

input   string S_21_1       = "ATR Filter";
input   ENUM_TIMEFRAMES      ATR_Timeframe              = PERIOD_H1;         //ATR Filter: ATR Timeframe
input   int                  ATR_Period                 = 0;                 //ATR Filter: period (0-off)
input   int                  Max_ATR_Pips               = 20;                //ATR Filter: max ATR, pips

input    string S_22         = "Настройки CCI";                               //CCI
input    ENUM_TIMEFRAMES      TimeFrame_CCI              = PERIOD_CURRENT;    //CCI: TimeFrame
input    int                  cci_Period_open            = 0;                //CCI: Period
input    int                  cci_level_open             = 100;               //CCI: верхний и нижний уровень

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input    string S_23         = "При макс.длина свечи = 0 - выкл.";            //Фильтр по размеру свечи (на вход)
input    double               maxcandle                  = 0;                 //Макс.длина свечи
input    int                  barcount                   = 8;                 //Количество баров для макс.свечи
input    string S_24         = "При паузе = 0 - выкл.";                       //Фильтр по убытку предыдущего ордера
input    int                  pause                      = 0;                 //Пауза после убыточной сделки(минут)
input    double               sizeloss                   = 60;                //Размер убытка для паузы (в пунктах)

input    string S_4          = "<==== Trailing stop/Breakeven ====>";         // >   >   >   >   >   >    >    >    >    >
input    double               Trail_Start                = 0;                 //Trailling Start
input    double               Trail_Size                 = 7;                 //Trailling Distance
input    double               Trail_Step                 = 1;                 //Trailling Step
input    int                  Trail_Minutes              = 0;
input    bool                 Trail_From_BE_Line         = true;
input    bool                 rollover_trall_end         = true;              //Запрет тралла в ролловер
input    double               BE_Start                   = 0;                 //BE: Если текущая цена лучше цены входа на Х пунктов
input    double               BE_Dist                    = 1;                 //BE: перемещаем СЛ на Y пунктов в профит
input    int                  BE_Minutes                 = 0;
input    int                  BE_After_Hour              = -1;
input    int                  BE_After_Min               = 0;

input    string S_3          = "<==== EXIT SETTINGS ====>";                   // >   >   >   >   >   >    >    >    >    >
input    string S_31         = "При Exit_Minutes = 0 - выкл.";                //1. Time Filter.
input    int                  Exit_Minutes               = 140;
input    int                  Time_Profit_Pips           = 5;
input    bool                 FixMondayTimeBug           = false;
input    string S_32         = "При Exit_Distance > 100 - выкл.";             //2. Channel Filter.
input    int                  Exit_Distance              = -13;
input    int                  Exit_Profit_Pips           = -12;
input    bool                 ExitChannelTP              = false;
input    bool                 DisableFilter2             = false;
input    string S_33         = "При MA_period = 0 - выкл.";                   //3. MA Filter.
input    ENUM_TIMEFRAMES      TimeFrameMA                = PERIOD_M1;
input    ENUM_MA_METHOD       MA_type                    = MODE_SMA;
ENUM_APPLIED_PRICE   MA_price                   = PRICE_CLOSE;
input    int                  MA_period                  = 2;
input    int                  Reverse_Profit             = 20;
input    string S_35         = "При PartialClose_Percent = 0 - выкл.";        //4. Partial Close
input    double               PartialClose_Percent       = 0;
input    int                  Part_Profit_Pips           = 0;
input    int                  Part_Distance              = -10;
input    bool                 Part_AllowCloseFull        = false;
input    string S_34         = "При CCI: Period = 0 - выкл.";                 //5. CCI Filter.
input    int                  cci_Period_close           = 0;                 //CCI: Period
input    int                  cci_level_close            = 100;               //CCI: верхний и нижний уровень
input    int                  CCI_Profit_Pips            = 20;
input    string S_36         = "При HardExit_Minutes = 0 и HardExit_TimeHour = -1 - выкл.";                //6. Hard Exit Filter.
input    int                  HardExit_Minutes           = 0;
input    int                  HardExit_TimeHour          = -1;
input    int                  HardExit_TimeMin           = 0;
input    int                  HardExit_Profit            = -100;

input    string S_5          = "<==== Trade Time Filter ====>";               // >   >   >   >   >   >    >    >    >    >
input    int                  GMT_Offset                 = 2;                 //Winter GMT offset of your broker
input    DstMode              DSTMode                    = DST_NEW_YORK;      //DST contract of your broker
input    bool                 TradeAllDaysInTheSameTime  = false;             //Торговля в одно время во все дни
input    int                  SkipDay                    = 0;
input    bool                 DisableTradeOnHolidays     = false;             //Disable trade on holidays
input    string S_51          = "<== MONDAY / ALL DAYS ==>";        // MONDAY
input    bool                 MONDAY_Enabled             = true;              //Торговать в понедельник
input    int                  MONDAY_Start_Trade_Hour    = 22;                //Start Trade Hour
input    int                  MONDAY_Start_Trade_Minute  = 0;                 //Start Trade Minute
input    int                  MONDAY_End_Trade_Hour      = 1;                 //End Trade Hour
input    int                  MONDAY_End_Trade_Minute    = 0;                 //End Trade Minute
input    string S_52          = "<== TUESDAY ==>";       // TUESDAY
input    bool                 TUESDAY_Enabled             = true;              //Торговать во вторник
input    int                  TUESDAY_Start_Trade_Hour   = 22;                //Start Trade Hour
input    int                  TUESDAY_Start_Trade_Minute = 0;                 //Start Trade Minute
input    int                  TUESDAY_End_Trade_Hour     = 1;                 //End Trade Hour
input    int                  TUESDAY_End_Trade_Minute   = 0;                 //End Trade Minute
input    string S_53          = "<== WEDNESDAY ==>";     // WEDNESDAY
input    bool                 WEDNESDAY_Enabled             = true;              //Торговать в среду
input    int                  WEDNESDAY_Start_Trade_Hour = 22;                //Start Trade Hour
input    int                  WEDNESDAY_Start_Trade_Minute=0;                //Start Trade Minute
input    int                  WEDNESDAY_End_Trade_Hour   = 1;                 //End Trade Hour
input    int                  WEDNESDAY_End_Trade_Minute = 0;                 //End Trade Minute
input    string S_54          = "<== THURSDAY ==>";      // THURSDAY
input    bool                 THURSDAY_Enabled             = true;              //Торговать в четверг
input    int                  THURSDAY_Start_Trade_Hour  = 22;                //Start Trade Hour
input    int                  THURSDAY_Start_Trade_Minute= 0;                 //Start Trade Minute
input    int                  THURSDAY_End_Trade_Hour    = 1;                 //End Trade Hour
input    int                  THURSDAY_End_Trade_Minute  = 0;                 //End Trade Minute
input    string S_55          = "<== FRIDAY ==>";        // FRIDAY
input    bool                 FRIDAY_Enabled             = true;              //Торговать в пятницу
input    int                  FRIDAY_Start_Trade_Hour    = 22;                //Start Trade Hour
input    int                  FRIDAY_Start_Trade_Minute  = 0;                 //Start Trade Minute
input    int                  FRIDAY_End_Trade_Hour      = 1;                 //End Trade Hour
input    int                  FRIDAY_End_Trade_Minute    = 0;                 //End Trade Minute

input    string S_6          = "<==== Roll Over Filter ====>";                // >   >   >   >   >   >    >    >    >    >
//input    bool                 use_rollover_filter        = 0;                 //Не торговать в ролловер
input    bool                 OpenOrdersInRollover       = true;             //Открывать сделки в ролловер
input    bool                 CloseOrdersInRollover      = true;             //Закрывать сделки в ролловер
input    string               rollover_start             = "23:55";           //Начало ролловера
input    string               rollover_end               = "00:35";           //Окончание ролловера
input    int                  LastTradeDayDecember       = 31;                //Последний торговый день в декабре
input    int                  FirstTradeDayJanuary       = 1;                 //Первый торговый день в январе  

input  string S_9          = "<==== News Filter ====>";                // >   >   >   >   >   >    >    >    >    >
input  bool                UseNewsFilter               = true;         //Использовать новостной фильтр
input  int                 CloseBeforeNews         = 0;                //Закрыть все открытые сделки до новостей,(0=выкл)
input  int                 News_CloseProfit            = -100;
input  int                 AfterNewsStop=60; // Indent after News, minuts (0 - Disable)
input  int                 BeforeNewsStop=60; // Indent before News, minuts
input bool                 NewsLight= true; // Enable light news
input bool                 NewsMedium=true; // Enable medium news
input bool                 NewsHard=true; // Enable hard news
input int                  offset=3;     // Your Time Zone, GMT (for news)
input string               NewsSymb="USD,EUR,GBP,CHF,CAD,AUD,NZD,JPY"; //Currency to display the news (empty - only the current currencies)
input bool                 DrawLines=true;       // Draw lines on the chart
input bool                 Next           = false;      // Draw only the future of news line
bool                 Signal         = false;      // Signals on the upcoming news

input    string S_7          = "<==== Optimization ====>";                    // >   >   >   >   >   >    >    >    >    >
input    double               DesiredRF                  = 20;                //Фактор Восстановления, не меньше
input    double               DesiredPF                  = 2;                 //Прибыльность, не меньше
input    int                  DesiredTN                  = 500;               //Количество сделок, не меньше
input    double               RatioThreshold             = 0;
input    string               DisableStart               = "01.01.2000";      //Запрет торговли с
input    string               DisableEnd                 = "02.01.2000";      //Запрет торговли до

input    string S_91          = "<==== Other Settings ====>";                  // >   >   >   >   >   >    >    >    >    >
input    bool                 showinfopanel              = true;              //Показывать инфопанель
input    color                Col_info                   = C'176,162,168';    //Цвет инфопанели
input    color                Col_info2                  = clrGray;           //Цвет инфопанели при неразрешённой торговле
input    bool                 VisualDebug                = true;
input    color                ChannelEnterColor          = clrYellow;         //Цвет канала BB
input    color                ChannelExitColor           = clrCornflowerBlue; //Цвет канала BB при выходе
input    color                WarnEnterColor             = clrLightSkyBlue;   //Цвет предупреждения при входе
input    color                WarnExitColor              = clrPlum;           //Цвет предупреждения при выходе
/*input    color                K1BandBuyEnterColor        = clrPaleTurquoise;  //Цвет канала K1Band (покупки)
input    color                K1BandSellEnterColor       = clrLightPink;      //Цвет канала K1Band (продажи)
input    color                K1BandBuyExitColor         = clrLightSkyBlue;   //Цвет канала K1Band при выходе (покупки)
input    color                K1BandSellExitColor        = clrCrimson;        //Цвет канала K1Band при выходе (продажи)*/
input    _EventLogs           LogMode                    = 1;                 //Режим логирования
input    bool                 WriteLogFile               = 0;                 //Записывать логи в файл
input    string               Comm                       = "Generic A-TLP|%MagicNumber%";

//--------News indicator
color highc          = clrRed;     // Colour important news
color mediumc        = clrBlue;    // Colour medium news
color lowc           = clrLime;    // The color of weak news
int   Style          = 2;          // Line style
int   Upd            = 86400;      // Period news updates in seconds

bool  Vhigh          = false;
bool  Vmedium        = false;
bool  Vlow           = false;
int   MinBefore=0;
int   MinAfter=0;
int NomNews=0;
string NewsArr[4][1000];
int Now=0;
datetime LastUpd;
string str1;
//--------------------------------------
double old_point = 0;
int                  stoplevel                  = 0;
double               lots1                      = 0;
double               lots_opened_buy            = 0;
double               lots_opened_sell           = 0;
int                  PipsDivided                = 1;
int                  count_sell, count_buy;
int                  day_of_trade               = 0;
string               tp_info                    = "";
string               be_info                    = "";
string               f1_info                    = "";
string               f2_info                    = "";
string               f3_info                    = "";
string               f4_info                    = "";
string               f5_info                    = "";
string               f6_info                    = "";
string               filter_info                = "";
string               risk_info                  = "";
string               risk_scale                 = "";
string               info_panel                 = "";
string               maxspread                  = "";
string               TradeHoursFirst            = "";
string               TradeHoursSecond           = "";
datetime             _TimeCurrent, _TimeM1, _TimePeriod, _TimeBars, iTimeTF, iTimeM1, iTime_MA, iTime_CCI;
datetime             need_to_verify_channel     = iTime(NULL, TimeFrame, 1);
datetime             ma_period_check, cci_period_check;
datetime             time_open_buy              = TimeCurrent();
datetime             time_open_sell             = TimeCurrent();

double               channel_width              = 0;
double               channel_upper, channel_lower;
//         double               channel_buy, channel_sell, channel_buy_exit, channel_sell_exit;
double               ma_shift[];
int                  cci_signal_open, cci_signal_close;
double               stoploss, takeprofit;
int                  lastticket, lasthistorytotal;
datetime             lasttimewrite, lastbarwrite, lastbarwrite1, last_closetime = 0;
//--- параметры для записи данных в файл
string               InpFileName;                                    // Имя файла
string               fileName                   = "EA_Generic";      // Имя файла
string               InpDirectoryName           = "Generic LOGS";    // Имя каталога

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool                 _RealTrade = (!MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_OPTIMIZATION));
bool                 SetEq_Symbol;
datetime             StartTime, EndTime, PrevDayStartTime, PrevDayEndTime;
datetime             rtime1, rtime2;
int                  rtimestart, rtimeend;
int                  Start_Trade_Hour[7], End_Trade_Hour[7], Start_Trade_Minute[7], End_Trade_Minute[7];
bool                 Day_Trade_Enabled[7];
string               First_StartTimeStr, First_EndTimeStr, Second_StartTimeStr, Second_EndTimeStr;
string               daystring[7]= {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
int                  day_of_year_trade=0;
string               set_name_info = "";
//         bool                 _IsFirstSession;
color                infopanelcolor, previnfopanelcolor;
int                  _DayOfWeek;
double               buy_total_profit, sell_total_profit;
datetime             first_buy_open_time, first_sell_open_time;
datetime             lastnewsupdate;
bool                 _IsNews;
bool                 skip_tick;
string               _period;
bool                 timer_active;
int                  CloseReason_Multi[2];
datetime             DayStartTimeShift;
int                  TimeShift;
int                  _DayOfWeekShift;
double               range;
bool                 _IsTime;
int                  consecutive_orders_buy=0, consecutive_orders_sell=0;
datetime             _HardExitTime, _BE_Time;
datetime             DisableStartTime, DisableEndTime;
//---- переменные для вычисления одновремменно открытых позиций

string Currencies = "AUD,EUR,USD,CHF,JPY,NZD,GBP,CAD,SGD,NOK,SEK,DKK,ZAR,MXN,HKD,HUF,CZK,PLN,RUR,TRY,XAU,XAG";

int NumOfCurrencies;  // Общее количество учитываемых валют
string Currency[]; // Учитываемые валюты
double VolumesArray[];
datetime LastUpdateTime;
bool AllowTrade;
bool trading_allowed_global=true;
double globalRiskScale = 1;
//---- переменные для вычисления одновремменно открытых позиций

string                        GlobPrefix="GA_", s1str, s2str;
double                        mintpb, mintps, tpb, tps;

int bands_handle, ma_handle, cciopen_handle, cciclose_handle, maopen_handle;
datetime _StrToTime, last_close_time;
datetime Time[];

string _SetName;
ENUM_TIMEFRAMES _TimeFrame;
int _Slippage;
double _Lots;
double _Auto_Risk;
int _MaxAmountCurrency;
int _MaxAmountCurrencyPair;
bool _MaxAmount_SkipManualTrades;
double _Max_Spread;
double _Max_Spread_On_Close;
double _MaxSpreadOnClose_Profit;
double _Stop_Loss;
double _Take_Profit;
int _TP_perc;
int _min_TP;
int _MaxDailyRange;
int _MDR_Toward;
bool _CheckMDRAfter0;
int _TotalOrders;
double _OrdersDistance;
int _MaxConsecutiveOrders;
string _S_2;
bool _Use_K1band;
double _K1_Exit_Profit_Pips;
string _S_21;
bool _UseBBChannel;
int _Entry_Break;
int _Min_Volatility;
int _Max_Volatility;
double _maxcandle;
int _pause;
double _sizeloss;
double _Trail_Start;
double _Trail_Size;
double _Trail_Step;
double _BE_Start;
double _BE_Dist;
int _BE_Minutes;
string _S_3;
int _Exit_Minutes;
int _Time_Profit_Pips;
int _Exit_Distance;
int _Exit_Profit_Pips;
int _MA_period;
int _Reverse_Profit;
double _PartialClose_Percent;
int _Part_Profit_Pips;
int _Part_Distance;
int _cci_Period_close;
int _CCI_Profit_Pips;
int _HardExit_Minutes;
int _HardExit_TimeHour;
int _HardExit_Profit;
string _S_5;
bool _DST;
bool _UseNewsFilter;
int _News_CloseProfit;
int _TimeBeforeNews;
int _news_offset;
bool _showinfopanel;
bool _VisualDebug;
_EventLogs _LogMode;
bool SetEqSymbol;

//---Grid ildar
double   DistanceBid_to_Buy = 9999;
double   DistanceBid_to_Sell = 9999; //минимальная дистанция от цены до ближайшего ордера
double   TradesLevelsBuyAndSell[]; //уровни цен открытых ордеров
int      TradesTypeBuy0Sell1[]; //пишем тип ордера для предыдущего массива
int      Trades[6]; //массив для подсчета количества ордеров, 0 - buy, 1 sell, 2buylim, 3 selllim, 4 buyst, 5 sellst
double   Profit_open_orders_sell = 0, Profit_open_orders_buy = 0;
string   Symbol_Work = Symbol();
double PlavPribPips=0; //просадка в пунктах
double MinBuyLevel=0, MinSellLevel=0; //Самые просевшие ордера в сетке
bool FlagGridOpen=false; //флаг для определения наличия открытых сеток
double Ask=0;
double Bid=0;
double Spread=0;
MqlTick tick;
double Equity=0; //эквити в валюте
//---Grid

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   _SetName = SetName;
   _TimeFrame = TimeFrame;
   _Slippage = Slippage;
   _Lots = Lots;
   _Auto_Risk = Auto_Risk;
   _MaxAmountCurrency = MaxAmountCurrency;
   _MaxAmountCurrencyPair = MaxAmountCurrencyPair;
   _MaxAmount_SkipManualTrades = MaxAmount_SkipManualTrades;
   _Max_Spread = Max_Spread;
   _Max_Spread_On_Close = Max_Spread_On_Close;
   _MaxSpreadOnClose_Profit = MaxSpreadOnClose_Profit;
   _Stop_Loss = Stop_Loss;
   _Take_Profit = Take_Profit;
   _TP_perc = TP_perc;
   _min_TP = min_TP;
   _MaxDailyRange = MaxDailyRange;
   _MDR_Toward = MDR_Toward;
   _CheckMDRAfter0 = CheckMDRAfter0;
   _TotalOrders = TotalOrders;
   _OrdersDistance = OrdersDistance;
   _MaxConsecutiveOrders = MaxConsecutiveOrders;
   _Entry_Break = Entry_Break;
   _Min_Volatility = Min_Volatility;
   _Max_Volatility = Max_Volatility;
   _maxcandle = maxcandle;
   _pause = pause;
   _sizeloss = sizeloss;
   _Trail_Start = Trail_Start;
   _Trail_Size = Trail_Size;
   _Trail_Step = Trail_Step;
   _BE_Start = BE_Start;
   _BE_Dist = BE_Dist;
   _BE_Minutes = BE_Minutes;
   _S_3 = S_3;
   _Exit_Minutes = Exit_Minutes;
   _Time_Profit_Pips = Time_Profit_Pips;
   _Exit_Distance = Exit_Distance;
   _Exit_Profit_Pips = Exit_Profit_Pips;
   _MA_period = MA_period;
   _Reverse_Profit = Reverse_Profit;
   _PartialClose_Percent = PartialClose_Percent;
   _Part_Profit_Pips = Part_Profit_Pips;
   _Part_Distance = Part_Distance;
   _cci_Period_close = cci_Period_close;
   _CCI_Profit_Pips = CCI_Profit_Pips;
   _HardExit_Minutes = HardExit_Minutes;
   _HardExit_TimeHour = HardExit_TimeHour;
   _HardExit_Profit = HardExit_Profit;
   _S_5 = S_5;
   _showinfopanel = showinfopanel;
   _VisualDebug = VisualDebug;
   _LogMode = LogMode;

   s1str = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
   s2str = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);

   int height=370;
//if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) { Print("Error: Trade Expert is not Allowed"); return(INIT_FAILED); }

   if(MQLInfoInteger(MQL_OPTIMIZATION))
     {
      _LogMode=3;
      _showinfopanel=false;
      _VisualDebug=false;
     }

   AllowTrade = true;
   StringToUpper(_SetName);
   SetEq_Symbol = StringFind(_SetName, StringSubstr(_Symbol, 0, 6))>=0;

   if(_RealTrade && ForbidTradeIfSetNameWarning && !SetEq_Symbol)
     {
      Print("Неправильное имя сета! Торговля не разрешена.");
      AllowTrade = false;
     }

   if(_MaxAmountCurrency>0)
      height += 37;
   if(_MaxAmountCurrencyPair>0)
      height += 37;
   if(_showinfopanel)
      fRectLabelCreate(0, "info_panel", 0, 0, 28, 170, height, Col_info);

   string s = "";
   switch(Period())
     {
      case PERIOD_M1:
         s = "M1";
         break;
      case PERIOD_M5:
         s = "M5";
         break;
      case PERIOD_M15:
         s = "M15";
         break;
      case PERIOD_M30:
         s = "M30";
         break;
      case PERIOD_H1:
         s = "H1";
         break;
      case PERIOD_H4:
         s = "H4";
         break;
      case PERIOD_D1:
         s = "D1";
         break;
      case PERIOD_W1:
         s = "W1";
         break;
      case PERIOD_MN1:
         s = "MN1";
         break;
     }

   _period=s;

   if(_LogMode < 3)
      InpFileName = fileName + "_" + _Symbol + "_" + s + ".txt";

   stoplevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   maxspread = (_Max_Spread > 0 ? DoubleToString(_Max_Spread, 1) + " pips" : "OFF");

   _TimeM1 = StringToTime(TimeToString(TimeCurrent(), TIME_MINUTES));

   day_of_year_trade=0; // при переинициализации советника некоторые переменные не обнуляются, а сохраняют свои последние значения
   infopanelcolor=0;
   previnfopanelcolor=0;
   lastnewsupdate=0;
   ma_period_check=0;
   cci_period_check=0;
   need_to_verify_channel=0;
   timer_active=false;

   if(!TradeAllDaysInTheSameTime)
     {
      Start_Trade_Hour[1] = MONDAY_Start_Trade_Hour;
      Start_Trade_Hour[2] = TUESDAY_Start_Trade_Hour;
      Start_Trade_Hour[3] = WEDNESDAY_Start_Trade_Hour;
      Start_Trade_Hour[4] = THURSDAY_Start_Trade_Hour;
      Start_Trade_Hour[5] = FRIDAY_Start_Trade_Hour;
      End_Trade_Hour[1] = MONDAY_End_Trade_Hour;
      End_Trade_Hour[2] = TUESDAY_End_Trade_Hour;
      End_Trade_Hour[3] = WEDNESDAY_End_Trade_Hour;
      End_Trade_Hour[4] = THURSDAY_End_Trade_Hour;
      End_Trade_Hour[5] = FRIDAY_End_Trade_Hour;
      Start_Trade_Minute[1] = MONDAY_Start_Trade_Minute;
      Start_Trade_Minute[2] = TUESDAY_Start_Trade_Minute;
      Start_Trade_Minute[3] = WEDNESDAY_Start_Trade_Minute;
      Start_Trade_Minute[4] = THURSDAY_Start_Trade_Minute;
      Start_Trade_Minute[5] = FRIDAY_Start_Trade_Minute;
      End_Trade_Minute[1]= MONDAY_End_Trade_Minute;
      End_Trade_Minute[2]= TUESDAY_End_Trade_Minute;
      End_Trade_Minute[3]= WEDNESDAY_End_Trade_Minute;
      End_Trade_Minute[4]= THURSDAY_End_Trade_Minute;
      End_Trade_Minute[5]= FRIDAY_End_Trade_Minute;
     }
   else
     {
      for(int i=1; i<=5; i++)
        {
         Start_Trade_Hour[i]=MONDAY_Start_Trade_Hour;
         Start_Trade_Minute[i]=MONDAY_Start_Trade_Minute;
         End_Trade_Hour[i]=MONDAY_End_Trade_Hour;
         End_Trade_Minute[i]=MONDAY_End_Trade_Minute;
        }
     }

   for(int i=1; i<=5; i++)
     {
      while(Start_Trade_Hour[i]*60+Start_Trade_Minute[i]>End_Trade_Hour[i]*60+End_Trade_Minute[i])
         End_Trade_Hour[i] += 24;
     }

   Day_Trade_Enabled[1]=MONDAY_Enabled;
   Day_Trade_Enabled[2]=TUESDAY_Enabled;
   Day_Trade_Enabled[3]=WEDNESDAY_Enabled;
   Day_Trade_Enabled[4]=THURSDAY_Enabled;
   Day_Trade_Enabled[5]=FRIDAY_Enabled;

   if(SkipDay >= 1 && SkipDay <= 5)
      Day_Trade_Enabled[SkipDay]=false;
   if(SkipDay == 6 && Start_Trade_Hour[5] < 24)
     {
      Start_Trade_Hour[5] = 24;
      Start_Trade_Minute[5] = 0;
     }
   if(SkipDay == 7 && End_Trade_Hour[5] > 24)
     {
      End_Trade_Hour[5] = 24;
      End_Trade_Minute[5] = 0;
     }

   for(int i=0; i<=6; i++)
     {
      if(!Day_Trade_Enabled[i])
        {
         Start_Trade_Hour[i]=0;
         Start_Trade_Minute[i]=0;
         End_Trade_Hour[i]=0;
         End_Trade_Minute[i]=0;
        }
     }

   rtimestart=-1;
   rtimeend=-1;
   string tt[];
   int i;
   i=StringSplit(rollover_start, StringGetCharacter(":", 0), tt);
   if(i==2)
     {
      rtimestart=(int)StringToInteger(tt[0])*60*60+(int)StringToInteger(tt[1])*60;
     }
   i=StringSplit(rollover_end, StringGetCharacter(":", 0), tt);
   if(i==2)
     {
      rtimeend=(int)StringToInteger(tt[0])*60*60+(int)StringToInteger(tt[1])*60;
     }
   if(rtimestart ==-1 || rtimeend == -1)
     {
      Print("Неправильно задано время ролловера.");
      return(INIT_FAILED);
     }

   DisableStartTime = StringToTime(DisableStart);
   DisableEndTime = StringToTime(DisableEnd);


   if(_OrdersDistance < 0.5)
      _OrdersDistance=0.5;
   if(_TotalOrders < 1)
      _TotalOrders=1;
   if(_TotalOrders > 10)
     {
      Print("Количество ордеров установлено больше 10. Максимальное количество ордеров: 10");
      _TotalOrders=10;
     }

   TimeShift = GMT_Offset - 2 - fGetDSTShift();

   if(_PartialClose_Percent > 1)
      _PartialClose_Percent = 1;

   if(_MaxConsecutiveOrders == -1)
      _MaxConsecutiveOrders = _TotalOrders;

   if(_Digits <= 3)
      old_point = 0.01;
   else
      old_point = 0.0001;

   if(_Digits == 3 || _Digits == 5)    //проверка на 4х, 5-и знаковый счет
     {
      _Slippage *= 10;
      _Max_Spread *= 10;
      _Take_Profit *= 10;
      _Stop_Loss *= 10;
      _min_TP *= 10;
      _Entry_Break *= 10;
      _Min_Volatility *= 10;
      _Max_Volatility *= 10;
      _maxcandle *= 10;
      _sizeloss *= 10;
      _Time_Profit_Pips *= 10;
      _Exit_Distance *= 10;
      _Exit_Profit_Pips *= 10;
      _Reverse_Profit *= 10;
      _CCI_Profit_Pips *= 10;
      _Trail_Start *= 10;
      _Trail_Size *= 10;
      _Trail_Step *= 10;
      _BE_Start *= 10;
      _BE_Dist *= 10;
      PipsDivided = 10;
      _MaxDailyRange *= 10;
      _MDR_Toward *= 10;
      _Max_Spread_On_Close *= 10;
      _OrdersDistance *= 10; /*_K1_Exit_Profit_Pips *= 10;*/
      _MaxSpreadOnClose_Profit *= 10;
      _Part_Profit_Pips *= 10;
      _Part_Distance *= 10;
      _News_CloseProfit *= 10;
      _HardExit_Profit *= 10;
     }

   /*if (_sizeloss < 0) {
      Print("Размер убыка для паузы перед открытием следующего ордера, должен быть указан в положительных числах!");
      Print("Текущее значение: ",_sizeloss/PipsDivided," Приведено к значению: ", MathAbs(_sizeloss/PipsDivided));
      _sizeloss = MathAbs(_sizeloss);
   }  */

//if (!_RealTrade && SymbolInfoInteger(_Symbol,SYMBOL_SPREAD) > _Max_Spread && _Max_Spread > 0) { Print("Error: Current Spread (" + DoubleToString(SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)/PipsDivided,1) +  ") > MaxSpread (" + DoubleToString(_Max_Spread/PipsDivided,1) + ")"); return(INIT_FAILED); }

   _Take_Profit = MathMax(_Take_Profit, NormalizeDouble(stoplevel, 1));
   _Stop_Loss = MathMax(_Stop_Loss, NormalizeDouble(stoplevel, 1));

   /*if (Auto_Risk > 0) */lots1 = AutoMM_Count(0); //расчет торгового лота
//else lots = _Lots;

   f1_info = "\n  1. Time Filter: OFF";
   f2_info = "\n  2. Channel Filter: OFF";
   f3_info = "\n  3. MA Filter: OFF";
   f4_info = "\n  4. Partial Close: OFF";
   f5_info = "\n  5. CCI Filter: OFF";
   f6_info = "\n  6. Hard Exit Filter: OFF";

   if(_Exit_Minutes > 0)
      f1_info = "\n  1. Time Filter: ON";
   if(_Exit_Distance/PipsDivided < 100)
      f2_info = "\n  2. Channel Filter: ON";
   if(_MA_period > 0)
      f3_info = "\n  3. MA Filter: ON";
//if(_Use_K1band) f5_info = "\n  5. K1Band Filter: ON";
   if(_PartialClose_Percent > 0)
      f4_info = "\n  4. Partial Close: ON";
//if(_cci_Period_close > 0) f5_info = "\n  5. CCI Filter: ON";
   if(_HardExit_Minutes > 0 || _HardExit_TimeHour > -1)
      f6_info = "\n  6. Hard Exit Filter: ON";
   filter_info = f1_info + f2_info + f3_info + f4_info + f5_info + f6_info;

   if(_Auto_Risk > 0.0)
     {
      if(MM_Depo == 0)
        {
         risk_info = "\n  AutoRisk = " + DoubleToString(_Auto_Risk, 1) + "%"+(_TotalOrders>1?"*"+IntegerToString(_TotalOrders)+" = "+DoubleToString(_Auto_Risk*_TotalOrders, 1)+"%":"");
        }
      else
        {
         risk_info = "\n  AutoRisk = " + DoubleToString(_Lots, 2) + " Lot / " + IntegerToString(MM_Depo) + " "+AccountInfoString(ACCOUNT_CURRENCY);
        }
     }
   else
      risk_info = "\n  AutoRisk - Not activated";

   be_info = "\n  Breakeven: ";
   if(_BE_Start > 0/* && Y > 0*/)
     {
      be_info += DoubleToString(_BE_Start/PipsDivided, 1)+" / " + DoubleToString(_BE_Dist/PipsDivided, 1)+" pips"; //безубыток
      if(_BE_Minutes > 0)
         be_info += " / " + IntegerToString(_BE_Minutes)+" Min";
     }
   else
      if(_BE_Minutes > 0)
        {
         be_info += DoubleToString(_BE_Dist/PipsDivided, 1)+" pips / " + IntegerToString(_BE_Minutes)+" Min";
        }
      else
         be_info += "OFF";

//   StringReplace(Comm,"%MagicNumber%",IntegerToString(MagicNumber));

   set_name_info=(StringLen(_SetName)>28 ? StringSubstr(_SetName, 0, 28)+"..." : _SetName);

   _IsNews=false;

   NumOfCurrencies = StringSplit(Currencies, StringGetCharacter(",", 0), Currency);
   if(NumOfCurrencies >= 0)
     {
      ArrayResize(VolumesArray, NumOfCurrencies);
     }
   else
     {
      _MaxAmountCurrency = 0;
      _MaxAmountCurrencyPair = 0;
     }

   Comment("");

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(_Slippage);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   bands_handle=iBands(NULL, _TimeFrame, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
   if(bands_handle==INVALID_HANDLE)
     {
      printf("Error creating Bands indicator");
      return(INIT_FAILED);
     }

   if(_MA_period>0)
     {
      ma_handle=iMA(NULL, TimeFrameMA, _MA_period, 0, MA_type, MA_price);
      if(ma_handle==INVALID_HANDLE)
        {
         printf("Error creating MA indicator");
         return(INIT_FAILED);
        }
     }

   if(cci_Period_open>0)
     {
      cciopen_handle = iCCI(NULL, _TimeFrame, cci_Period_open, PRICE_CLOSE);
      if(cciopen_handle==INVALID_HANDLE)
        {
         printf("Error creating CCI indicator");
         return(INIT_FAILED);
        }
     }

   if(_cci_Period_close>0)
     {
      cciclose_handle = iCCI(NULL, _TimeFrame, _cci_Period_close, PRICE_CLOSE);
      if(cciclose_handle==INVALID_HANDLE)
        {
         printf("Error creating CCI indicator");
         return(INIT_FAILED);
        }
     }
   ArraySetAsSeries(Time, true);

   if(StringLen(NewsSymb)>1)
      str1=NewsSymb;
   else
      str1=Symbol();

   Vhigh=NewsHard;
   Vmedium=NewsMedium;
   Vlow=NewsLight;
   MinBefore=BeforeNewsStop;
   MinAfter=AfterNewsStop;
   UpdateInfoPanel();
   
//NewsFilter
   if(StringLen(NewsSymb)>1)
      str1=NewsSymb;
   else
      str1=Symbol();
   Vhigh=NewsHard;
   Vmedium=NewsMedium;
   Vlow=NewsLight;
   MinBefore=BeforeNewsStop;
   MinAfter=AfterNewsStop;
   if(UseNewsFilter)
      IsNews();
//NewsFilter

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(_RealTrade)
     {
      Comment("");
      if(_showinfopanel)
         fRectLabelDelete(0, "info_panel");
     }

   ObjectsDeleteAll(0, 0, OBJ_VLINE);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   CheckScale();
   SymbolInfoTick(Symbol(), tick);
   Ask=tick.ask;
   Bid=tick.bid;
   if(Grid_Step)
     {
      CountTrades(); //for grid
      Plavpribil();
      if(Trades[0]+Trades[1] > 1)
        {
         GridClose(Grid_Profit_pips_for_close);
        }
      GridNextStep(Grid_Step, Grid_max_orders);
     }

   skip_tick = false;

   ResetLastError();

   _TimeCurrent = TimeCurrent(tm);
   _DayOfWeek = tm.day_of_week;
   CopyTime(_Symbol, _TimeFrame, 0, 10, Time);

   iTimeTF = iTime(NULL, _TimeFrame, 0);
   iTimeM1 = iTime(NULL, PERIOD_M1, 0);
   iTime_MA = iTime(NULL, TimeFrameMA, 0);
   iTime_CCI = iTime(NULL, TimeFrame_CCI, 0);

   if(_TimeBars != iTimeM1)
     {
      _TimeBars = iTimeM1;
      bool res = true;
      res = res && UpdateData(_TimeFrame);
      res = res && UpdateData(PERIOD_M1);
      res = res && UpdateData(TimeFrameMA);
      res = res && UpdateData(TimeFrame_CCI);
      if(!res)
         Print("Ошибка при синхронизации истории.");
      int Error = GetLastError(); //поиск ошибок в завершение
      if(Error == 4401)
         Error = 0;
      if(Error != 0)
         Print("UpdateData Error ", Error, ": ", ErrorDescription(Error));
     }

   if((_DayOfWeek>=0) && (_DayOfWeek<=6))
     {
      if(day_of_year_trade != tm.day_of_year)
        {

         TimeShift = GMT_Offset - 2 - fGetDSTShift();

         int weekends_shift=0;
         if(TimeDayOfWeek(TimeCurrent()) == 0 && TimeShift < 0)
           {
            weekends_shift = -24*60*60;
           }
         if(TimeDayOfWeek(TimeCurrent()) == 6 && TimeShift > 0)
           {
            weekends_shift = +24*60*60;
           }
         _DayOfWeekShift = TimeDayOfWeek(TimeCurrent()+weekends_shift-TimeShift*60*60);
         if(_DayOfWeekShift > 5)
            _DayOfWeekShift=1;
         if(_DayOfWeekShift < 1)
            _DayOfWeekShift=5;
         int _PrevDayOfWeekShift = _DayOfWeekShift-1;
         if(_PrevDayOfWeekShift < 1)
            _PrevDayOfWeekShift=5;
         if(_PrevDayOfWeekShift > 5)
            _PrevDayOfWeekShift=1;

         datetime _CurrentDate = StringToTime(TimeToString(_TimeCurrent, TIME_DATE));
         DayStartTimeShift = _CurrentDate+TimeShift*60*60;

         PrevDayStartTime=_CurrentDate-24*60*60+(Start_Trade_Hour[_PrevDayOfWeekShift])*60*60+Start_Trade_Minute[_PrevDayOfWeekShift]*60+TimeShift*60*60;
         PrevDayEndTime = _CurrentDate-24*60*60+(End_Trade_Hour[_PrevDayOfWeekShift])*60*60+End_Trade_Minute[_PrevDayOfWeekShift]*60+TimeShift*60*60;
         StartTime=_CurrentDate+(Start_Trade_Hour[_DayOfWeekShift])*60*60+Start_Trade_Minute[_DayOfWeekShift]*60+TimeShift*60*60;
         EndTime = _CurrentDate+(End_Trade_Hour[_DayOfWeekShift])*60*60+End_Trade_Minute[_DayOfWeekShift]*60+TimeShift*60*60;

         if(_DayOfWeek == 0 && StartTime < DayStartTimeShift+24*60*60)
           {
            StartTime=DayStartTimeShift+24*60*60;
           }
         if(_DayOfWeek == 5 && EndTime > DayStartTimeShift+24*60*60)
           {
            EndTime=DayStartTimeShift+24*60*60;
           }

         _HardExitTime = _CurrentDate + _HardExit_TimeHour*60*60 + HardExit_TimeMin*60 + TimeShift*60*60;
         _BE_Time = _CurrentDate + BE_After_Hour*60*60 + BE_After_Min*60 + TimeShift*60*60;

         if(_showinfopanel)
           {
            First_StartTimeStr=TimeToString(PrevDayStartTime, TIME_MINUTES);
            if(TimeDayOfWeek(PrevDayStartTime) != _DayOfWeek)
               First_StartTimeStr = "00:00";
            First_EndTimeStr=TimeToString(PrevDayEndTime, TIME_MINUTES);
            if(TimeDayOfWeek(PrevDayEndTime) != _DayOfWeek)
               First_EndTimeStr = "00:00";
            Second_StartTimeStr=TimeToString(StartTime, TIME_MINUTES);
            if(TimeDayOfWeek(StartTime) != _DayOfWeek)
               Second_StartTimeStr = "00:00";
            Second_EndTimeStr=TimeToString(EndTime, TIME_MINUTES);
            if(TimeDayOfWeek(EndTime) != _DayOfWeek)
               Second_EndTimeStr = "00:00";
           }


         rtime1 = _CurrentDate + rtimestart + TimeShift*60*60;
         rtime2 = _CurrentDate + rtimeend + TimeShift*60*60;
         //if (rtime2 < rtime1) rtime2 += 24*60*60;
         //rtime1 = StringToTime(StringConcatenate(TimeToString(_TimeCurrent,TIME_DATE)," ",rollover_start))+TimeShift*60*60;
         //rtime2 = StringToTime(StringConcatenate(TimeToString(_TimeCurrent,TIME_DATE)," ",rollover_end))+TimeShift*60*60;

         day_of_year_trade = tm.day_of_year;
        }
     }

   UpdateInfoPanel();

   if(_TimeM1 == iTimeM1 && !every_tick)
      return ;
   _TimeM1 =  iTimeM1;

   _IsTime=IsTime();
   if(!_IsTime && PositionsTotal()<1)
      return;
   SymbolInfoTick(_Symbol, last_tick);

   if(need_to_verify_channel != iTimeTF)  //обновлять данные индикатора раз в период
     {

      double bands1[], bands2[];
      if(CopyBuffer(bands_handle, 1, BB_Shift, 1, bands1)<=0 || CopyBuffer(bands_handle, 2, BB_Shift, 1, bands2)<=0)
        {
         Print("CopyBuffer Bands failed, no data");
         return;
        }

      channel_upper = bands1[0];
      channel_lower = bands2[0];

      DrawChannel("up_", channel_upper + Entry_Break*old_point, ChannelEnterColor); //in mt4
      DrawChannel("down_", channel_lower - Entry_Break*old_point, ChannelEnterColor);
      DrawChannel("down_exit_", channel_upper + Exit_Distance*old_point, ChannelExitColor);
      DrawChannel("up_exit_", channel_lower - Exit_Distance*old_point, ChannelExitColor);

      if(ExitChannelTP)
         fSetTPbyExitChannel();

      channel_width = channel_upper - channel_lower;
      if(!skip_tick)
         need_to_verify_channel = iTimeTF;

      if(_TP_perc > 0)
         _Take_Profit = MathMax(NormalizeDouble(channel_width/_Point /100 * _TP_perc, 1), _min_TP); //проверка на динамический ТП

     }

   if(_MA_period > 0 && ma_period_check != iTime_MA)
     {
      if(CopyBuffer(ma_handle, 0, 1, 5, ma_shift)<=0)
        {
         Print("CopyBuffer MA failed, no data");
         return;
        }
      ArraySetAsSeries(ma_shift, true);

      ma_period_check = iTime_MA;
     }

   if(cci_period_check != iTime_CCI)
     {
      if(cci_Period_open>0)
        {
         cci_signal_open=fGetCCISignalOpen(cci_Period_open, PRICE_CLOSE, cci_level_open, 1);
        }
      else
         cci_signal_open=-1;
      if(_cci_Period_close>0)
        {
         cci_signal_close=fGetCCISignalClose(_cci_Period_close, PRICE_CLOSE, cci_level_close, 1);
        }
      else
         cci_signal_close=-1;
      cci_period_check = iTime_CCI;
     }

   if(skip_tick)
     {
      //Print("skipping tick");
      SetTimer(1);
      return;
     }

   if(timer_active)
     {
      EventKillTimer();
      timer_active=false;
     }


   range = 0;
   count_buy = 0;
   count_sell = 0;
   int _OrdersTotal = PositionsTotal();
   CloseReason_Multi[POSITION_TYPE_BUY]=0;
   CloseReason_Multi[POSITION_TYPE_SELL]=0;

   if(_TotalOrders>1 && CloseSimultaneously)
     {
      int cnt_buy=CountOrder(POSITION_TYPE_BUY);
      int cnt_sell=CountOrder(POSITION_TYPE_SELL);
      if(cnt_buy > 0)
         buy_total_profit=GetOrdersTotalProfit(POSITION_TYPE_BUY)/cnt_buy;
      if(cnt_sell > 0)
         sell_total_profit=GetOrdersTotalProfit(POSITION_TYPE_SELL)/cnt_sell;
      first_buy_open_time=GetFirstOpenTime(POSITION_TYPE_BUY);
      first_sell_open_time=GetFirstOpenTime(POSITION_TYPE_SELL);
     }

   for(int pos = _OrdersTotal - 1; pos >= 0; pos--)
     {
      if(!myposition.SelectByIndex(pos))
        {
         if(_LogMode < 3)
           {
            string q = __FUNCTION__ + ": не удалось выделить ордер! " + fMyErDesc();
            Print(q);
            fWriteDataToFile(q);
           }
        }
      else
         if(myposition.PositionType() <= POSITION_TYPE_SELL && myposition.Symbol() == _Symbol && myposition.Magic() == MagicNumber)
           {

            if(myposition.PositionType() == POSITION_TYPE_BUY)
              {
               count_buy++;
               if(myposition.StopLoss() == 0.0 && !Grid_Step)  //модифицирование ордера
                 {
                  stoploss = NormalizeDouble(myposition.PriceOpen() - _Stop_Loss*_Point, _Digits);
                  takeprofit = NormalizeDouble(myposition.PriceOpen() + _Take_Profit*_Point, _Digits);

                  if(!ExitChannelTP)
                     fModifyPosition(myposition.Ticket(), myposition.PriceOpen(), stoploss, takeprofit, 0, clrGreen);
                  else
                     fModifyPosition(myposition.Ticket(), myposition.PriceOpen(), stoploss, MathMax(MathMax(tpb, myposition.PriceOpen()+_Exit_Profit_Pips*_Point), mintpb), 0, clrGreen);

                  continue;
                 }

               if(((_BE_Start > 0 && _BE_Start > _BE_Dist && last_tick.bid - myposition.PriceOpen() >= _BE_Start*_Point) || (((_BE_Minutes > 0 && _TimeCurrent - myposition.Time() > 60*_BE_Minutes) || (BE_After_Hour > -1 && myposition.Time() < _BE_Time && _TimeCurrent >= _BE_Time)) && last_tick.bid - myposition.PriceOpen() >= (_BE_Dist+stoplevel)*_Point)) /*&& Y > 0*/ && myposition.StopLoss() < myposition.PriceOpen())  //безубыток
                 {
                  stoploss = NormalizeDouble(myposition.PriceOpen() + _BE_Dist*_Point, _Digits);
                  if(stoploss > myposition.StopLoss())
                     fModifyPosition(myposition.Ticket(), myposition.PriceOpen(), stoploss, myposition.TakeProfit(), 0, clrGreen);
                 }

               Modify_and_exit_condition(myposition.PositionType(), myposition.Volume(), myposition.PriceOpen(), myposition.Time(), myposition.Ticket(), myposition.StopLoss()); //модификация ордеров и проверка условий на выход
              }

            else
               if(myposition.PositionType() == POSITION_TYPE_SELL)
                 {
                  count_sell++;
                  if(myposition.StopLoss() == 0.0  && !Grid_Step)    //модификация ордера
                    {
                     stoploss = NormalizeDouble(myposition.PriceOpen() + _Stop_Loss*_Point, _Digits);
                     takeprofit = NormalizeDouble(myposition.PriceOpen() - _Take_Profit*_Point, _Digits);

                     if(!ExitChannelTP)
                        fModifyPosition(myposition.Ticket(), myposition.PriceOpen(), stoploss, takeprofit, 0, clrGreen);
                     else
                        fModifyPosition(myposition.Ticket(), myposition.PriceOpen(), stoploss, MathMin(MathMin(tps, myposition.PriceOpen()-_Exit_Profit_Pips*_Point), mintps), 0, clrGreen);

                     continue;
                    }

                  if(((_BE_Start > 0 && _BE_Start > _BE_Dist && myposition.PriceOpen() - last_tick.ask >= _BE_Start*_Point) || (((_BE_Minutes > 0 && _TimeCurrent - myposition.Time() > 60*_BE_Minutes) || (BE_After_Hour > -1 && myposition.Time() < _BE_Time && _TimeCurrent >= _BE_Time)) && myposition.PriceOpen() - last_tick.ask > (_BE_Dist+stoplevel)*_Point)) /*&& Y > 0*/ && myposition.StopLoss() > myposition.PriceOpen())  //БУ
                    {
                     stoploss = NormalizeDouble(myposition.PriceOpen() - _BE_Dist*_Point, _Digits);
                     if(stoploss < myposition.StopLoss())
                        fModifyPosition(myposition.Ticket(), myposition.PriceOpen(), stoploss, myposition.TakeProfit(), 0, clrGreen);
                    }

                  Modify_and_exit_condition(myposition.PositionType(), myposition.Volume(), myposition.PriceOpen(), myposition.Time(), myposition.Ticket(), myposition.StopLoss()); //модификация ордеров и проверка условий на выход
                 }
           }
     }

   if(!AllowTrade)
      return;
   if(Grid_Step && Trades[0]+Trades[1] > 0)
      return;
//if (!GlobalVariableCheck(GlobPrefix+"StopAll") && !GlobalVariableCheck(GlobPrefix+s1str+"_Stop") && !GlobalVariableCheck(GlobPrefix+s2str+"_Stop")){

   if((!_IsTime && !OpenAfterTradeHours) || (!OpenOrdersInRollover && fGetRollOver()))
      return;

   double h_price;
   bool is_order_dist;
   bool openresult;
   bool channel_condition=false;
   bool bb_condition=false, k1_condition=false;
   bool con_orders;

   h_price=GetMaxMinOpenPrice(POSITION_TYPE_BUY, MIN); // минимальная цена открытых ордеров
   if(h_price != 0)
      is_order_dist = last_tick.ask < h_price-_OrdersDistance*_Point;
   else
      is_order_dist = true;  // расстояние от открытых ордеров не меньше заданного

   count_buy=CountOrder(POSITION_TYPE_BUY);
   count_sell=CountOrder(POSITION_TYPE_SELL);

   channel_condition = (OnlyBid ? last_tick.bid : last_tick.ask) < channel_lower - _Entry_Break*_Point;

   con_orders = _MaxConsecutiveOrders == 0 || (_MaxConsecutiveOrders != 0 && consecutive_orders_buy < _MaxConsecutiveOrders);

// Открытие сделок, если соблюдены все условия
   if(trade_direction != 2 && count_buy < 1 && _IsTime &&  //если нет открытых покупок
      channel_condition)    //если произошло касание канала BB
     {
      openresult=OpenTradeConditions("BUY", POSITION_TYPE_BUY, time_open_buy, count_buy, count_sell);
     }
   else
      if(trade_direction != 2 && count_buy >= 1 && count_buy < _TotalOrders && is_order_dist && _TimeCurrent-time_open_buy/*GetLastOpenTime(POSITION_TYPE_BUY)*/>MinPause && con_orders)
        {
         openresult=OpenTradeConditions("BUY", POSITION_TYPE_BUY, time_open_buy, count_buy, count_sell);
        }

   h_price=GetMaxMinOpenPrice(POSITION_TYPE_SELL, MAX); // максимальная цена открытых ордеров
   if(h_price != 0)
      is_order_dist = last_tick.bid > h_price+_OrdersDistance*_Point;
   else
      is_order_dist = true; // расстояние от открытых ордеров не меньше заданного

   count_buy=CountOrder(POSITION_TYPE_BUY);
   count_sell=CountOrder(POSITION_TYPE_SELL);

   channel_condition=false;
   bb_condition=false;
   k1_condition=false;

   channel_condition = last_tick.bid > channel_upper + _Entry_Break*_Point;

   con_orders = _MaxConsecutiveOrders == 0 || (_MaxConsecutiveOrders != 0 && consecutive_orders_sell < _MaxConsecutiveOrders);

   if(trade_direction != 1 && count_sell < 1 && _IsTime &&  //если нет открытых продаж
      channel_condition)    //если произошло касание канала BB
     {
      openresult=OpenTradeConditions("SELL", POSITION_TYPE_SELL, time_open_sell, count_sell, count_buy);
     }
   else
      if(trade_direction != 1 && count_sell >= 1 && count_sell < _TotalOrders && is_order_dist && _TimeCurrent-time_open_sell/*GetLastOpenTime(POSITION_TYPE_SELL)*/>MinPause && con_orders)
        {
         openresult=OpenTradeConditions("SELL", POSITION_TYPE_SELL, time_open_sell, count_sell, count_buy);
        }

  } //OnTick()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UpdateData(ENUM_TIMEFRAMES period)
  {
   if(Bars(_Symbol, period) <= 0)
     {
      int attempts=0;
      while(!SeriesInfoInteger(_Symbol, period, SERIES_SYNCHRONIZED) && !IsStopped() && attempts<1000)
        {
         Sleep(10);
         attempts++;
        }
     }
   return Bars(_Symbol, period) > 0;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetTimer(int time)
  {
   if(!_RealTrade)
      return;
   EventSetTimer(time);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   timer_active=true;
   OnTick();
  }

//+------------------------------------------------------------------+
bool Modify_and_exit_condition(int _OrderType, double _OrderLots, double _OrderOpenPrice, datetime _OrderOpenTime, long _OrderTicket, double _OrderStopLoss)
  {

   if((_Trail_Start > 0 || Trail_Minutes > 0) && _Trail_Size > 0)   //Тралл открытой позиции
     {
      if(!rollover_trall_end || (rollover_trall_end && !fGetRollOver()))
         fTrailingStopFunc();
     }

   string logstr="";
   string warnstr="";
   string filterstr="";
   int filterno=0;

   bool condition_for_the_exit = false;
//   bool channel_condition = false;
   bool bb_condition=false, k1_condition=false;
   bool channel_condition2 = false;

   double PriceType = last_tick.ask; //если ордер селл.
   double OrderDistance = _OrderOpenPrice - PriceType;
   double orderdist;
   string orderstr="";
   string ordertotalstr="";

   if(_OrderType == POSITION_TYPE_BUY)    //если ордер бай
     {
      PriceType = last_tick.bid;
      OrderDistance = PriceType - _OrderOpenPrice;
     }

   if(_TotalOrders>1 && CloseSimultaneously)
     {
      orderdist=OrderDistance;
      orderstr="; прибыль ордера - "+DoubleToString(orderdist/_Point/PipsDivided, 1)+" пунктов";
      ordertotalstr=" средняя";
      if(_OrderType == POSITION_TYPE_BUY)
        {
         OrderDistance=buy_total_profit;
         _OrderOpenTime=first_buy_open_time;
        }
      if(_OrderType == POSITION_TYPE_SELL)
        {
         OrderDistance=sell_total_profit;
         _OrderOpenTime=first_sell_open_time;
        }
     }

//if (_UseBBChannel) {
   if(_OrderType == POSITION_TYPE_SELL && (OnlyBid ? last_tick.bid : last_tick.ask) <= channel_lower - _Exit_Distance*_Point)
      bb_condition = true;
   else
      if(_OrderType == POSITION_TYPE_BUY && last_tick.bid >= channel_upper + _Exit_Distance*_Point)
         bb_condition = true;
//   }
   /*if (_Use_K1band) {
      if (_OrderType == POSITION_TYPE_SELL && (OnlyBid ? last_tick.bid : last_tick.ask) <= channel_sell_exit) k1_condition = true;
      else if (_OrderType == POSITION_TYPE_BUY && last_tick.bid >= channel_buy_exit) k1_condition = true;
      }*/

   if(_OrderType == POSITION_TYPE_SELL && (OnlyBid ? last_tick.bid : last_tick.ask) <= channel_lower - _Part_Distance*_Point)
      channel_condition2 = true;
   else
      if(_OrderType == POSITION_TYPE_BUY && last_tick.bid >= channel_upper + _Part_Distance*_Point)
         channel_condition2 = true;

   int exitmin=_Exit_Minutes;
   if(FixMondayTimeBug && _DayOfWeekShift == 1 && _TimeCurrent - _OrderOpenTime > 86400)
     {
      exitmin = _Exit_Minutes + 48*60;
     }
   if((_Exit_Minutes > 0 && _TimeCurrent - _OrderOpenTime > 60 * exitmin && // ордер открыт более _Exit_Minutes и
       OrderDistance > _Time_Profit_Pips*_Point) || (CloseReason_Multi[_OrderType] == 1))                                   // плавающая прибыль более _Time_Profit_Pips (0)
     {
      condition_for_the_exit = true;
      filterno=1;
      if(_LogMode < 2)
        {
         warnstr="1. Time";
         filterstr="1. Time";
         logstr = "Закрытие ордера #" + IntegerToString(_OrderTicket) + " по цене "+ DoubleToString(PriceType, _Digits) + " (фильтр "+filterstr+")" + ". Время существования более " + IntegerToString(_Exit_Minutes) +
                  " минут и"+ordertotalstr+" плавающая прибыль составляет более " + DoubleToString(_Time_Profit_Pips/PipsDivided, 1) + " пунктов: " + DoubleToString(OrderDistance/_Point/PipsDivided, 1)+" пунктов" + orderstr + "; Спред = " + DoubleToString((last_tick.ask - last_tick.bid) / _Point/PipsDivided, 1)+ " пунктов.";
        }
     }
   if((/*_UseBBChannel && */_Exit_Distance/PipsDivided < 100 && bb_condition && !DisableFilter2 &&    // цена вышла за границу канала и
                            OrderDistance > _Exit_Profit_Pips*_Point && !condition_for_the_exit) || (CloseReason_Multi[_OrderType] == 2))             // плавающая прибыль более _Exit_Profit_Pips (-12)
     {
      condition_for_the_exit = true;
      filterno=2;
      if(_LogMode < 2)
        {
         warnstr="2. BB Channel";
         filterstr="2. BB Channel";
         logstr = "Закрытие ордера #" + IntegerToString(_OrderTicket) + " по цене "+ DoubleToString(PriceType, _Digits) +  " (фильтр "+filterstr+")" + ". Цена пересекла границу канала " + DoubleToString((_OrderType==POSITION_TYPE_SELL?channel_lower:channel_upper), _Digits) + " на " +
                  DoubleToString(_Exit_Distance/PipsDivided, 1) + " пунктов и"+ordertotalstr+" плавающая прибыль составила более " + DoubleToString(_Exit_Profit_Pips/PipsDivided, 1) + " пунктов: " + DoubleToString(OrderDistance/_Point/PipsDivided, 1)+" пунктов" + orderstr + "; Спред = " + DoubleToString((last_tick.ask - last_tick.bid) / _Point/PipsDivided, 1)+ " пунктов.";
        }
     }

   if(_MA_period > 0 && _OrderOpenTime < iTime(NULL, TimeFrameMA, 0))  //фильтра по МА
     {

      int MA_Type_Exit = -1; //обнуление
      if(ma_shift[1] > ma_shift[2] && ma_shift[2] <= ma_shift[3] && ma_shift[3] <= ma_shift[4])
         MA_Type_Exit = POSITION_TYPE_SELL;
      else
         if(ma_shift[1] < ma_shift[2] && ma_shift[2] >= ma_shift[3] && ma_shift[3] >= ma_shift[4])
            MA_Type_Exit = POSITION_TYPE_BUY;

      if((((_OrderType == POSITION_TYPE_SELL && MA_Type_Exit == POSITION_TYPE_SELL) || (_OrderType == POSITION_TYPE_BUY && MA_Type_Exit == POSITION_TYPE_BUY)) && //скользящая средняя повышается или понижается
          OrderDistance > _Reverse_Profit*_Point && !condition_for_the_exit) || (CloseReason_Multi[_OrderType] == 3))   // и плавающая прибыль более _Reverse_Profit (20)
        {
         condition_for_the_exit = true;
         filterno=3;
         if(_LogMode < 2)
           {
            warnstr="3. MA";
            filterstr="3. MA";
            logstr = "Закрытие ордера #" + IntegerToString(myposition.Ticket()) + " по цене "+ DoubleToString(PriceType, _Digits) +  " (фильтр "+filterstr+")" + ". Скользящая средняя изменяется" +
                     " и"+ordertotalstr+" плавающая прибыль более " + DoubleToString(_Reverse_Profit/PipsDivided, 1) + " пунктов: " + DoubleToString(OrderDistance/_Point/PipsDivided, 1)+" пунктов" + orderstr + "; Спред = " + DoubleToString((last_tick.ask - last_tick.bid) / _Point/PipsDivided, 1)+ " пунктов.";
           }
        }
     }

   if((_cci_Period_close > 0 && !condition_for_the_exit && OrderDistance > _CCI_Profit_Pips*_Point && cci_signal_close != _OrderType &&
       cci_signal_close != -1) || (CloseReason_Multi[_OrderType] == 5))   //фильтр по CCI
     {
      condition_for_the_exit = true;
      filterno=5;
      if(_LogMode < 2)
        {
         warnstr="5. CCI";
         filterstr="5. CCI";
         logstr = "Закрытие ордера #" + IntegerToString(_OrderTicket) + " по цене "+ DoubleToString(PriceType, _Digits) +  " (фильтр "+filterstr+")" + "; Спред = " + DoubleToString((last_tick.ask - last_tick.bid) / _Point/PipsDivided, 1)+ " пунктов.";
        }
     }

   if((_PartialClose_Percent > 0 && channel_condition2 && ((_OrderType == POSITION_TYPE_BUY?_OrderLots == lots_opened_buy:_OrderLots == lots_opened_sell)) && !condition_for_the_exit &&    // частичное закрытие
       OrderDistance > _Part_Profit_Pips*_Point) || (CloseReason_Multi[_OrderType] == 4))
     {
      double _lots = MathFloor((_OrderLots*_PartialClose_Percent)/SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP))* SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      _lots = MathMax(_lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)); //сравнение полученнго лота с минимальным

      if((_lots < _OrderLots) || (Part_AllowCloseFull && _lots <= _OrderLots))
        {
         condition_for_the_exit = true;
         _OrderLots = _lots;
         filterno=4;
         if(_LogMode < 2)
           {
            warnstr="4. Partial Close";
            filterstr="4. Partial Close";
            logstr = "Частичное закрытие "+DoubleToString(_OrderLots, 2)+" лотов ордера #" + IntegerToString(_OrderTicket) + " по цене "+ DoubleToString(PriceType, _Digits) +  " (фильтр "+filterstr+")" +
                     ". Плавающая прибыль составила более " + DoubleToString(_Part_Profit_Pips/PipsDivided, 1) + " пунктов: " + DoubleToString(OrderDistance/_Point/PipsDivided, 1)+" пунктов" + orderstr + "; Спред = " + DoubleToString((last_tick.ask - last_tick.bid) / _Point/PipsDivided, 1)+ " пунктов.";
           }
        }
     }

   int hardexitmin=_HardExit_Minutes;
   if(FixMondayTimeBug && _DayOfWeekShift == 1 && _TimeCurrent - _OrderOpenTime > 86400)
     {
      hardexitmin = _HardExit_Minutes + 48*60;
     }
   if(_HardExit_Minutes > 0 || _HardExit_TimeHour > -1)
     {
      bool IsHardExitTime = false;
      string reason = "";
      if(_HardExit_Minutes > 0 && _TimeCurrent - _OrderOpenTime > 60 * hardexitmin)
        {
         IsHardExitTime = true;
         reason = "Время существования более " + IntegerToString(_HardExit_Minutes) + " минут";
        }
      if(_HardExit_TimeHour > -1 && _OrderOpenTime < _HardExitTime && _TimeCurrent >=_HardExitTime)
        {
         IsHardExitTime = true;
         reason = "Закрытие по наступлению времени суток - " + IntegerToString(_HardExit_TimeHour) + ":" + IntegerToString(HardExit_TimeMin, 2, StringGetCharacter("0", 0));
        }
      if((IsHardExitTime &&  // ордер открыт более _Exit_Minutes и
          (OrderDistance > _HardExit_Profit*_Point)) || (CloseReason_Multi[_OrderType] == 6))                                   // плавающая прибыль более _Time_Profit_Pips (0)
        {
         condition_for_the_exit = true;
         filterno=6;
         if(_LogMode < 2)
           {
            warnstr="6. Hard Exit";
            filterstr="6. Hard Exit";
            logstr = "Закрытие ордера #" + IntegerToString(_OrderTicket) + " по цене "+ DoubleToString(PriceType, _Digits) +  " (фильтр "+filterstr+")" + ". "+ reason +
                     " и"+ordertotalstr+" плавающая прибыль составляет " + "более "+ DoubleToString(_HardExit_Profit/PipsDivided, 1) + " пунктов: " + DoubleToString(OrderDistance/_Point/PipsDivided, 1)+" пунктов" + orderstr + "; Спред = " + DoubleToString((last_tick.ask - last_tick.bid) / _Point/PipsDivided, 1)+ " пунктов.";
           }
        }
     }

   if(CloseReason_Multi[_OrderType] == 0 && condition_for_the_exit)
     {
      if((!CloseOrdersInRollover) && fGetRollOver())
        {
         if(_LogMode < 2 && _TimeCurrent-lasttimewrite > 60)
           {
            logstr = "Попытка закрытия ордера #" + IntegerToString(myposition.Ticket()) + " (фильтр "+filterstr+"): Фильтр ролловера. Ордер не был закрыт.";
            warnstr += " + rollover";
            DrawWarn(warnstr, WarnExitColor);
            Print(logstr);
            fWriteDataToFile(logstr);
            lasttimewrite = _TimeCurrent;
           }
         return(false);
        }
      if(_Max_Spread_On_Close>0)
        {
         if((last_tick.ask - last_tick.bid) > _Max_Spread_On_Close*_Point && (myposition.PositionType()==POSITION_TYPE_SELL || CheckSpreadOnBuyClose) && OrderDistance < _MaxSpreadOnClose_Profit*_Point)    //фильтр по максимальному спреду
           {
            if(_LogMode < 2 && _TimeCurrent-lasttimewrite > 60)
              {
               logstr = "Попытка закрытия ордера #" + IntegerToString(myposition.Ticket()) + " (фильтр "+filterstr+"): Спред (" + DoubleToString((last_tick.ask - last_tick.bid) / _Point/PipsDivided, 1) + " пунктов) больше максимального (" + DoubleToString(_Max_Spread_On_Close/PipsDivided, 1) + ")! Ордер не был закрыт.";
               warnstr += " + spread";
               DrawWarn(warnstr, WarnExitColor);
               Print(logstr);
               fWriteDataToFile(logstr);
               lasttimewrite = _TimeCurrent;
              }
            return(false);
           }
        }
     }

   if(Grid_Step && Trades[0]+Trades[1] > 1)
      condition_for_the_exit = false;
   if(Grid_Step && GetProfitOpenPosInPoint(Symbol(), -1, MagicNumber) < 0)
      condition_for_the_exit = false;

   if(condition_for_the_exit)   //если сработал хоть один фильтр:
     {

      if(_TotalOrders>1 && CloseSimultaneously)
         CloseReason_Multi[_OrderType]=filterno;

      if(warnstr != "")
         DrawWarn(warnstr, WarnExitColor);
      if(logstr != "")
        {
         Print(logstr);
         fWriteDataToFile(logstr);
        }

      int at=0;

      if(!trade.PositionClose(_OrderTicket))  //закрытие ордера
        {
         if(_LogMode < 3)
           {
            string q = __FUNCTION__ + ": Ордер " + _Symbol + " #" + IntegerToString(myposition.Ticket()) + " не был закрыт! " + trade.ResultRetcodeDescription();
            Print(q);
           }
        }
      else
        {
         //Sleep(1000);
         return(true);
        }
      //Sleep(3000);
      return(true);
     }

   return(true);
  }

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool OpenTradeConditions(string _OrderType, int OP_TYPE, datetime &time_open, int order_cnt, int opposite_order)
  {

   if(IsNews())
      return false; //не открывать ордера во время новостей.

   bool donotcheck = (order_cnt > 0 && DoNotCheckAfterFirst);

   if(/*order_cnt == 0 && */cci_Period_open > 0 && cci_signal_open != OP_TYPE)   //фильтр по CCI // проверять только при открытии первого ордера
     {
      if(_LogMode < 2 && lastbarwrite != iTimeTF)
        {
         string q = _Symbol + "| CCI не вышел за уровень: ±" + IntegerToString(cci_level_open) + " Ордер " + _OrderType + " не был открыт.";
         Print(q);
         fWriteDataToFile(q);
         DrawWarn("filter CCI", WarnEnterColor);
         lastbarwrite = iTimeTF;
        }
      return(false);
     }


   if(cci_Period_close > 0 && cci_signal_close != OP_TYPE && cci_signal_close != -1)   //фильтр по CCI по закрытию включён
     {
      if(_LogMode < 2 && lastbarwrite != iTimeTF)
        {
         string q = Symbol() + "| CCI по закрытию находится за уровнем: ±" + IntegerToString(cci_level_close) + " Ордер " + _OrderType + " не был открыт.";
         Print(q);
         fWriteDataToFile(q);
         DrawWarn("filter CCI close", WarnEnterColor);
         lastbarwrite = iTimeTF;
        }
      return(false);
     }

   if(!donotcheck && channel_width != 0 && channel_width < _Min_Volatility*_Point)    //фильтр по ширине канале
     {
      if(_LogMode < 2 && lastbarwrite != iTimeTF)
        {
         string q = _Symbol + "| Текущая ширина канала: (" + DoubleToString(channel_width/_Point/PipsDivided, 1) + " пунктов) меньше, чем минимальная ширина канала: " + DoubleToString(_Min_Volatility/PipsDivided, 1) + " Ордер " + _OrderType + " не был открыт.";
         Print(q);
         fWriteDataToFile(q);
         DrawWarn("filter channel width", WarnEnterColor);
         lastbarwrite = iTimeTF;
        }
      return(false);
     }
   if(!donotcheck && Max_Volatility > 0 && channel_width > _Max_Volatility*_Point)    //фильтр по максимальной ширине канале
     {
      if(_LogMode < 2 && lastbarwrite != iTimeTF)
        {
         string q = _Symbol + "| Текущая ширина канала: (" + DoubleToString(channel_width/_Point/PipsDivided, 1) + " пунктов) больше, чем максимальная ширина канала: " + DoubleToString(_Max_Volatility/PipsDivided, 1) + " Ордер " + _OrderType + " не был открыт.";
         Print(q);
         fWriteDataToFile(q);
         DrawWarn("filter max channel width", WarnEnterColor);
         lastbarwrite = iTimeTF;
        }
      return(false);
     }
   if(!donotcheck && _maxcandle > 0)
     {
      double candlehl=0;
      double candlerange=0;
      if(OP_TYPE==POSITION_TYPE_BUY)
        {
         double h[];
         CopyHigh(NULL, _TimeFrame, 0, barcount, h);
         if(ArrayMaximum(h)==-1)
            return false;
         candlerange=h[ArrayMaximum(h)]-last_tick.ask;
        }
      if(OP_TYPE==POSITION_TYPE_SELL)
        {
         double l[];
         CopyLow(NULL, _TimeFrame, 0, barcount, l);
         if(ArrayMinimum(l)==-1)
            return false;
         candlerange=last_tick.bid-l[ArrayMinimum(l)];
        }
      if(candlerange>_maxcandle*_Point)
        {
         //      if (((OP_TYPE==POSITION_TYPE_BUY) && (candlehl-last_tick.ask>_maxcandle*_Point)) ||
         //         ((OP_TYPE==POSITION_TYPE_SELL) && (last_tick.bid-candlehl>_maxcandle*_Point))) {
         //if ((candle() > _maxcandle*_Point)){ // Фильтр по размеру предыдущих свечей
         if(_LogMode < 2 && lastbarwrite != iTimeTF)
           {
            //string q = _Symbol + "| Найдена свеча за предыдущих " + IntegerToString(barcount) + " баров, больше " + DoubleToString(_maxcandle/PipsDivided, 1) + " пунктов. Ордер " + _OrderType + " не был открыт.";
            string q = _Symbol + "| Диапазон движения цены за предыдущих " + IntegerToString(barcount) + " баров "+_period+" (" + DoubleToString(candlerange/_Point/PipsDivided, 1) + " пунктов) больше " + DoubleToString(_maxcandle/PipsDivided, 1) + " пунктов. Ордер " + _OrderType + " не был открыт.";
            Print(q);
            fWriteDataToFile(q);
            lastbarwrite = iTimeTF;
           }
         return(false);
        }
     }
   if(!Hedging && opposite_order >= 1)    //фильтр запрета на хеджирования
     {
      if(_LogMode < 2 && _TimeCurrent-lasttimewrite > 120)
        {
         string q = _Symbol + "| Фильтр хеджирующих позиций включен и найдена противоположная сделка. Ордер " + _OrderType + " не был открыт.";
         Print(q);
         fWriteDataToFile(q);
         DrawWarn("filter hedge", WarnEnterColor);
         lasttimewrite = _TimeCurrent;
        }
      return(false);
     }
   if(!donotcheck && _MaxDailyRange > 0)   //фильтр _MaxDailyRange
     {
      int mdr_shift=0;
      double OpenD1;
      datetime timeopend1=DayStartTimeShift;
      if(TimeShift < 0 && _TimeCurrent > DayStartTimeShift+24*60*60 && !_CheckMDRAfter0)
        {
         timeopend1 = DayStartTimeShift+24*60*60;
        }
      if(TimeShift == 0 && _CheckMDRAfter0)
        {
         timeopend1 = DayStartTimeShift-24*60*60;
        }
      //if (_CheckMDRAfter0 && _IsFirstSession) mdr_shift=1;
      //iOpenD1=iOpen(NULL,PERIOD_D1,mdr_shift);
      int barshift;
      int a=0;
      do
        {
         barshift=iBarShift(NULL, _Period, timeopend1, true);
         if(barshift==-1)
            timeopend1 -= 24*60*60; // если попадает на выходные
         //if (barshift==-1) Print("BarShift = -1, timeopend1 = ",TimeToStr(timeopend1));
         a++;
        }
      while(barshift == -1 && a < 10);
      if(a>=10)
        {
         Print("BarShift Error");
         return(false);
        }
      if(MDRFromHiLo && barshift>0)
        {
         double h[], l[];
         CopyHigh(NULL, _TimeFrame, 0, barshift+1, h);
         CopyLow(NULL, _TimeFrame, 0, barshift+1, l);
         if(OP_TYPE==POSITION_TYPE_BUY)
            OpenD1=h[ArrayMaximum(h)];
         else
            OpenD1=l[ArrayMinimum(l)];
        }
      else
         OpenD1 = iOpen(NULL, _Period, barshift);
      double mdr = OP_TYPE==POSITION_TYPE_BUY ? OpenD1 - last_tick.bid : last_tick.bid - OpenD1;
      //if (mdr == 0) { Print("mdr = 0"); return(false); }
      if(mdr > _MaxDailyRange*_Point)
        {
         if(_LogMode < 2 && lastbarwrite != iTimeTF)
           {
            string q = _Symbol + "| Дневной диапазон движения цены: (" + DoubleToString(mdr/_Point/PipsDivided, 1) + " пунктов) ,больше _MaxDailyRange: " + DoubleToString(_MaxDailyRange/PipsDivided, 1) + " Ордер " + _OrderType + " не был открыт.";
            Print(q);
            lastbarwrite = iTimeTF;
           }
         return(false);
        }
     }
   if(!donotcheck && _MDR_Toward > 0)   //фильтр MDR_Toward
     {
      int mdr_shift=0;
      double OpenD1;
      datetime timeopend1=DayStartTimeShift;
      if(TimeShift < 0 && _TimeCurrent > DayStartTimeShift+24*60*60 && !_CheckMDRAfter0)
        {
         timeopend1 = DayStartTimeShift+24*60*60;
        }
      if(TimeShift == 0 && _CheckMDRAfter0)
        {
         timeopend1 = DayStartTimeShift-24*60*60;
        }
      //if (_CheckMDRAfter0 && _IsFirstSession) mdr_shift=1;
      //iOpenD1=iOpen(NULL,PERIOD_D1,mdr_shift);
      int barshift=iBarShift(NULL, _Period, timeopend1);
      if(MDR_Toward_FromHiLo && barshift>0)
        {
         double h[], l[];
         CopyHigh(NULL, _TimeFrame, 0, barshift+1, h);
         CopyLow(NULL, _TimeFrame, 0, barshift+1, l);
         if(OP_TYPE==POSITION_TYPE_BUY)
            OpenD1=l[ArrayMinimum(l)];
         else
            OpenD1=h[ArrayMaximum(h)];
        }
      else
         OpenD1 = iOpen(NULL, _Period, barshift);
      double mdr_toward = OP_TYPE==POSITION_TYPE_BUY ? last_tick.bid - OpenD1  : OpenD1 - last_tick.bid ;
      //if (mdr_toward == 0) { Print("mdr_toward = 0"); return(false); }
      if(mdr_toward > _MDR_Toward*_Point)
        {
         if(_LogMode < 2 && lastbarwrite != iTimeTF)
           {
            string q = _Symbol + "| Дневной диапазон движения цены: (" + DoubleToString(mdr_toward/_Point/PipsDivided, 1) + " пунктов) ,больше MDR_Toward: " + DoubleToString(_MDR_Toward/PipsDivided, 1) + " Ордер " + _OrderType + " не был открыт.";
            Print(q);
            lastbarwrite = iTimeTF;
           }
         return(false);
        }
     }
   if(_RealTrade && _MaxAmountCurrency>0)    //фильтр по максимально разрешенному обьему
     {
      string Str, Str1, Str2;
      double MaxLot;
      MaxLot=_MaxAmountCurrency;
      CheckArbitrage();
      Str1 = StringSubstr(_Symbol, 0, 3);
      Str2 = StringSubstr(_Symbol, 3, 3);
      bool allow_by_max_amount=true;
      if(OP_TYPE==POSITION_TYPE_BUY)
        {
         if(Volumes(Str1) >= MaxLot)
           {
            Str=Str1;
            allow_by_max_amount=false;
           }
         if(Volumes(Str2) <= -MaxLot)
           {
            Str=Str2;
            allow_by_max_amount=false;
           }
        }
      if(OP_TYPE==POSITION_TYPE_SELL)
        {
         if(Volumes(Str1) <= -MaxLot)
           {
            Str=Str1;
            allow_by_max_amount=false;
           }
         if(Volumes(Str2) >= MaxLot)
           {
            Str=Str2;
            allow_by_max_amount=false;
           }
        }
      if(!allow_by_max_amount)
        {
         if(_LogMode < 2 && lastbarwrite != Time[0])
           {
            string q = _Symbol + "| Максимальное количество сделок в одном направлении ("+DoubleToString(MaxLot, 0)+") по " + Str + " будет превышено." + " Ордер " + _OrderType + " не был открыт.";
            Print(q);
            DrawWarn("filter _MaxAmountCurrency", WarnEnterColor);
            lastbarwrite = Time[0];
           }
         return(false);
        }
     }
   if(_RealTrade && _MaxAmountCurrencyPair>0)    //фильтр по максимально разрешенному обьему
     {
      if(CountOrder2(OP_TYPE) >= _MaxAmountCurrencyPair)
        {
         if(_LogMode < 2 && lastbarwrite != Time[0])
           {
            string q = _Symbol + "| Максимальное количество сделок в одном направлении ("+IntegerToString(_MaxAmountCurrencyPair)+") по " + _Symbol + " будет превышено." + " Ордер " + _OrderType + " не был открыт.";
            Print(q);
            DrawWarn("filter _MaxAmountCurrencyPair", WarnEnterColor);
            lastbarwrite = Time[0];
           }
         return(false);
        }
     }

   if(_Max_Spread > 0 && (last_tick.ask - last_tick.bid) > _Max_Spread*_Point && (CheckSpreadOnSellOpen || OP_TYPE==POSITION_TYPE_BUY))    //фильтр по максимальному спреду
     {
      if(_LogMode < 2 && _TimeCurrent-lasttimewrite > 60)
        {
         string q = _Symbol + "| Спред (" + DoubleToString((last_tick.ask - last_tick.bid) / _Point/PipsDivided, 1) + " пунктов) больше максимального (" + DoubleToString(_Max_Spread/PipsDivided, 1) + ")! Ордер " + _OrderType + " не был открыт.";
         Print(q);
         fWriteDataToFile(q);
         DrawWarn("filter spread", WarnEnterColor);
         lasttimewrite = _TimeCurrent;
        }
      return(false);
     }



   if(_pause > 0 && lastloss() != 0)    //если последний ордер не закрыт в профит (или убыток больше заданного)
     {
      return(false);
     }

   if(!trading_allowed_global)
     {
      if(_LogMode < 3 && lastbarwrite1 != iTimeTF)
        {
         string q = _Symbol + "| Торговля запрещена на основании глобальных переменных." + " Ордер " + _OrderType + " не был открыт.";
         Print(q);
         fWriteDataToFile(q);
         DrawWarn("trade is not allowed", WarnEnterColor);
         lastbarwrite1 = iTimeTF;
        }
      return(false);
     }

   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
     {
      if(_LogMode < 3 && lastbarwrite1 != iTimeTF)
        {
         string q = _Symbol + "| Торговля не разрешена. Необходимо включить опцию <Разрешить " +
                    "советнику торговать> в свойствах эксперта." + " Ордер " + _OrderType + " не был открыт.";
         Print(q);
         fWriteDataToFile(q);
         DrawWarn("trade is not allowed", WarnEnterColor);
         lastbarwrite1 = iTimeTF;
        }
      return(false);
     }
	 
   if(!donotcheck && ATR_Period > 0) {
      int handle=iATR(Symbol(), ATR_Timeframe, ATR_Period);
      double atrValue = CopyBufferMQL4(handle,0,0);
      if(atrValue > Max_ATR_Pips * old_point) {
         string q = Symbol() + "| Current ATR: (" + DoubleToString(atrValue/old_point, 1) + " pips) is greater than the maximum ATR: " + DoubleToString(Max_ATR_Pips, 1) + " Order " + _OrderType + " was not open.";
         Print(q); fWriteDataToFile(q);
         DrawWarn("filter ATR",WarnEnterColor);
	     lastbarwrite = iTimeTF;
         return (false);
      }
   }	

   if(_TimeCurrent>DisableStartTime && _TimeCurrent<DisableEndTime)
      return(false);
   bool res=false;

   res=OpenTrade(_OrderType, order_cnt);  //открываем торговый ордер
   if(res)
     {
      time_open = _TimeCurrent;
      if(OP_TYPE == POSITION_TYPE_BUY)
         consecutive_orders_buy++;
      else
         consecutive_orders_sell++;
     }

   return(res);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool OpenTrade(string type, int _orderCount) //открытие ордеров
  {
   double price = 0;
   double sl=0;
   double tp = 0;
   int cmd = -1;
   color col_type = clrNONE;

   if(_Auto_Risk > 0)
      lots1 = AutoMM_Count(_orderCount); //расчет торгового лота
   else
      lots1 = Lots;

   if(Grid_Step && (Trades[0]+Trades[1])  > 0 && Grid_Lot_multiplikator > 1)
     {
      lots1 = lots1 * MathPow(Grid_Lot_multiplikator, (Trades[0]+Trades[1]));
      lots1 = (NormalizeDouble(lots1, 2));
     }
   for(int count = 0; count < 5; count++)
     {

      if(type == "BUY")
        {
         if(!Grid_Step)
           {
            sl = NormalizeDouble(last_tick.ask - _Stop_Loss*_Point, _Digits);
            tp = NormalizeDouble(last_tick.ask + _Take_Profit*_Point, _Digits);
           }
         if(!trade.Buy(lots1, _Symbol, last_tick.ask, sl, tp, "Generic A-TLP|"+IntegerToString(MagicNumber))) {}
        }
      if(type == "SELL")
        {
         if(!Grid_Step)
           {
            sl = NormalizeDouble(last_tick.bid + _Stop_Loss*_Point, _Digits);
            tp = NormalizeDouble(last_tick.bid - _Take_Profit*_Point, _Digits);
           }
         if(!trade.Sell(lots1, _Symbol, last_tick.bid, sl, tp, "Generic A-TLP|"+IntegerToString(MagicNumber))) {}
        }
      int ticket = (int)trade.ResultOrder();

      Sleep(3000);
      if(ticket > 0)
        {
         lastticket = ticket;
         if(_LogMode < 3)
           {
            if(!myposition.SelectByTicket(ticket))
              {
               string q = __FUNCTION__ + ": не удалось выделить ордер " +
                          IntegerToString(ticket) + "! " + fMyErDesc();
               Print(q);
              }
           }
         if(_LogMode < 2)
           {
            string q = __FUNCTION__ + ": ордер " + type + " открыт по цене " + DoubleToString(myposition.PriceOpen(), _Digits) + "; Ширина канала  = " + DoubleToString(channel_width/_Point, 1) + "; Спред = " + DoubleToString((last_tick.ask-last_tick.bid)/10/_Point, 1);
            Print(q);
           }
         return(true);
        }
      else
        {
         lastticket = 0;
         if(_LogMode < 3)
           {
            string q = __FUNCTION__ + ": ордер " + type + " не был открыт!: " + trade.ResultRetcodeDescription();
            Print(q);
           }
        }
     }
   return(false);
  }

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CheckScale() {
   double checkScale = 1.0;
   if(GlobalVariableCheck("IncoGlobalRiskScale")) {
      checkScale = GlobalVariableGet("IncoGlobalRiskScale");
   } else {
      risk_scale = "";
   }
   if(MathAbs(checkScale - globalRiskScale) > DBL_EPSILON) {
      globalRiskScale = checkScale;
      risk_scale = "\n  Global Risk Scale: " + DoubleToString(globalRiskScale, 2);
      UpdateInfoPanel();
   }
}
double AutoMM_Count(int _orderCount) //Расчет лота при указании процента риска в настройках.
  {
   double lot=_Lots;
   if(_Auto_Risk > 0.0)
     {
      if(MM_Depo == 0)
        {

         double TickValue = (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) == 0 ? 1 : SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE));
         double Balance = (AccountInfoDouble(ACCOUNT_EQUITY) > AccountInfoDouble(ACCOUNT_BALANCE) ? AccountInfoDouble(ACCOUNT_BALANCE) : AccountInfoDouble(ACCOUNT_EQUITY));
         if(VirtualDepo>0)
            Balance = VirtualDepo;
         lot = ((Balance - AccountInfoDouble(ACCOUNT_CREDIT)) * (_Auto_Risk / 100)) / _Stop_Loss / TickValue;
         //lot = MathFloor(lot/SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP))* SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP); //округление полученного лота вниз
         //lot = MathMin(MathMax(lot, SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN)), SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX)); //сравнение полученнго лота с минимальным/максимальным.
         //Print(lot + " " + StopLoss + " / " + SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)/0.00001);
         //return (lot);
        }
      else
         lot = NormalizeDouble(_Lots * MathFloor(AccountInfoDouble(ACCOUNT_BALANCE)/MM_Depo), 2);
      //lot = MathMin(MathMax(lot, SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN)), SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX)); //сравнение полученнго лота с минимальным/максимальным.
     }
	 lot = lot * MathPow(MultLot, _orderCount);
	 lot = NormalizeDouble(lot * globalRiskScale, 2);
   if(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) != 0)
      lot = MathFloor(lot/SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP))* SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP); //округление полученного лота вниз
   lot = MathMin(MathMax(lot, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)), SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX)); //сравнение полученнго лота с минимальным/максимальным.
   return(lot);
  }

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
int lastloss()
  {
   int signal = 0;
   int oldticket = 0;
   int ticket = 0;
   double priceopen = 0;
   double priceclose = 0;
   datetime closetime = 0;
   int otype = -1;


   if(lastticket > 0)
     {
      oldticket = lastticket;
     }
   else
     {
      if(_LogMode < 2)
        {
         Print(__FUNCTION__ + ": не обнаружены ранее закрытые ордера, функция пропущена");
        }
     }

   if(oldticket > 0)
     {
      HistorySelect(TimeCurrent()-PeriodSeconds(PERIOD_MN1), TimeCurrent());

      double dealclose=0;
      for(int j=HistoryDealsTotal()-1; j>=0; j--)
        {
         mydeal.SelectByIndex(j);
         if(mydeal.Entry() == DEAL_ENTRY_OUT)
           {
            priceclose = mydeal.Price();
            closetime = mydeal.Time();
           }
         if(mydeal.Entry() == DEAL_ENTRY_IN)
           {
            priceopen = mydeal.Price();
            otype = mydeal.DealType();
            break;
           }
        }
     }
   else
     {
      if(_LogMode < 2)
        {
         Print(__FUNCTION__ + ": тикет предыдущего ордера не найден. Возможно, советник ранее не открывал ордера.");
        }
     }

//if (otype == DEAL_TYPE_BUY) Print("!!! ",(priceopen-priceclose)/_Point, " ", _sizeloss);
//if (otype == DEAL_TYPE_SELL) Print("!!! ",(priceclose-priceopen)/_Point, " ", _sizeloss);

   if(otype == DEAL_TYPE_BUY && priceopen-priceclose > _sizeloss*_Point && TimeCurrent()-closetime < _pause*60)
      signal = 1;

   if(otype == DEAL_TYPE_SELL && priceclose-priceopen > _sizeloss*_Point && TimeCurrent()-closetime < _pause*60)
      signal = 2;

   if(signal > 0)
     {
      if(_LogMode<2)
        {
         string q1 = __FUNCTION__ + ": Сработал фильтр по убытку последнего закрытого ордера. Новый ордер не был открыт.";
         string q2 = __FUNCTION__ + ": До возможности открытия нового ордера осталось " + DoubleToString(_pause-(TimeCurrent()-closetime)/60, 0)+" минут";

         Print(q1);
         Print(q2);
        }
      last_closetime = closetime;
     }

   return (signal);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
/*double candle()
{
   double c = 0;
   for (int i = 0; i<=barcount; i++) {
      if (iHigh (NULL,_TimeFrame,i)-iLow(NULL,_TimeFrame,i)>= c) c = iHigh(NULL,_TimeFrame,i)-iLow(NULL,_TimeFrame,i);
   }
return (c);
}*/

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void fTrailingStopFunc()
  {

   double tr_start = _Trail_Start*_Point;
   double tr_size = _Trail_Size*_Point;
   double tr_step = MathMax(_Trail_Step*_Point, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE)*_Point);

   if(myposition.PositionType() == POSITION_TYPE_BUY)
     {
      double tr_pos=last_tick.bid - tr_size;
      if(((Trail_Minutes > 0 && _TimeCurrent - myposition.Time() > 60*Trail_Minutes) || (_Trail_Start > 0 && last_tick.bid-myposition.PriceOpen()>=tr_start)) && tr_pos-myposition.StopLoss()>=tr_step && (!Trail_From_BE_Line || last_tick.bid-myposition.PriceOpen()>=tr_size))
        {
         fModifyPosition(myposition.Ticket(), myposition.PriceOpen(), NormalizeDouble(tr_pos, _Digits), myposition.TakeProfit(), 0, clrGreen);
         return;
        }
      /*if(myposition.StopLoss() < myposition.PriceOpen() && last_tick.bid - myposition.PriceOpen() >= tr_start){ //если SL еще не двигали
         fModifyPosition(myposition.Ticket(),myposition.PriceOpen(),NormalizeDouble(last_tick.bid - tr_start,_Digits),myposition.TakeProfit(),0,clrGreen);
         return;
      }
      if(myposition.StopLoss() >= myposition.PriceOpen()){ //если SL уже двигали
         double dif = last_tick.bid - myposition.StopLoss() - tr_size;
         if(dif >= tr_step)
            fModifyPosition(myposition.Ticket(),myposition.PriceOpen(),NormalizeDouble(myposition.StopLoss() + dif,_Digits),
                              myposition.TakeProfit(),0,clrGreen);
         return;
      }*/
     }
   else
      if(myposition.PositionType() == POSITION_TYPE_SELL)
        {
         double tr_pos=last_tick.ask + tr_size;
         if(((Trail_Minutes > 0 && _TimeCurrent - myposition.Time() > 60*Trail_Minutes) || (_Trail_Start > 0 && myposition.PriceOpen()-last_tick.ask>=tr_start)) && myposition.StopLoss()-tr_pos>=tr_step && (!Trail_From_BE_Line || myposition.PriceOpen()-last_tick.ask>=tr_size))
           {
            fModifyPosition(myposition.Ticket(), myposition.PriceOpen(), NormalizeDouble(tr_pos, _Digits), myposition.TakeProfit(), 0, clrGreen);
            return;
           }
         /*if(myposition.StopLoss() > myposition.PriceOpen() && myposition.PriceOpen() - last_tick.ask >= tr_start){ //если SL еще не двигали
            fModifyPosition(myposition.Ticket(),myposition.PriceOpen(),NormalizeDouble(last_tick.ask + tr_start,_Digits),myposition.TakeProfit(),0,clrTomato);
            return;
         }
         if(myposition.StopLoss() <= myposition.PriceOpen()){ //если SL уже двигали
            double dif = myposition.StopLoss() - last_tick.ask - tr_size;
            if(dif >= tr_step)
               fModifyPosition(myposition.Ticket(),myposition.PriceOpen(),NormalizeDouble(myposition.StopLoss() - dif,_Digits),
                                 myposition.TakeProfit(),0,clrTomato);
            return;
         }*/
        }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void fModifyPosition(ulong ticket, double price, double sl, double tp, datetime expir = 0, color col = clrNONE)
  {
   if(!trade.PositionModify(ticket, NormalizeDouble(sl, _Digits), NormalizeDouble(tp, _Digits)))
     {
      if(_LogMode < 3)
        {
         string q = __FUNCTION__ + ": не удалось модифицировать ордер #" +
                    IntegerToString(ticket) + "! " + trade.ResultRetcodeDescription();
         Print(q);

        }
     }
   Sleep(1000);
  }

//+------------------------------------------------------------------+
//    возвращает ИСТИНА, если сейчас время ролловера                 +
//    иначе - ЛОЖЬ                                                   +
//+------------------------------------------------------------------+
bool fGetRollOver(void)
  {
//if(use_rollover_filter) { //Не открывать сделки в ролловер.
   if(rtime1 > rtime2)
     {
      if((_TimeCurrent >= rtime1 && _TimeCurrent < rtime2+60*60*24) || (_TimeCurrent >= rtime1-60*60*24 && _TimeCurrent < rtime2))
        {
         //         if(_TimeCurrent >= rtime1 || _TimeCurrent < rtime2)
         return(true);
        }
     }
   else
     {
      if(_TimeCurrent >= rtime1 && _TimeCurrent < rtime2)
         return(true);
     }
//}
   return(false);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
string timestr(int h, int m)
  {
   int hh=h;
   if(hh==24)
      hh=0;
   string h1, m1;
   h1=IntegerToString(hh, 2, '0');
   m1=IntegerToString(m, 2, '0');
   return h1+":"+m1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string fInfoTradeHours()
  {

   int day=tm.day_of_week;
   string str="", dayupcase;
//bool showday;

   dayupcase=daystring[day];
   StringToUpper(dayupcase);

   str  = "\n  "+dayupcase+"    (GMT "+StringFormat("%+d",GMT_Offset)+", DST " + dstStr[DSTMode] + ")";
//showday = (DayStart[day] != DayEnd[day]) || (DayStart[day] != day);
   if((tm.mon == 12 && tm.day > LastTradeDayDecember) 
   || (tm.mon == 1 && tm.day < FirstTradeDayJanuary)) {
      str += "\n  Merry Christmas!!!\n";
   }
   
   if (DisableTradeOnHolidays && IsAroundHoliday(_TimeCurrent)) {
      str += "\n No trade on holliday \n";
   }

   if((First_StartTimeStr != First_EndTimeStr) ||
      (Second_StartTimeStr != Second_EndTimeStr))
     {
      if(First_StartTimeStr != First_EndTimeStr)
        {
         str += "\n  First Session:     " + First_StartTimeStr + " - " + First_EndTimeStr;
        }
      else
         str += "\n";

      if(Second_StartTimeStr != Second_EndTimeStr)
        {
         str += "\n  Second Session: " + Second_StartTimeStr + " - " + Second_EndTimeStr;
        }
      else
         str += "\n";
     }
   else
     {
      str += "\n  No trade today\n";
     }

   /*if (First_StartTimeStr[day] != First_EndTimeStr[day]) {
      str += "\n  Start Time: " + First_StartTimeStr[day];
      if (showday)    str += ", "+daystring[DayStart[day]];
      str += "\n  End Time:  " + First_EndTimeStr[day];
      if (showday)    str += ", "+daystring[DayEnd[day]];
      }
   else {
      str += "\n  No trade today\n";
      }*/

   return(str);

  }

//+------------------------------------------------------------------+
bool IsTime()
  {
   if((tm.mon == 12 && tm.day > LastTradeDayDecember) 
   || (tm.mon == 1 && tm.day < FirstTradeDayJanuary))
      return (false);
      
   if (DisableTradeOnHolidays && IsAroundHoliday(_TimeCurrent)) return (false);
   
//   switch(tm.day_of_week)
//   {
//        case 1: return(IsNow(MONDAY_Start_Trade_Hour,MONDAY_Start_Trade_Minute,MONDAY_End_Trade_Hour,MONDAY_End_Trade_Minute));
//        case 2: return(IsNow(TUESDAY_Start_Trade_Hour,TUESDAY_Start_Trade_Minute,TUESDAY_End_Trade_Hour,TUESDAY_End_Trade_Minute));
//        case 3: return(IsNow(WEDNESDAY_Start_Trade_Hour,WEDNESDAY_Start_Trade_Minute,WEDNESDAY_End_Trade_Hour,WEDNESDAY_End_Trade_Minute));
//        case 4: return(IsNow(THURSDAY_Start_Trade_Hour,THURSDAY_Start_Trade_Minute,THURSDAY_End_Trade_Hour,THURSDAY_End_Trade_Minute));
//        case 5: return(IsNow(FRIDAY_Start_Trade_Hour,FRIDAY_Start_Trade_Minute,FRIDAY_End_Trade_Hour,FRIDAY_End_Trade_Minute));
//        default: return(false);
//
//   }

//_IsFirstSession=false;

   /*   if(PrevDayStartTime > PrevDayEndTime) {
         if ((_TimeCurrent >= PrevDayStartTime && _TimeCurrent < PrevDayEndTime+60*60*24) || (_TimeCurrent >= PrevDayStartTime-60*60*24 && _TimeCurrent < PrevDayEndTime)) {
            _IsFirstSession=true;
            return(true);
         }
      }*/
   if(PrevDayStartTime < PrevDayEndTime)
     {
      if(_TimeCurrent >= PrevDayStartTime && _TimeCurrent < PrevDayEndTime)
        {
         //_IsFirstSession=true;
         return(true);
        }
     }

   /*   if(StartTime > EndTime) {
         if ((_TimeCurrent >= StartTime && _TimeCurrent < EndTime+60*60*24) || (_TimeCurrent >= StartTime-60*60*24 && _TimeCurrent < EndTime)) {
            return(true);
         }
      }*/
   if(StartTime < EndTime)
     {
      if(_TimeCurrent >= StartTime && _TimeCurrent < EndTime)
        {
         return(true);
        }
     }

   return(false);
  }
//+------------------------------------------------------------------+
//bool IsNow(int Start_Trade_Hour, int Start_Trade_Minute, int End_Trade_Hour, int End_Trade_Minute)
//{
//
//   if(Start_Trade_Hour > End_Trade_Hour) {
//      if ((_TimeCurrent >= StartTime && _TimeCurrent < EndTime+60*60*24) || (_TimeCurrent >= StartTime-60*60*24 && _TimeCurrent < EndTime)) {
//
//         return(true);
//      }
//   }
//   else if(Start_Trade_Hour < End_Trade_Hour) {
//      if (_TimeCurrent >= StartTime && _TimeCurrent < EndTime) {
//
//         return(true);
//      }
//   }
//
//   return(false);
//}

//+------------------------------------------------------------------+
//int fGetGMTOffset() {
//   int time = (int)(TimeCurrent() - TimeGMT());
//   double offset = time;
//   offset *= 0.01;
//   offset = MathCeil(offset) * 100;
//   offset = offset/3600;
//   int gmtoffset = (int)NormalizeDouble(offset,0);
//   return(gmtoffset);
//}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int fGetDSTShift() {
   if(DSTMode == DST_NEW_YORK)
      return (0);
   int shift = 0;
   if(IsSummerTime(DST_NEW_YORK))
      shift++;
   if(IsSummerTime(DSTMode))
      shift--;
   return (shift);
}

bool IsSummerTime(DstMode _mode) {
   MqlDateTime dt;
   TimeCurrent(dt);
   int day = dt.day;
   int month = dt.mon;
   int weekday = dt.day_of_week;
   
   switch(_mode) {
   case DST_NEW_YORK:
      return ((month > 3 && month < 11) 
           || (month == 3 && day - weekday > 7) 
           || (month == 11 && weekday - day >= 0));
   case DST_EUROPE:
      return ((month > 3 && month < 10) 
           || (month == 3 && 31 - day + weekday < 7) 
           || (month == 10 && 31 - day + weekday >= 7));
   case DST_AUSTRALIA: //remember, in Australia June to August is winter!
      return((month < 4 || month > 10) 
            || (month == 4 && weekday - day >= 0) 
            || (month == 10 && day - weekday > 0));
   }      
   return (false);
}


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|          Записывает строку 's' в файл InpFileName                |
//+------------------------------------------------------------------+
void fWriteDataToFile(string s)
  {

   if(!WriteLogFile)
      return;
   if(MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION))
      return;
//--- откроем файл для записи данных (если его нет, то создастся автоматически)
   ResetLastError();
   string data = "";
   data = IntegerToString(tm.day) + "." + IntegerToString(tm.mon) + "." + IntegerToString(tm.year) + "  " +
          IntegerToString(tm.hour) + ":" + IntegerToString(tm.min);
   int file_handle = FileOpen(InpDirectoryName+"//"+InpFileName, FILE_TXT|FILE_READ|FILE_WRITE);
   if(file_handle != INVALID_HANDLE)
     {
      PrintFormat("Файл %s открыт для записи", InpFileName);
      PrintFormat("Путь к файлу: %s\\Files\\", TerminalInfoString(TERMINAL_DATA_PATH));

      FileSeek(file_handle, 0, SEEK_END); //переставляем курсор в конец файла

      s = data + "   " + s;

      //--- запишем значения в файл
      FileWrite(file_handle, s);
      //--- закрываем файл
      FileClose(file_handle);
      PrintFormat("Данные записаны, файл %s закрыт", InpFileName);
     }
   else
      PrintFormat("Не удалось открыть файл %s, " + fMyErDesc(), InpFileName);
  }
//+------------------------------------------------------------------+
//| Создает прямоугольную метку                                      |
//+------------------------------------------------------------------+
bool fRectLabelCreate(const long             chart_ID    = 0,                 // ID графика
                      const string           name        = "RectLabel",       // имя метки
                      const int              sub_window  = 0,                 // номер подокна
                      const int              x           = 0,                 // координата по оси X
                      const int              y           = 0,                 // координата по оси Y
                      const int              width       = 50,                // ширина
                      const int              height      = 18,                // высота
                      const color            back_clr    = C'236,233,216',    // цвет фона
                      const ENUM_BORDER_TYPE border      = BORDER_SUNKEN,     // тип границы
                      const ENUM_BASE_CORNER corner      = CORNER_LEFT_UPPER, // угол графика для привязки
                      const color            clr         = clrRed,            // цвет плоской границы (Flat)
                      const ENUM_LINE_STYLE  style       = STYLE_SOLID,       // стиль плоской границы
                      const int              line_width  = 1,                 // толщина плоской границы
                      const bool             back        = true,             // на заднем плане
                      const bool             selection   = false,             // выделить для перемещений
                      const bool             hidden      = true,              // скрыт в списке объектов
                      const long             z_order     = 0)                 // приоритет на нажатие мышью
  {
     {
      //--- сбросим значение ошибки
      ResetLastError();
      if(ObjectFind(chart_ID, name)==0)
         return true;
      //--- создадим прямоугольную метку
      if(!ObjectCreate(chart_ID, name, OBJ_RECTANGLE_LABEL, sub_window, 0, 0))
        {
         if(LogMode<3)
           {
            Print(__FUNCTION__,
                  ": не удалось создать прямоугольную метку! " + fMyErDesc());
           }
         return(false);
        }
      //--- установим координаты метки
      ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE, y);
      //--- установим размеры метки
      ObjectSetInteger(chart_ID, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(chart_ID, name, OBJPROP_YSIZE, height);
      //--- установим цвет фона
      ObjectSetInteger(chart_ID, name, OBJPROP_BGCOLOR, back_clr);
      //--- установим тип границы
      ObjectSetInteger(chart_ID, name, OBJPROP_BORDER_TYPE, border);
      //--- установим угол графика, относительно которого будут определяться координаты точки
      ObjectSetInteger(chart_ID, name, OBJPROP_CORNER, corner);
      //--- установим цвет плоской рамки (в режиме Flat)
      ObjectSetInteger(chart_ID, name, OBJPROP_COLOR, clr);
      //--- установим стиль линии плоской рамки
      ObjectSetInteger(chart_ID, name, OBJPROP_STYLE, style);
      //--- установим толщину плоской границы
      ObjectSetInteger(chart_ID, name, OBJPROP_WIDTH, line_width);
      //--- отобразим на переднем (false) или заднем (true) плане
      ObjectSetInteger(chart_ID, name, OBJPROP_BACK, back);
      //--- включим (true) или отключим (false) режим перемещения метки мышью
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE, selection);
      ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED, selection);
      //--- скроем (true) или отобразим (false) имя графического объекта в списке объектов
      ObjectSetInteger(chart_ID, name, OBJPROP_HIDDEN, hidden);
      //--- установим приоритет на получение события нажатия мыши на графике
      ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER, z_order);
      //--- успешное выполнение
      return(true);
     }
  }
//+------------------------------------------------------------------+
//| Удаляет прямоугольную метку                                      |
//+------------------------------------------------------------------+
bool fRectLabelDelete(const long   chart_ID   = 0,           // ID графика
                      const string name       = "RectLabel") // имя метки
  {
//--- сбросим значение ошибки
   ResetLastError();
//--- удалим метку
   if(ObjectFind(chart_ID, name) != -1)
     {
      if(!ObjectDelete(chart_ID, name))
        {
         if(LogMode<3)
           {
            Print(__FUNCTION__,
                  ": не удалось удалить прямоугольную метку! " + fMyErDesc());
           }
         return(false);
        }
     }
//--- успешное выполнение
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double WindowPriceMax(int index=0)
  {
   return(ChartGetDouble(0, CHART_PRICE_MAX, index));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double WindowPriceMin(int index=0)
  {
   return(ChartGetDouble(0, CHART_PRICE_MIN, index));
  }
//+------------------------------------------------------------------+
void DrawWarn(string text, color col)
  {

   string obid=_Symbol+TimeToStr(Time[0]);
   if(ObjectFind(0, obid)!=-1)
      ObjectDelete(0, obid);

   ENUM_ANCHOR_POINT anc;
   double price;

   if((WindowPriceMax()+WindowPriceMin())/2 < Bid)
     {
      /*double ch_lower=(UseBBChannel?channel_lower:channel_buy);
      if (Use_K1band && UseBBChannel) ch_lower=MathMin(channel_lower,channel_buy);
      price=ch_lower-MathAbs(Entry_Break)*2*old_point;*/
      price=channel_lower-MathAbs(Entry_Break)*2*old_point;
      anc=ANCHOR_RIGHT;
     }
   else
     {
      /*double ch_upper=(UseBBChannel?channel_upper:channel_sell);
      if (Use_K1band && UseBBChannel) ch_upper=MathMax(channel_upper,channel_sell);
      price=ch_upper+MathAbs(Entry_Break)*2*old_point;*/
      price=channel_upper+MathAbs(Entry_Break)*2*old_point;
      anc=ANCHOR_LEFT;
     }

   ObjectCreate(0, obid, OBJ_TEXT, 0, Time[0], price);
   ObjectSet(obid, OBJPROP_ANGLE, 90);
   ObjectSet(obid, OBJPROP_ANCHOR, anc);
   ObjectSet(obid, OBJPROP_BACK, false);
   ObjectSetText(obid, text, 10, "Arial", col);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ObjectSetText(string name,
                   string text,
                   int font_size,
                   string font="",
                   color text_color=CLR_NONE)
  {
   int tmpObjType=(int)ObjectGetInteger(0, name, OBJPROP_TYPE);
   if(tmpObjType!=OBJ_LABEL && tmpObjType!=OBJ_TEXT)
      return(false);
   if(StringLen(text)>0 && font_size>0)
     {
      if(ObjectSetString(0, name, OBJPROP_TEXT, text)==true
         && ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size)==true)
        {
         if((StringLen(font)>0)
            && ObjectSetString(0, name, OBJPROP_FONT, font)==false)
            return(false);
         if(text_color>-1
            && ObjectSetInteger(0, name, OBJPROP_COLOR, text_color)==false)
            return(false);
         return(true);
        }
      return(false);
     }
   return(false);
  }

//+------------------------------------------------------------------+
void DrawChannel(string dir, double pr1, color clr=clrYellow)  //рисование линий для входов по каналу BB
  {
   if(Bars(NULL, PERIOD_CURRENT)<2)
      return;
   string name=_Symbol+" "+dir+TimeToStr(Time[0]);
   string name_prev=_Symbol+" "+dir+TimeToStr(Time[1]);
   int obj1 = ObjectFind(0, name);
   int obj2 = ObjectFind(0, name_prev);

   if(obj1 < 0)
     {
      double pr2 = pr1;
      if(obj2 == 0)
         pr2 = ObjectGetDouble(0, name_prev, OBJPROP_PRICE, 1);

      ObjectCreate(0, name, OBJ_TREND, 0, Time[1], pr2, Time[0], pr1);
      ObjectSet(name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      //ObjectSet(name,OBJPROP_BACK,true);
      //ObjectSet(name,OBJPROP_SELECTABLE,false);
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
string TimeToStr(datetime value, int mode=TIME_DATE|TIME_MINUTES)  //is mt4
  {
   return(TimeToString(value, mode));
  }
//+------------------------------------------------------------------+
bool ObjectSet(string name, int index, double value)
  {
   switch(index)
     {
      //case OBJPROP_TIME1:
      //   ObjectSetInteger(0,name,OBJPROP_TIME,(int)value);return(true);
      //case OBJPROP_PRICE1:
      //   ObjectSetDouble(0,name,OBJPROP_PRICE,value);return(true);
      //case OBJPROP_TIME2:
      //   ObjectSetInteger(0,name,OBJPROP_TIME,1,(int)value);return(true);
      //case OBJPROP_PRICE2:
      //   ObjectSetDouble(0,name,OBJPROP_PRICE,1,value);return(true);
      //case OBJPROP_TIME3:
      //   ObjectSetInteger(0,name,OBJPROP_TIME,2,(int)value);return(true);
      //case OBJPROP_PRICE3:
      //   ObjectSetDouble(0,name,OBJPROP_PRICE,2,value);return(true);
      case OBJPROP_COLOR:
         ObjectSetInteger(0, name, OBJPROP_COLOR, (int)value);
         return(true);
      case OBJPROP_STYLE:
         ObjectSetInteger(0, name, OBJPROP_STYLE, (int)value);
         return(true);
      case OBJPROP_WIDTH:
         ObjectSetInteger(0, name, OBJPROP_WIDTH, (int)value);
         return(true);
      case OBJPROP_BACK:
         ObjectSetInteger(0, name, OBJPROP_BACK, (int)value);
         return(true);
      case OBJPROP_RAY:
         ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, (int)value);
         return(true);
      case OBJPROP_ELLIPSE:
         ObjectSetInteger(0, name, OBJPROP_ELLIPSE, (int)value);
         return(true);
      case OBJPROP_SCALE:
         ObjectSetDouble(0, name, OBJPROP_SCALE, value);
         return(true);
      case OBJPROP_ANGLE:
         ObjectSetDouble(0, name, OBJPROP_ANGLE, value);
         return(true);
      case OBJPROP_ARROWCODE:
         ObjectSetInteger(0, name, OBJPROP_ARROWCODE, (int)value);
         return(true);
      case OBJPROP_TIMEFRAMES:
         ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, (int)value);
         return(true);
      case OBJPROP_DEVIATION:
         ObjectSetDouble(0, name, OBJPROP_DEVIATION, value);
         return(true);
      case OBJPROP_FONTSIZE:
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, (int)value);
         return(true);
      case OBJPROP_CORNER:
         ObjectSetInteger(0, name, OBJPROP_CORNER, (int)value);
         return(true);
      case OBJPROP_XDISTANCE:
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, (int)value);
         return(true);
      case OBJPROP_YDISTANCE:
         ObjectSetInteger(0, name, OBJPROP_YDISTANCE, (int)value);
         return(true);
      //case OBJPROP_FIBOLEVELS:
      //   ObjectSetInteger(0,name,OBJPROP_LEVELS,(int)value);return(true);
      case OBJPROP_LEVELCOLOR:
         ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR, (int)value);
         return(true);
      case OBJPROP_LEVELSTYLE:
         ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE, (int)value);
         return(true);
      case OBJPROP_LEVELWIDTH:
         ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH, (int)value);
         return(true);

      default:
         return(false);
     }
   return(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateInfoPanel()
  {
   if(_RealTrade || MQLInfoInteger(MQL_VISUAL_MODE))
     {
      //if(day_of_trade != DayOfWeek()){
      //         if(TP_perc > 0) tp_info = "\n  Dynamic Take Profit = " + IntegerToString(TP_perc) + "%";
      //         else tp_info = "\n  Dynamic Take Profit: OFF";
      TradeHoursFirst = fInfoTradeHours();
      if(_RealTrade && MaxAmountCurrency>0)
        {
         if(LastUpdateTime<TimeCurrent())
           {
            CheckArbitrage();
            LastUpdateTime=TimeCurrent();
           }
        }
      //   day_of_trade = DayOfWeek();
      //}

      if(_showinfopanel)
        {
         string warn_trading="";
         if(SetEqSymbol)
            warn_trading="Set name [OK] ";
         else
            warn_trading=(AllowTrade?"Set Name [WARNING]":"Set Name Warning. Trade is disabled.");
         if(/*_IsTime && */!trading_allowed_global)
            warn_trading = "Trading is disabled by Global Variables";
         if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
            warn_trading = "Trading is disabled !!!";
         info_panel =
            "\n ----------------------------------------------------"
            + "\n              GENERIC A-TLP"
            + "\n ----------------------------------------------------"
            + "\n  A FREE PRODUCT POWERED BY"
            + "\n       http://TRADELIKEAPRO.ru"
            + "\n ----------------------------------------------------"
            + "\n "+set_name_info
            + "\n "+warn_trading
            + "\n ----------------------------------------------------"
            + TradeHoursFirst
            + "\n  ---------------------------------------------------"
            //            + tp_info
            + "\n  Take Profit = " + (TP_perc > 0?"Dynamic, "+IntegerToString(TP_perc) + "%":DoubleToString(Take_Profit, 1) + " pips")
            + "\n  Stop Loss = " + DoubleToString(Stop_Loss, 1) + " pips"
            + be_info
            + "\n  ---------------------------------------------------"
            + "\n  Max Spread = " + maxspread /*+ (Max_Spread_On_Close>0?" / Close: "+DoubleToStr(Max_Spread_On_Close,1):"")*/
            + "\n  Spread = " + DoubleToString((Ask - Bid) / old_point, 1) + " pips";

         if(Max_Spread > 0)
           {
            if(Ask - Bid > Max_Spread * old_point)
               info_panel = info_panel + " - HIGH !!!";
            else
               info_panel = info_panel + " - NORMAL";
           }
         info_panel = info_panel
                      + risk_info
					  + risk_scale
                      + "\n  Max Orders = "+IntegerToString(TotalOrders) + (TotalOrders>1?", Distance = "+DoubleToString(OrdersDistance, 1):"")
                      + "\n  Trading Lots = " + DoubleToString(lots1, 2) + (TotalOrders>1?"*" + IntegerToString(TotalOrders) + " = " + DoubleToString(lots1*TotalOrders, 2):"") /*+(Hedging?", hedg = "+DoubleToStr(lots*TotalOrders*2, 2):"")*/
                      + "\n  ---------------------------------------------------"
                      + filter_info
                      + "\n  7. News Filter: "+(UseNewsFilter?"ON"+(_IsNews?", Activated":""):"OFF");
         if(MaxAmountCurrency>0)
           {
            info_panel = info_panel
                         + "\n  ---------------------------------------------------"
                         +CheckString();
           }
         if(MaxAmountCurrencyPair>0)
           {
            info_panel = info_panel
                         + "\n  ---------------------------------------------------"
                         + "\n  " + _Symbol + " BUY count: "+IntegerToString(CountOrder2(OP_BUY))
                         + "\n  " + _Symbol + " SELL count: "+IntegerToString(CountOrder2(OP_SELL));
           }
         info_panel = info_panel
                      + "\n  ---------------------------------------------------";
         previnfopanelcolor=infopanelcolor;
         infopanelcolor=(MQLInfoInteger(MQL_TRADE_ALLOWED)?Col_info:Col_info2);
         if(infopanelcolor != previnfopanelcolor)
           {
            ObjectSetInteger(0, "info_panel", OBJPROP_BGCOLOR, infopanelcolor);
           }

         Comment(info_panel);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountOrder(int Order_Type = -1)
  {
   int orders=0;

   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(myposition.SelectByIndex(i)==false)
         continue;
      if(myposition.Symbol()!=_Symbol || myposition.Magic() != MagicNumber || myposition.PositionType() > POSITION_TYPE_SELL)
         continue;

      if(Order_Type == myposition.PositionType() || Order_Type == -1)
         orders++;
     }

   if(orders == 0)
     {
      if(Order_Type == POSITION_TYPE_BUY)
         consecutive_orders_buy = 0;
      if(Order_Type == POSITION_TYPE_SELL)
         consecutive_orders_sell = 0;
      if(Order_Type == -1)
        {
         consecutive_orders_buy = 0;
         consecutive_orders_sell = 0;
        }
     }
   return orders;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetMaxMinOpenPrice(int ordertype, _MaxMin maxtype)
  {
   double maxminprice=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(myposition.SelectByIndex(i)==false)
         continue;
      if(myposition.Symbol()!=_Symbol || myposition.Magic() != MagicNumber)
         continue;
      if((ordertype != -1) && (myposition.PositionType() != ordertype))
         continue;
      if(maxminprice==0)
         maxminprice=myposition.PriceOpen();
      if((maxtype==MAX) && (myposition.PriceOpen()>maxminprice))
         maxminprice=myposition.PriceOpen();
      if((maxtype==MIN) && (myposition.PriceOpen()<maxminprice))
         maxminprice=myposition.PriceOpen();
     }
   return maxminprice;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime GetLastOpenTime(int ordertype)
  {
   datetime opentime=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(myposition.SelectByIndex(i)==false)
         continue;
      if(myposition.Symbol()!=_Symbol || myposition.Magic() != MagicNumber)
         continue;
      if((ordertype != -1) && (myposition.PositionType() != ordertype))
         continue;
      if(opentime==0)
         opentime=myposition.Time();
      if(myposition.Time()>opentime)
         opentime=myposition.Time();
     }
   return opentime;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime GetFirstOpenTime(int ordertype)
  {
   datetime opentime=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(myposition.SelectByIndex(i)==false)
         continue;
      if(myposition.Symbol()!=_Symbol || myposition.Magic() != MagicNumber || myposition.PositionType() > POSITION_TYPE_SELL)
         continue;
      if((ordertype != -1) && (myposition.PositionType() != ordertype))
         continue;
      if(opentime==0)
         opentime=myposition.Time();
      if(myposition.Time()<opentime)
         opentime=myposition.Time();
     }
   return opentime;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetLastOrderTicket(int ordertype)
  {
   datetime opentime=0;
   int last_order_ticket=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(myposition.SelectByIndex(i)==false)
         continue;
      if(myposition.Symbol()!=_Symbol || myposition.Magic() != MagicNumber || myposition.PositionType() > POSITION_TYPE_SELL)
         continue;
      if((ordertype != -1) && (myposition.PositionType() != ordertype))
         continue;
      if(opentime==0)
        {
         opentime=myposition.Time();
         last_order_ticket=(int)myposition.Ticket();
        }
      if(myposition.Time()>opentime)
        {
         opentime=myposition.Time();
         last_order_ticket=(int)myposition.Ticket();
        }
     }
   return last_order_ticket;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetOrdersTotalProfit(int ordertype)
  {
   double orderprofit=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(myposition.SelectByIndex(i)==false)
         continue;
      if(myposition.Symbol()!=_Symbol || myposition.Magic() != MagicNumber || myposition.PositionType() > POSITION_TYPE_SELL)
         continue;
      if((ordertype != -1) && (myposition.PositionType() != ordertype))
         continue;
      if(myposition.PositionType()==POSITION_TYPE_BUY)
        {
         orderprofit += last_tick.bid - myposition.PriceOpen();
        }
      if(myposition.PositionType()==POSITION_TYPE_SELL)
        {
         orderprofit += myposition.PriceOpen() - last_tick.ask;
        }
     }
   return orderprofit;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double  OnTester()
  {
   double  param = 0.0;
   double  coeff = 1.0;
   double  coefn = 1.0;
   double  coefr = 1.0;
   double  coefa = 1.0;
   double  balance = TesterStatistics(STAT_PROFIT);
   double  proff = TesterStatistics(STAT_PROFIT_FACTOR);
   double  trades_number = TesterStatistics(STAT_TRADES);
   double  recf = TesterStatistics(STAT_RECOVERY_FACTOR);
   if(balance>0)
     {
      coefa=MathAbs((TesterStatistics(STAT_GROSS_PROFIT)*TesterStatistics(STAT_LOSS_TRADES)+1)/
                    (TesterStatistics(STAT_PROFIT_TRADES)*TesterStatistics(STAT_GROSS_LOSS)+1));
      if(coefa>RatioThreshold)
         coefa=1;
      if(recf < DesiredRF && recf > 0)
        {
         coefr = pow((recf/DesiredRF), 1);
        }
      if(proff < DesiredPF && proff > 1)
        {
         coeff = pow((proff / DesiredPF), 3);
        }
      if(trades_number < DesiredTN)
        {
         coefn = pow((trades_number / DesiredTN), 1);
        }
     }
   else
      balance = balance/10000;
   param = balance * coeff * coefn * coefr * coefa;
   return(param);
  }

template<typename T>
bool IsError(string fname, T val, bool skipif0=true)
  {
   bool result=false;
   int Error = GetLastError();
   if(Error == 4066 || Error == 4073 || Error == 4074 || (skipif0 && val == 0))
      result=true;
   else
      if(Error != 0)
        {
         Print(fname, " Error ", Error, ": ", ErrorDescription(Error));
         Print(fname, " = ", val);
         result=true;
        }
//if (Error != 0 && result) Print("IsError(): error ",Error,", function ",fname);
   return(result);
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Volumes(string Str)
  {
   for(int i=0; i<NumOfCurrencies; i++)
      if(Currency[i] == Str)
         return(VolumesArray[i]);

   return(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckArbitrage()
  {
   int i;
   string Str1, Str2;
   int vol1, vol2;

   for(i = 0; i < NumOfCurrencies; i++)
      VolumesArray[i] = 0;

   for(i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(myposition.SelectByIndex(i)==false)
         continue;
      if(myposition.PositionType() > POSITION_TYPE_SELL)
         continue;
      if(_MaxAmount_SkipManualTrades && myposition.Magic() == 0)
         continue;

      Str1 = StringSubstr(myposition.Symbol(), 0, 3);
      Str2 = StringSubstr(myposition.Symbol(), 3, 3);

      vol1=-1;
      vol2=-1;
      for(int j=0; j<NumOfCurrencies; j++)
        {
         if(Currency[j] == Str1)
            vol1=j;
         if(Currency[j] == Str2)
            vol2=j;
         if(vol1 != -1 && vol2 != -1)
            break;
        }

      if(myposition.PositionType() == POSITION_TYPE_BUY)
        {
         if(vol1 != -1)
            VolumesArray[vol1] += 1; //myposition.Volume();
         if(vol2 != -1)
            VolumesArray[vol2] -= 1; //myposition.Volume();
        }
      else
         if(myposition.PositionType() == POSITION_TYPE_SELL)
           {
            if(vol1 != -1)
               VolumesArray[vol1] -= 1; //myposition.Volume();
            if(vol2 != -1)
               VolumesArray[vol2] += 1; //myposition.Volume();
           }
     }
   return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CheckString()
  {
//int i,x=1;
   string S1 = "", S2 = "", S;
   string Str1=StringSubstr(_Symbol, 0, 3);
   string Str2=StringSubstr(_Symbol, 3, 3);
   S1 = S1 + "Max"+Str1+ " count " + DoubleToString(_MaxAmountCurrency, 0) + "   Max"+Str2+ " count " + DoubleToString(_MaxAmountCurrency, 0);
   if(Volumes(Str1) != 0)
      S2 = S2 + Str1 + " count = " + DoubleToString(Volumes(Str1), 0)+ "   ";
   if(Volumes(Str2) != 0)
      S2 = S2 + Str2 + " count = " + DoubleToString(Volumes(Str2), 0)+ "   ";
   /*  for (i = 0; i < AmountCurrency; i++)
       if (VolumesArray[i] != 0)
          {
         if(x%2 != 0 ) Str = Str + "\n  ";
         x++;
         Str = Str + Currency[i] + " count = " + DoubleToString(VolumesArray[i], 0) + "   ";
         }*/
   S = "\n  " + S1 + "\n  " + S2;
   return(S);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountOrder2(int Order_Type)
  {
   int orders=0;

   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(myposition.SelectByIndex(i)==false)
         continue;
      if(myposition.Symbol()!=_Symbol || myposition.PositionType() > POSITION_TYPE_SELL)
         continue;
      if(_MaxAmount_SkipManualTrades && myposition.Magic() == 0)
         continue;

      if(Order_Type == myposition.PositionType() || Order_Type == -1)
         orders++;
     }
   return orders;
  }

//+------------------------------------------------------------------+
void fSetTPbyExitChannel()
  {
   stoplevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   mintpb = NormalizeDouble(last_tick.ask+MathMax(stoplevel, 1)*_Point, _Digits);
   mintps = NormalizeDouble(last_tick.bid-MathMax(stoplevel, 1)*_Point, _Digits);
   tpb = NormalizeDouble(channel_upper+_Exit_Distance*_Point, _Digits);
   tps = NormalizeDouble(channel_lower-(_Exit_Distance*_Point)+(OnlyBid?MathMin(_Max_Spread_On_Close*_Point, (last_tick.ask-last_tick.bid)):0), _Digits);

   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(myposition.SelectByIndex(i)==false)
        {
         Print(tm.hour, ":", tm.min, " | ", __FUNCTION__, " ", fMyErDesc());
         continue;
        }
      if(myposition.Symbol()!=_Symbol || myposition.Magic() != MagicNumber)
         continue;
      double newtp=0;
      if(myposition.PositionType()==POSITION_TYPE_BUY)
        {
         newtp = MathMax(MathMax(tpb, myposition.PriceOpen()+_Exit_Profit_Pips*_Point), mintpb);
         if(!CompareDoubles(newtp, myposition.TakeProfit()))
            fModifyPosition(myposition.Ticket(), myposition.PriceOpen(), myposition.StopLoss(), newtp, 0, clrWhite);
        }
      else
         if(myposition.PositionType() == POSITION_TYPE_SELL)
           {
            newtp = MathMin(MathMin(tps, myposition.PriceOpen()-_Exit_Profit_Pips*_Point), mintps);
            if(!CompareDoubles(newtp, myposition.TakeProfit()))
               fModifyPosition(myposition.Ticket(), myposition.PriceOpen(), myposition.StopLoss(), newtp, 0, clrWhite);
           }
     }
  }

//+------------------------------------------------------------------+
string ErrorDescription(int err=-1) {return fMyErDesc(err);}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string fMyErDesc(int err=-1)
  {
   int aErrNum;
   if(err == -1)
     {
      aErrNum = GetLastError();
     }
   else
     {
      aErrNum = err;
     }

   string pref="Ошибка №: "+IntegerToString(aErrNum)+" - ";
   switch(aErrNum)
     {
      case 0:
         return(pref+"Нет ошибки. Торговая операция прошла успешно.");
      case 1:
         return(pref+"Нет ошибки, но результат неизвестен. (OrderModify пытается " +
                "изменить уже установленные значения такими же значениями. " +
                "Необходимо изменить одно или несколько значений и повторить попытку.)");
      case 2:
         return(pref+"Общая ошибка. Прекратить все попытки торговых операций до " +
                "выяснения обстоятельств. Возможно перезагрузить операционную " +
                "систему и клиентский терминал.");
      case 3:
         return(pref+"Неправильные параметры. В торговую функцию переданы неправильные " +
                "параметры, например, неправильный символ, неопознанная торговая " +
                "операция, отрицательное допустимое отклонение цены, " +
                "несуществующий номер тикета и т.п. Необходимо изменить логику программы.");
      case 4:
         return(pref+"Торговый сервер занят. Можно повторить попытку через достаточно " +
                "большой промежуток времени (от нескольких минут).");
      case 5:
         return(pref+"Старая версия клиентского терминала. Необходимо установить " +
                "последнюю версию клиентского терминала.");
      case 6:
         return(pref+"Нет связи с торговым сервером.  Необходимо убедиться, что связь " +
                "не нарушена (например, при помощи функции IsConnected) и " +
                "через небольшой промежуток времени (от 5 секунд) повторить попытку.");
      case 7:
         return(pref+"Недостаточно прав.");
      case 8:
         return(pref+"Слишком частые запросы. Необходимо уменьшить частоту запросов, " +
                "изменить логику программы.");
      case 9:
         return(pref+"Недопустимая операция, нарушающая функционирование сервера");
      case 64:
         return(pref+"Счет заблокирован. Необходимо прекратить все попытки торговых операций.");
      case 65:
         return(pref+"Неправильный номер счета. Необходимо прекратить все попытки " +
                "торговых операций.");
      case 128:
         return(pref+"Истек срок ожидания совершения сделки. Прежде, чем производить " +
                "повторную попытку (не менее, чем через 1 минуту), необходимо " +
                "убедиться, что торговая операция действительно не прошла " +
                "(новая позиция не была открыта, либо существующий ордер не " +
                "был изменён или удалён, либо существующая позиция не была закрыта)");
      case 129:
         return(pref+"Неправильная цена bid или ask, возможно, ненормализованная " +
                "цена. Необходимо после задержки от 5 секунд обновить " +
                "данные при помощи функции RefreshRates и повторить попытку. " +
                "Если ошибка не исчезает, необходимо прекратить все попытки " +
                "торговых операций и изменить логику программы.");
      case 130:
         return(pref+"Неправильные стопы. Слишком близкие стопы или неправильно " +
                "рассчитанные или ненормализованные цены в стопах (или в " +
                "цене открытия отложенного ордера). Попытку можно повторять " +
                "только в том случае, если ошибка произошла из-за устаревания " +
                "цены. Необходимо после задержки от 5 секунд обновить данные " +
                "при помощи функции RefreshRates и повторить попытку. Если " +
                "ошибка не исчезает, необходимо прекратить все попытки " +
                "торговых операций и изменить логику программы.");
      case 131:
         return(pref+"Неправильный объем, ошибка в грануляции объема. Необходимо " +
                "прекратить все попытки торговых операций и изменить логику программы.");
      case 132:
         return(pref+"Рынок закрыт. Можно повторить попытку через достаточно большой " +
                "промежуток времени (от нескольких минут).");
      case 133:
         return(pref+"Торговля запрещена. Необходимо прекратить все попытки торговых операций.");
      case 134:
         return(pref+"Недостаточно средств для совершения операции. Повторять сделку " +
                "с теми же параметрами нельзя. Попытку можно повторить после " +
                "задержки от 5 секунд, уменьшив объем, но надо быть уверенным в " +
                "достаточности средств для совершения операции.");
      case 135:
         return(pref+"Цена изменилась. Можно без задержки обновить данные при помощи " +
                "функции RefreshRates и повторить попытку.");
      case 136:
         return(pref+"Нет цен. Брокер по какой-то причине (например, в начале сессии " +
                "цен нет, неподтвержденные цены, быстрый рынок) не дал цен или " +
                "отказал. Необходимо после задержки от 5 секунд обновить данные " +
                "при помощи функции RefreshRates и повторить попытку.");
      case 137:
         return(pref+"Брокер занят");
      case 138:
         return(pref+"Новые цены. Запрошенная цена устарела, либо перепутаны bid и " +
                "ask. Можно без задержки обновить данные при помощи функции " +
                "RefreshRates и повторить попытку. Если ошибка не исчезает, " +
                "необходимо прекратить все попытки торговых операций и изменить " +
                "логику программы.");
      case 139:
         return(pref+"Ордер заблокирован и уже обрабатывается. . Необходимо прекратить " +
                "все попытки торговых операций и изменить логику программы.");
      case 140:
         return(pref+"Разрешена только покупка. Повторять операцию SELL нельзя.");
      case 141:
         return(pref+"Слишком много запросов. Необходимо уменьшить частоту " +
                "запросов, изменить логику программы.");
      case 142:
         return(pref+"Ордер поставлен в очередь. Это не ошибка, а один из кодов " +
                "взаимодействия между клиентским терминалом и торговым " +
                "сервером. Этот код может быть получен в редком случае, " +
                "когда во время выполнения торговой операции произошёл " +
                "обрыв и последующее восстановление связи. Необходимо " +
                "обрабатывать так же как и ошибку 128.");
      case 143:
         return(pref+"Ордер принят дилером к исполнению. Один из кодов взаимодействия " +
                "между клиентским терминалом и торговым сервером. Может " +
                "возникнуть по той же причине, что и код 142. Необходимо " +
                "обрабатывать так же как и ошибку 128.");
      case 144:
         return(pref+"Ордер аннулирован самим клиентом при ручном подтверждении " +
                "сделки. Один из кодов взаимодействия между клиентским " +
                "терминалом и торговым сервером.");
      case 145:
         return(pref+"Модификация запрещена, так как ордер слишком близок к " +
                "рынку и заблокирован из-за возможного скорого исполнения. " +
                "Можно не ранее, чем через 15 секунд, обновить данные при " +
                "помощи функции RefreshRates и повторить попытку.");
      case 146:
         return(pref+"Подсистема торговли занята. Повторить попытку только после " +
                "того, как функция IsTradeContextBusy вернет FALSE.");
      case 147:
         return(pref+"Использование даты истечения ордера запрещено брокером. " +
                "Операцию можно повторить только в том случае, если " +
                "обнулить параметр expiration.");
      case 148:
         return(pref+"Количество открытых и отложенных ордеров достигло предела, " +
                "установленного брокером. Новые открытые позиции и " +
                "отложенные ордера возможны только после закрытия или " +
                "удаления существующих позиций или ордеров.");
      case 149:
         return(pref+"Попытка открыть противоположную позицию к уже существующей " +
                "в случае, если хеджирование запрещено. Сначала необходимо " +
                "закрыть существующую противоположную позицию, либо отказаться " +
                "от всех попыток таких торговых операций, либо изменить " +
                "логику программы.");
      case 150:
         return(pref+"Попытка закрыть позицию по инструменту в противоречии с правилом FIFO");
      //---- Коды ошибок выполнения MQL4-программы (советника)
      case 4000:
         return(pref+"Нет ошибки");
      case 4001:
         return(pref+"Неправильный указатель функции");
      case 4002:
         return(pref+"Индекс массива - вне диапазона");
      case 4003:
         return(pref+"Нет памяти для стека функций");
      case 4004:
         return(pref+"Переполнение стека после рекурсивного вызова");
      case 4005:
         return(pref+"На стеке нет памяти для передачи параметров");
      case 4006:
         return(pref+"Нет памяти для строкового параметра");
      case 4007:
         return(pref+"Нет памяти для временной строки");
      case 4008:
         return(pref+"Неинициализированная строка");
      case 4009:
         return(pref+"Неинициализированная строка в массиве");
      case 4010:
         return(pref+"Нет памяти для строкового массива");
      case 4011:
         return(pref+"Слишком длинная строка");
      case 4012:
         return(pref+"Остаток от деления на ноль");
      case 4013:
         return(pref+"Деление на ноль");
      case 4014:
         return(pref+"Неизвестная команда");
      case 4015:
         return(pref+"Неправильный переход");
      case 4016:
         return(pref+"Неинициализированный массив");
      case 4017:
         return(pref+"Вызовы DLL не разрешены");
      case 4018:
         return(pref+"Невозможно загрузить библиотеку");
      case 4019:
         return(pref+"Невозможно вызвать функцию");
      case 4020:
         return(pref+"Вызовы внешних библиотечных функций не разрешены");
      case 4021:
         return(pref+"Недостаточно памяти для строки, возвращаемой из функции");
      case 4022:
         return(pref+"Система занята");
      case 4050:
         return(pref+"Неправильное количество параметров функции");
      case 4051:
         return(pref+"Недопустимое значение параметра функции");
      case 4052:
         return(pref+"Внутренняя ошибка строковой функции");
      case 4053:
         return(pref+"Ошибка массива");
      case 4054:
         return(pref+"Неправильное использование массива-таймсерии");
      case 4055:
         return(pref+"Ошибка пользовательского индикатора");
      case 4056:
         return(pref+"Массивы несовместимы");
      case 4057:
         return(pref+"Ошибка обработки глобальныех переменных");
      case 4058:
         return(pref+"Глобальная переменная не обнаружена");
      case 4059:
         return(pref+"Функция не разрешена в тестовом режиме");
      case 4060:
         return(pref+"Функция не разрешена");
      case 4061:
         return(pref+"Ошибка отправки почты");
      case 4062:
         return(pref+"Ожидается параметр типа string");
      case 4063:
         return(pref+"Ожидается параметр типа integer");
      case 4064:
         return(pref+"Ожидается параметр типа double");
      case 4065:
         return(pref+"В качестве параметра ожидается массив");
      case 4066:
         return(pref+"Запрошенные исторические данные в состоянии обновления");
      case 4067:
         return(pref+"Ошибка при выполнении торговой операции");
      case 4099:
         return(pref+"Конец файла");
      case 4100:
         return(pref+"Ошибка при работе с файлом");
      case 4101:
         return(pref+"Неправильное имя файла");
      case 4102:
         return(pref+"Слишком много открытых файлов");
      case 4103:
         return(pref+"Невозможно открыть файл");
      case 4104:
         return(pref+"Несовместимый режим доступа к файлу");
      case 4105:
         return(pref+"Ни один ордер не выбран");
      case 4106:
         return(pref+"Неизвестный символ");
      case 4107:
         return(pref+"Неправильный параметр цены для торговой функции");
      case 4108:
         return(pref+"Неверный номер тикета");
      case 4109:
         return(pref+"Торговля не разрешена. Необходимо включить опцию <Разрешить " +
                "советнику торговать> в свойствах эксперта");
      case 4110:
         return(pref+"Длинные позиции не разрешены - необходимо проверить свойства эксперта");
      case 4111:
         return(pref+"Короткие позиции не разрешены - необходимо проверить свойства эксперта");
      case 4200:
         return(pref+"Объект уже существует");
      case 4201:
         return(pref+"Запрошено неизвестное свойство объекта");
      case 4202:
         return(pref+"Объект не существует");
      case 4203:
         return(pref+"Неизвестный тип объекта");
      case 4204:
         return(pref+"Нет имени объекта");
      case 4205:
         return(pref+"Ошибка координат объекта");
      case 4206:
         return(pref+"Не найдено указанное подокно");
      case 4207:
         return(pref+"Ошибка при работе с объектом");
      default:
         return(pref+"Несуществующий номер ошибки");
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CompareDoubles(double number1, double number2)
  {
   if(MathAbs(number1-number2) > _Point)
      return(false);
   else
      return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE fGetCCISignalOpen(int period, ENUM_APPLIED_PRICE typeprice, int toplevel, int sh)
  {
   double arrCCI[];

   if(CopyBuffer(cciopen_handle, 0, sh, 1, arrCCI)<=0)
     {
      Print("CopyBuffer CCI failed, no data");
      return -1;
     }

   double cci = arrCCI[0];

   if(cci > toplevel)
      return(POSITION_TYPE_SELL);
   if(cci < -toplevel)
      return(POSITION_TYPE_BUY);
   return(-1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE fGetCCISignalClose(int period, ENUM_APPLIED_PRICE typeprice, int toplevel, int sh)
  {
   double arrCCI[];

   if(CopyBuffer(cciclose_handle, 0, sh, 1, arrCCI)<=0)
     {
      Print("CopyBuffer CCI failed, no data");
      return -1;
     }

   double cci = arrCCI[0];

   if(cci > toplevel)
      return(POSITION_TYPE_SELL);
   if(cci < -toplevel)
      return(POSITION_TYPE_BUY);
   return(-1);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GridNextStep(double Grid_Step_Count = 0, int Grid_max_orders_count = 2)
  {
//следующий шаг сетки, если пора по условиям
   if(Grid_Step_Count==0)
      return;
   if(Trades[0]+Trades[1] < 1 || Trades[0]+Trades[1] >= Grid_max_orders_count)
      return;
   if(MinBuyLevel>0 && (MinBuyLevel-Bid)/_Point>Grid_Step_Count)
     {
      OpenTrade("BUY" , 1);
      FlagGridOpen=true;
      Print("NextGridStep: Open Buy!");
     }
   if(MinSellLevel>0 && (Bid-MinSellLevel)/_Point>Grid_Step_Count)
     {
      OpenTrade("SELL", 1);
      FlagGridOpen=true;
      Print("NextGridStep: Open Sell!");
     }
  } //NextGridStep


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GridClose(int Grid_profit_for_close = 0)
  {
   double Grid_p = GetProfitOpenPosInPoint(Symbol_Work, -1, MagicNumber);
   if(Grid_p > Grid_profit_for_close)
     {
      Print("Grid Close! ", "Grid profit = ", Grid_p);
      CloseAll(OP_BUY);
      CloseAll(OP_SELL);
     }
   FlagGridOpen=false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CountTrades() //подсчет количества открытых ордеров и плавающей прибыли в валюте депозита
  {
   ArrayFill(Trades, 0, 6, 0);
   Profit_open_orders_buy = 0;
   Profit_open_orders_sell = 0;
   ArrayFree(TradesLevelsBuyAndSell);
   ArrayFree(TradesTypeBuy0Sell1);

#ifdef __MQL5__
   for(int i=0; i<PositionsTotal(); i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(myposition.SelectByIndex(i)==false)
         continue;
      if(myposition.Symbol()!=Symbol_Work || myposition.Magic() != MagicNumber)
         continue;

      ArrayResize(TradesLevelsBuyAndSell, PositionsTotal());
      ArrayResize(TradesTypeBuy0Sell1, PositionsTotal());
      TradesLevelsBuyAndSell[i] = myposition.PriceOpen(); //записать уровни цен открытых ордеров

      switch(myposition.PositionType())
        {
         case POSITION_TYPE_BUY:
            Trades[0]++;
            Profit_open_orders_buy = Profit_open_orders_buy + myposition.Profit();
            TradesTypeBuy0Sell1[i] = 0;
            break;
         case POSITION_TYPE_SELL:
            Trades[1]++;   //0 - buy, 1 sell, 2buylim, 3 selllim, 4 buyst, 5 sellst
            Profit_open_orders_sell = Profit_open_orders_sell + myposition.Profit();
            TradesTypeBuy0Sell1[i] = 1;
            break;
        }
     } //for

#endif

#ifdef __MQL4__
   RefreshRates();
   int total=OrdersTotal();
   for(int pos=0; pos<total; pos++)
     {
      if(OrderSelect(pos, SELECT_BY_POS, MODE_TRADES)==false)
         continue;
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=MagicNumber)
         continue;

      ArrayResize(TradesLevelsBuyAndSell, OrdersTotal());
      ArrayResize(TradesTypeBuy0Sell1, OrdersTotal());
      TradesLevelsBuyAndSell[pos] = OrderOpenPrice(); //записать уровни цен открытых ордеров

      switch(OrderType())
        {
         case 0:
            Trades[0]++;
            //Profit_open_orders_buy = Profit_open_orders_buy + OrderProfit();
            Profit_open_orders_buy = Profit_open_orders_buy + (int)MathRound((Bid - OrderOpenPrice()) / _Point);
            TradesTypeBuy0Sell1[pos] = 0;
            break;
         case 1:
            Trades[1]++;  //0 - buy, 1 sell, 2buylim, 3 selllim, 4 buyst, 5 sellst
            //Profit_open_orders_sell = Profit_open_orders_sell + OrderProfit();
            Profit_open_orders_sell = Profit_open_orders_sell + (int)MathRound((OrderOpenPrice() - Ask) / _Point);
            TradesTypeBuy0Sell1[pos] = 1;
            break;
         case 2:
            Trades[2]++;
         case 3:
            Trades[3]++;
         case 4:
            Trades[4]++;
         case 5:
            Trades[5]++;
        }
     }
#endif

   int array_size = ArrayRange(TradesLevelsBuyAndSell, 0);
   DistanceBid_to_Buy = 99999;
   DistanceBid_to_Sell = 99999;

   for(int i=0; i < array_size; i++)
     {
      if(TradesTypeBuy0Sell1[i] ==0)
        {
         if(MathAbs(last_tick.bid - TradesLevelsBuyAndSell[i]) < DistanceBid_to_Buy)
            DistanceBid_to_Buy = MathAbs(last_tick.bid - TradesLevelsBuyAndSell[i]);
        }
      if(TradesTypeBuy0Sell1[i] ==1)
        {
         if(MathAbs(last_tick.bid - TradesLevelsBuyAndSell[i]) < DistanceBid_to_Sell)
            DistanceBid_to_Sell = MathAbs(last_tick.bid - TradesLevelsBuyAndSell[i]);
        }
     } //for

  } //CountTrades

//|  Описание : Возвращает суммарный профит открытых позиций в пунктах         |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    sy - наименование инструмента   (""   - любой символ,                   |
//|                                     NULL - текущий символ)                 |
//|    op - операция                   (-1   - любая позиция)                  |
//|    mn - MagicNumber                (-1   - любой магик)                    |
//+----------------------------------------------------------------------------+
double GetProfitOpenPosInPoint(string symbol="", int posit=-1, int magik=-1)
  {
   double profit=0;

   if(symbol=="0")
      symbol=Symbol();

   for(int i=0; i<PositionsTotal(); i++)
     {
      if(myposition.SelectByIndex(i)==false)
         continue;
      if((myposition.Symbol()==symbol || symbol=="") && (posit < 0 || myposition.PositionType()==posit))
        {
         if(magik<0 || myposition.Magic()==magik)
           {
            if(myposition.PositionType()==OP_BUY)
              {
               profit+=(Bid - myposition.PriceOpen())/_Point;
              }
            if(myposition.PositionType()==OP_SELL)
              {
               profit+=(myposition.PriceOpen() - Ask)/_Point;
              }
           }
        }

     }
   return(profit);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Plavpribil()
  {
//вычисляем плавающую прибыль/убыток и вычисляем самый просевший ордер бай/селл
   double plav_prib=0;
   MinBuyLevel=0;
   MinSellLevel=0;
   Equity=0;

#ifdef __MQL5__
   int pos = PositionsTotal();
   for(int i=0; i<pos; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(myposition.SelectByIndex(i)==false)
         continue;
      if(myposition.Symbol()!=Symbol_Work || myposition.Magic() != MagicNumber)
         continue;

      Equity=Equity+myposition.Profit()+myposition.Swap()-myposition.Commission();

      switch(myposition.PositionType())
        {
         case POSITION_TYPE_BUY:
            plav_prib=plav_prib+(Bid-myposition.PriceOpen());
            if(MinBuyLevel==0)
               MinBuyLevel = myposition.PriceOpen();
            if(myposition.PriceOpen() < MinBuyLevel)
               MinBuyLevel = myposition.PriceOpen(); //вычисляем самый просевший ордер бай
            break;
         case POSITION_TYPE_SELL:
            plav_prib=plav_prib+(myposition.PriceOpen()-Bid);
            if(MinSellLevel==0)
               MinSellLevel=myposition.PriceOpen();
            if(myposition.PriceOpen() > MinSellLevel)
               MinSellLevel = myposition.PriceOpen(); //так же селл
            break;
        }
     } //for
#endif

   return(plav_prib);
  } //plavpribil()
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseOrder(ulong ticket, double lots = 0, color clr = clrGreen)
  {

   if(ticket <=0)
     {
      Print(__FUNCTION__ + " Ошибка! Неверный ticket: " + IntegerToString(ticket));
      return;
     }

   lots=NormalizeDouble(lots, 2);

#ifdef __MQL4__ //---------------

   int err=0;
   double price=0;
   bool exit_loop=false;
   int retry=15;
   int cnt1=0;
   if(lots ==0)
      lots = OrderLots();
   RefreshRates();

   while(!exit_loop && cnt1<retry)
     {
      if(OrderType() == OP_BUY)
         price=Bid;
      if(OrderType() == OP_SELL)
         price=Ask;
      price=NormalizeDouble(price, _Digits);

      if(!IsTesting())    //если торговый поток занят - подождать
        {
         while(IsTradeContextBusy() == TRUE)
           {
            Sleep(100);
            RefreshRates();
           }
        }

      if(!OrderClose(ticket, lots, price, Slippage, clr))
        {
         err=GetLastError();
         switch(err)
           {
            case ERR_INVALID_PRICE:
               RefreshRates();
               break;
            case ERR_REQUOTE:
               RefreshRates();
               break;
            case ERR_OFF_QUOTES:
               RefreshRates();
               break;
            case ERR_BROKER_BUSY:
               break;
            default:
               exit_loop=true;
               break;
           }
         Sleep(1000);
         cnt1++;
        }
      else
         exit_loop=true;
     }

   if(err!=ERR_NO_ERROR && err!=ERR_NO_RESULT)
      Print(__FUNCTION__ + " Ошибка закрытия ордера ticket: ", ticket, " ", err);

#endif

#ifdef __MQL5__

   for(int count = 0; count < 15; count++)
     {
      if(!trade.PositionClose(ticket))  //закрытие ордера
        {
         string q = __FUNCTION__ + ": Ордер " + Symbol_Work + " #" +
                    IntegerToString(ticket) + " не был закрыт! " + trade.ResultRetcodeDescription();
         Print(q);
        }
      else
        {
         string q = __FUNCTION__ + ": Ордер " + Symbol_Work + " #" + IntegerToString(ticket) + "закрыт";
         Print(q);
         return;
        } //if
      Sleep(1000);
     } //for

#endif

  } //CloseOrder

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAll(int OrderType = -1)
  {
#ifdef __MQL5__
   int i;
   int pt = PositionsTotal();
   ulong pos_arr[];
   ArrayResize(pos_arr, pt);

   for(i = 0; i < pt; i++)
     {
      bool pos_select = myposition.SelectByIndex(i);
      if(pos_select)
         pos_arr[i] = myposition.Ticket();
     } //for

   for(i=0; i<ArraySize(pos_arr); i++)
     {
      bool pos_select = myposition.SelectByTicket(pos_arr[i]);
      string sym = myposition.Symbol();
      ulong mgk = myposition.Magic();
      int pos1 = myposition.PositionType();
      if(pos_select && sym == Symbol_Work && mgk == MagicNumber && (pos1 == OrderType || OrderType == -1))
        {
         CloseOrder(pos_arr[i]);
         Sleep(1000);
        }
     }

#endif

#ifdef __MQL4__
   for(int pos=0; pos<OrdersTotal(); pos++)
     {
      if(OrderSelect(pos, SELECT_BY_POS, MODE_TRADES)==false)
         continue;
      if(OrderSymbol()!=Symbol_Work || OrderMagicNumber()!=MagicNumber)
         continue;
      if(OrderType()==OrderType)
        {
         CloseOrder(OrderTicket());
        }
     } //for
#endif
  } //CloseAll

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNews() //true - ожидаются новости
  {
   double CheckNews=0;
   if(AfterNewsStop>0)
     {
      if(TimeCurrent()-LastUpd>=Upd)
        {
         //comment.SetText(9, "News Loading...", COLOR_WIN);
         UpdateNews();
         LastUpd=TimeCurrent();
        }
      //ChartRedraw(0);
      //---Draw a line on the chart news--------------------------------------------
      if(DrawLines)
        {
         for(int i=0; i<NomNews; i++)
           {
            string Name=StringSubstr(TimeToString(TimeNewsFunck(i), TIME_MINUTES)+"_"+NewsArr[1][i]+"_"+NewsArr[3][i], 0, 63);
            if(NewsArr[3][i]!="")
               if(ObjectFind(0, Name)==0)
                  continue;
            if(StringFind(str1, NewsArr[1][i])<0)
               continue;
            if(TimeNewsFunck(i)<TimeCurrent() && Next)
               continue;

            color clrf = clrNONE;
            if(Vhigh && StringFind(NewsArr[2][i], "High")>=0)
               clrf=highc;
            if(Vmedium && StringFind(NewsArr[2][i], "Moderate")>=0)
               clrf=mediumc;
            if(Vlow && StringFind(NewsArr[2][i], "Low")>=0)
               clrf=lowc;

            if(clrf==clrNONE)
               continue;

            if(NewsArr[3][i]!="")
              {
               ObjectCreate(0, Name, OBJ_VLINE, 0, TimeNewsFunck(i), 0);
               ObjectSet(Name, OBJPROP_COLOR, clrf);
               ObjectSet(Name, OBJPROP_STYLE, Style);
               ObjectSetInteger(0, Name, OBJPROP_BACK, true);
              }
           }
        }
      //---------------event Processing------------------------------------
      int i;
      CheckNews=0;
      for(i=0; i<NomNews; i++)
        {
         int power=0;
         if(Vhigh && StringFind(NewsArr[2][i], "High")>=0)
            power=1;
         if(Vmedium && StringFind(NewsArr[2][i], "Moderate")>=0)
            power=2;
         if(Vlow && StringFind(NewsArr[2][i], "Low")>=0)
            power=3;
         if(power==0)
            continue;
         if(TimeCurrent()+MinBefore*60>TimeNewsFunck(i) && TimeCurrent()-MinAfter*60<TimeNewsFunck(i) && StringFind(str1, NewsArr[1][i])>=0)
           {
            CheckNews=1;
            break;
           }
         else
            CheckNews=0;

        }
      if(CheckNews==1 && i!=Now && Signal)
        {
         Alert("In ", (int)(TimeNewsFunck(i)-TimeCurrent())/60, " minutes released news ", NewsArr[1][i], "_", NewsArr[3][i]);
         Now=i;
        }
      /***  ***/
     }

   if(CheckNews>0)
     {
      _IsNews = true;
      //comment.SetText(9, "News waiting...", COLOR_WIN);
      return(true);
     }
   else
     {
      _IsNews = false;
      //comment.SetText(9, "No News", COLOR_WIN);
      return(false);
     }

  } //ont
//+------------------------------------------------------------------+
//////////////////////////////////////////////////////////////////////////////////
// Download CBOE page source code in a text variable
// And returns the result
//////////////////////////////////////////////////////////////////////////////////
string ReadCBOE()
  {

   string cookie=NULL, headers;
   char post[], result[];
   string TXT="";
   int res;
//--- to work with the server, you must add the URL "https://www.google.com/finance"
//--- the list of allowed URL (Main menu-> Tools-> Settings tab "Advisors"):
   string google_url="http://ec.forexprostools.com/?columns=exc_currency,exc_importance&importance=1,2,3&calType=week&timeZone=15&lang=1";
//---
   ResetLastError();
//--- download html-pages
   int timeout=5000; //--- timeout less than 1,000 (1 sec.) is insufficient at a low speed of the Internet
   res=WebRequest("GET", google_url, cookie, NULL, timeout, post, 0, result, headers);
//--- error checking
   if(res==-1)
     {
      Print("WebRequest error, err.code  =", GetLastError());
      MessageBox("You must add the address http://ec.forexprostools.com/ in the list of allowed URL tab 'Advisors' ", " Error ", MB_ICONINFORMATION);
      //--- You must add the address ' "+ google url"' in the list of allowed URL tab 'Advisors' "," Error "
     }
   else
     {
      //--- successful download
      //PrintFormat("File successfully downloaded, the file size in bytes  =%d.",ArraySize(result));
      //--- save the data in the file
      int filehandle=FileOpen("news-log.html", FILE_WRITE|FILE_BIN);
      //--- проверка ошибки
      if(filehandle!=INVALID_HANDLE)
        {
         //---save the contents of the array result [] in file
         FileWriteArray(filehandle, result, 0, ArraySize(result));
         //--- close file
         FileClose(filehandle);

         int filehandle2=FileOpen("news-log.html", FILE_READ|FILE_ANSI);

         if(filehandle2 > -1)
           {
            while(!FileIsEnding(filehandle2))
              {
               TXT += FileReadString(filehandle2);
              }
           }

         //TXT=FileReadString(filehandle2,ArraySize(result));
         FileClose(filehandle2);
        }
      else
        {
         Print("Error in FileOpen. Error code =", GetLastError());
        }
     }

   return(TXT);
  }
//+------------------------------------------------------------------+
datetime TimeNewsFunck(int nomf)
  {
   string s=NewsArr[0][nomf];
   string time="";
   int str = StringConcatenate(time, StringSubstr(s, 0, 4), ".", StringSubstr(s, 5, 2), ".", StringSubstr(s, 8, 2), " ", StringSubstr(s, 11, 2), ":", StringSubstr(s, 14, 4));
   return((datetime)(StringToTime(time) + GMT_Offset*3600));
  }
//////////////////////////////////////////////////////////////////////////////////
void UpdateNews()
  {
   string TEXT=ReadCBOE();
   int sh = StringFind(TEXT, "pageStartAt>")+12;
   int sh2= StringFind(TEXT, "</tbody>");
   TEXT=StringSubstr(TEXT, sh, sh2-sh);

   sh=0;
   while(!IsStopped())
     {
      sh = StringFind(TEXT, "event_timestamp", sh)+17;
      sh2= StringFind(TEXT, "onclick", sh)-2;
      if(sh<17 || sh2<0)
         break;
      NewsArr[0][NomNews]=StringSubstr(TEXT, sh, sh2-sh);

      sh = StringFind(TEXT, "flagCur", sh)+10;
      sh2= sh+3;
      if(sh<10 || sh2<3)
         break;
      NewsArr[1][NomNews]=StringSubstr(TEXT, sh, sh2-sh);
      if(StringFind(str1, NewsArr[1][NomNews])<0)
         continue;

      sh = StringFind(TEXT, "title", sh)+7;
      sh2= StringFind(TEXT, "Volatility", sh)-1;
      if(sh<7 || sh2<0)
         break;
      NewsArr[2][NomNews]=StringSubstr(TEXT, sh, sh2-sh);
      if(StringFind(NewsArr[2][NomNews], "High")>=0 && !Vhigh)
         continue;
      if(StringFind(NewsArr[2][NomNews], "Moderate")>=0 && !Vmedium)
         continue;
      if(StringFind(NewsArr[2][NomNews], "Low")>=0 && !Vlow)
         continue;

      sh=StringFind(TEXT, "left event", sh)+12;
      int sh1=StringFind(TEXT, "Speaks", sh);
      sh2=StringFind(TEXT, "<", sh);
      if(sh<12 || sh2<0)
         break;
      if(sh1<0 || sh1>sh2)
         NewsArr[3][NomNews]=StringSubstr(TEXT, sh, sh2-sh);
      else
         NewsArr[3][NomNews]=StringSubstr(TEXT, sh, sh1-sh);

      NomNews++;
      if(NomNews==300)
         break;
     }
  }
//+------------------------------------------------------------------+
//+---------News filter end---------------------------------------------------------+

bool IsUSFederalHoliday(datetime dt) {
   // ** for holiday descriptions: http://en.wikipedia.org/wiki/Bank_holidays_in_United_States#List_of_Federal_Holidays
   //                              http://en.wikipedia.org/wiki/Public_holidays_in_the_United_States#Federal_holidays
   // ** holidays that fall on a weekend are usually observed on the closest weekday
   
   #define Thursday   4
   #define Friday     5
   #define Sunday     0
   #define Monday     1
   
   datetime tomorrow = dt + 86400, yesterday = dt - 86400;
   MqlDateTime today_dt, tomorrow_dt, yesterday_td;
   TimeToStruct(dt, today_dt);
   TimeToStruct(dt, tomorrow_dt);
   TimeToStruct(dt, yesterday_td);
        
   int today_moy = today_dt.mon, today_dom = today_dt.day, today_dow = today_dt.day_of_week, today_year = today_dt.year,
       yesterday_moy = yesterday_td.mon, yesterday_dom = yesterday_td.day, yesterday_dow = yesterday_td.day_of_week,
       tomorrow_moy = tomorrow_dt.mon, tomorrow_dom = tomorrow_dt.day, tomorrow_dow = tomorrow_dt.day_of_week;
       
   if (today_moy == 1)
      return (
         // New Year's Day - part 1/2 (January 1st)
         ((today_dom == 1) || (today_dow == Monday && yesterday_dom == 1)) ||
         // Inauguration Day (Every fourth year on January 20th or, if the 20th is a Sunday, January 21st)
         (((today_year - 1) % 4 == 0) && ((today_dom == 20 && today_dow != Sunday) || (today_dom == 21 && today_dow == Monday))) ||
         // MLK's Birthday (Third Monday in January)
         (today_dow == Monday && MathCeil(today_dom / 7.0) == 3) );
   if (today_moy == 2)
      // President's Day (Third Monday in February)
      return (today_dow == Monday && MathCeil(today_dom / 7.0) == 3);
   if (today_moy == 5)
      // Memorial Day (Last Monday in May)
      return (today_dow == Monday && 31 - today_dom < 7);
   if (today_moy == 6)
      // Juneteenth National Independence Day (June 19)
      return ((today_dom == 19) || (today_dow == Friday && tomorrow_dom == 19) || (today_dow == Monday && yesterday_dom == 19));
   if (today_moy == 7)
      // Independence Day (July 4th)
      return ((today_dom == 4) || (today_dow == Friday && tomorrow_dom == 4) || (today_dow == Monday && yesterday_dom == 4));
   if (today_moy == 9)
      // Labor Day (First Monday in September)
      return (today_dow == Monday && MathCeil(today_dom / 7.0) == 1);
   if (today_moy == 10)
      // Columbus Day (Second Monday in October)
      return (today_dow == Monday && MathCeil(today_dom / 7.0) == 2);
   if (today_moy == 11)
      return (
         // Veterans Day (November 11th)
         ((today_dom == 11) || (today_dow == Friday && tomorrow_dom == 11) || (today_dow == Monday && yesterday_dom == 11)) ||
         // Thanksgiving Day (Fourth Thursday in November)
         (today_dow == Thursday && MathCeil(today_dom / 7.0) == 4) );
   if (today_moy == 12)
      return (
         // Christmas Day (December 25th)
         ((today_dom == 25) || (today_dow == Friday && tomorrow_dom == 25) || (today_dow == Monday && yesterday_dom == 25)) ||
         // New Year's Day - part 2/2 (January 1st)
         (today_dow == Friday && tomorrow_dom == 1) );
         
   return (false);
}

//+--------- Holidays check -------------------------------------------------------------+
bool isHoliday(datetime dt) {
   return (IsUSFederalHoliday(dt));
}

bool IsAroundHoliday(datetime dt) {
   // Today is holiday
   if (isHoliday(dt)) {
      return (true);
   }
   
   MqlDateTime today_dt;
   TimeToStruct(dt, today_dt);
   
   int today_dow = today_dt.day_of_week, today_hour = today_dt.hour;
   
   datetime torrow = dt + 86400;
   // If today is Friday, next trade day is Monday
   if (today_dow == 5) {
      torrow += 86400 * 2;
   }
   // Tomorrow is holliday, no trade on second session
   if (isHoliday(torrow) && today_hour > 8) {
      return (true);
   }
   
   datetime yesterday = dt - 86400;
   // If today is Monday, previous trade day is Friday
   if (today_dow == 1) {
      yesterday -= 86400 * 2;
   }
   // Yesterday is holliday, no trade on first session
   if (isHoliday(yesterday) && today_hour < 8) {
      return (true);
   }
   
   return (false);
}
//+---------Holidays check end----------------------------------------------------+

//+---------MQL4 compatibility----------------------------------------------------+
int TimeDayOfWeek(datetime date)
{
   MqlDateTime tm1;
   TimeToStruct(date, tm1);
   return(tm1.day_of_week);
}
double CopyBufferMQL4(int handle,int index,int shift)
{
   double buf[];
   switch(index)
   {
      case 0: if(CopyBuffer(handle,0,shift,1,buf)>0)
         return(buf[0]); break;
      case 1: if(CopyBuffer(handle,1,shift,1,buf)>0)
         return(buf[0]); break;
      case 2: if(CopyBuffer(handle,2,shift,1,buf)>0)
         return(buf[0]); break;
      case 3: if(CopyBuffer(handle,3,shift,1,buf)>0)
         return(buf[0]); break;
      case 4: if(CopyBuffer(handle,4,shift,1,buf)>0)
         return(buf[0]); break;
      default: break;
   }
   return(EMPTY_VALUE);
}
//+---------MQL4 compatibility end------------------------------------------------+
