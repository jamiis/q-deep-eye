# process master IP addresses
f = open('master_ip_address.txt', 'r')
master_ip_data = f.readline().split('-')
master_ip_address = []

for ip_datum in master_ip_data[1:]:
  master_ip_address.append(int(ip_datum))
formatted_master_ip = format_ip_address(master_ip_address)
print formatted_master_ip
f.close()

# process slaves IP addresses
f = open('slaves_ip_addresses.txt', 'r')
lines = f.readlines()[3:]
slaves_ip_addresses = []

for line in lines:
  slave_ip_address = []
  line = line.split(' ')[0].split('-')
  for ip_datum in line[1:]:
    slave_ip_address.append(int(ip_datum))
  formatted_slave_ip = format_ip_address(slave_ip_address)
  slaves_ip_addresses.append(formatted_slave_ip)
print slaves_ip_addresses
f.close()

def format_ip_address(ip_address):
  return ".".join(ip_address)
    
