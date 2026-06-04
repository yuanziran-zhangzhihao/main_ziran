#define _GNU_SOURCE
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#define LISTEN_PORT 8000

extern char **environ;

static const char *pick_flag(void)
{
    static const char *names[] = {
        "FLAG_VALUE",
        "FLAG",
        "PCTF_FLAG",
        "GZCTF_FLAG",
        "A1CTF_FLAG",
        NULL,
    };
    size_t i;

    for (i = 0; names[i]; i++) {
        const char *value = getenv(names[i]);

        if (value && *value)
            return value;
    }

    return "PCTF{pwn_ret2dlresolve_static_20260604}";
}

static void clear_flag_env(void)
{
    static const char *names[] = {
        "FLAG_VALUE",
        "FLAG",
        "PCTF_FLAG",
        "GZCTF_FLAG",
        "A1CTF_FLAG",
        NULL,
    };
    size_t i;

    for (i = 0; names[i]; i++)
        unsetenv(names[i]);
}

static void write_flag_file(const char *flag)
{
    int fd = open("/home/ctf/flag", O_WRONLY | O_CREAT | O_TRUNC, 0644);
    size_t len = strlen(flag);

    if (fd < 0) {
        perror("open flag");
        exit(1);
    }

    if (write(fd, flag, len) != (ssize_t)len) {
        perror("write flag");
        close(fd);
        exit(1);
    }

    close(fd);
}

static void serve(void)
{
    int server_fd;
    int opt = 1;
    struct sockaddr_in addr;

    signal(SIGCHLD, SIG_IGN);
    signal(SIGPIPE, SIG_IGN);

    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("socket");
        exit(1);
    }

    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) {
        perror("setsockopt");
        exit(1);
    }

    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_port = htons(LISTEN_PORT);

    if (bind(server_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("bind");
        exit(1);
    }

    if (listen(server_fd, 16) < 0) {
        perror("listen");
        exit(1);
    }

    dprintf(2, "[+] pwn-ret2dlresolve listening on 0.0.0.0:%d\n", LISTEN_PORT);

    while (1) {
        int client_fd = accept(server_fd, NULL, NULL);

        if (client_fd < 0) {
            if (errno == EINTR)
                continue;
            perror("accept");
            break;
        }

        if (fork() == 0) {
            char *argv[] = { "/home/ctf/pwn", NULL };

            dup2(client_fd, STDIN_FILENO);
            dup2(client_fd, STDOUT_FILENO);
            dup2(client_fd, STDERR_FILENO);
            close(client_fd);
            if (chdir("/home/ctf") < 0) {
                perror("chdir");
                _exit(127);
            }
            execve(argv[0], argv, environ);
            perror("execve");
            _exit(127);
        }

        close(client_fd);
    }
}

int main(void)
{
    const char *flag = pick_flag();

    write_flag_file(flag);
    clear_flag_env();
    serve();
    return 0;
}
