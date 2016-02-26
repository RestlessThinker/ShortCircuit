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
