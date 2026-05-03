import curses
import random
import time

def matrix_rain(stdscr):
    curses.curs_set(0)
    stdscr.nodelay(1)
    stdscr.timeout(50)
    
    height, width = stdscr.getmaxyx()
    columns = [{'y': random.randint(0, height), 'speed': random.randint(1, 3), 'chars': []} for _ in range(width // 2)]
    
    curses.start_color()
    curses.init_pair(1, curses.COLOR_GREEN, curses.COLOR_BLACK)
    stdscr.attron(curses.color_pair(1))
    
    katakana = [chr(code) for code in range(0x30A0, 0x30FF)]
    chars = katakana + [str(i) for i in range(10)] + [chr(i) for i in range(65, 91)]
    
    while True:
        key = stdscr.getch()
        if key != -1:
            break
            
        stdscr.clear()
        for col in columns:
            if random.random() > 0.95:
                col['chars'].append(random.choice(chars))
            if len(col['chars']) > 20:
                col['chars'].pop(0)
            for i, ch in enumerate(col['chars']):
                y_pos = col['y'] - i
                if 0 <= y_pos < height:
                    stdscr.addch(y_pos, columns.index(col) * 2, ch)
            col['y'] += col['speed']
            if col['y'] > height + 20:
                col['y'] = random.randint(-20, 0)
                col['chars'] = []
                col['speed'] = random.randint(1, 3)
        
        stdscr.refresh()
        time.sleep(0.05)

if __name__ == "__main__":
    curses.wrapper(matrix_rain)
