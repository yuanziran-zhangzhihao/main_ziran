#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void backdoor(){
    printf("backdoor called\n");
    system("/bin/sh");
}

void vuln(){
    char buf[0x40];
    void *p = malloc(0x100);
    printf("chunk_addr: %p\n",p);
    read(0,p,0x1000);
    memcpy(buf,p,0x100);
    
    free(p);
}

void init(){
    setvbuf(stdout,0,2,0);
    setvbuf(stdin,0,2,0);
    setvbuf(stderr,0,2,0);
}
void gift() {
    __asm__(
        "pop %rdi\n"
        "ret\n"
    );
}

int main(){
    init();
    char buf[0x40];
    char *p = malloc(0x100);
    puts("input your name:");
    read(0,buf,0x40);
    puts("input your pasword:");
    read(0,p,0x100);
    if(strcmp(buf,"admin")==0&&strcmp(p,"123456")==0){
        puts("login success!");
        vuln();
    }else{
        puts("login failed!");
    }
}
