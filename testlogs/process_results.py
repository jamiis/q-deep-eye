import sys

def get_average_score(filename):
  number_of_episodes = 0
  total_score = 0
  f = open(filename, 'r')
  lines = f.readlines()
  for line in lines:
    if line[0:5] == 'Game_':
      delimited_line = line.split("\t")
      total_score += int(delimited_line[1])
      number_of_episodes = int(delimited_line[3])
  f.close()
  return total_score / float(number_of_episodes)
    
if __name__ == "__main__":
  game = sys.argv[1]
  steps = sys.argv[2]
  filename = '{}_step{}000000_nn1.out'.format(game,steps)
  average_score = get_average_score(filename)
  print '{} average score is {}'.format(filename, average_score)
