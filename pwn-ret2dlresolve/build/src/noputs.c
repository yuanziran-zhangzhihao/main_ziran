#include <stdio.h>
#include <time.h>
#include <seccomp.h>
#include <sys/prctl.h>
#include <unistd.h>

void init(){
    setvbuf(stderr, NULL, _IONBF, 0);   
    setvbuf(stdout,NULL,_IONBF,0);
    setvbuf(stdin,NULL,_IONBF,0);
}

void gift(){
    char buf[0x3];
    read(0,buf,0x3);
    printf(buf);
}

void box(){
    prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0);
    scmp_filter_ctx c = seccomp_init(SCMP_ACT_ALLOW);
    seccomp_rule_add(c, SCMP_ACT_ERRNO(1), SCMP_SYS(write),  1, SCMP_A0(SCMP_CMP_EQ, 1));
    seccomp_rule_add(c, SCMP_ACT_ERRNO(1), SCMP_SYS(writev), 1, SCMP_A0(SCMP_CMP_EQ, 1));
    seccomp_load(c);
}

int verify(lock){
    char buf[0x10];
    int sign;
    read(0,buf,0x10);
    sign = strcmp(lock,buf);
    if(sign){
    exit(1); 
    }
}


void shell(){
    system("/bin/sh");
}


int main(){
    init();
    gift();
    box();
    srand(time(NULL));
    int lock = rand()%100;
    verify(lock);
    char buf[0x30];
    read(0, buf, 0x200);
    return 0;
}