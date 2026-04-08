#include <signal.h>
#include <stdio.h>
#include <unistd.h>

__attribute__((naked, used)) void gadget_pop_rdi(void)
{
    __asm__("pop %rdi; ret");
}

__attribute__((naked, used)) void gadget_pop_rsi_r15(void)
{
    __asm__("pop %rsi; pop %r15; ret");
}

__attribute__((naked, used)) void gadget_pop_rdx(void)
{
    __asm__("pop %rdx; ret");
}

static void init(void)
{
    alarm(60);
    setvbuf(stdin, NULL, _IONBF, 0);
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);
}

static void vuln(void)
{
    char buf[0x40];

    puts("ret2dlresolve practice");
    puts("payload:");
    read(0, buf, 0x200);
}

int main(void)
{
    init();
    vuln();
    return 0;
}
