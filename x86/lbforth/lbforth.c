/*******************************************************************************
*
* A minimal Forth compiler in C
* By Leif Bruder <leifbruder@gmail.com> http://defineanswer42.wordpress.com
* Release 2014-04-04
*
* Based on Richard W.M. Jones' excellent Jonesforth sources/tutorial
*
* PUBLIC DOMAIN
*
* I, the copyright holder of this work, hereby release it into the public
* domain. This applies worldwide. In case this is not legally possible, I grant
* any entity the right to use this work for any purpose, without any conditions,
* unless such conditions are required by law.
*
*******************************************************************************/

/* Only a single include here; I'll define everything on the fly to keep
* dependencies as low as possible. In this file, the only C standard functions
* used are getchar, putchar and the EOF value. */
#include <stdio.h>

#ifdef H8_80186
#include <conio.h>
#define CONST const
#else
#ifdef OLIVETTI
#include <sys/pcos.h>
#include "myread.h"
#include "oliport.h"
#define CONST const
#else
#ifdef MULTIBUS
#define INITSCRIPT_FILE
#define CONST
void outp(); /* port, val) */
int inp(); /* port */
#else
#define CONST const
#endif
#endif
#endif

/* Base cell data types. Use short/long on most systems for 16 bit cells. */
/* Experiment here if necessary. */
#define CELL_BASE_TYPE int
#define DOUBLE_CELL_BASE_TYPE long

/* Basic memory configuration */
#define MEM_SIZE 32768 /* main memory size in bytes */
#define STACK_SIZE 256 /* cells reserved for the stack */
#define RSTACK_SIZE 64 /* cells reserved for the return stack */
#define INPUT_LINE_SIZE 32 /* bytes reserved for the WORD buffer */

/******************************************************************************/

/* Our basic data types */
typedef CELL_BASE_TYPE scell;
typedef DOUBLE_CELL_BASE_TYPE dscell;
typedef unsigned CELL_BASE_TYPE cell;
typedef unsigned DOUBLE_CELL_BASE_TYPE dcell;
typedef unsigned char byte;
#define CELL_SIZE sizeof(cell)
#define DCELL_SIZE sizeof(dcell)

/* A few constants that describe the memory layout of this implementation */
#define LATEST_POSITION INPUT_LINE_SIZE
#define HERE_POSITION (LATEST_POSITION + CELL_SIZE)
#define BASE_POSITION (HERE_POSITION + CELL_SIZE)
#define STATE_POSITION (BASE_POSITION + CELL_SIZE)
#define STACK_POSITION (STATE_POSITION + CELL_SIZE)
#define RSTACK_POSITION (STACK_POSITION + STACK_SIZE * CELL_SIZE)
#define HERE_START (RSTACK_POSITION + RSTACK_SIZE * CELL_SIZE)
#define MAX_BUILTIN_ID 81

/* Flags and masks for the dictionary */
#define FLAG_IMMEDIATE 0x80
#define FLAG_HIDDEN 0x40
#define MASK_NAMELENGTH 0x1F

/* This is the main memory to be used by this Forth. There will be no malloc
* in this file. */
byte memory[MEM_SIZE];

/* Pointers to Forth variables stored inside the main memory array */
cell *latest;
cell *here;
cell *base;
cell *state;
cell *sp;
cell *stack;
cell *rsp;
cell *rstack;

/* A few helper variables for the compiler */
int exitReq;
int errorFlag;
cell next;
cell lastIp;
cell quit_address;
cell commandAddress;
cell maxBuiltinAddress;

/* The TIB, stored outside the main memory array for now */
char lineBuffer[128];
int charsInLineBuffer = 0;
int positionInLineBuffer = 0;

/* A basic setup for defining builtins. This Forth uses impossibly low
* adresses as IDs for the builtins so we can define builtins as
* standard C functions. Slower but easier to port. */
#define BUILTIN(id, name, c_name, flags) CONST int c_name##_id=id; CONST char* c_name##_name=name; CONST byte c_name##_flags=flags; void c_name()
#define ADD_BUILTIN(c_name) addBuiltin(c_name##_id, c_name##_name, c_name##_flags, c_name)
typedef void(*builtin)();
builtin builtins[MAX_BUILTIN_ID] = { 0 };

char *emptyString = "";
int f_silent;
FILE *f_reading;

/* This is our initialization script containing all the words we define in
* Forth for convenience. Focus is on simplicity, not speed. Partly copied from
* Jonesforth (see top of file). */
char *initscript_pos;
#define INITSCRIPT_FILE
#ifndef INITSCRIPT_FILE
CONST char *initScript =
    ": 's' 115 ;\n"
    ": '\"' 34 ;\n"
    ": ':' 58 ;\n"
    ": ';' 59 ;\n"
    ": \"'\" 39 ;\n"
    ": CELL+ CELL + ;\n"
    ": CELL- CELL - ;\n"
    ": DECIMAL 10 BASE ! ;\n"
    ": HEX 16 BASE ! ;\n"
    ": OCTAL 8 BASE ! ;\n"
    ": 2DUP OVER OVER ;\n"
    ": 2DROP DROP DROP ;\n"
    ": NIP SWAP DROP ;\n"
    ": 2NIP 2SWAP 2DROP ;\n"
    ": TUCK SWAP OVER ;\n"
    ": / /MOD NIP ;\n"
    ": MOD /MOD DROP ;\n"
    ": BL 32 ;\n"
    ": CR 10 EMIT ;\n"
    ": SPACE BL EMIT ;\n"
    ": NEGATE 0 SWAP - ;\n"
    ": DNEGATE 0. 2SWAP D- ;\n"
    ": CELLS CELL * ;\n"
    ": ALLOT HERE @ + HERE ! ;\n"
    ": TRUE -1 ;\n"
    ": FALSE 0 ;\n"
    ": 0= 0 = ;\n"
    ": 0< 0 < ;\n"
    ": 0> 0 > ;\n"
    ": <> = 0= ;\n"
    ": <= > 0= ;\n"
    ": >= < 0= ;\n"
    ": 0<= 0 <= ;\n"
    ": 0>= 0 >= ;\n"
    ": 1+ 1 + ;\n"
    ": 1- 1 - ;\n"
    ": 2+ 2 + ;\n"
    ": 2- 2 - ;\n"
    ": 2/ 2 / ;\n"
    ": 2* 2 * ;\n"
    ": D2/ 2. D/ ;\n"
    ": +! DUP @ ROT + SWAP ! ;\n"
    ": [COMPILE] WORD FIND >CFA , ; IMMEDIATE\n"
    ": [CHAR] key ' LIT , , ; IMMEDIATE\n"
    ": RECURSE LATEST @ >CFA , ; IMMEDIATE\n"
    ": DOCOL 0 ;\n"
    ": CONSTANT CREATE DOCOL , ' LIT , , ' EXIT , ;\n"
    ": 2CONSTANT SWAP CREATE DOCOL , ' LIT , , ' LIT , , ' EXIT , ;\n"
    ": VARIABLE HERE @ CELL ALLOT CREATE DOCOL , ' LIT , , ' EXIT , ;\n" /* TODO: Allot AFTER the code, not before */
    ": 2VARIABLE HERE @ 2 CELLS ALLOT CREATE DOCOL , ' LIT , , ' EXIT , ;\n" /* TODO: Allot AFTER the code, not before */
    ": IF ' 0BRANCH , HERE @ 0 , ; IMMEDIATE\n"
    ": THEN DUP HERE @ SWAP - SWAP ! ; IMMEDIATE\n"
    ": ELSE ' BRANCH , HERE @ 0 , SWAP DUP HERE @ SWAP - SWAP ! ; IMMEDIATE\n"
    ": BEGIN HERE @ ; IMMEDIATE\n"
    ": UNTIL ' 0BRANCH , HERE @ - , ; IMMEDIATE\n"
    ": AGAIN ' BRANCH , HERE @ - , ; IMMEDIATE\n"
    ": WHILE ' 0BRANCH , HERE @ 0 , ; IMMEDIATE\n"
    ": REPEAT ' BRANCH , SWAP HERE @ - , DUP HERE @ SWAP - SWAP ! ; IMMEDIATE\n"
    ": UNLESS ' 0= , [COMPILE] IF ; IMMEDIATE\n"
    ": DO HERE @ ' SWAP , ' >R , ' >R , ; IMMEDIATE\n"
    ": LOOP ' R> , ' R> , ' SWAP , ' 1+ , ' 2DUP , ' = , ' 0BRANCH , HERE @ - , ' 2DROP , ; IMMEDIATE\n"
    ": +LOOP ' R> , ' R> , ' SWAP , ' ROT , ' + , ' 2DUP , ' <= , ' 0BRANCH , HERE @ - , ' 2DROP , ; IMMEDIATE\n"
    ": I ' R@ , ; IMMEDIATE\n"
    ": SPACES DUP 0> IF 0 DO SPACE LOOP ELSE DROP THEN ;\n"
    ": ABS DUP 0< IF NEGATE THEN ;\n"
    ": DABS 2DUP 0. D< IF DNEGATE THEN ;\n"
    ": .DIGIT DUP 9 > IF 55 ELSE 48 THEN + EMIT ;\n"
    ": .SIGN DUP 0< IF 45 EMIT NEGATE THEN ;\n" /* BUG: 10000000000... will be shown wrong */
    ": .POS BASE @ /MOD ?DUP IF RECURSE THEN .DIGIT ;\n"
    ": . .SIGN DUP IF .POS ELSE .DIGIT THEN ;\n"
    ": COUNTPOS SWAP 1 + SWAP BASE @ / ?DUP IF RECURSE THEN ;\n"
    ": DIGITS DUP 0< IF 1 ELSE 0 THEN SWAP COUNTPOS ;\n"
    ": .R OVER DIGITS - SPACES . ;\n"
    ": . . SPACE ;\n"
    ": ? @ . ;\n"
    ": .S DSP@ BEGIN DUP S0@ > WHILE DUP ? CELL - REPEAT DROP ;\n"
    ": TYPE 0 DO DUP C@ EMIT 1 + LOOP DROP ;\n"
    ": ALIGN BEGIN HERE @ CELL MOD WHILE 0 C, REPEAT ;\n"
    ": xs\" ' LITSTRING , HERE @ 0 , BEGIN KEY DUP 34 <> WHILE C, REPEAT DROP DUP HERE @ SWAP - CELL - SWAP ! ALIGN ; IMMEDIATE\n"
    ": s\" IMMEDIATE STATE @ IF ' LITSTRING , HERE @ 0 , BEGIN KEY DUP '\"' <> WHILE C, REPEAT DROP DUP HERE @ SWAP - CELL- SWAP\n"
    "       ! ALIGN ELSE HERE @ BEGIN KEY DUP '\"' <> WHILE OVER C! 1+ REPEAT DROP HERE @ - HERE @ SWAP THEN ;\n"
    ": .\" [COMPILE] s\" ' TYPE , ; IMMEDIATE\n"
    ": ( BEGIN KEY [CHAR] ) = UNTIL ; IMMEDIATE\n"
    ": COUNT DUP 1+ SWAP C@ ;\n"
    ": MIN 2DUP < IF DROP ELSE NIP THEN ;\n"
    ": MAX 2DUP > IF DROP ELSE NIP THEN ;\n"
    ": D0= OR 0= ;\n"
    ": DMIN 2OVER 2OVER D< IF 2DROP ELSE 2NIP THEN ;\n"
    ": DMAX 2OVER 2OVER D> IF 2DROP ELSE 2NIP THEN ;\n"
    ": F_HIDDEN 64 ;\n"
    ": F_IMMEDIATE 128 ;\n"
    ": F_LENMASK 31 ;\n"
    ": ID. CELL+ DUP C@ F_LENMASK AND BEGIN DUP 0> WHILE SWAP 1+ DUP C@ EMIT SWAP 1- REPEAT 2DROP ;\n"
    ": ?HIDDEN CELL+ C@ F_HIDDEN AND ;\n"
    ": ?IMMEDIATE CELL+ C@ F_IMMEDIATE AND ;\n"
    ": WORDS LATEST @ BEGIN ?DUP WHILE DUP ?HIDDEN NOT IF DUP ID. SPACE THEN @ REPEAT CR ;\n"
    ": CASE IMMEDIATE 0 ;\n"
    ": OF IMMEDIATE ' OVER , ' = , [COMPILE] IF ' DROP , ;\n"
    ": ENDOF IMMEDIATE [COMPILE] ELSE ;\n"
    ": ENDCASE IMMEDIATE ' DROP , BEGIN ?DUP WHILE [COMPILE] THEN REPEAT ;\n"
    ": PICK 1+ CELL * DSP@ SWAP - @ ;\n"
    ": >DFA >CFA CELL+ ;\n"
    ": CFA> LATEST @ BEGIN ?DUP WHILE 2DUP >CFA SWAP = IF NIP EXIT THEN @ REPEAT DROP 0 ;\n"
    ": ALIGNED 3 + 3 NOT AND ;\n"
    ": LITERAL IMMEDIATE ' LIT , , ;\n"
    ": SEE WORD FIND HERE @ LATEST @ BEGIN 2 PICK OVER <> WHILE NIP DUP @ REPEAT DROP SWAP ':' EMIT SPACE DUP ID. SPACE\n"
    "  DUP ?IMMEDIATE IF .\" IMMEDIATE \" THEN >DFA BEGIN 2DUP > WHILE DUP @ CASE \n"
    "  ' LIT OF CELL+ DUP @ . ENDOF\n"
    "  ' LITSTRING OF 's' EMIT '\"' EMIT SPACE CELL+ DUP @ SWAP CELL+ SWAP 2DUP TELL '\"' EMIT SPACE + ALIGNED CELL- ENDOF\n"
    "  ' 0BRANCH OF .\" 0BRANCH ( \" CELL+ DUP @ . .\" ) \" ENDOF\n"
    "  ' BRANCH OF .\" BRANCH ( \" CELL+ DUP @ . .\" ) \" ENDOF\n"
    "  ' ' OF \"'\" EMIT SPACE CELL+ DUP @ CFA> ID. SPACE ENDOF\n"
    "  ' EXIT OF 2DUP CELL+ <> IF .\" EXIT \" THEN ENDOF\n"
    "  DUP CFA> ID. SPACE ENDCASE CELL+ REPEAT ';' EMIT CR 2DROP ;\n"
    ": VALUE CREATE DOCOL , ' LIT , , ' EXIT , ;\n"
    ": TO IMMEDIATE WORD FIND >DFA CELL+ STATE @ IF ' LIT , , ' ! , ELSE ! THEN ;\n"
    ": +TO IMMEDIATE WORD FIND >DFA CELL+ STATE @ IF ' LIT , , ' +! , ELSE +! THEN ;\n"
    ": ['] IMMEDIATE ' LIT , ;\n";
#endif
/*

*/

/******************************************************************************/

/* The primary data output function. This is the place to change if you want
* to e.g. output data on a microcontroller via a serial interface. */
void putkey(c)
   char c;
{
#ifdef OLIVETTI
    if (c==13) {
        _pcos_putbyte(DID_CONSOLE,10);
    }
    _pcos_putbyte(DID_CONSOLE,c);
    if (c==10) {
       _pcos_putbyte(DID_CONSOLE,13); 
    }
#else
    putchar(c);
#endif
}

/* The primary data input function. This is where you place the code to e.g.
* read from a serial line. */
int llkey()
{
#ifdef OLIVETTI
    char ch;
    int i;
#endif

    if (*initscript_pos) {
        return *(initscript_pos++);
    }
    if (f_reading != NULL) {
        int ch = fgetc(f_reading);
        if (ch==EOF) {
            fclose(f_reading);
            f_reading = NULL;
        } else {
            if (!f_silent) {
                putkey(ch);
            }
            return ch;
        }
    }

#ifdef OLIVETTI
    _myread(&ch,1);  /* TODO: Check error return here? */
    return ch;
#else
    return getchar();
#endif
}

/* Anything waiting in the keyboard buffer? */
int keyWaiting()
{
    return positionInLineBuffer < charsInLineBuffer ? -1 : 0;
}

/* Line buffered character input. We're duplicating the functionality of the
* stdio library here to make the code easier to port to other input sources */
int getkey()
{
    int c;

    if (keyWaiting())
        return lineBuffer[positionInLineBuffer++];

    charsInLineBuffer = 0;
    while ((c = llkey()) != EOF)
    {
        if (charsInLineBuffer == sizeof(lineBuffer)) break;
        lineBuffer[charsInLineBuffer++] = c;
        if (c == '\n') break;
    }

    positionInLineBuffer = 1;
    return lineBuffer[0];
}

/* C string output */
void tell(str)
  CONST char *str;
{
    while (*str)
        putkey(*str++);
}

/* The basic (data) stack operations */

cell pop()
{
    if (*sp == 1)
    {
        tell("? Stack underflow\n");
        errorFlag = 1;
        return 0;
    }
    return stack[--(*sp)];
}

cell tos()
{
    if (*sp == 1)
    {
        tell("? Stack underflow\n");
        errorFlag = 1;
        return 0;
    }
    return stack[(*sp)-1];
}

void push(data)
  cell data;
{
    if (*sp >= STACK_SIZE)
    {
        tell("? Stack overflow\n");
        errorFlag = 1;
        return;
    }
    stack[(*sp)++] = data;
}

dcell dpop()
{
    cell tmp[2];
    tmp[1] = pop();
    tmp[0] = pop();
    return *((dcell*)tmp);
}

void dpush(data)
  dcell data;
{
    cell tmp[2];
    *((dcell*)tmp) = data;
    push(tmp[0]);
    push(tmp[1]);
}

/* The basic return stack operations */

cell rpop()
{
    if (*rsp == 1)
    {
        tell("? RStack underflow\n");
        errorFlag = 1;
        return 0;
    }
    return rstack[--(*rsp)];
}

void rpush(cdata)
  cell cdata;
{
    if (*rsp >= RSTACK_SIZE)
    {
        tell("? RStack overflow\n");
        errorFlag = 1;
        return;
    }
    rstack[(*rsp)++] = cdata;
}

/* Secure memory access */

cell readMem(address)
  cell address;
{
    if (address > MEM_SIZE)
    {
        tell("Internal error in readMem: Invalid addres\n");
        errorFlag = 1;
        return 0;
    }
    return *((cell*)(memory + address));
}

void writeMem(address, value)
  cell address;
  cell value;
{
    if (address > MEM_SIZE)
    {
        tell("Internal error in writeMem: Invalid address\n");
        errorFlag = 1;
        return;
    }
    *((cell*)(memory + address)) = value;
}

/* Reading a word into the input line buffer */
byte readWord()
{
    char *line = (char*)memory;
    byte len = 0;
    int c;

    while ((c = getkey()) != EOF)
    {
        if (c == ' ') continue;
        if (c == '\n') continue;
        if (c != '\\') break;

        while ((c = getkey()) != EOF)
            if (c == '\n')
                break;
    }

    while (c != ' ' && c != '\n' && c != EOF)
    {
        if (len >= (INPUT_LINE_SIZE - 1))
            break;
        line[++len] = c;
        c = getkey();
    }
    line[0] = len;
    return len;
}

/* toupper() clone so we don't have to pull in ctype.h */
char up(c)
  char c;
{
    return (c >= 'a' && c <= 'z') ? c - 'a' + 'A' : c;
}

/* Dictionary lookup */
cell findWord(address, len)
    cell address;
    cell len;
{
    cell ret = *latest;
    char *name = (char*) &memory[address];
    cell i;
    int found;

    for (ret = *latest; ret; ret = readMem(ret))
    {
        if ((memory[ret + CELL_SIZE] & MASK_NAMELENGTH) != len) continue;
        if (memory[ret + CELL_SIZE] & FLAG_HIDDEN) continue;

        found = 1;
        for (i = 0; i < len; i++)
        {
            if (up(memory[ret + i + 1 + CELL_SIZE]) != up(name[i]))
            {
                found = 0;
                break;
            }
        }
        if (found) break;
    }
    return ret;
}

/* Basic number parsing, base <= 36 only atm */
void parseNumber(word, len, number, notRead, isDouble)
  byte *word;
  cell len;
  dcell *number;
  cell *notRead;
  byte *isDouble;
{
    int negative = 0;
    cell i;
    char c;
    cell current;

    *number = 0;
    *isDouble = 0;

    if (len == 0)
    {
        *notRead = 0;
        return;
    }

    if (word[0] == '-')
    {
        negative = 1;
        len--;
        word++;
    }
    else if (word[0] == '+')
    {
        len--;
        word++;
    }

    for (i = 0; i < len; i++)
    {
        c = *word;
        word++;
        if (c == '.') { *isDouble = 1; continue; }
        else if (c >= '0' && c <= '9') current = c - '0';
        else if (c >= 'A' && c <= 'Z') current = 10 + c - 'A';
        else if (c >= 'a' && c <= 'z') current = 10 + c - 'a';
        else break;

        if (current >= *base) break;

        *number = *number * *base + current;
    }

    *notRead = len - i;
    if (negative) *number = (-((scell)*number));
}

/*******************************************************************************
*
* Builtin definitions
*
*******************************************************************************/

CONST int docol_id=0; CONST char* docol_name="RUNDOCOL"; CONST byte docol_flags=0; void docol()
{
    rpush(lastIp);
    next = commandAddress + CELL_SIZE;
}

/* The first few builtins are very simple, not need to waste vertical space here */
CONST int doCellSize_id=1; CONST char* doCellSize_name="CELL"; CONST byte doCellSize_flags=0; void doCellSize() { push(sizeof(cell)); }
CONST int memRead_id=2; CONST char* memRead_name="@"; CONST byte memRead_flags=0; void memRead() { push(readMem(pop())); }
CONST int memReadByte_id=3; CONST char* memReadByte_name="C@"; CONST byte memReadByte_flags=0; void memReadByte() { push(memory[pop()]); }
CONST int key_id=4; CONST char* key_name="KEY"; CONST byte key_flags=0; void key() { push(getkey()); }
CONST int emit_id=5; CONST char* emit_name="EMIT"; CONST byte emit_flags=0; void emit() { putkey(pop() & 255); }
CONST int drop_id=6; CONST char* drop_name="DROP"; CONST byte drop_flags=0; void drop() { pop(); }
CONST int doExit_id=7; CONST char* doExit_name="EXIT"; CONST byte doExit_flags=0; void doExit() { next = rpop(); }
CONST int bye_id=8; CONST char* bye_name="BYE"; CONST byte bye_flags=0; void bye() { exitReq = 1; }
CONST int doLatest_id=9; CONST char* doLatest_name="LATEST"; CONST byte doLatest_flags=0; void doLatest() { push(32); }
CONST int doHere_id=10; CONST char* doHere_name="HERE"; CONST byte doHere_flags=0; void doHere() { push((32 + sizeof(cell))); }
CONST int doBase_id=11; CONST char* doBase_name="BASE"; CONST byte doBase_flags=0; void doBase() { push(((32 + sizeof(cell)) + sizeof(cell))); }
CONST int doState_id=12; CONST char* doState_name="STATE"; CONST byte doState_flags=0; void doState() { push((((32 + sizeof(cell)) + sizeof(cell)) + sizeof(cell))); }
CONST int gotoInterpreter_id=13; CONST char* gotoInterpreter_name="["; CONST byte gotoInterpreter_flags=0x80; void gotoInterpreter() { *state = 0; }
CONST int gotoCompiler_id=14; CONST char* gotoCompiler_name="]"; CONST byte gotoCompiler_flags=0; void gotoCompiler() { *state = 1; }
CONST int hide_id=15; CONST char* hide_name="HIDE"; CONST byte hide_flags=0; void hide() { memory[*latest + sizeof(cell)] ^= 0x40; }
CONST int rtos_id=16; CONST char* rtos_name="R>"; CONST byte rtos_flags=0; void rtos() { push(rpop()); }
CONST int stor_id=17; CONST char* stor_name=">R"; CONST byte stor_flags=0; void stor() { rpush(pop()); }
CONST int key_p_id=18; CONST char* key_p_name="KEY?"; CONST byte key_p_flags=0; void key_p() { push(keyWaiting()); }
CONST int branch_id=19; CONST char* branch_name="BRANCH"; CONST byte branch_flags=0; void branch() { next += readMem(next); }
CONST int zbranch_id=20; CONST char* zbranch_name="0BRANCH"; CONST byte zbranch_flags=0; void zbranch() { next += pop() ? sizeof(cell) : readMem(next); }
CONST int toggleImmediate_id=21; CONST char* toggleImmediate_name="IMMEDIATE"; CONST byte toggleImmediate_flags=0x80; void toggleImmediate() { memory[*latest + sizeof(cell)] ^= 0x80; }
CONST int doFree_id=22; CONST char* doFree_name="FREE"; CONST byte doFree_flags=0; void doFree() { push(32768 - *here); }
CONST int s0_r_id=23; CONST char* s0_r_name="S0@"; CONST byte s0_r_flags=0; void s0_r() { push(((((32 + sizeof(cell)) + sizeof(cell)) + sizeof(cell)) + sizeof(cell)) + sizeof(cell)); }
CONST int dsp_r_id=24; CONST char* dsp_r_name="DSP@"; CONST byte dsp_r_flags=0; void dsp_r() { push(((((32 + sizeof(cell)) + sizeof(cell)) + sizeof(cell)) + sizeof(cell)) + *sp * sizeof(cell)); }
CONST int not_id=25; CONST char* not_name="NOT"; CONST byte not_flags=0; void not() { push(~pop()); }
CONST int dup_id=26; CONST char* dup_name="DUP"; CONST byte dup_flags=0; void dup() { push(tos()); }

CONST int memWrite_id=27; CONST char* memWrite_name="!"; CONST byte memWrite_flags=0; void memWrite()
{
    cell address = pop();
    cell value = pop();
    writeMem(address, value);
}

CONST int memWriteByte_id=28; CONST char* memWriteByte_name="C!"; CONST byte memWriteByte_flags=0; void memWriteByte()
{
    cell address = pop();
    cell value = pop();
    memory[address] = value & 255;
}

CONST int swap_id=29; CONST char* swap_name="SWAP"; CONST byte swap_flags=0; void swap()
{
    cell a = pop();
    cell b = pop();
    push(a);
    push(b);
}

CONST int over_id=30; CONST char* over_name="OVER"; CONST byte over_flags=0; void over()
{
    cell a = pop();
    cell b = tos();
    push(a);
    push(b);
}

CONST int comma_id=31; CONST char* comma_name=","; CONST byte comma_flags=0; void comma()
{
    push(*here);
    memWrite();
    *here += sizeof(cell);
}

CONST int commaByte_id=32; CONST char* commaByte_name="C,"; CONST byte commaByte_flags=0; void commaByte()
{
    push(*here);
    memWriteByte();
    *here += sizeof(byte);
}

CONST int word_id=33; CONST char* word_name="WORD"; CONST byte word_flags=0; void word()
{
    byte len = readWord();
    push(1);
    push(len);
}

CONST int find_id=34; CONST char* find_name="FIND"; CONST byte find_flags=0; void find()
{
    cell len = pop();
    cell address = pop();
    cell ret = findWord(address, len);
    push(ret);
}

cell getCfa(address)
  cell address;
{
    byte len = (memory[address + sizeof(cell)] & 0x1F) + 1;
    while ((len & (sizeof(cell)-1)) != 0) len++;
    return address + sizeof(cell) + len;
}

CONST int cfa_id=35; CONST char* cfa_name=">CFA"; CONST byte cfa_flags=0; void cfa()
{
    cell address = pop();
    cell ret = getCfa(address);
    if (ret < maxBuiltinAddress)
        push(readMem(ret));
    else
        push(ret);
}

CONST int number_id=36; CONST char* number_name="NUMBER"; CONST byte number_flags=0; void number()
{
    dcell num;
    cell notRead;
    byte isDouble;
    cell len = pop();
    byte* address = &memory[pop()];
    parseNumber(address, len, &num, &notRead, &isDouble);
    if (isDouble) dpush(num); else push((cell)num);
    push(notRead);
}

CONST int lit_id=37; CONST char* lit_name="LIT"; CONST byte lit_flags=0; void lit()
{
    push(readMem(next));
    next += sizeof(cell);
}


CONST int quit_id=38; CONST char* quit_name="QUIT"; CONST byte quit_flags=0; void quit()
{
    cell address;
    dcell number;
    cell notRead;
    cell command;
    int i;
    byte isDouble;
    cell tmp[2];

    int immediate;

    for (exitReq = 0; exitReq == 0;)
    {
        lastIp = next = quit_address;
        errorFlag = 0;

        word();
        find();

        address = pop();
        if (address)
        {
            immediate = (memory[address + sizeof(cell)] & 0x80);
            commandAddress = getCfa(address);
            command = readMem(commandAddress);
            if (*state && !immediate)
            {
                if (command < 81 && command != docol_id)
                    push(command);
                else
                    push(commandAddress);
                comma();
            }
            else
            {
                while (!errorFlag && !exitReq)
                {
                    if (command == quit_id) break;
                    else if (command < 81) {
                        void (*funcptr)();
                        funcptr = builtins[command];
                        (*funcptr)();
                    } else {
                        lastIp = next;
                        next = command;
                    }

                    commandAddress = next;
                    command = readMem(commandAddress);
                    next += sizeof(cell);
                }
            }
        }
        else
        {
            parseNumber(&memory[1], memory[0], &number, &notRead, &isDouble);
            if (notRead)
            {
                tell("Unknown word: ");
                for (i=0; i<memory[0]; i++)
                    putkey(memory[i+1]);
                putkey('\n');

                *sp = *rsp = 1;
                continue;
            }
            else
            {
                if (*state)
                {
                    *((dcell*)tmp) = number;
                    push(lit_id);
                    comma();

                    if (isDouble)
                    {
                        push(tmp[0]);
                        comma();
                        push(lit_id);
                        comma();
                        push(tmp[1]);
                        comma();
                    }
                    else
                    {
                        push((cell)number);
                        comma();
                    }
                }
                else
                {
                    if (isDouble) dpush(number); else push((cell)number);
                }
            }
        }

        if (errorFlag)
            *sp = *rsp = 1;
        else if (!keyWaiting() && !(*initscript_pos) && (!f_reading || !f_silent))
            tell(" OK\n");
    }
}

CONST int plus_id=39; CONST char* plus_name="+"; CONST byte plus_flags=0; void plus()
{
    scell n1 = pop();
    scell n2 = pop();
    push(n1 + n2);
}

CONST int minus_id=40; CONST char* minus_name="-"; CONST byte minus_flags=0; void minus()
{
    scell n1 = pop();
    scell n2 = pop();
    push(n2 - n1);
}

CONST int mul_id=41; CONST char* mul_name="*"; CONST byte mul_flags=0; void mul()
{
    scell n1 = pop();
    scell n2 = pop();
    push(n1 * n2);
}

CONST int divmod_id=42; CONST char* divmod_name="/MOD"; CONST byte divmod_flags=0; void divmod()
{
    scell n1 = pop();
    scell n2 = pop();
    push(n2 % n1);
    push(n2 / n1);
}

CONST int rot_id=43; CONST char* rot_name="ROT"; CONST byte rot_flags=0; void rot()
{
    cell a = pop();
    cell b = pop();
    cell c = pop();
    push(b);
    push(a);
    push(c);
}

/* void createWord(CONST char* name, byte len, byte flags); */
void createWord();

CONST int doCreate_id=44; CONST char* doCreate_name="CREATE"; CONST byte doCreate_flags=0; void doCreate()
{
    byte len;
    cell address;
    word();
    len = pop() & 255;
    address = pop();
    createWord((char*)&memory[address], len, 0);
}

CONST int colon_id=45; CONST char* colon_name=":"; CONST byte colon_flags=0; void colon()
{
    doCreate();
    push(docol_id);
    comma();
    hide();
    *state = 1;
}

CONST int semicolon_id=46; CONST char* semicolon_name=";"; CONST byte semicolon_flags=0x80; void semicolon()
{
    push(doExit_id);
    comma();
    hide();
    *state = 0;
}

CONST int rget_id=47; CONST char* rget_name="R@"; CONST byte rget_flags=0; void rget()
{
    cell tmp = rpop();
    rpush(tmp);
    push(tmp);
}

CONST int doJ_id=48; CONST char* doJ_name="J"; CONST byte doJ_flags=0; void doJ()
{
    cell tmp1 = rpop();
    cell tmp2 = rpop();
    cell tmp3 = rpop();
    rpush(tmp3);
    rpush(tmp2);
    rpush(tmp1);
    push(tmp3);
}

CONST int tick_id=49; CONST char* tick_name="'"; CONST byte tick_flags=0x80; void tick()
{
    word();
    find();
    cfa();

    if (*state)
    {
        push(lit_id);
        comma();
        comma();
    }
}

CONST int equals_id=50; CONST char* equals_name="="; CONST byte equals_flags=0; void equals()
{
    cell a1 = pop();
    cell a2 = pop();
    push(a2 == a1 ? -1 : 0);
}

CONST int smaller_id=51; CONST char* smaller_name="<"; CONST byte smaller_flags=0; void smaller()
{
    scell a1 = pop();
    scell a2 = pop();
    push(a2 < a1 ? -1 : 0);
}

CONST int larger_id=52; CONST char* larger_name=">"; CONST byte larger_flags=0; void larger()
{
    scell a1 = pop();
    scell a2 = pop();
    push(a2 > a1 ? -1 : 0);
}

CONST int doAnd_id=53; CONST char* doAnd_name="AND"; CONST byte doAnd_flags=0; void doAnd()
{
    cell a1 = pop();
    cell a2 = pop();
    push(a2 & a1);
}

CONST int doOr_id=54; CONST char* doOr_name="OR"; CONST byte doOr_flags=0; void doOr()
{
    cell a1 = pop();
    cell a2 = pop();
    push(a2 | a1);
}

CONST int p_dup_id=55; CONST char* p_dup_name="?DUP"; CONST byte p_dup_flags=0; void p_dup()
{
    cell a = tos();
    if (a) push(a);
}

CONST int litstring_id=56; CONST char* litstring_name="LITSTRING"; CONST byte litstring_flags=0; void litstring()
{
    cell length = readMem(next);
    next += sizeof(cell);
    push(next);
    push(length);
    next += length;
    while (next & (sizeof(cell)-1))
        next++;
}

CONST int xor_id=57; CONST char* xor_name="XOR"; CONST byte xor_flags=0; void xor()
{
    cell a = pop();
    cell b = pop();
    push(a ^ b);
}

CONST int timesDivide_id=58; CONST char* timesDivide_name="*/"; CONST byte timesDivide_flags=0; void timesDivide()
{
    cell n3 = pop();
    dcell n2 = pop();
    dcell n1 = pop();
    dcell r = (n1 * n2) / n3;
    push((cell)r);
    if ((cell)r != r)
    {
        tell("Arithmetic overflow\n");
        errorFlag = 1;
    }
}

CONST int timesDivideMod_id=59; CONST char* timesDivideMod_name="*/MOD"; CONST byte timesDivideMod_flags=0; void timesDivideMod()
{
    cell n3 = pop();
    dcell n2 = pop();
    dcell n1 = pop();
    dcell r = (n1 * n2) / n3;
    dcell m = (n1 * n2) % n3;
    push((cell)m);
    push((cell)r);
    if ((cell)r != r)
    {
        tell("Arithmetic overflow\n");
        errorFlag = 1;
    }
}

CONST int dequals_id=60; CONST char* dequals_name="D="; CONST byte dequals_flags=0; void dequals()
{
    dcell a1 = dpop();
    dcell a2 = dpop();
    push(a2 == a1 ? -1 : 0);
}

CONST int dsmaller_id=61; CONST char* dsmaller_name="D<"; CONST byte dsmaller_flags=0; void dsmaller()
{
    dscell a1 = dpop();
    dscell a2 = dpop();
    push(a2 < a1 ? -1 : 0);
}

CONST int dlarger_id=62; CONST char* dlarger_name="D>"; CONST byte dlarger_flags=0; void dlarger()
{
    dscell a1 = dpop();
    dscell a2 = dpop();
    push(a2 > a1 ? -1 : 0);
}

CONST int dusmaller_id=63; CONST char* dusmaller_name="DU<"; CONST byte dusmaller_flags=0; void dusmaller()
{
    dcell a1 = dpop();
    dcell a2 = dpop();
    push(a2 < a1 ? -1 : 0);
}

CONST int dplus_id=64; CONST char* dplus_name="D+"; CONST byte dplus_flags=0; void dplus()
{
    dscell n1 = dpop();
    dscell n2 = dpop();
    dpush(n1 + n2);
}

CONST int dminus_id=65; CONST char* dminus_name="D-"; CONST byte dminus_flags=0; void dminus()
{
    dscell n1 = dpop();
    dscell n2 = dpop();
    dpush(n2 - n1);
}

CONST int dmul_id=66; CONST char* dmul_name="D*"; CONST byte dmul_flags=0; void dmul()
{
    dscell n1 = dpop();
    dscell n2 = dpop();
    dpush(n1 * n2);
}

CONST int ddiv_id=67; CONST char* ddiv_name="D/"; CONST byte ddiv_flags=0; void ddiv()
{
    dscell n1 = dpop();
    dscell n2 = dpop();
    dpush(n2 / n1);
}

CONST int dswap_id=68; CONST char* dswap_name="2SWAP"; CONST byte dswap_flags=0; void dswap()
{
    dcell a = dpop();
    dcell b = dpop();
    dpush(a);
    dpush(b);
}

CONST int dover_id=69; CONST char* dover_name="2OVER"; CONST byte dover_flags=0; void dover()
{
    dcell a = dpop();
    dcell b = dpop();
    dpush(b);
    dpush(a);
    dpush(b);
}

CONST int drot_id=70; CONST char* drot_name="2ROT"; CONST byte drot_flags=0; void drot()
{
    dcell a = dpop();
    dcell b = dpop();
    dcell c = dpop();
    dpush(b);
    dpush(a);
    dpush(c);
}

CONST int cwtell_id=71; CONST char* cwtell_name="TELL"; CONST byte cwtell_flags=0; void cwtell()
{
    cell length = pop();
    cell addr = pop();

    while (length>0) {
        putkey(memory[addr]);
        length--;
        addr++;
    }
}

CONST int outport_id=72; CONST char* outport_name="OUT"; CONST byte outport_flags=0; void outport()
{
    cell portAddr = pop();
    cell value = pop() & 0x0FF;

#ifdef H8_80186
    outp(portAddr, value);
#else
#ifdef OLIVETTI
    outp(portAddr, value);
#else
#ifdef MULTIBUS
    outp(portAddr, value);
#endif
#endif
#endif
}

CONST int inport_id=73; CONST char* inport_name="IN"; CONST byte inport_flags=0; void inport()
{
    cell portAddr = pop();
    unsigned char value;

#ifdef H8_80186
    value = inp(portAddr);
#else
#ifdef OLIVETTI
    value = inp(portAddr);
#else
#ifdef MULTIBUS
    value = inp(portAddr);
#endif
#endif
#endif

    push(value);
}

CONST int readfile_id=74; CONST char* readfile_name="READFILE"; CONST byte readfile_flags=0; void readfile()
{
    char *fn;
    char save;
    int bread;
    cell length = pop();
    cell addr = pop();

    fn = &memory[addr];

    /* make sure the filename is null-terminated */
    save = memory[addr+length];
    memory[addr+length] = '\0';

    if (f_reading!=NULL) {
        fclose(f_reading);
        f_reading = NULL;
    }

    f_silent = 0;
    f_reading = fopen(fn, "rt");

    if (f_reading == NULL) {
        fprintf(stderr, "failed to open file %s\n", fn);
    }

    memory[addr+length] = save;
}

CONST int showfile_id=75; CONST char* showfile_name="SHOWFILE"; CONST byte showfile_flags=0; void showfile()
{
    char *fn;
    FILE *f;
    char save;
    int bread;
    cell length = pop();
    cell addr = pop();

    fn = &memory[addr];

    /* make sure the filename is null-terminated */
    save = memory[addr+length];
    memory[addr+length] = '\0';

    f = fopen(fn, "rt");

    if (f == NULL) {
        fprintf(stderr, "failed to open file %s\n", fn);
        memory[addr+length] = save;
        return;
    }

    memory[addr+length] = save;

    while (1) {
        int c = fgetc(f);
        if (c==-1) {
            fclose(f);
            return;
        }
        putkey(c);
    }
}

CONST int showdir_id=76; CONST char* showdir_name="SHOWDIR"; CONST byte showdir_flags=0; void showdir()
{
#ifdef OLIVETTI
    char name_buf[33];
    int length;
    int search_mode;
    int drive;
    int count;
    char *file_pointer;
    int retval;
    int i;

    search_mode = 1;
    drive = -1;
    count = 0;
    while (1) {
        length = 0;
        file_pointer = name_buf;
        retval = _pcos_search(drive, search_mode, &length,
                            &file_pointer, NULL);
        if (retval != PCOS_ERR_OK) break;
        search_mode = 0;   /* from now on search from the
                            last file found */
        name_buf[length] = 0;  /* zero terminate name */
        tell(name_buf);
        for(i=length; i<16; i++) {
            putkey(' ');
        }
        count+=1;
        if ((count%4)==0) {
            putkey('\n');
        }
    }
    if ((count%4)!=0) {
        putkey('\n');
    }
#endif
}

CONST int erase_id=77; CONST char* erase_name="ERASE"; CONST byte erase_flags=0; void erase()
{
    cell length = pop();
    cell addr = pop();
    cell i;

    for (i=0; i<length; i++) {
        memory[addr] = 0;
        addr++;
    }
}

CONST int execute_id=78; CONST char* execute_name="EXECUTE"; CONST byte execute_flags=0; void execute()
{
    cell addr = pop();

    lastIp = next;
    next = addr;
}

CONST int charlit_id=79; CONST char* charlit_name="CHAR"; CONST byte charlit_flags=0; void charlit()
{
    word();
    push(memory[1]);
}

CONST int atxy_id=80; CONST char* atxy_name="AT-XY"; CONST byte atxy_flags=0; void atxy()
{
    cell y = pop()+1;
    cell x = pop()+1;

#ifdef OLIVETTI
    _pcos_chgcur0(x,y);
#else
    printf("%c[%d;%df",0x1B,y,x);
#endif
}
  


/*******************************************************************************
*
* Loose ends
*
*******************************************************************************/

/* Create a word in the dictionary */
void createWord(name, len, flags)
    CONST char* name;
    byte len;
    byte flags;
{
    cell newLatest = *here;
    push(*latest);
    comma();
    push(len | flags);
    commaByte();
    while (len--)
    {
        push(*name);
        commaByte();
        name++;
    }
    while (*here & (CELL_SIZE-1))
    {
        push(0);
        commaByte();
    }
    *latest = newLatest;
}

/* A simple strlen clone so we don't have to pull in string.h */
byte slen(str)
  CONST char *str;
{
    byte ret = 0;
    while (*str++) ret++;
    return ret;
}

/* Add a builtin to the dictionary */
void addBuiltin(code, name, flags, f)
    cell code;
    CONST char* name;
    CONST byte flags;
    builtin f;
{
    if (errorFlag) return;

    if (code >= MAX_BUILTIN_ID)
    {
        tell("Error adding builtin ");
        tell(name);
        tell(": Out of builtin IDs\n");
        errorFlag = 1;
        return;
    }

    if (builtins[code] != 0)
    {
        tell("Error adding builtin ");
        tell(name);
        tell(": ID given twice\n");
        errorFlag = 1;
        return;
    }

    builtins[code] = f;
    createWord(name, slen(name), flags);
    push(code);
    comma();
    push(doExit_id);
    comma();
}

char inbuf[1024];

/* Program setup and jump to outer interpreter */
int main()
{
    errorFlag = 0;

    if (DCELL_SIZE != 2*CELL_SIZE)
    {
        tell("Configuration error: DCELL_SIZE != 2*CELL_SIZE\n");
        return 1;
    }

    state = (cell*)&memory[STATE_POSITION];
    base = (cell*)&memory[BASE_POSITION];
    latest = (cell*)&memory[LATEST_POSITION];
    here = (cell*)&memory[HERE_POSITION];
    sp = (cell*)&memory[STACK_POSITION];
    stack = (cell*)&memory[STACK_POSITION + CELL_SIZE];
    rsp = (cell*)&memory[RSTACK_POSITION];
    rstack = (cell*)&memory[RSTACK_POSITION + CELL_SIZE];

    *sp = *rsp = 1;
    *state = 0;
    *base = 10;
    *latest = 0;
    *here = HERE_START;

    f_reading = NULL;

    addBuiltin(docol_id, docol_name, docol_flags, docol);
    addBuiltin(doCellSize_id, doCellSize_name, doCellSize_flags, doCellSize);
    addBuiltin(memRead_id, memRead_name, memRead_flags, memRead);
    addBuiltin(memWrite_id, memWrite_name, memWrite_flags, memWrite);
    addBuiltin(memReadByte_id, memReadByte_name, memReadByte_flags, memReadByte);
    addBuiltin(memWriteByte_id, memWriteByte_name, memWriteByte_flags, memWriteByte);
    addBuiltin(key_id, key_name, key_flags, key);
    addBuiltin(emit_id, emit_name, emit_flags, emit);
    addBuiltin(swap_id, swap_name, swap_flags, swap);
    addBuiltin(dup_id, dup_name, dup_flags, dup);
    addBuiltin(drop_id, drop_name, drop_flags, drop);
    addBuiltin(over_id, over_name, over_flags, over);
    addBuiltin(comma_id, comma_name, comma_flags, comma);
    addBuiltin(commaByte_id, commaByte_name, commaByte_flags, commaByte);
    addBuiltin(word_id, word_name, word_flags, word);
    addBuiltin(find_id, find_name, find_flags, find);
    addBuiltin(cfa_id, cfa_name, cfa_flags, cfa);
    addBuiltin(doExit_id, doExit_name, doExit_flags, doExit);
    addBuiltin(quit_id, quit_name, quit_flags, quit);
    quit_address = getCfa(*latest);
    addBuiltin(number_id, number_name, number_flags, number);
    addBuiltin(bye_id, bye_name, bye_flags, bye);
    addBuiltin(doLatest_id, doLatest_name, doLatest_flags, doLatest);
    addBuiltin(doHere_id, doHere_name, doHere_flags, doHere);
    addBuiltin(doBase_id, doBase_name, doBase_flags, doBase);
    addBuiltin(doState_id, doState_name, doState_flags, doState);
    addBuiltin(plus_id, plus_name, plus_flags, plus);
    addBuiltin(minus_id, minus_name, minus_flags, minus);
    addBuiltin(mul_id, mul_name, mul_flags, mul);
    addBuiltin(divmod_id, divmod_name, divmod_flags, divmod);
    addBuiltin(rot_id, rot_name, rot_flags, rot);
    addBuiltin(gotoInterpreter_id, gotoInterpreter_name, gotoInterpreter_flags, gotoInterpreter);
    addBuiltin(gotoCompiler_id, gotoCompiler_name, gotoCompiler_flags, gotoCompiler);
    addBuiltin(doCreate_id, doCreate_name, doCreate_flags, doCreate);
    addBuiltin(hide_id, hide_name, hide_flags, hide);
    addBuiltin(lit_id, lit_name, lit_flags, lit);
    addBuiltin(colon_id, colon_name, colon_flags, colon);
    addBuiltin(semicolon_id, semicolon_name, semicolon_flags, semicolon);
    addBuiltin(rtos_id, rtos_name, rtos_flags, rtos);
    addBuiltin(stor_id, stor_name, stor_flags, stor);
    addBuiltin(rget_id, rget_name, rget_flags, rget);
    addBuiltin(doJ_id, doJ_name, doJ_flags, doJ);
    addBuiltin(tick_id, tick_name, tick_flags, tick);
    addBuiltin(key_p_id, key_p_name, key_p_flags, key_p);
    addBuiltin(equals_id, equals_name, equals_flags, equals);
    addBuiltin(smaller_id, smaller_name, smaller_flags, smaller);
    addBuiltin(larger_id, larger_name, larger_flags, larger);
    addBuiltin(doAnd_id, doAnd_name, doAnd_flags, doAnd);
    addBuiltin(doOr_id, doOr_name, doOr_flags, doOr);
    addBuiltin(branch_id, branch_name, branch_flags, branch);
    addBuiltin(zbranch_id, zbranch_name, zbranch_flags, zbranch);
    addBuiltin(toggleImmediate_id, toggleImmediate_name, toggleImmediate_flags, toggleImmediate);
    addBuiltin(doFree_id, doFree_name, doFree_flags, doFree);
    addBuiltin(p_dup_id, p_dup_name, p_dup_flags, p_dup);
    addBuiltin(s0_r_id, s0_r_name, s0_r_flags, s0_r);
    addBuiltin(dsp_r_id, dsp_r_name, dsp_r_flags, dsp_r);
    addBuiltin(litstring_id, litstring_name, litstring_flags, litstring);
    addBuiltin(not_id, not_name, not_flags, not);
    addBuiltin(xor_id, xor_name, xor_flags, xor);
    addBuiltin(timesDivide_id, timesDivide_name, timesDivide_flags, timesDivide);
    addBuiltin(timesDivideMod_id, timesDivideMod_name, timesDivideMod_flags, timesDivideMod);
    addBuiltin(dequals_id, dequals_name, dequals_flags, dequals);
    addBuiltin(dsmaller_id, dsmaller_name, dsmaller_flags, dsmaller);
    addBuiltin(dlarger_id, dlarger_name, dlarger_flags, dlarger);
    addBuiltin(dusmaller_id, dusmaller_name, dusmaller_flags, dusmaller);
    addBuiltin(dplus_id, dplus_name, dplus_flags, dplus);
    addBuiltin(dminus_id, dminus_name, dminus_flags, dminus);
    addBuiltin(dmul_id, dmul_name, dmul_flags, dmul);
    addBuiltin(ddiv_id, ddiv_name, ddiv_flags, ddiv);
    addBuiltin(dswap_id, dswap_name, dswap_flags, dswap);
    addBuiltin(dover_id, dover_name, dover_flags, dover);
    addBuiltin(drot_id, drot_name, drot_flags, drot);
    addBuiltin(cwtell_id, cwtell_name, cwtell_flags, cwtell);
    addBuiltin(inport_id, inport_name, inport_flags, inport);
    addBuiltin(outport_id, outport_name, outport_flags, outport);
    addBuiltin(readfile_id, readfile_name, readfile_flags, readfile);
    addBuiltin(showfile_id, showfile_name, showfile_flags, showfile);
    addBuiltin(showdir_id, showdir_name, showdir_flags, showdir);
    addBuiltin(erase_id, erase_name, erase_flags, erase);
    addBuiltin(execute_id, execute_name, execute_flags, execute);
    addBuiltin(charlit_id, charlit_name, charlit_flags, charlit);
    addBuiltin(atxy_id, atxy_name, atxy_flags, atxy);
    maxBuiltinAddress = (*here) - 1;

    if (errorFlag) return 1;

    tell("lbforth by Leif Bruder.\n");
#ifdef OLIVETTI
    tell("Modified for olivetti M20 by Scott Baker, www.smbaker.com.\n");
#else
#ifdef H8_80186
    tell("Modified for H8-80186 by Scott Baker, www.smbaker.com.\n");
#else
#ifdef MULTIBUS
    tell("Modified for iRMX86 by Scott Baker, www.smbaker.com.\n");
#endif
#endif
#endif

#ifdef INITSCRIPT_FILE
    f_silent = 1; /* let initscript be silent */
    f_reading = fopen("initsc.f", "rt");
    if (f_reading == NULL) {
        tell("Failed to open initscript file\n");
        return 1;
    }
    initscript_pos = emptyString;
#else
    initscript_pos = (char*)initScript;
#endif

    tell("Initializing...\n");
    quit();
    return 0;
}
