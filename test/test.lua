pcall(require, "luacov")

local zmq         = require "zmq"
local utils       = require "utils"
local TEST_CASE   = require "lunit".TEST_CASE

local zmq_ver = zmq.version()
local zmq_ver_num = zmq_ver[1] * 10000 + zmq_ver[2] * 100 + zmq_ver[3]
local function IS_ZMQ_GE(min, maj, pat)
  local v = min * 10000 + (maj or 0) * 100 + (pat or 0)
  return zmq_ver_num >= v
end

local library_name, library_version
if zmq._NAME == 'lzmq-zmq' then
  library_name = zmq._NAME
  library_version = zmq._VERSION
else
  library_name = "lua-zmq"
  library_version = "0.0.0"
end

local jit = jit

print("------------------------------------")
print("Module    name: " .. library_name);
print("Module version: " .. library_version);
print("Lua    version: " .. (jit and jit.version or _VERSION))
print("ZeroMQ version: " .. table.concat(zmq_ver, '.'))
print("------------------------------------")
print("")

local pcall, error, type, table, tostring, print, debug = pcall, error, type, table, tostring, print, debug
local RUN = utils.RUN
local IT, CMD, PASS, SKIP_CASE = utils.IT, utils.CMD, utils.PASS, utils.SKIP_CASE
local nreturn, is_equal = utils.nreturn, utils.is_equal

-- lua-zmq do not provide context option constants
local ZMQ_IO_THREADS = zmq.IO_THREADS or 1

local ENABLE = true

local _ENV = TEST_CASE'zmq.module' if ENABLE then

local it = IT(_ENV or _M)

it('should provide public API', function()
  assert_function(zmq.version)
  assert_function(zmq.init)
  assert_function(zmq.sleep)
  assert_function(zmq.device)
  assert_function(zmq.stopwatch_start)
  assert_table(zmq.zmq_msg_t)
  assert_function(zmq.zmq_msg_t.init)
  assert_function(zmq.zmq_msg_t.init_data)
  assert_function(zmq.zmq_msg_t.init_size)
end)

end

local _ENV = TEST_CASE'zmq.context' if ENABLE then

local it = IT(_ENV or _M)

local ctx, skt

function teardown()
  if skt then skt:close() skt = nil end
  if ctx then ctx:term() ctx = nil end
end

it('should create default context', function()
  ctx = assert(zmq.init())
  assert_function(ctx.term)
  assert_function(ctx.socket)
  assert_function(ctx.lightuserdata)
  if IS_ZMQ_GE(3) then
    assert_function(ctx.set)
    assert_function(ctx.get)
  end
end)

if IS_ZMQ_GE(3) then
it('should set default io_threads', function()
  ctx = assert(zmq.init(2))
  assert_equal(2, ctx:get(ZMQ_IO_THREADS))
end)
end

if library_name == 'lzmq-zmq' then
it('should not hang-up while context terminate', function()
  ctx = assert(zmq.init())
  skt = assert(ctx:socket(zmq.PUB))
  assert_true(ctx:term())
end)
end

end

local _ENV = TEST_CASE'zmq.message' if ENABLE then

local it = IT(_ENV or _M)

local msg, src

function setup() end

function teardown()
  if msg then
    msg:close()
    msg = nil
  end
  if src then
    src:close()
    src = nil
  end
end

it('module should provide create API', function()
  assert_table(zmq.zmq_msg_t)
  assert_function(zmq.zmq_msg_t.init)
  assert_function(zmq.zmq_msg_t.init_size)
  assert_function(zmq.zmq_msg_t.init_data)
end)

it('message table have to me callable', function()
  local err
  assert_pass(function()
    msg, err = zmq.zmq_msg_t()
  end)
  assert(msg, err)

  assert_function(msg.copy)
  assert_function(msg.move)
  assert_function(msg.close)
  assert_function(msg.data)
  assert_function(msg.set_size)
  assert_function(msg.set_data)
  assert_function(msg.size)
end)

it('should create empty message', function()
  msg = assert(zmq.zmq_msg_t.init())
  assert_equal(0, msg:size())
  if not jit then
    assert_userdata(msg:data())
  end
  assert_equal('', tostring(msg))
end)

it('should create message with given size', function()
  msg = assert(zmq.zmq_msg_t.init_size(12))
  assert_equal(12, msg:size())
  local str = tostring(msg)
  assert_equal(12, #str)
end)

it('should create message with given data', function()
  msg = assert(zmq.zmq_msg_t.init_data('hello world'))
  assert_equal('hello world', tostring(msg))
end)

it('should reset data with message resize', function()
  msg = assert(zmq.zmq_msg_t.init_data('hello world'))
  assert_equal('hello world', tostring(msg))
  assert_true(msg:set_data('hello, world!!!'))
  assert_equal('hello, world!!!', tostring(msg))
  assert_true(msg:set_data('hello'))
  assert_equal('hello', tostring(msg))
end)

if library_name == 'lzmq-zmq' then
it('should keep data on resize', function()
  msg = assert(zmq.zmq_msg_t.init_data('hello world'))
  assert_equal('hello world', tostring(msg))
  assert_true(msg:set_size(5))
  assert_equal('hello', tostring(msg))
  assert_true(msg:set_size(1024))
  assert_equal('hello', tostring(msg):sub(1, 5))
  assert_equal(1024, #tostring(msg))
end)
end

it('should raise error if copy has no src msg', function()
  msg = assert(zmq.zmq_msg_t.init_data('hello world'))
  assert_error(function() msg:copy() end)
  assert_error(function() msg:copy(nil) end)
end)

it('should copy msg', function()
  src = assert(zmq.zmq_msg_t.init_data('hello world'))
  msg = assert(zmq.zmq_msg_t.init())
  assert_true(msg:copy(src))
  assert_equal('hello world', tostring(src))
  assert_equal('hello world', tostring(msg))
end)

it('should raise error if move has no src msg', function()
  msg = assert(zmq.zmq_msg_t.init_data('hello world'))
  assert_error(function() msg:move() end)
  assert_error(function() msg:move(nil) end)
end)

it('should move msg', function()
  src = assert(zmq.zmq_msg_t.init_data('hello world'))
  msg = assert(zmq.zmq_msg_t.init())
  assert_true(msg:move(src))
  assert_equal('', tostring(src))
  assert_equal('hello world', tostring(msg))
end)

end

local _ENV = TEST_CASE'zmq.socket' if ENABLE then

local it = IT(_ENV or _M)

local ctx, srv, cli

function setup()
  ctx = assert(zmq.init())
end

function teardown()
  if cli then cli:close() cli = nil end
  if srv then srv:close() srv = nil end
  if ctx then ctx:term() ctx = nil end
end

it('should create socket', function()
  srv = assert(ctx:socket(zmq.PUB))
end)

it('should set/get socket option', function()
  srv = assert(ctx:socket(zmq.PUB))
  assert_equal(zmq.PUB, srv:getopt(zmq.TYPE))
  assert_equal(zmq.PUB, srv:type())
  assert_true(srv:setopt(zmq.LINGER, 125))
  assert_equal(125, srv:getopt(zmq.LINGER))
  assert_equal(125, srv:linger())
  assert_true(srv:set_linger(128))
  assert_equal(128, srv:getopt(zmq.LINGER))
  assert_equal(128, srv:linger())
end)

it('should send/recv strings', function()
  srv = assert(ctx:socket(zmq.PUB))
  cli = assert(ctx:socket(zmq.SUB))
  assert_true(srv:bind('inproc://test.zmq'))
  zmq.sleep(1)
  assert_true(cli:connect('inproc://test.zmq'))
  assert_true(cli:subscribe(''))
  local msg = 'hello'
  assert_true(srv:send(msg))
  assert_equal(msg, cli:recv())
end)

it('recv should honor flags', function()
  cli = assert(ctx:socket(zmq.SUB))
  cli:connect('inproc://test.zmq')
  assert_nil(cli:recv(zmq.DONTWAIT))
end)

it('should send/recv multipart messages', function()
  srv = assert(ctx:socket(zmq.PUB))
  cli = assert(ctx:socket(zmq.SUB))
  assert_true(srv:bind('inproc://test.zmq'))
  zmq.sleep(1)
  assert_true(cli:connect('inproc://test.zmq'))
  assert_true(cli:subscribe(''))

  local msg1 = 'hello'
  local msg2 = 'world'
  assert_true(srv:send(msg1, zmq.SNDMORE))
  assert_true(srv:send(msg2))
  assert_equal(msg1, cli:recv())
  assert_equal(1, cli:getopt(zmq.RCVMORE))
  assert_equal(1, cli:rcvmore())
  assert_equal(msg2, cli:recv())
  assert_equal(0, cli:getopt(zmq.RCVMORE))
  assert_equal(0, cli:rcvmore())
end)

it('should send/recv message object', function()
  srv = assert(ctx:socket(zmq.PUB))
  cli = assert(ctx:socket(zmq.SUB))
  assert_true(srv:bind('inproc://test.zmq'))
  zmq.sleep(1)
  assert_true(cli:connect('inproc://test.zmq'))
  assert_true(cli:subscribe(''))
  local msg = zmq.zmq_msg_t.init_data('hello world')
  assert_true(srv:send_msg(msg))
  assert_equal('', tostring(msg))
  assert_true(cli:recv_msg(msg))
  assert_equal('hello world', tostring(msg))
end)

it('recv new message should raise error', function()
  srv = assert(ctx:socket(zmq.PUB))
  cli = assert(ctx:socket(zmq.SUB))
  assert_true(srv:bind('inproc://test.zmq'))
  zmq.sleep(1)
  assert_true(cli:connect('inproc://test.zmq'))
  assert_true(cli:subscribe(''))
  local msg = zmq.zmq_msg_t.init_data('hello world')
  assert_true(srv:send_msg(msg))
  assert_equal('', tostring(msg))
  assert_error(function()cli:recv_msg()end)
end)

end

local _ENV = TEST_CASE'zmq.time' if ENABLE then

local sec, k = 1000000, 0.08

local it = IT(_ENV or _M)

it('stopwatch and sleep should work', function()
  local timer = zmq.stopwatch_start()
  zmq.sleep(1)
  local elapsed = assert_number(timer:stop())
  assert(elapsed > (sec * (1-k)) and elapsed < (sec * (1+k)), elapsed)
end)

it('stop method should raise error if stopwatch timer already stopped', function()
  local timer = zmq.stopwatch_start()
  zmq.sleep(1)
  assert_number(timer:stop())
  assert_error(function() timer:stop() end)
end)

it('restart stopwatch', function()
  local timer = zmq.stopwatch_start()
  zmq.sleep(1)
  assert_number(timer:stop())

  if library_name == 'lzmq-zmq' then
    assert(timer:start())
    zmq.sleep(1)
    local elapsed = assert_number(timer:stop())
    assert(elapsed > (sec * (1-k)) and elapsed < (sec * (1+k)), elapsed)
  end
end)

end

RUN()
