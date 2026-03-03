/* 

   This program converts only the .text section of a
   C program into a file that can be included when doing
   the Verilog build of the SoC.

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ROWLEN 32

unsigned char ram[4][ROWLEN];

void print_init(int n)
{
  int i, j;

  for (i = 0; i < 4; i++) {
    printf("localparam RAM%d_%02X = 256'h",i, n);
    for (j = 0; j < ROWLEN; j++) printf("%02X", ram[i][j]);
    printf(";\n");
  }
}

int main(int argc, char **argv)
{
  FILE *fp;
  int i, v, count = 0, index = ROWLEN - 1, n = 0;
  
  if (argc != 2) {
    fprintf(stderr, "Usage: conv_to_init filename\n");
    exit(EXIT_FAILURE);
  }

  fp = fopen(argv[1], "rb");
  if (fp == NULL) {
    fprintf(stderr, "Could not open %s\n", argv[1]);
    exit(EXIT_FAILURE);
  }

  printf("// This is a generated file containg the machine code\n");
  memset(ram, 0, sizeof(ram));

  while ((v = fgetc(fp)) != EOF) {
    ram[count%4][index] = v;
    if (count%4 == 3) index -= 1;
    count += 1;
    if (index == -1) {
      print_init(n);
      n += 1;
      index = ROWLEN - 1;
      memset(ram, 0, sizeof(ram));
    }
  }

  fclose(fp);

  // complete one if in progress
  if (index != ROWLEN -1) {
    print_init(n);
    n += 1;
  }

  if (n >= 0x40) {
    fprintf(stderr, "ERROR: PROGRAM IS TOO LARGE, greater than 8192 bytes : %d \n", n);
    fprintf(stderr, "It must be LESS THAN 8192 to leave room for the stack\n");
    return(EXIT_FAILURE);
  }

  for (i = n; i < 0x40; i++) {
      memset(ram, 0, sizeof(ram));
      print_init(i);
  }

  printf("// count = %d, index = %d\n", count, index);



  return EXIT_SUCCESS;
}


  
