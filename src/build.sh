#!/bin/sh

AS=/home/user/programs/bin/nasm
LINK=ld

$AS -f elf64 -O0 -g -l linux.lst -o linux.o linux.asm
$AS -f elf64 -O0 -g -l tostring.lst -o tostring.o tostring.asm
$AS -f elf64 -O0 -g -l vectors.lst -o vectors.o vectors.asm
$AS -f elf64 -O0 -g -l fops.lst -o fops.o fops.asm
$AS -f elf64 -O0 -g -l sigmoid.lst -o sigmoid.o sigmoid.asm
$AS -f elf64 -O0 -g -l matrix.lst -o matrix.o matrix.asm
$AS -f elf64 -O0 -g -l mse.lst -o mse.o mse.asm
$AS -f elf64 -O0 -g -l ann.lst -o ann.o ann.asm
$AS -f elf64 -O0 -g -l test_ann.lst -o test_ann.o test_ann.asm

$LINK -b elf64-x86-64 \
    vectors.o linux.o tostring.o matrix.o fops.o sigmoid.o mse.o ann.o test_ann.o \
    -o test_ann --entry main -z stack-size=1000
