/*
   Generated by EX4-TO-MQ4 decompiler LITE V4.0.409.1g [-]
   Website: https://purebeam.biz
   E-mail : purebeam@gmail.com
*/
#include <WinUser32.mqh>
#import "user32.dll"
   int RegisterWindowMessageA(string a0);
#import

int start() {
   ObjectSet("calctl", OBJPROP_PRICE1, -1);
   int li_0 = WindowHandle(Symbol(), Period());
   int li_4 = RegisterWindowMessageA("MetaTrader4_Internal_Message");
   PostMessageA(li_0, li_4, 2, 1);
   return (0);
}
