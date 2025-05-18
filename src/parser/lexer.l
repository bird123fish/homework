%option noyywrap
%{
    /*
        这部分会被原样拷贝到生成的cpp文件的开头
    */
#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <iomanip>
#include <cstring>

#include "SyntaxTree.hpp"
#include "parser.hpp"

int line_number = 1;          // 行号，从1开始
int column_start_number = 0;  // token开始的列号
int column_end_number = 0;    // token结束的列号

int current_token;

bool is_head_print = false;   // 是否已经打印表头

// 输出token信息
void print_msg(std::ostream &out) {
    if(!is_head_print){
        out << std::setw(10) << "Token"
            << std::setw(15) << "Text"
            << std::setw(10) << "Line"
            << std::setw(15) << "Column (S,E)"
            << std::endl;
        is_head_print = true;
    }
    
    out << std::setw(10) << current_token
        << std::setw(15) << yytext
        << std::setw(10) << line_number
        << std::setw(15) << "(" << column_start_number << "," << column_end_number << ")" 
        << std::endl;
}

// 处理token并返回
int handle_token(int token) {
    current_token = token;
    column_start_number = column_end_number;
    yylval.symbol_size = strlen(yytext);
    yylval.current_symbol = new char[yylval.symbol_size + 1];
    strcpy(yylval.current_symbol, yytext);
    column_end_number += yylval.symbol_size;  // 更新列号
    print_msg(std::cout);
    return token;
}

// 错误处理函数
void handle_error(const char* message) {
    std::cerr << "Error at line " << line_number 
              << ", column " << column_end_number 
              << ": " << message << std::endl;
}
%}

%%

\/\*([^\*]|\*[^\/])*\*+\/  {
    // 处理多行注释
    column_start_number = column_end_number;
    for (unsigned i = 0; i < strlen(yytext); i++) {
        if (yytext[i] == '\n') {
            line_number++;
            column_end_number = 0;
        } else {
            column_end_number++;
        }
    }
}

\/\/.*  {
    // 处理单行注释
    column_start_number = column_end_number;
    column_end_number += strlen(yytext);
}

int         { return handle_token(INT); }
void        { return handle_token(VOID); }
if          { return handle_token(IF); }
else        { return handle_token(ELSE); }
return      { return handle_token(RETURN); }

[a-zA-Z_][a-zA-Z_0-9]* { return handle_token(Ident); }
[0-9]+                { return handle_token(IntConst); }

"+"     { return handle_token(ADD); }
"-"     { return handle_token(SUB); }
"*"     { return handle_token(MUL); }
"/"     { return handle_token(DIV); }
"%"     { return handle_token(MOD); }
"("     { return handle_token(LPAREN); }
")"     { return handle_token(RPAREN); }
"["     { return handle_token(LBRACKET); }
"]"     { return handle_token(RBRACKET); }
"{"     { return handle_token(LBRACE); }
"}"     { return handle_token(RBRACE); }
"<"     { return handle_token(LESS); }
"<="    { return handle_token(LESS_EQUAL); }
">"     { return handle_token(GREATER); }
">="    { return handle_token(GREATER_EQUAL); }
"=="    { return handle_token(EQUAL); }
"!="    { return handle_token(NOT_EQUAL); }
"&&"    { return handle_token(AND); }
"||"    { return handle_token(OR); }
"!"     { return handle_token(NOT); }
"="     { return handle_token(ASSIGN); }
","     { return handle_token(COMMA); }
";"     { return handle_token(SEMICOLON); }

\n      {
    // 处理换行符
    line_number++;
    column_start_number = column_end_number;
    column_end_number = 0;
}

[ \r]+  {
    // 处理空格和回车
    column_start_number = column_end_number;
    column_end_number += strlen(yytext);
}

\t      {
    // 处理制表符（假设制表符宽度为4）
    column_start_number = column_end_number;
    column_end_number += 4;
}

.       {
    // 处理无法识别的字符
    handle_error("Unrecognized character");
    return handle_token(ERROR);
}

%%

// 初始化函数
int yylex_init() {
    line_number = 1;
    column_start_number = 0;
    column_end_number = 0;
    is_head_print = false;
    return 0;
}
