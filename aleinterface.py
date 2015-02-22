import theano.tensor as T
import theano
import numpy

class InterfaceException(Exception):
	def __init__(self, value):
		self.value = value
	def __str__(self):
		return repr(self.value)

class ALEInterface:
	"""Interface for interacting with ALE"""
	def __init__(self, input_FIFO_name, output__FIFO__name, 
		receive_screen=True, receive_ram=False, receive_rldata=True, useRLE=True):
		
		self.receive_screen = receive_screen
		self.receive_ram = receive_ram
		self.receive_rldata = receive_rldata
		self.useRLE = useRLE #using run length encoding
		self.has_sent = True

		self.width, self.height = self.initpipe(input_FIFO_name, output__FIFO__name)
		print "width = ", self.width, "height = ", self.height

		self.__screen = numpy.ndarray((self.height,self.width),dtype=numpy.int)
		self.screen = theano.shared(self.__screen, borrow=True)
		self.RAM = theano.shared(numpy.ndarray((128,),dtype=numpy.int))#Probabily unnecessary since the agent shouldn't read the RAM information
		self.reward = 0
		self.terminate = False

	def initpipe(self, input_FIFO_name, output__FIFO__name):
		"""Handshaking with ALE to exchange essential information"""
		#send before receive to avoid deadlock
		self.outfile = open(output__FIFO__name,'w')
		s = '1'if self.receive_screen else '0'
		r = '1'if self.receive_ram else '0'
		k = '0'#deprecated
		R = '1'if self.receive_rldata else '0'
		self.outfile.write(str.join(',',[s,r,k,R])+'\n')
		self.outfile.flush()

		self.infile = open(input_FIFO_name, 'r')
		(width, height) = tuple(self.infile.readline().split('-'))
		width, height = int(width), int(height)

		return width, height

	def setreward(self, value):
		self.reward = value

	def getreward(self):
		return self.reward

	def setterminate(self, value):
		self.terminate = value

	def getterminate(self):
		return self.terminate

	def getscreen(self):
		return self.screen
	def observe(self):
		"""Receive the data sent from ALE and update the latest experience.
		return True if the input FIFO terminated abnormally, else return false""" 
		if(not self.has_sent):#To avoid the deadlock where both the agent and the ALE are waiting for the other's message
			raise InterfaceException("observe() called twice without calling act()")
		self.has_sent = False

		line = self.infile.readline()
		if(line is None):#ALE has termintated abnormally)
			return True
		if(line == 'DIE\n'):#Game Over or maximum frame of this episode is reached
			self.setterminate(True)
			return False

		newdata = line.split(':')
		if(len(newdata) > 0): #skipping empty line
			datagroup = 0
			if(self.receive_ram):
				pass#unnecessary
				datagroup+=1
			if(self.receive_screen):
				screen_raw = newdata[datagroup]
				self.read_screen(screen_raw)
				datagroup+=1
			if(self.receive_rldata):
				rldata_raw = newdata[datagroup]
				self.read_rldata(rldata_raw)
				datagroup+=1
		return False

	def read_screen(self, screen_raw):
		if(self.useRLE):
			return self.read_screen_RLE(screen_raw)
		else:
			index = 0
			for i in xrange(self.height):
				for j in xrange(self.width):
					pixval = int(screen_raw[index:index+2],16) #Convert from hexadecimal to decimal
					self.__screen[i,j]=pixval
					index+=2

	def read_screen_RLE(self, screen_raw):
		index = 0
		i, j = 0,0
		while(index < len(screen_raw)):
			pixval = int(screen_raw[index:index+2],16) #Convert from hexadecimal to decimal
			runlength = int(screen_raw[index+2:index+4],16)
			for runindex in xrange(runlength):
				self.__screen[i,j] = pixval
				print "pixval=",pixval,"runlength=",runlength,"i=", i, "j=",j
				j +=1 
				if(j >= self.width):
					j=0
					i+=1
			index+=4

	def read_rldata(self, rldata_raw):
		terminate, reward = tuple(rldata_raw.split(','))
		self.setterminate(terminate == 1) 
		self.setreward(int(reward))

	def act(self, action, p2_action=18):
		"""Send an action to ALE. action is an integer from 0 to 17"""
		if(self.has_sent):
			raise InterfaceException("act() called twice without calling observe()")
		self.outfile.write(str(action)+','+str(p2_action)+'\n')
		self.outfile.flush()
		self.has_sent=True

	def close(self):
		self.infile.close()
		self.outfile.close()