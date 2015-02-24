import theano.tensor as T
import theano
import numpy

class InterfaceException(Exception):
	"""The execption raised by the interface"""
	def __init__(self, value):
		self.value = value
	def __str__(self):
		return repr(self.value)

class ALEInterface:
	"""Interface for interacting with ALE. Handles Handshaking, receiving messages from and seding 
	messages to ALE. Three members are important:screen, reward, and terminate. They can be accessed 
	through getters and setters. e.g. getreward(). Two most important methods are observe() and 
	act(). Call close() to close the connections. """
	def __init__(self, input_FIFO_name, output_FIFO_name, 
		receive_screen=True, receive_ram=False, receive_rldata=True, useRLE=True):
		"""Constructor. The input FIFO and the output FIFO should be created beforehand.
		input:
		string input_FIFO_name: the path to the FIFO passing messages from ALE to the agent.
		string output_FIFO_name: the path to the FIFO passing messages from the agent to ALE. 
		bool receive_screen: Wheter to receive the screen data from ALE. Default is True.
		bool receive_ram: Whether to receive the RAM data of the game from ALE. Default is False. 
		bool receive_rldata: Wheter to receive the reinforcement learning data from ALE i.e. 
		the reward and whether to terminate. Default is True.
		bool useRLE: Wheter the ALE is encoding the screen data with run length encoding. Default is True."""
		
		#Setting up flags
		self.receive_screen = receive_screen
		self.receive_ram = receive_ram
		self.receive_rldata = receive_rldata
		self.useRLE = useRLE #using run length encoding
		self.has_sent = True #This is used to prevent the deadlock where both the agent and ALE are waiting for the other's message. 

		#Handshaking, receiving the width and height of the screen from ALE. Also tells ALE what information we want to receive. 
		self.width, self.height = self.initpipe(input_FIFO_name, output_FIFO_name)
		#print "width = ", self.width, "height = ", self.height

		#Initializing members. 
		self.__screen = numpy.ndarray((self.height,self.width),dtype=numpy.int)
		self.screen = theano.shared(self.__screen, borrow=True)
		self.RAM = theano.shared(numpy.ndarray((128,),dtype=numpy.int))#Probabily unnecessary since the agent shouldn't read the RAM information
		self.reward = 0
		self.terminate = False #Indicating whether the current game(or episode) has just ended. 

	def initpipe(self, input_FIFO_name, output_FIFO_name):
		"""Establishin connection and handshaking with ALE to exchange essential information. 
		Returns the width and height of the screen. The input FIFO and the output FIFO should 
		be created beforehand. 
		input: 
		string input_FIFO_name: the path to the FIFO passing messages from ALE to the agent.
		string output_FIFO_name: the path to the FIFO passing messages from the agent to ALE. 
		return:
		A tuple of integers. The first element is the width of the screen, and the second is the height
		"""
		#send before receive to avoid deadlock
		self.outfile = open(output_FIFO_name,'w')
		s = '1'if self.receive_screen else '0' 
		r = '1'if self.receive_ram else '0' 
		k = '0'#deprecated
		R = '1'if self.receive_rldata else '0'
		self.outfile.write(str.join(',',[s,r,k,R])+'\n')
		self.outfile.flush()

		#receiving screen information from ALE
		self.infile = open(input_FIFO_name, 'r')
		(width, height) = tuple(self.infile.readline().split('-'))
		width, height = int(width), int(height)

		return width, height

	def setreward(self, value):
		"""input: int value: The value to set the reward."""
		self.reward = value

	def getreward(self):
		"""return: An int. the latest reward received from ALE."""
		return self.reward

	def setterminate(self, value):
		"""input: bool value: The value to set terminate"""
		self.terminate = value

	def getterminate(self):
		"""return: A bool. Whether the coonection should terminate"""
		return self.terminate

	def getscreen(self):
		"""return: A theano.shared whose value is a numpy.ndarray of h-by-w representing the screen.
		Each element is a numpy.int representing the pixel value. """ 
		return self.screen
	def observe(self):
		"""Receive the data sent from ALE and update the latest experience. This method must not be called 
		consecutively without calling an act() in between, otherwise both ALE and the agent will be waiting 
		for each other's message and it will be a deadlock.
		return True if the input FIFO terminated abnormally, else return false. """ 
		if(not self.has_sent):#To avoid the deadlock where both the agent and the ALE are waiting for the other's message
			raise InterfaceException("observe() called twice without calling act()")
		self.has_sent = False

		#receiving message from ALE
		line = self.infile.readline()
		if(line is None):#ALE has termintated abnormally)
			return True
		if(line == 'DIE\n'):#Game Over or maximum frame of this episode is reached
			self.setterminate(True)
			return False

		#parsing the message and updating data members. 
		newdata = line.split(':')
		if(len(newdata) > 0): #skipping empty line
			datagroup = 0
			if(self.receive_ram):
				pass#Not implemented yet, since the agent should not receive the RAM data of the game. 
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
		"""Parse the latest screen data received from ALE and update the screen.
		input: string screen_raw: The screen data received from ALE. """
		if(self.useRLE):# If the screen data is encoded with run length encoding. 
			self.read_screen_RLE(screen_raw)
		else:
			index = 0
			for i in xrange(self.height):
				for j in xrange(self.width):
					pixval = int(screen_raw[index:index+2],16) #Convert from hexadecimal to decimal
					self.__screen[i,j]=pixval
					index+=2

	def read_screen_RLE(self, screen_raw):
		"""Parse the latest screen data received from ALE when it is encoded with run length encoding 
		and update the screen.
		input: string screen_raw: The screen data received from ALE. """
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
		"""read and update the reinforcement learning data i.e. the lates reward and whether the episode has ended. 
		input: string rldata_raw: the reinforcement learning data received from ALE. """
		terminate, reward = tuple(rldata_raw.split(','))
		self.setterminate(terminate == 1) 
		self.setreward(int(reward))

	def act(self, action, p2_action=18):
		"""Send an action to ALE. action is an integer from 0 to 17 which specifies the actionf of player 0.
		0 = noop
		1 = fire
		2 = up
		3 = right
		4 = left
		5 = down
		6 = up+right
		7 = up+left
		8 = down+right
		9 = down+left
		10 = up+fire
		11 = right+fire
		12 = left+fire
		13 = down+fire
		14 = up+right+fire
		15 = up+left+fire
		16 = down+right+fire
		17 = down+left+fire
		Can aslo control player 1's action through p2_action. The values are equal to that of player1 + 18. e.g.
		p2_action=18 means to noop. 
		"""
		if(self.has_sent):#probabily unnecessary to have a gate here?
			raise InterfaceException("act() called twice without calling observe()")
		self.outfile.write(str(action)+','+str(p2_action)+'\n')
		self.outfile.flush()
		self.has_sent=True

	def close(self):
		"""close the interface"""
		self.infile.close()
		self.outfile.close()
