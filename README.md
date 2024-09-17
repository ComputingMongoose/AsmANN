# AsmANN (Assembly language Artificial Neural Network)

This repository contains different experiments with building an Artificial Neural Network in x86 64-bit Assembly language.

Currently it contains only a minimalist ANN.

## Building

The code is intended for a Linux operating system using nasm. OS-specific code is in [src/linux.asm](src/linux.asm) . If you want to compile this on another operating system, you need to change this file. I have a video on my Youtube channel on how to implement these functions on Windows.

To compile the code, you need *nasm* and *ld*. There is a [src/build.sh](src/build.sh) file that can be used to automate the build. You should edit it to set the currect paths to your nasm and ld. If you don't have nasm on your OS, I have a video about compiling it from source without root access.

## Running

After compiling, you will get the executable file *test_ann*. You should execute this file to get the network to train. I have a video about it here: https://youtu.be/AYuyN8vvkAM

## Other resources

Checkout my assembly language playlist on Youtube: https://www.youtube.com/playlist?list=PL7-u-wmV6bWqmPScAQzyfqLT05xKvUUEC
And my artificial intelligence playlist: https://www.youtube.com/playlist?list=PL7-u-wmV6bWopRa1Qchpq9s0PPJyn2MKl

