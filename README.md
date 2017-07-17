# lua-lzmq-zmq
[![Licence](http://img.shields.io/badge/Licence-MIT-brightgreen.svg)](LICENSE)
[![Build Status](https://travis-ci.org/moteus/lua-lzmq-zmq.svg?branch=master)](https://travis-ci.org/moteus/lua-lzmq-zmq)
[![Coverage Status](https://coveralls.io/repos/github/moteus/lua-lzmq-zmq/badge.svg)](https://coveralls.io/github/moteus/lua-lzmq-zmq)

Wrapper around [lzmq](https://github.com/zeromq/lzmq) library to be compatiable with [lua-zmq](https://github.com/Neopallium/lua-zmq) library

 * [x] Context
 * [x] Socket
 * [x] Message
 * [x] Poller
 * [x] Tests

### General notes
* Object can be either userdata or table. I do not consider underlying type like part of public API.
* I do not consider error message format as part of lua-zmq API so this library provide its own variant.
* Convert to string of object now is not compatiable (except for `zmq.zmq_msg_t` class)
* libzmq has changed since 2.x version and some functionlity not avaliable (e.g. `ZMQ_HWM` or `ZMQ_SWAP` options).
This library do not provide any emulation for such cases.
* `lua-zmq` in some cases returns second `nil` value (e.g. `zmq.zmq_msg_t.init()` returns new message and `nil`
as second value, `socket:setopt()` returns `true` and `nil` as second value). `lzmq-zmq` returns only one value.

### Context
* `lua-zmq` do not close sockets when terminate context but just hang-up forever when try do it and there exists
alive sockets. `lzmq-zmq` closes all opend sockets before terminate context.

### Socket
* `lzmq-zmq` provides set function with and without `set_` prefix. `lua-zmq` exports function only with one name.
E.g. `skt:set_linger` but no `skt:linger` and `skt:subscribe` but no `skt:set_subscribe`.

* Socket object has one additional method `skt:socket()` which returns `lzmq.socket` object.
This function need to uset with original `lzmq.poller` calss and is not part of original `lua-zmq` API

### Message
* `lzmq-zmq` keep data on resize message. if you have message `hello world` and then you call 
`msg:set_size(5)` then message will contain `hello`, but `lua-zmq` does not save such data and it 
will contain garabage but because of memory allocator it may have correct result.

### Poller
Thie library uses lzmq.poller class directly
