#include "node.h"
#include "node_buffer.h"
#include "node_version.h"
#include "v8.h"

#include <stdint.h>

using namespace v8;


Handle<Value> MaskedCrc(const Arguments& args) {
  HandleScope scope;

  if(args.Length() != 2) {
    ThrowException(Exception::TypeError(String::New("Wrong arguments")));
    return scope.Close(Undefined());
  }

  if(!node::Buffer::HasInstance(args[0])) {
    ThrowException(Exception::TypeError(String::New("First argument isn't buffer")));
    return scope.Close(Undefined());
  }

  if(!node::Buffer::HasInstance(args[1])) {
    ThrowException(Exception::TypeError(String::New("Second argument isn't buffer")));
    return scope.Close(Undefined());
  }

  Local<Object> crc = args[0]->ToObject();
  size_t crc_size   = node::Buffer::Length(crc);
  uint8_t* crc_data = (uint8_t*) node::Buffer::Data(crc);

  Local<Object> result = args[1]->ToObject();
  size_t result_size   = node::Buffer::Length(result);
  uint8_t* result_data = (uint8_t*) node::Buffer::Data(result);

  if(crc_size < 4) {
    ThrowException(Exception::TypeError(String::New("Crc buffer < 4 bytes in length")));
    return scope.Close(Undefined());
  }

  if(result_size < 4) {
    ThrowException(Exception::TypeError(String::New("Result buffer < 4 bytes in length")));
    return scope.Close(Undefined());
  }

  // from array to uint32_t
  uint32_t unmasked = (crc_data[0] << 24) | (crc_data[1] << 16) | (crc_data[2] << 8) | (crc_data[3]);

  // mask the crc
  uint32_t masked = ((unmasked >> 15) | (unmasked << 17)) + 0xa282ead8;

  // to array from uint32_t
  result_data[3] = (masked >> 24) & 0xff;
  result_data[2] = (masked >> 16) & 0xff;
  result_data[1] = (masked >> 8)  & 0xff;
  result_data[0] = (masked >> 0)  & 0xff;

  return scope.Close(Undefined());
}

void init(Handle<Object> exports) {
  exports->Set(String::NewSymbol("nativeMaskedCrc"), FunctionTemplate::New(MaskedCrc)->GetFunction());
}

NODE_MODULE(native, init)
