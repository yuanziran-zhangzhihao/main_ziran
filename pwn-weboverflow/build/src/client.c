#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#define PORT 8080
#define BUF 1024

int main() {
    int fd = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in a;
    memset(&a, 0, sizeof(a));
    a.sin_family = AF_INET;
    a.sin_port = htons(PORT);
    inet_pton(AF_INET, "127.0.0.1", &a.sin_addr);

    if (connect(fd, (struct sockaddr*)&a, sizeof(a)) < 0) {
        perror("connect");
        return 1;
    }

    // 读一下服务端欢迎语（如果没有也不影响）
    char buf[BUF];
    int n = recv(fd, buf, BUF-1, 0);
    if (n > 0) { buf[n] = 0; printf("%s", buf); }

    // 从stdin读，发给服务端
    while (fgets(buf, sizeof(buf), stdin)) {
        send(fd, buf, strlen(buf), 0);
        n = recv(fd, buf, BUF-1, 0);   // 读服务端回显
        if (n <= 0) break;
        buf[n] = 0;
        printf("%s", buf);
    }

    close(fd);
    return 0;
}
