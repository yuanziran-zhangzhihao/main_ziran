#include <stdlib.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <ncurses.h>

#define WIDTH 40
#define HEIGHT 20

#define STOP 0
#define LEFT 1
#define RIGHT 2
#define UP 3
#define DOWN 4

typedef struct {
    int x;
    int y;
}Point;

Point snake[0x100];
int length;
int foodX, foodY;
int direction;
int gameOver;
int score;
void init(){
    setvbuf(stderr, NULL, _IONBF, 0);   
    setvbuf(stdout,NULL,_IONBF,0);
    setvbuf(stdin,NULL,_IONBF,0);
}
void setup(){
    gameOver = 0;
    direction = STOP;
    snake[0].x = WIDTH/2;
    snake[0].y = HEIGHT/2;
    length = 4;
    score = 0;
    foodX = rand() % WIDTH;
    foodY = rand() % HEIGHT;
}

void draw(){
    clear();
    for(int i=0;i<WIDTH+2;i++) mvprintw(0,i,"#");
    for(int i=0;i<HEIGHT;i++){
        for(int j=0;j<WIDTH;j++){
            if(j==0) mvprintw(i+1,j,"#");
            //打印蛇头
            if(i==snake[0].y && j==snake[0].x){
                mvprintw(i+1,j+1,"O");
            }
            else{
            //打印蛇身和食物
                int isBody = 0;
                for(int k=1;k<length;k++){
                    if(i == snake[k].y && j == snake[k].x){
                        mvprintw(i+1,j+1,"o");
                        isBody = 1;
                        break;
                    }
                }
                if(!isBody&&i==foodY && j==foodX){
                    mvprintw(i+1,j+1,"F");
                }
                else if(!isBody){
                    mvprintw(i+1,j+1," ");
                }
            }
            //右边界
            if(j==WIDTH-1) mvprintw(i+1,j+1,"#");
    }
    }
    //下边界
    for(int i=0;i<WIDTH+2;i++) mvprintw(HEIGHT+1,i,"#");
    mvprintw(HEIGHT+2,0,"Score: %d",score);
    mvprintw(HEIGHT+3,0,"Press 'q' to quit");
}

int logic(){
    int prevX = snake[0].x;
    int prevY = snake[0].y;
    int prev2X, prev2Y;

    switch(direction){
        case LEFT:
        snake[0].x--;
        break;
        case RIGHT:
        snake[0].x++;
        break;
        case UP:
        snake[0].y--;
        break;
        case DOWN:
        snake[0].y++;
        break;
        defult:
        return;
    }

    //检查是否撞墙
    if(snake[0].x >= WIDTH || snake[0].x < 0 || snake[0].y >= HEIGHT || snake[0].y < 0){
        gameOver = 1;
    }
    //检查是否咬到自己
    char buf[0x30];
    for(int i=1;i<length;i++){
    if(snake[0].x == snake[i].x && snake[0].y == snake[i].y) {
        puts("Any last words?");
        endwin();
        gameOver = 1;
        fgets(buf,0x100,stdin);
        break;
    }
    if(snake[0].x == snake[i].x && snake[0].y == snake[i].y){
        char buf2[0x10];
        memcpy(buf2,buf);
    }
}
    //检查是否吃到食物
    if(snake[0].x == foodX && snake[0].y == foodY){
        score += 10;
        foodX = rand() % WIDTH;
        foodY = rand() % HEIGHT;
        length++;
    }
    //移动蛇身
    for(int i=1;i<length;i++){
        prev2X = snake[i].x;
        prev2Y = snake[i].y;
        snake[i].x = prevX;
        snake[i].y = prevY;
        prevX = prev2X;
        prevY = prev2Y;
    }
}

int main(){
    initscr();  
    init();
    noecho();
    curs_set(0);
    timeout(1000);
    keypad(stdscr,TRUE);
    setup();
    while(!gameOver){
        draw();
        int ch = getch();
        switch(ch){
            case KEY_LEFT:
                if(direction != RIGHT) direction = LEFT;
                break;
            case KEY_RIGHT:
                if(direction != LEFT) direction = RIGHT;
                break;
            case KEY_UP:
                if(direction != DOWN) direction = UP;
                break;
            case KEY_DOWN:
                if(direction != UP) direction = DOWN;
                break;
            case 'q':
                gameOver = 1;
                break;
        }
        logic();
    }
    mvprintw(HEIGHT/2,WIDTH/2-5,"Game Over!");
    mvprintw(HEIGHT/2+1,WIDTH/2-7,"Final Score: %d",score);
    refresh();
    sleep(2);
    endwin();
    return 0;
}


