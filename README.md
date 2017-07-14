# lua-lzmq-zmq
Wrapper around [lzmq](https://github.com/zeromq/lzmq) library to be compatiable with [lua-zmq](https://github.com/Neopallium/lua-zmq) library

 * [x] Context
 * [x] Socket
 * [x] Message
 * [x] Poller
 * [ ] Tests

### General notes
* Object can be either userdata or table. I do not consider underlying type like part of public API.
* I do not consider error message format as part of lua-zmq API so this library provide its own variant.
* Convert to string of object now is not compatiable (except for `zmq.zmq_msg_t` class)
* libzmq has changed since 2.x version and some functionlity not avaliable (e.g. `ZMQ_HWM` or `ZMQ_SWAP` options).
This library do not provide any emulation for such cases.

### Socket
* Library provide set/get function for all option even it read or write only.
If option can not be set/get then function returns EINVAL error.

* Socket object has one additional method `skt:socket()` which returns `lzmq.socket` object.
This function need to uset with original `lzmq.poller` calss and is not part of original `lua-zmq` API

### Message
Thie library uses lzmq.message class directly
* **TODO** `msg:data()` returns string data but not lightuserdata like in `lua-zmq`.

### Poller
Thie library uses lzmq.poller class directly
