import control

def action(a = None, b = None):
    if not a: a = control.player_a_noop 
    if not b: b = control.player_b_noop 
    fout.write("%d,%d\n" % (a, b))
    fout.flush()

def main():
    action(control.system_reset)

if __name__ == "__main__":
    fin  = open('ale_fifo_out')
    fout = open('ale_fifo_in', 'w')

    str_in = fin.readline()
    str_in_split = str_in.split('-')
    width = int(str_in_split[0])
    height = int(str_in_split[1])

    print 'w', width, 'h', height

    update_screen_matrix = 1
    update_console_ram = 0
    skip_frames_num = 1

    fout.write("%d,%d,%d\n"%(
        update_screen_matrix, 
        update_console_ram, 
        skip_frames_num))
    fout.flush()

    # enter main loop of game
    main()
