
-- returns the connection to the slave servers
-- inputs: servers   a list of server ips
-- returns: connects a list of connections

function initialize_connections( ... )
	-- body
end

-- A connection looks something like this:
-- local con = {ip="52.5.123.123", ......}


-- inputs: 	connect 	A coonection object
--			reward		The reward
--			state		The preprocessed screen
--			terminal	terminal

-- returns: action 		The action returned by the slave
function get_action(connect, reward, state, terminal)
	-- TODO: body
	return 1
end