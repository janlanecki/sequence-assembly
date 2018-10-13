# Sequence checker in assembly x86_64

### Checks if the sequence of numbers in a file (interpreting bytes as numbers) is formatted as
```
(permutation of a set M, 0, permutation of M, 0, ..., permutation of M, 0)
```
### and returns 0 if the sequence is formatted as above, 1 if not or the filename was incorrect.

#### Run instructions:
```
nasm -f elf64 -o sequence.o sequence.asm
ld -o sequence sequence.o
./sequence filename
```
