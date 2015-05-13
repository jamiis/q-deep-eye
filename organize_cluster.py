import sys

def get_master_ip_address():
  f = open('master_ip_address.txt', 'r')
  master_ip_data = f.readline().split('-')
  f.close()
  master_ip_address = []
  for ip_datum in master_ip_data[1:]:
    master_ip_address.append(ip_datum)
  return format_ip_address(master_ip_address)


def get_slaves_ip_addresses():
  f = open('slaves_ip_addresses.txt', 'r')
  lines = f.readlines()[3:]
  slaves_ip_addresses = []

  for line in lines:
    slave_ip_address = []
    line = line.split(' ')[0].split('-')
    for ip_datum in line[1:]:
      slave_ip_address.append(ip_datum)
    formatted_slave_ip = format_ip_address(slave_ip_address)
    slaves_ip_addresses.append(formatted_slave_ip)
  f.close()

  return slaves_ip_addresses

def format_ip_address(ip_address):
  return ".".join(ip_address)

def launch_slave_jobs(master_ip, slaves_ip, game, steps):
  init_slave_jobs(master_ip, slaves_ip, game, steps)
  for i, slave_ip in enumerate(slaves_ip):
    bash_file = 'launch_slave_{0}.sh'.format(i)
    array_slave_ip = slave_ip.split('.')
    hostname = 'ip-'+"-".join(array_slave_ip)
    qsub_definition = 'qsub -l h={0} init_slave_{1}.sh'.format(hostname, i)
    f = open(bash_file, 'w')
    f.write('#!/bin/bash\n')
    f.write(qsub_definition)
    f.close()

def init_slave_jobs(master_ip, slaves_ip, game, steps):
  for i, slave_ip in enumerate(slaves_ip):
    bash_file = 'init_slave_{0}.sh'.format(i)
    s3_path = 's3://dqn/weights'
    weights_file = '{0}_dqn{1}_step{2}000000.t7'.format(game, i, steps)
    f = open(bash_file, 'w')
    f.write('#!/bin/bash\n')
    f.write('s3cmd get {0}/{1}\n'.format(s3_path, weights_file))
    f.write('./run_slave {0} {1}'.format(weights_file, master_ip))
    f.close()  
    
if __name__ == "__main__":
  game = sys.argv[1]
  steps = sys.argv[2]
  master_ip = get_master_ip_address()
  slaves_ip = get_slaves_ip_addresses()
  launch_slave_jobs(master_ip, slaves_ip, game, steps)
