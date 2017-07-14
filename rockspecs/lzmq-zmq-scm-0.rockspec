package = "lzmq-zmq"
version = "scm-0"
source = {
  url = "https://github.com/moteus/lua-lzmq-zmq/archive/master.zip",
  dir = "lua-lzmq-zmq-master",
}

description = {
  summary = "Wrapper around lzmq library to be compatiable with lua-zmq library",
  homepage = "lua-lzmq-zmq",
  detailed = [[]],
  license  = "MIT/X11",
}

dependencies = {
  "lua >= 5.1, < 5.4",
  -- "lzmq" or "lzmq-ffi",
}

build = {
  type = "builtin",
  copy_directories = {},

  modules = {
    ["zmq" ]        = "src/zmq.lua",
    ["zmq.poller" ] = "src/zmq/poller.lua",
  }
}
