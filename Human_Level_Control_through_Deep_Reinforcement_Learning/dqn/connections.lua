local socket = require("socket")
local string = require("string")
local torch = require("torch")
local lanes = require("lanes").configure()

-- returns the connection to the slave servers
-- inputs: IP_list   a list of server ips
-- returns: connects a list of connections

function initialize_connections(IP_list, port)
	local connections = {}
	local index = 1
	for i,v in ipairs(IP_list) do
		c = socket.tcp()
        c:settimeout(3)
		success, msg = c:connect(v, port)
		if not success then
			print("Can not connect to slave "..v..":"..msg.."\n")
        else
		    connections[index] = c
            index = index+1
        end
	end
	return connections
end

-- A connection looks something like this:
-- local con = {ip="52.5.123.123", ......}


-- inputs: 	connect 	A coonection object to the slave
--			texttosend	The texttosend

-- returns: action 		The action returned by the slave
function get_action(connect, texttosend)
	connect:send(texttosend.."\n")
	local a, errmsg = connect:receive()
    if errmsg == 'timeout' then
        return -1
    end
	return a+0
end

--inputs:
--			slaves      A list of the connections
--			reward		The reward
--			state		The preprocessed screen
--			terminal	terminal
--returns:	actions  	A list of actions
function collect_actions(slaves, reward, state, terminal)
	text = totext(reward,state, terminal)
	f = lanes.gen(get_action)
	actions = {}
	for i,v in ipairs(slaves) do
		actions[i] = f(v,text)
	end
	return actions
end

function totext(reward, state, terminal)
	local str = tostring(reward).."/"
	for i = 1, state:size(1), 1 do
		str = str..tostring(state[i])..","
	end
	str = str.."/"..tostring(terminal)
	--r/state[1],state[2],/terminal
	return str
end

function parse_rst(str)
	local lines={}
	local index=1
	for i in string.gmatch(str, "[^/]+") do
		lines[index] = i
		index = index+1
	end
	local reward = lines[1]+0
	local terminal = lines[3]=='true'
	local state=torch.Tensor(84*84)
	
	local index=0
	for i in string.gmatch(lines[2], "[^,]+") do
		index = index+1
		state[index] = i +0
	end
	return reward, state, terminal
end
