import sys
# prepare 'process_all_instances' script 
f = open('run_saver.txt', 'w')
game = sys.argv[1]
dqn_a = sys.argv[2]
dqn_b = sys.argv[3]

if int(dqn_a) < 10:
  dqn_a = '0{}'.format(dqn_a)

if int(dqn_b) < 10:
  dqn_b = '0{}'.format(dqn_b)

f.write('bash save_files_to_s3.sh {} {} {}'.format(game, dqn_a, dqn_b))
f.write('\nexit')
f.close()
