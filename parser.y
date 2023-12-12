%{
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
void yyerror(const char* message);
int yylex();
extern FILE* yyin;
extern char* yytext;
extern int line_count;
struct Symbol {
        char* name;
        char* value;
        struct Symbol* next;
};
struct Symbol* symbol_table = 0;
struct Symbol* find_symbol(char* name) {
        struct Symbol* current = symbol_table;
        while (current != 0) {
                if (strcmp(current->name, name) == 0) {
                        return current;
                }
                current = current->next;
        }
        return 0;
}
void add_symbol(char* name, char* value) {
        struct Symbol* s = find_symbol(name);
        if (s != 0) {
                
        } else {
                struct Symbol* new_symbol = (struct Symbol*) malloc(sizeof(struct Symbol));
                new_symbol->name = name;
                new_symbol->value = value;
                new_symbol->next = symbol_table;
                symbol_table = new_symbol;
        }
}
void edit_symbol(char* name, char* value) {
        struct Symbol* s = find_symbol(name);
        if (s != 0) {
                s->value = value;
        } else {
                
        }
}
void print_symbol_table() {
        struct Symbol* current = symbol_table;
        while (current != 0) {
                if(strncmp(current->value,"\"",1)==0){
                        printf("\t%s dw 13,10, %s\n", current->name, current->value);
                }
                else if(strncmp(current->value,"t",1)==0){
                        printf("\t%s dw ?\n", current->name);
                }
                else if(strncmp(current->name,"t",1)==0){
                        printf("\t%s dw %s\n", current->name, current->value);
                }
                current = current->next;
        }
}
%}
%union{
        char* sval;
        char* ival;
        char* fval;
}
/*Simbolos Terminales*/
%token <sval> ID
%token <ival> NUM
%token WRITE
%token READ
%token IF
%token LPAR
%token RPAR
%token <sval> OP_MATH
%token <sval> OP_REL
%token ASSIGN
%token TWODOTS 
%token <sval> TEXTO
%token <fval> DECIMAL
%token GOTO

%type <sval> expression
%type <sval> value
%type <sval> assign
%type <sval> statement
%type <sval> statements
%type <sval> label
%type <sval> ifcond
%type <sval> read
%type <sval> write
%type <sval> gotostmt
%type <sval> body
%type <sval> labelparts
%type <sval> valueForCd
%type <sval> parts
%start program
%%
program : body {
        printf("\.data:\n");
        print_symbol_table();
        printf("\.code:\n");
        printf($1);
        printf("mov ah, 4Ch\nint 21h\n");
        }
        ;
body    : statement {$$ = $1;}
        | %empty {}
        ;
statement       : statements body {
                        $$ = malloc(strlen("blob")+strlen($1) + strlen($2) + 1);
                        sprintf($$, "%s\n%s", $1, $2);        
                }
                ;
statements : assign {$$ =  $1;}
          | read {$$=$1;}
          | write {$$=$1;}
          | ifcond {$$=$1;}
          | gotostmt {$$=$1;}
          | label {$$ = $1;}
          ;
assign  : ID ASSIGN expression {
                add_symbol($1, "?");
                $$ = malloc(strlen("mov ,ax\n") + strlen($1) + strlen($3) + 1);
                sprintf($$, "%smov %s,ax\n\n",$3, $1);
        }
        | ID ASSIGN value{
                add_symbol($1, $3);
                struct Symbol* s = find_symbol($1);
                if(strncmp(s->value, "\"",1) == 0){
                        $$ = malloc(strlen("mov dx, offset \nmov ah, 09h\nint 21h\n") + strlen($1)+ 1);
                        sprintf($$, "mov dx, offset %s\nmov ah, 09h\nint 21h\n\n", $1);  
                }
                else if(strncmp(s->value,"t",1)==0){
                        $$ = malloc(strlen("mov ax, \n mov , ax\n") + strlen($1) + strlen($3) + 1);
                        sprintf($$, "mov ax, %s\nmov %s, ax\n\n", $3, $1);        
                }
                else if(atoi(s->value)!=0 || strcmp(s->value,"0")==0){
                        $$ = malloc(strlen("mov , \n") + strlen($1) + strlen($3) + 1);
                        sprintf($$, "mov %s, %s\n\n", $1, $3);
                }
                else{
                        $$ = malloc(strlen($3) + strlen("sub ax, \'0\'\nmov , ax\n") + strlen($1) + 1);
                        sprintf($$, "%s\nsub al, \'0\'\nmov %s,ax\n", $3, $1);
                }

        }
        ;
expression      : value OP_MATH value {
                        if(strcmp($2,"+") == 0){
                                $$ = malloc(strlen("mov ax, \nmov bx, \nadd ax, bx\n") + strlen($1) + strlen($3) + 1);
                                sprintf($$, "mov ax, %s\nmov bx, %s\nadd ax, bx\n", $1, $3);
                        }
                        else if(strcmp($2,"-") == 0){
                                $$ = malloc(strlen("mov ax, \nmov bx, \nsub ax, bx\n") + strlen($1) + strlen($3) + 1);
                                sprintf($$, "mov ax, %s\nmov bx, %s\nsub ax, bx\n", $1, $3);
                        }
                        else if(strcmp($2,"*") == 0){
                                $$ = malloc(strlen("mov ax, \nmov bx, \nmul ax, bx\n") + strlen($1) + strlen($3) + 1);
                                sprintf($$, "mov ax, %s\nmov bx, %s\nmul ax, bx\n", $1, $3);
                        }
                        else if(strcmp($2,"/") == 0){
                                $$ = malloc(strlen("mov ax, \nmov bx, \ndiv ax, bx\n") + strlen($1) + strlen($3) + 1);
                                sprintf($$, "mov ax, %s\nmov bx, %s\ndiv ax, bx\n", $1, $3);
                        }
                        else if(strcmp($2,"%") ==0){
                                $$ = malloc(strlen("mov ax, \nmov bx, \nmod ax, bx\n") + strlen($1) + strlen($3) + 1);
                                sprintf($$, "mov ax, %s\nmov bx, %s\nmod ax, bx\n", $1, $3);
                        }
                }
                ;

read    : READ LPAR RPAR{
                $$ = malloc(strlen("mov ah, 1\nint 21h\n") + 1);
                sprintf($$, "mov ah, 1\nint 21h\n");
        }
        ;
write   : WRITE LPAR parts RPAR{
                if(strncmp($3,"\"",1) == 0){
                        char *value = malloc(strlen(" $") + strlen($3) + 1);
                        sprintf(value, "%s\b$\"", $3);
                        const char *cadena_original = $3;
                        char *nueva_cadena = malloc(strlen(cadena_original) + 1);
                        int j = 0;
                        for (int i = 0; cadena_original[i] != '\0'; i++) {
                                if (cadena_original[i] != ' ' && cadena_original[i] != '"') {
                                nueva_cadena[j++] = cadena_original[i];
                                }
                        }
                        nueva_cadena[j] = '\0'; 
                        add_symbol(nueva_cadena,value);
                        $$ = malloc(strlen("mov dx, offset \nmov ah, 09h\nint 21h\n") + strlen(nueva_cadena)+ 1);
                        sprintf($$, "mov dx, offset %s\nmov ah, 09h\nint 21h\n\n",nueva_cadena);
                }
                else{
                        $$ = malloc(strlen("mov ax, \nadd ax,\'0\'\nmov dl, al\nmov ah,2\nint 21h\n"));
                        sprintf($$, "mov ax, %s\nadd ax,\'0\'\nmov dl, al\nmov ah,2\nint 21h\n", $3);
                }
        }
        ;
parts   : TEXTO {$$ = $1;}
        | ID {$$= $1;}
        ;
ifcond  : IF valueForCd OP_REL valueForCd GOTO ID
        {
                if(strcmp($3,"<") == 0){
                                $$ = malloc(strlen("mov ax, \nmov bx, \ncmp ax, bx\njl \n") + strlen($2) + strlen($4) + strlen($6) + 1);
                                sprintf($$, "mov ax, %s\nmov bx, %s\ncmp ax, bx\njl %s\n", $2, $4, $6);
                }
                else if(strcmp($3,">") == 0){
                                $$ = malloc(strlen("mov ax, \nmov bx, \ncmp ax, bx\njg \n") + strlen($2) + strlen($4) + strlen($6) + 1);
                                sprintf($$, "mov ax, %s\nmov bx, %s\ncmp ax, bx\njg %s\n", $2, $4, $6);
                }
                else if (strcmp($3,"<=") == 0){
                                $$ = malloc(strlen("mov ax, \nmov bx, \ncmp ax, bx\njle \n") + strlen($2) + strlen($4) + strlen($6) + 1);
                                sprintf($$, "mov ax, %s\nmov bx, %s\ncmp ax, bx\njle %s\n", $2, $4, $6);
                }
                else if(strcmp($3,">=") == 0){
                                $$ = malloc(strlen("mov ax, \nmov bx, \ncmp ax, bx\njge \n") + strlen($2) + strlen($4) + strlen($6) + 1);
                                sprintf($$, "mov ax, %s\nmov bx, %s\ncmp ax, bx\njge %s\n", $2, $4, $6);
                }
                else if(strcmp($3,"==") == 0){
                                $$ = malloc(strlen("mov ax, \nmov bx, \ncmp ax, bx\nje \n") + strlen($2) + strlen($4) + strlen($6) + 1);
                                sprintf($$, "mov ax, %s\nmov bx, %s\ncmp ax, bx\nje %s\n", $2, $4, $6);
                }
                else if(strcmp($3,"!=") == 0){
                                $$ = malloc(strlen("mov ax, \nmov bx, \ncmp ax, bx\njne \n") + strlen($2) + strlen($4) + strlen($6) + 1);
                                sprintf($$, "mov ax, %s\nmov bx, %s\ncmp ax, bx\njne %s\n", $2, $4, $6);
                }
        }
        ;
label   : ID TWODOTS labelparts  {
                add_symbol($1, "label");
                $$=malloc(strlen($1) + strlen($3) + strlen(":\n") + 1);
                sprintf($$,"%s:\n%s\n", $1, $3); 
        }
labelparts      : body {$$ = $1;}
                ;
        ;
gotostmt: GOTO ID{
                $$=malloc(strlen("jmp \n") + strlen($2) + 1);
                sprintf($$, "jmp %s\n", $2);
        }
        ;
valueForCd      : ID { $$ = $1;}
                | NUM { $$ = $1;}
                | TEXTO { $$ = $1;}
                | DECIMAL { $$ = $1;}
                ;
value   : ID {
                $$ = $1;
        }
        | NUM {
                $$ = $1;
        }
        | DECIMAL {
                $$ = $1;
        }
        | TEXTO{
                $$ = malloc(strlen(" $") + strlen($1) + 1);
                sprintf($$, "%s\b$\"", $1);
        }
        | read{
                $$ = $1;
        }
        ;
%%
int main(int argc, char *argv[]){
    if (argc < 2) { //Utilizacion de archivo de entrada
        printf("Uso: %s archivo_de_entrada\n", argv[0]);
    }
    FILE *archivo = fopen(argv[1], "r");//Inicializacion de archivo de entrada
    if (archivo == NULL) {//Verificacion de apertura correcta de archivo
        printf("Error: no se pudo abrir el archivo de entrada.\n");
        return 1;
    }
    yyin = archivo; // Archivo a escanear
    yyparse();
    fclose(archivo);//Cerradura de archivo
    return 0;
}
void yyerror(const char* message) {
    fprintf(stderr, "Error en la línea %d: %s -> %s\n", line_count, message, yytext);
    exit(1);
}