#include <arpa/inet.h>
#include <ctype.h>
#include <errno.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#define LISTEN_PORT 8080
#define RECV_BUF_SIZE 8192
#define BODY_BUF_SIZE 4096

static const char *FLAG = "flag{router_stack_overflow_for_beginners}";

static const char *INDEX_HTML =
"<!DOCTYPE html>\n"
"<html lang=\"zh-CN\">\n"
"<head>\n"
"  <meta charset=\"UTF-8\">\n"
"  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
"  <title>Tendora N301 Wireless Router</title>\n"
"  <link rel=\"stylesheet\" href=\"/style.css\">\n"
"</head>\n"
"<body>\n"
"  <div class=\"topbar\">\n"
"    <div class=\"logo\">Tendora</div>\n"
"    <div class=\"model\">N301 Wireless-N Easy Setup Router</div>\n"
"    <div class=\"fw\">Firmware V5.0.1.12_en</div>\n"
"  </div>\n"
"  <div class=\"tabs\">\n"
"    <a href=\"#\">Status</a>\n"
"    <a class=\"active\" href=\"#\">Wireless</a>\n"
"    <a href=\"#\">DHCP</a>\n"
"    <a href=\"#\">Advanced</a>\n"
"    <a href=\"#\">System Tools</a>\n"
"  </div>\n"
"  <div class=\"layout\">\n"
"    <aside class=\"menu\">\n"
"      <div class=\"menu-title\">Wireless Menu</div>\n"
"      <a class=\"active\" href=\"#\">Wireless Basic Settings</a>\n"
"      <a href=\"#\">Wireless Security</a>\n"
"      <a href=\"#\">MAC Filter</a>\n"
"      <a href=\"#\">WPS Settings</a>\n"
"      <a href=\"#\">Station List</a>\n"
"    </aside>\n"
"    <main class=\"content\">\n"
"      <div class=\"crumb\">Home &gt;&gt; Wireless &gt;&gt; Wireless Basic Settings</div>\n"
"      <section class=\"panel\">\n"
"        <div class=\"panel-head\">\n"
"          <h1>Wireless Basic Settings</h1>\n"
"          <span>goform endpoint: /goform/WifiBasicSet</span>\n"
"        </div>\n"
"        <p class=\"desc\">Configure the 2.4 GHz radio parameters. Apply will submit the form directly to the management handler.</p>\n"
"        <form id=\"wifi-form\">\n"
"          <label>\n"
"            <span>Wireless Network Name (SSID)</span>\n"
"            <input name=\"ssid\" type=\"text\" maxlength=\"256\" value=\"Tendora_Office\">\n"
"          </label>\n"
"          <label>\n"
"            <span>Channel</span>\n"
"            <select name=\"channel\">\n"
"              <option>1</option>\n"
"              <option>6</option>\n"
"              <option selected>11</option>\n"
"            </select>\n"
"          </label>\n"
"          <label>\n"
"            <span>WPA Pre-Shared Key</span>\n"
"            <input name=\"password\" type=\"text\" value=\"12345678\">\n"
"          </label>\n"
"          <div class=\"actions\">\n"
"            <button type=\"submit\">OK</button>\n"
"            <button type=\"button\" class=\"ghost\" onclick=\"location.reload()\">Cancel</button>\n"
"          </div>\n"
"        </form>\n"
"      </section>\n"
"      <section class=\"notice\">\n"
"        <h2>Security Notice</h2>\n"
"        <p>This synthetic challenge imitates the tone of legacy router advisories: a malformed SSID supplied to the web management form may cause stack corruption in the wireless setup handler.</p>\n"
"        <ul>\n"
"          <li>Product Line: Tendora N301</li>\n"
"          <li>Affected Component: Wireless Basic Settings</li>\n"
"          <li>Attack Vector: Authenticated POST request</li>\n"
"          <li>Expected Skill Level: Beginner</li>\n"
"        </ul>\n"
"      </section>\n"
"      <pre id=\"result\">Awaiting configuration change...</pre>\n"
"    </main>\n"
"  </div>\n"
"  <script src=\"/app.js\"></script>\n"
"</body>\n"
"</html>\n";

static const char *STYLE_CSS =
":root {\n"
"  --red: #c51b1b;\n"
"  --red-dark: #9f1111;\n"
"  --line: #d9d9d9;\n"
"  --panel: #ffffff;\n"
"  --page: #f1f1f1;\n"
"  --ink: #222;\n"
"  --muted: #6b6b6b;\n"
"}\n"
"* { box-sizing: border-box; }\n"
"body { margin: 0; background: var(--page); color: var(--ink); font-family: Tahoma, Arial, 'Microsoft YaHei', sans-serif; }\n"
".topbar { display: flex; align-items: center; gap: 18px; padding: 14px 22px; color: #fff; background: linear-gradient(180deg, var(--red), var(--red-dark)); border-bottom: 3px solid #7d0e0e; }\n"
".logo { font-size: 34px; font-weight: 700; letter-spacing: .02em; }\n"
".model { flex: 1; font-size: 18px; }\n"
".fw { font-size: 13px; opacity: .92; }\n"
".tabs { display: flex; gap: 2px; padding: 0 16px; background: #ececec; border-bottom: 1px solid #cfcfcf; }\n"
".tabs a { padding: 12px 18px; color: #333; text-decoration: none; background: #e4e4e4; border-left: 1px solid #d5d5d5; border-right: 1px solid #d5d5d5; }\n"
".tabs a.active { color: #fff; background: var(--red); }\n"
".layout { display: grid; grid-template-columns: 240px 1fr; gap: 18px; padding: 18px; }\n"
".menu, .panel, .notice, pre { background: var(--panel); border: 1px solid var(--line); }\n"
".menu-title { padding: 12px 14px; color: #fff; background: #666; font-weight: 700; }\n"
".menu a { display: block; padding: 12px 14px; color: #333; text-decoration: none; border-top: 1px solid #ededed; }\n"
".menu a.active { color: var(--red); font-weight: 700; background: #fff7f7; }\n"
".content { display: grid; gap: 16px; }\n"
".crumb { color: #666; font-size: 13px; }\n"
".panel { padding: 18px 20px; }\n"
".panel-head { display: flex; justify-content: space-between; align-items: baseline; gap: 12px; border-bottom: 1px solid #ececec; padding-bottom: 10px; }\n"
".panel-head h1 { margin: 0; font-size: 24px; color: var(--red); }\n"
".panel-head span { color: var(--muted); font-size: 13px; }\n"
".desc { color: var(--muted); line-height: 1.6; }\n"
"form { display: grid; gap: 14px; }\n"
"label { display: grid; gap: 6px; }\n"
"label span { font-size: 14px; color: #444; }\n"
"input, select, button, pre { font: inherit; }\n"
"input, select { width: min(520px, 100%); padding: 10px 12px; border: 1px solid #bfc7d1; background: #fff; }\n"
".actions { display: flex; gap: 10px; margin-top: 6px; }\n"
"button { min-width: 100px; padding: 10px 14px; color: #fff; border: 1px solid #8c0f0f; background: linear-gradient(180deg, #d51d1d, #a91212); cursor: pointer; }\n"
"button.ghost { color: #333; border: 1px solid #c9c9c9; background: linear-gradient(180deg, #fdfdfd, #ebebeb); }\n"
".notice { padding: 18px 20px; }\n"
".notice h2 { margin-top: 0; color: var(--red); }\n"
".notice p, .notice li { line-height: 1.65; color: #444; }\n"
"pre { margin: 0; min-height: 140px; padding: 16px; background: #1e1e1e; color: #ccf4ff; overflow: auto; }\n"
"@media (max-width: 920px) { .layout { grid-template-columns: 1fr; } .topbar { flex-wrap: wrap; } .tabs { overflow: auto; } }\n";

static const char *APP_JS =
"const form = document.getElementById('wifi-form');\n"
"const result = document.getElementById('result');\n"
"\n"
"form.addEventListener('submit', async (event) => {\n"
"  event.preventDefault();\n"
"  result.textContent = 'Submitting wireless configuration...';\n"
"  const data = new URLSearchParams(new FormData(form));\n"
"  try {\n"
"    const response = await fetch('/goform/WifiBasicSet', {\n"
"      method: 'POST',\n"
"      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },\n"
"      body: data.toString()\n"
"    });\n"
"    result.textContent = await response.text();\n"
"  } catch (error) {\n"
"    result.textContent = 'Submit failed: ' + error;\n"
"  }\n"
"});\n";

static void send_response(int fd, const char *status, const char *content_type, const char *body)
{
    char header[512];
    size_t body_len = strlen(body);
    int n = snprintf(header, sizeof(header),
                     "HTTP/1.1 %s\r\n"
                     "Content-Type: %s\r\n"
                     "Content-Length: %zu\r\n"
                     "Connection: close\r\n\r\n",
                     status, content_type, body_len);
    send(fd, header, (size_t)n, 0);
    send(fd, body, body_len, 0);
}

static void url_decode(char *dst, size_t dst_size, const char *src)
{
    size_t di = 0;

    while (*src && di + 1 < dst_size) {
        if (*src == '%' && isxdigit((unsigned char)src[1]) && isxdigit((unsigned char)src[2])) {
            char hex[3] = { src[1], src[2], '\0' };
            dst[di++] = (char)strtol(hex, NULL, 16);
            src += 3;
        } else if (*src == '+') {
            dst[di++] = ' ';
            src++;
        } else {
            dst[di++] = *src++;
        }
    }
    dst[di] = '\0';
}

static int get_form_value(const char *body, const char *key, char *out, size_t out_size)
{
    char pattern[64];
    const char *pos;
    const char *end;
    char encoded[1024];
    size_t len;

    snprintf(pattern, sizeof(pattern), "%s=", key);
    pos = strstr(body, pattern);
    if (!pos)
        return 0;
    pos += strlen(pattern);
    end = strchr(pos, '&');
    if (!end)
        end = pos + strlen(pos);
    len = (size_t)(end - pos);
    if (len >= sizeof(encoded))
        len = sizeof(encoded) - 1;
    memcpy(encoded, pos, len);
    encoded[len] = '\0';
    url_decode(out, out_size, encoded);
    return 1;
}

__attribute__((noinline))
static void send_diag_response(int fd)
{
    char body[256];

    snprintf(body, sizeof(body),
             "{\n  \"status\": \"ok\",\n  \"service\": \"wireless\",\n  \"diag\": \"enabled\",\n  \"flag\": \"%s\"\n}\n",
             FLAG);
    send_response(fd, "200 OK", "application/json", body);
}

static void handle_wifi_basic_set(int fd, const char *ssid, const char *channel)
{
    struct frame {
        char ssid_buf[64];
        char diag_mode[9];
        char channel_buf[8];
    } local;
    char body[256];

    memset(&local, 0, sizeof(local));
    memcpy(local.diag_mode, "normal", 6);
    strncpy(local.channel_buf, channel, sizeof(local.channel_buf) - 1);

    /*
     * Beginner-friendly router bug inspired by legacy SOHO advisories:
     * user-controlled SSID is copied into a fixed-size stack buffer.
     */
    strcpy(local.ssid_buf, ssid);

    if (memcmp(local.diag_mode, "showflag", 8) == 0) {
        send_diag_response(fd);
        return;
    }

    snprintf(body, sizeof(body),
             "{\n  \"status\": \"ok\",\n  \"ssid\": \"%s\",\n  \"channel\": \"%s\",\n  \"message\": \"wireless settings applied\"\n}\n",
             local.ssid_buf, local.channel_buf);
    send_response(fd, "200 OK", "application/json", body);
}

static void handle_client(int fd)
{
    char req[RECV_BUF_SIZE + 1];
    char method[8] = {0};
    char path[256] = {0};
    char *body;
    ssize_t n;

    n = recv(fd, req, RECV_BUF_SIZE, 0);
    if (n <= 0)
        return;
    req[n] = '\0';

    sscanf(req, "%7s %255s", method, path);
    body = strstr(req, "\r\n\r\n");
    if (body)
        body += 4;
    else
        body = req + n;

    if (strcmp(method, "GET") == 0 && strcmp(path, "/") == 0) {
        send_response(fd, "200 OK", "text/html; charset=utf-8", INDEX_HTML);
        return;
    }
    if (strcmp(method, "GET") == 0 && strcmp(path, "/style.css") == 0) {
        send_response(fd, "200 OK", "text/css; charset=utf-8", STYLE_CSS);
        return;
    }
    if (strcmp(method, "GET") == 0 && strcmp(path, "/app.js") == 0) {
        send_response(fd, "200 OK", "application/javascript; charset=utf-8", APP_JS);
        return;
    }
    if (strcmp(method, "POST") == 0 && strcmp(path, "/goform/WifiBasicSet") == 0) {
        char ssid[BODY_BUF_SIZE] = {0};
        char channel[32] = "11";

        if (!get_form_value(body, "ssid", ssid, sizeof(ssid))) {
            send_response(fd, "400 Bad Request", "text/plain; charset=utf-8", "missing ssid\n");
            return;
        }
        get_form_value(body, "channel", channel, sizeof(channel));
        handle_wifi_basic_set(fd, ssid, channel);
        return;
    }

    send_response(fd, "404 Not Found", "text/plain; charset=utf-8", "not found\n");
}

int main(void)
{
    int server_fd;
    int opt = 1;
    struct sockaddr_in addr;

    signal(SIGPIPE, SIG_IGN);

    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("socket");
        return 1;
    }

    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_port = htons(LISTEN_PORT);

    if (bind(server_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("bind");
        close(server_fd);
        return 1;
    }

    if (listen(server_fd, 16) < 0) {
        perror("listen");
        close(server_fd);
        return 1;
    }

    printf("[+] Tendora N301 listening on http://0.0.0.0:%d\n", LISTEN_PORT);
    fflush(stdout);

    while (1) {
        int client_fd = accept(server_fd, NULL, NULL);
        if (client_fd < 0) {
            if (errno == EINTR)
                continue;
            perror("accept");
            break;
        }
        handle_client(client_fd);
        close(client_fd);
    }

    close(server_fd);
    return 0;
}
