--[[
Copyright (c) 2014 Google Inc.

See LICENSE file for full terms of limited license.
]]

if not dqn then
    require "initenv"
end
require("connections")
local string = require("string")

local cmd = torch.CmdLine()
cmd:text()
cmd:text('Testing Agent in Environment:')
cmd:text()
cmd:text('Options:')

cmd:option('-framework', '', 'name of training framework')
cmd:option('-env', '', 'name of environment to use')
cmd:option('-game_path', '', 'path to environment file (ROM)')
cmd:option('-env_params', '', 'string of environment parameters')
cmd:option('-pool_frms', '',
           'string of frame pooling parameters (e.g.: size=2,type="max")')
cmd:option('-actrep', 1, 'how many times to repeat action')
cmd:option('-random_starts', 0, 'play action 0 between 1 and random_starts ' ..
           'number of times at the start of each training episode')

cmd:option('-name', '', 'filename used for saving network and training history')
cmd:option('-network', '', 'reload pretrained network')
cmd:option('-agent', '', 'name of agent file to use')
cmd:option('-agent_params', '', 'string of agent parameters')
cmd:option('-seed', 1, 'fixed input seed for repeatable experiments')
cmd:option('-saveNetworkParams', false,
           'saves the agent network in a separate file')
cmd:option('-prog_freq', 5*10^3, 'frequency of progress output')
cmd:option('-save_freq', 5*10^4, 'the model is saved every save_freq steps')
cmd:option('-eval_freq', 10^4, 'frequency of greedy evaluation')
cmd:option('-save_versions', 0, '')

cmd:option('-steps', 10^5, 'number of training steps to perform')
cmd:option('-eval_steps', 10^5, 'number of evaluation steps')

cmd:option('-verbose', 2,
           'the higher the level, the more information is printed to screen')
cmd:option('-threads', 1, 'number of BLAS threads')
cmd:option('-gpu', -1, 'gpu flag')
cmd:option('-ip_list', '', 'list of slave ips')
cmd:option('-output_freq', '', 'output frequency')
cmd:option('-port', 2600, 'the port for connection')

cmd:text()

local opt = cmd:parse(arg)

--- General setup.
local game_env, game_actions, agent, opt = setup(opt)
--We don't need the agent here. 
--What we need is connections to the children
local ip_list = {}
local index = 1
for i in string.gmatch(opt.ip_list, "[^,]+") do
    ip_list[index] = i
    index = index+1
end
local slaves = initialize_connections(ip_list, opt.port)
--local slaves = initialize_connections( ... )



-- override print to always flush the output
local old_print = print
local print = function(...)
    old_print(...)
    io.flush()
end

local learn_start = agent.learn_start
local start_time = sys.clock()
local reward_counts = {}
local episode_counts = {}
local time_history = {}
local v_history = {}
local qmax_history = {}
local td_history = {}
local reward_history = {}
local step = 0
time_history[1] = 0

local total_reward = 0
local episode_reward = 0
local nrewards
local nepisodes = 0

local screen, reward, terminal = game_env:getState()
episode_reward = episode_reward+reward

print("Iteration ..", step)
while step < opt.steps do
    step = step + 1
    --local action_index = agent:perceive(reward, screen, terminal)
    -- print("step = ", tostring(step))

    local state = agent:preprocess(screen):float()
    local action_counts = {}
    local collected_actions = {}

    local texttosend = totext(reward, state, terminal)
    for i, v in pairs(slaves) do
        local a = get_action(v, texttosend)
        if a == -1 then
            --slaves[i] = nil
        else
            collected_actions[i] = a
        end
    end
    --collected_actions = collect_actions(slaves, reward, state, terminal)

    for i,a in pairs(collected_actions) do
        --local a  = get_action(v, reward, state, terminal)
        -- print(step, a)
        --local a = 1
        if action_counts[a] then
            action_counts[a] = action_counts[a]+1
        else
            action_counts[a] = 1
        end
    end
    local max_vote, action_index
    max_vote = 0
    for i,v in pairs(action_counts) do
        if v > max_vote then
            max_vote = v
            action_index = i
            --TODO think of a better way to break the tie
        end
    end
    -- print (action_counts)
    -- print("step=", step,"action =",action_index)
    -- game over? get next game!
    if not terminal then
        screen, reward, terminal = game_env:step(game_actions[action_index], true)
        total_reward = total_reward+reward
        episode_reward = episode_reward+reward
    else
        print("Game_over: Final score = ", episode_reward, "nepisodes = ", nepisodes+1)
        total_reward = total_reward+episode_reward
        episode_reward = 0
        nepisodes = nepisodes+1
        if opt.random_starts > 0 then
            screen, reward, terminal = game_env:nextRandomGame()
        else
            screen, reward, terminal = game_env:newGame()
        end
    end

    -- if step % opt.prog_freq == 0 then
    --     assert(step==agent.numSteps, 'trainer step: ' .. step ..
    --             ' & agent.numSteps: ' .. agent.numSteps)
    --     print("Steps: ", step)
    --     agent:report()
    --     collectgarbage()
    -- end

    if step%1000 == 0 then collectgarbage() end

    if step%opt.output_freq ==0 then
        print("iteration ..", step)
        print("action = ", action_index, "reward=", episode_reward, "max_vote=", max_vote)
    end
    -- if step % opt.eval_freq == 0 and step > learn_start then

    --     screen, reward, terminal = game_env:newGame()

    --     total_reward = 0
    --     nrewards = 0
    --     nepisodes = 0
    --     episode_reward = 0

    --     local eval_time = sys.clock()
    --     for estep=1,opt.eval_steps do
    --         local action_index = agent:perceive(reward, screen, terminal, true, 0.05)

    --         -- Play game in test mode (episodes don't end when losing a life)
    --         screen, reward, terminal = game_env:step(game_actions[action_index])

    --         if estep%1000 == 0 then collectgarbage() end

    --         -- record every reward
    --         episode_reward = episode_reward + reward
    --         if reward ~= 0 then
    --            nrewards = nrewards + 1
    --         end

    --         if terminal then
    --             total_reward = total_reward + episode_reward
    --             episode_reward = 0
    --             nepisodes = nepisodes + 1
    --             screen, reward, terminal = game_env:nextRandomGame()
    --         end
    --     end

    --     eval_time = sys.clock() - eval_time
    --     start_time = start_time + eval_time
    --     agent:compute_validation_statistics()
    --     local ind = #reward_history+1
    --     total_reward = total_reward/math.max(1, nepisodes)

    --     if #reward_history == 0 or total_reward > torch.Tensor(reward_history):max() then
    --         agent.best_network = agent.network:clone()
    --     end

    --     if agent.v_avg then
    --         v_history[ind] = agent.v_avg
    --         td_history[ind] = agent.tderr_avg
    --         qmax_history[ind] = agent.q_max
    --     end
    --     print("V", v_history[ind], "TD error", td_history[ind], "Qmax", qmax_history[ind])

    --     reward_history[ind] = total_reward
    --     reward_counts[ind] = nrewards
    --     episode_counts[ind] = nepisodes

    --     time_history[ind+1] = sys.clock() - start_time

    --     local time_dif = time_history[ind+1] - time_history[ind]

    --     local training_rate = opt.actrep*opt.eval_freq/time_dif

    --     print(string.format(
    --         '\nSteps: %d (frames: %d), reward: %.2f, epsilon: %.2f, lr: %G, ' ..
    --         'training time: %ds, training rate: %dfps, testing time: %ds, ' ..
    --         'testing rate: %dfps,  num. ep.: %d,  num. rewards: %d',
    --         step, step*opt.actrep, total_reward, agent.ep, agent.lr, time_dif,
    --         training_rate, eval_time, opt.actrep*opt.eval_steps/eval_time,
    --         nepisodes, nrewards))
    -- end

    -- if step % opt.save_freq == 0 or step == opt.steps then
    --     local s, a, r, s2, term = agent.valid_s, agent.valid_a, agent.valid_r,
    --         agent.valid_s2, agent.valid_term
    --     agent.valid_s, agent.valid_a, agent.valid_r, agent.valid_s2,
    --         agent.valid_term = nil, nil, nil, nil, nil, nil, nil
    --     local w, dw, g, g2, delta, delta2, deltas, tmp = agent.w, agent.dw,
    --         agent.g, agent.g2, agent.delta, agent.delta2, agent.deltas, agent.tmp
    --     agent.w, agent.dw, agent.g, agent.g2, agent.delta, agent.delta2,
    --         agent.deltas, agent.tmp = nil, nil, nil, nil, nil, nil, nil, nil

    --     local filename = opt.name
    --     if opt.save_versions > 0 then
    --         filename = filename .. "_" .. math.floor(step / opt.save_versions)
    --     end
    --     filename = filename
    --     torch.save(filename .. ".t7", {agent = agent,
    --                             model = agent.network,
    --                             best_model = agent.best_network,
    --                             reward_history = reward_history,
    --                             reward_counts = reward_counts,
    --                             episode_counts = episode_counts,
    --                             time_history = time_history,
    --                             v_history = v_history,
    --                             td_history = td_history,
    --                             qmax_history = qmax_history,
    --                             arguments=opt})
    --     if opt.saveNetworkParams then
    --         local nets = {network=w:clone():float()}
    --         torch.save(filename..'.params.t7', nets, 'ascii')
    --     end
    --     agent.valid_s, agent.valid_a, agent.valid_r, agent.valid_s2,
    --         agent.valid_term = s, a, r, s2, term
    --     agent.w, agent.dw, agent.g, agent.g2, agent.delta, agent.delta2,
    --         agent.deltas, agent.tmp = w, dw, g, g2, delta, delta2, deltas, tmp
    --     print('Saved:', filename .. '.t7')
    --     io.flush()
    --     collectgarbage()
    -- end
end


for i,v in ipairs(slaves) do
    v:send('exit\n')
    v:shutdown()
    v:close()    
end
print("=========================")
print("Finished Testing:")
print("Number of episodes = ", nepisodes)
if nepisodes > 0 then
    print("Average Score = ", total_reward/nepisodes)
else
    print("Total Score = ", total_reward)
end
