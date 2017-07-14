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

print("------------------------------------")
print("Module    name: " .. library_name);
print("Module version: " .. library_version);
print("Lua    version: " .. (_G.jit and _G.jit.version or _G._VERSION))
print("cURL   version: " .. table.concat(zmq_ver, '.'))
print("------------------------------------")
print("")

local pcall, error, type, table, tostring, print, debug = pcall, error, type, table, tostring, print, debug
local RUN = utils.RUN
local IT, CMD, PASS, SKIP_CASE = utils.IT, utils.CMD, utils.PASS, utils.SKIP_CASE
local nreturn, is_equal = utils.nreturn, utils.is_equal

-- lua-zmq do not provide context option constants
local ZMQ_IO_THREADS = zmq.IO_THREADS or 1

local ENABLE = true

local _ENV = TEST_CASE'zmq.context' if ENABLE then

local it = IT(_ENV or _M)

local err, ctx, skt

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
  assert_userdata(msg:data())
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


RUN()

--[[local msg = zmq.zmq_msg_t.init()
assert(msg:size() == 0)]]