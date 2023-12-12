%{
#include "parser.tab.h"
#include <stdio.h>
int line_count = 1;
%}

%option noyywrap

/*Structure for the tokens*/
id     [a-zA-Z][a-zA-Z_0-9]*
typefloat  [0-9]+\.[0-9]+
typeint    [0-9]+
typestring \".*\"
%%  
\(          {return (LPAR);}
\)          {return (RPAR);}
\+          {yylval.sval = strdup(yytext); return (OP_MATH);}
\-          {yylval.sval = strdup(yytext); return (OP_MATH);}
\*          {yylval.sval = strdup(yytext); return (OP_MATH);}
\/          {yylval.sval = strdup(yytext); return (OP_MATH);}
\^          {yylval.sval = strdup(yytext); return (OP_MATH);}
\%	        {yylval.sval = strdup(yytext); return (OP_MATH);}

\=\=        {yylval.sval = strdup(yytext); return (OP_REL);}
\!\=        {yylval.sval = strdup(yytext); return (OP_REL);}
\<          {yylval.sval = strdup(yytext); return (OP_REL);}
\>          {yylval.sval = strdup(yytext); return (OP_REL);}
\<\=        {yylval.sval = strdup(yytext); return (OP_REL);}
\>\=        {yylval.sval = strdup(yytext); return (OP_REL);}

\:          {return (TWODOTS);}
\=	        {return (ASSIGN);}

GOTO        {return (GOTO);}

write	    {return (WRITE);}
read	    {return (READ);}
if	        {return (IF);}

{typestring}    { yylval.sval = strdup(yytext); return TEXTO; }
{typeint}       { yylval.ival = strdup(yytext); return NUM; }
{typefloat}     { yylval.fval = strdup(yytext); return DECIMAL;}
{id}            { yylval.sval = strdup(yytext); return ID;}


\n {line_count++;}
[ \t]+      {/*ignore*/}
%%