# ShortCircuit
[![Build Status](https://travis-ci.org/RestlessThinker/ShortCircuit.svg?branch=master)](https://travis-ci.org/RestlessThinker/ShortCircuit)

Circuit Breaker Pattern framework written in Swift

![number5img](https://cloud.githubusercontent.com/assets/1472984/13364737/36d1bb3c-dc96-11e5-9f8e-61ee28387b51.jpg)

```swift
let number5 = ShortCircuitFactory.getNSUserDefaultsInstance()

if (number5.isAlive("testService")) {
  // make http request

  // upon success
  // number5.reportSucess("testService")
  // upon failure 
  // number5.reportFailure("testService")
} else {
  // service unavailable, do something else
}
```

```obj-c
id<CircuitBreaker> memoryCircuit = [ShortCircuitFactory getNSUserDefaultsInstance:20 retryTimeout:20];
  NSString *serviceName = @"testService";
  if ([memoryCircuit isAvailable:serviceName]) {
    
    // upon success
    // [memoryCircuit reportSuccess:serviceName];
    // upon failure
    // [memoryCircuit reportfailure:serviceName];
    
  } else {
    // service unavailable, do something else   
  }
}
```

## Swift Server

A server implementation is in the works. Creating a Redis Adapter.

