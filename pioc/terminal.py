import select
import sys

class Terminal():
    def __init__(self):
        self.old_settings = None

    def setRaw(self):
        import termios
        import tty
        self.old_settings = termios.tcgetattr(sys.stdin)
        tty.setcbreak(sys.stdin.fileno())
        #tty.setraw(sys.stdin.fileno())

    def restoreRaw(self):
        import termios
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, self.old_settings)

    def keyReady(self):
        return select.select([sys.stdin], [], [], 0) == ([sys.stdin], [], [])
    
    def keyGet(self):
        return sys.stdin.read(1)
    
if __name__ == "__main__":
    t = Terminal()
    t.setRaw()
    try:
        while True:
            if t.keyReady():
                c = t.keyGet()
                if c == 'q':
                    break
                print("got key: %s" % c)
    finally:
        t.restoreRaw()
