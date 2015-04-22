require 'string'

function create_log(agent, env, opt)
	local logger = {}
	datetime = os.date("*t", os.time())
	logger.filename = opt.log_folder..opt.env
						..'-'..datetime.year
						..'-'..datetime.month
						..'-'..datetime.day
						..'-'..datetime.hour
						..'-'..datetime.min
						..'-'..datetime.sec..'.log'
	logger.agent = agent
	logger.env = env
	logger.file = io.open(logger.filename, "w")
	function logger:log(step, reward, rawstate, term)
		local state = self.agent:preprocess(rawstate)  
		local repr = self.agent.hasher:forward(state)
		local Nov = self.agent.last_novelty
		local maxQ = self.agent.q_max
		printstring = string.format('%s=%d,%s=%d,%s=%.5f,%s=%.5f,%s=%.4f,%s=', 
			'step',step,
			'reward',reward,
			'novelty',Nov,
			'epsilon', agent.ep,
			'maxQ',maxQ,
			'hashed_screen')
		for i=1,repr:size()[1],1 do
			printstring=printstring..' '..string.format('%5f',repr[i])
		end
		self.file:write(printstring..'\n')
	end
	return logger
end
