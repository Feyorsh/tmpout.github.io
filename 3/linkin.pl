linkin.pl
~ isra

Yet another proof-of-concept x64 ELF virus written in Perl:

 * It works by patching the last byte (return instruction) of the .fini section
   and then injecting a payload in the free space (null bytes) between the
   .fini and .rodata sections. Infection is accomplished only if free space is
   greater than size of payload + size of virus.

 * Payload and replication are performed after the main program is executed 
   (on termination).

 * It uses a non-destructive hardcoded payload that prints an extract from the
   song "in the end" by Linkin Park and then infects other binaries in the
   current directory.

 * Replication is achieved by running the infected binary as a perl script 
   (based on perljam.pl).

 * ELF headers, file size and entry point are not modified.

 * It works on regular and position independent binaries.

 * It does not implement any evasion techniques.

 * Tested on Debian 11 x86_64. 

Size of linkin.pl + payload is ~2400. A quick search on (my) /usr/bin shows
that 817 files have enough free space for infection. Interesting binaries
include: su, perl, cat, cp, ls.

Write-up coming soon. For now a quick summary of the workflow:

 * Traverse current directory (non-recursevily) looking for targets.

 * Inspect entries 14-18 in the section header table to find .fini by checking
   if sh_flags = 6 (AX) and sh_addralign = 4.

 * Read next section header entry (.rodata) and calculate: 

      free space = .rodatash_offset - (.fini sh_offset + .fini sh_size).

 * Check if free space > payload size + virus size.

 * Create temporary copy to apply changes.

 * Adjust payload to include binary's filename (see perljam.pl).

 * Copy payload + virus starting at position .fini sh_offset + .fini sh_size-1

 * Copy the rest of the binary without changes and replace the original binary
   with the modified copy.

If you are unsure which binary to use for testing infection do the following:

 * Create test.c
 ------------------------------------------------------------------------------
 #include <stdio.h>

 int main(void) {
     printf("hello world\n");
     return 0;
 }
 ------------------------------------------------------------------------------

 * Compile it: 

      $ gcc test.c -o test

 * Check free space (should be greater than 2400): 

      $ a=$(readelf -S -W a | grep ".fini " | awk '{printf $4}'); \
      b=$(readelf -S -W a | grep ".rodata " | awk '{printf $4}'); \
      perl -e "printf(qq(%d\n),(0x$b-0x$a))"

 * Run linkin.pl on the same directory (no output): 

      $ perl linkin.pl

 * Run infected binary

      $ ./test
      hola mundo
      I tried so hard and got so far, but in the end it doesn't even matter


Code:
 
 linkin.pl - minimized code to reduce virus size.
 linkin-packed.pl - packed virus (i.e. lazy obfuscation)
 linkin-commented.pl - code with comments and some indentation
 linkin.s - assembly code used to generate the payload


Bugs:

 * Payload message won't be printed if the binary .fini code closes stdout
   before exiting. However, you can use strace to check that the write()
   syscall is actually called.


Resources:

 https://github.com/ilv/vx/tree/main/linkin
 https://hckng.org/articles/perljam-elf64-virus.html
 https://tmpout.sh/1/7.html
