#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/wait.h>
#include <signal.h>

#define PORT 8080
#define BACKLOG 10
#define VULN_SIZE 0x400   // 明确定义 vuln 大小

void handle_client(int client_fd) {
    char buffer[0x20];  // 小缓冲区，用于 memcpy 目标
    char vuln[VULN_SIZE]; // 把 vuln 放在 handle_client 栈上（更容易溢出）

    memset(buffer, 0, sizeof(buffer));
    memset(vuln, 0, sizeof(vuln));

    const char *welcome_msg = "Welcome to the vulnerable server!\n";
    send(client_fd, welcome_msg, strlen(welcome_msg), 0);

    ssize_t n = recv(client_fd, vuln, sizeof(vuln) - 1, 0);
    if (n > 0) {
        vuln[n] = '\0';
        memcpy(buffer, vuln, n);  

        const char *response = "Data processed. Goodbye.\n";
        send(client_fd, response, strlen(response), 0);
    }

    close(client_fd);
}

int main() {
    signal(SIGCHLD, SIG_IGN);

    int s = socket(AF_INET, SOCK_STREAM, 0);
    if (s < 0) {
        perror("socket failed");
        exit(EXIT_FAILURE);
    }

    int opt = 1;
    setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(PORT);
    addr.sin_addr.s_addr = INADDR_ANY;

    if (bind(s, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("bind failed");
        exit(EXIT_FAILURE);
    }

    if (listen(s, BACKLOG) < 0) {
        perror("listen failed");
        exit(EXIT_FAILURE);
    }

    printf("Server listening on port %d\n", PORT);

    while (1) {
        int client_fd = accept(s, NULL, NULL);
        if (client_fd < 0) {
            perror("accept failed");
            continue;
        }

        if (fork() == 0) {
            close(s); // 子进程不需要监听套接字
            handle_client(client_fd);
            exit(0);
        }
        close(client_fd); // 父进程关闭连接套接字
    }
}