# ShortCircuit
[![Build Status](https://travis-ci.org/RestlessThinker/ShortCircuit.svg?branch=master)](https://travis-ci.org/RestlessThinker/ShortCircuit)
Circuit Breaker Pattern framework written in Swift

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
