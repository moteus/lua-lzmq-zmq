local lzmq = require"lzmq"

local zmq = {
  _NAME      = 'lzmq-zmq';
  _VERSION   = '0.1.0-dev';
  _LICENSE   = "MIT";
  _COPYRIGHT = "Copyright (c) 2017 Alexey Melnichuk";
}

local socket_options = {
  'AFFINITY',
  'IDENTITY',
  'SUBSCRIBE',
  'UNSUBSCRIBE',
  'RATE',
  'RECOVERY_IVL',
  'SNDBUF',
  'RCVBUF',
  'RCVMORE',
  'FD',
  'EVENTS',
  'TYPE',
  'LINGER',
  'RECONNECT_IVL',
  'BACKLOG',
  'RECONNECT_IVL_MAX',
  'MAXMSGSIZE',
  'SNDHWM',
  'RCVHWM',
  'MULTICAST_HOPS',
  'RCVTIMEO',
  'SNDTIMEO',
  'LAST_ENDPOINT',
  'ROUTER_MANDATORY',
  'TCP_KEEPALIVE',
  'TCP_KEEPALIVE_CNT',
  'TCP_KEEPALIVE_IDLE',
  'TCP_KEEPALIVE_INTVL',
  'IMMEDIATE',
  'XPUB_VERBOSE',
  'ROUTER_RAW',
  'IPV6',
  'MECHANISM',
  'PLAIN_SERVER',
  'PLAIN_USERNAME',
  'PLAIN_PASSWORD',
  'CURVE_SERVER',
  'CURVE_PUBLICKEY',
  'CURVE_SECRETKEY',
  'CURVE_SERVERKEY',
  'PROBE_ROUTER',
  'REQ_CORRELATE',
  'REQ_RELAXED',
  'CONFLATE',
  'ZAP_DOMAIN',
  'ROUTER_HANDOVER',
  'TOS',
  'CONNECT_RID',
  'GSSAPI_SERVER',
  'GSSAPI_PRINCIPAL',
  'GSSAPI_SERVICE_PRINCIPAL',
  'GSSAPI_PLAINTEXT',
  'HANDSHAKE_IVL',
  'SOCKS_PROXY',
  'XPUB_NODROP',
  'BLOCKY',
  'XPUB_MANUAL',
  'XPUB_WELCOME_MSG',
  'STREAM_NOTIFY',
  'INVERT_MATCHING',
  'HEARTBEAT_IVL',
  'HEARTBEAT_TTL',
  'HEARTBEAT_TIMEOUT',
  'XPUB_VERBOSER',
  'CONNECT_TIMEOUT',
  'TCP_MAXRT',
  'THREAD_SAFE',
  'MULTICAST_MAXTPDU',
  'VMCI_BUFFER_SIZE',
  'VMCI_BUFFER_MIN_SIZE',
  'VMCI_BUFFER_MAX_SIZE',
  'VMCI_CONNECT_TIMEOUT',
  'USE_FD',
}

local socket_options_map = {}

for _, name in ipairs(socket_options) do
  local id = lzmq[name]
  if id then
    socket_options_map[id] = name
  end
end

local function export_constants(src, dst)
  dst = dst or {}
  for k, v in pairs(src) do
    if type(v) == 'number' then
      dst[k] = v
    end
  end
  return dst
end

export_constants(lzmq, zmq)
zmq.ZErrors = export_constants(lzmq.errors)

zmq.IO_THREADS = 1
zmq.MAX_SOCKETS = 2
zmq.SOCKET_LIMIT = 3
zmq.THREAD_PRIORITY = 3
zmq.THREAD_SCHED_POLICY = 4
zmq.MAX_MSGSZ = 5

function zmq.version()
  return lzmq.version()
end

local function zmq_error(err)
  return tostring(err)
end

local EINVAL = zmq_error(lzmq.error(lzmq.errors.EINVAL))

local ZMQ_Context, ZMQ_Socket, ZMQ_Poller, ZMQ_Message

ZMQ_Context = {} do
ZMQ_Context.__index = ZMQ_Context

function zmq.init(threads)
  local ctx, err = lzmq.context{
    io_threads = threads or 1
  }
  if not ctx then return nil, zmq_error(err) end

  return setmetatable({
    _ctx = ctx
  }, ZMQ_Context)
end

function zmq.init_ctx(lightuserdata)
  local ctx, err = lzmq.init_ctx(lightuserdata)
  if not ctx then return nil, zmq_error(err) end

  -- turn on autoclose sockets
  -- ctx:autoclose(true)

  return setmetatable({
    _ctx = ctx
  }, ZMQ_Context)
end

function ZMQ_Context:term()
  if self._ctx then 
    self._ctx:destroy()
    self._ctx = nil
  end
  return true
end

function ZMQ_Context:socket(typ)
  local skt, err = self._ctx:socket(typ)
  if not skt then return nil, zmq_error(err) end

  return setmetatable({
    _skt = skt
  }, ZMQ_Socket)
end

function ZMQ_Context:lightuserdata()
  return self._ctx:lightuserdata()
end

function ZMQ_Context:get(key)
  return self._ctx:get(key)
end

function ZMQ_Context:set(key, value)
  return self._ctx:set(key, value)
end

function ZMQ_Context:__tostring()
  return ("ZMQ_Context: %s"):format(tostring(self._ctx))
end

end

ZMQ_Socket = {} do

local function build_wrapper(name, fn)
  local wrapper = function(self, ...)
    local ok, err = fn(self._skt, ...)
    if not ok then return nil, zmq_error(err) end
    return ok
  end
  ZMQ_Socket[name] = wrapper
  return wrapper
end

ZMQ_Socket.__index = function(self, k)
  local v = ZMQ_Socket[k]
  if v ~= nil then return v end

  if not self._skt then return end

  -- we need export only options setter/getter functions
  local opt = string.match(k, '^set_(.+)$') or k
  if type(lzmq[ string.upper(opt)]) == 'number' then
    local fn = self._skt[k] or self._skt['get_' .. k]
    if fn then return build_wrapper(k, fn) end
  end
end

local setopt_map, getopt_map = {}, {}

function ZMQ_Socket:__tostring()
  return ("ZMQ_Socket: %s"):format(tostring(self._skt))
end

function ZMQ_Socket:close()
  if self._skt then
    local ok, err = self._skt:close()
    if not ok then return nil, zmq_error(err) end
    self._skt = nil
  end
  return true
end

function ZMQ_Socket:bind(host)
  local ok, err = self._skt:bind(host)
  if not ok then return nil, zmq_error(err) end
  return true
end

function ZMQ_Socket:unbind(host)
  local ok, err = self._skt:unbind(host)
  if not ok then return nil, zmq_error(err) end
  return true
end

function ZMQ_Socket:connect(host)
  local ok, err = self._skt:connect(host)
  if not ok then return nil, zmq_error(err) end
  return true
end

function ZMQ_Socket:disconnect(host)
  local ok, err = self._skt:connect(host)
  if not ok then return nil, zmq_error(err) end
  return true
end

function ZMQ_Socket:setopt(opt, val)
  local fn = setopt_map[opt]
  if fn == nil then
    local name = socket_options_map[opt]
    if not name then
      fn, setopt_map[opt] = false, false
    else
      name = 'set_' .. string.lower(name)
      fn = self._skt[name]
      if not name then
        fn, setopt_map[opt] = false, false
      else
        setopt_map[opt] = fn
      end
    end
  end
  if not fn then return nil, EINVAL end

  local ok, err = fn(self._skt, val)
  if not ok then return nil, zmq_error(err) end

  return true
end

function ZMQ_Socket:getopt(opt)
  local fn = getopt_map[opt]
  if fn == nil then
    local name = socket_options_map[opt]
    if not name then
      fn, getopt_map[opt] = false, false
    else
      name = 'get_' .. string.lower(name)
      fn = self._skt[name]
      if not name then
        fn, getopt_map[opt] = false, false
      else
        getopt_map[opt] = fn
      end
    end
  end
  if not fn then return nil, EINVAL end

  local ok, err = fn(self._skt, val)
  if ok == nil then return nil, zmq_error(err) end

  return ok
end

function ZMQ_Socket:send(msg, flags)
  local ok, err = self._skt:send(msg, flags)
  if not ok then return nil, zmq_error(err) end
  return true
end

function ZMQ_Socket:send_msg(msg, flags)
  local ok, err = self._skt:send_msg(msg._msg, flags)
  if not ok then return nil, zmq_error(err) end
  return true
end

function ZMQ_Socket:recv(flags)
  local msg, err = self._skt:recv(flags)
  if not msg then return nil, zmq_error(err) end
  return msg
end

function ZMQ_Socket:recv_msg(msg, ...)
  local ok, err = self._skt:recv_msg(msg._msg, ...)
  if not ok then return nil, zmq_error(err) end
  return msg
end

-- This is not part of lua-zmq API, but it allows use lzmq.poller without
-- needing write wrapper around it.
function ZMQ_Socket:socket()
  return self._skt
end

end

ZMQ_Message = {} do
ZMQ_Message.__index = ZMQ_Message

local function ZMQ_Message_new(msg)
  return setmetatable({
    _msg = msg
  }, ZMQ_Message)
end

zmq.zmq_msg_t = {} do

function zmq.zmq_msg_t.init()
  local msg, err = lzmq.msg_init()
  if not msg then return nil, zmq_error(err) end
  return ZMQ_Message_new(msg)
end

function zmq.zmq_msg_t.init_size(size)
  local msg, err = lzmq.msg_init_size(size)
  if not msg then return nil, zmq_error(err) end
  return ZMQ_Message_new(msg)
end

function zmq.zmq_msg_t.init_data(data)
  local msg, err = lzmq.msg_init_data(data)
  if not msg then return nil, zmq_error(err) end
  return ZMQ_Message_new(msg)
end

end

function ZMQ_Message:copy(src)
  local ok, err = self._msg:copy(src._msg)
  if not ok then return nil, zmq_error(err) end
  return true
end

function ZMQ_Message:move(src)
  local ok, err = self._msg:move(src._msg)
  if not ok then return nil, zmq_error(err) end
  return true
end

function ZMQ_Message:close()
  if self._msg then
    self._msg:close()
    self._msg = nil
  end
  return true
end

function ZMQ_Message:data()
  local res, err = self._msg:pointer()
  if not res then return nil, zmq_error(err) end
  return res
end

function ZMQ_Message:set_size(size)
  local ok, err = self._msg:set_size(size)
  if not ok then return nil, zmq_error(err) end
  return true
end

function ZMQ_Message:set_data(data)
  local ok, err = self._msg:set_size(#data)
  if not ok then return nil, zmq_error(err) end
  self._msg:set_data(data)
  return true
end

function ZMQ_Message:size()
  local res, err = self._msg:size()
  if not res then return nil, zmq_error(err) end
  return res
end

function ZMQ_Message:__tostring()
  return self._msg:data()
end

end

zmq.sleep = lzmq.utils.sleep

zmq.stopwatch_start = function()
  return lzmq.utils.stopwatch():start()
end

zmq.device = lzmq.device

setmetatable(zmq.zmq_msg_t,{__call = function(self, ...)
  return self.init(...)
end})

return zmq