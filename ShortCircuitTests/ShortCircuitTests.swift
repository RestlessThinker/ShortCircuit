//
//  ShortCircuitTests.swift
//  ShortCircuitTests
//
//  Created by Louie Penaflor on 10/28/15.
//
//

import XCTest
@testable import ShortCircuit

class ShortCircuitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey("ShortCircuittestServicefailures")
        userDefaults.removeObjectForKey("fooService")
        userDefaults.synchronize()
    }
    
    func testDummyAdapter() {
        let dummy = DummyAdapter()
        dummy.saveStatus("testService", attributeName: "getUser", statusValue: 1, flush: true)
        XCTAssertTrue(dummy.loadStatus("testService", attributeName: "getUser") == 1, "should be true")
        
        dummy.saveStatus("testService", attributeName: "getUser", statusValue: 2, flush: true)
        XCTAssertTrue(dummy.loadStatus("testService", attributeName: "getUser") == 2, "should have changed to hot")
    }
    
    func testNSUserDefaultsAdapter() {
        let adapter = NSUserDefaultsAdapter()
        adapter.saveStatus("fooService", attributeName: "getAccount", statusValue: 3, flush: true)
        XCTAssertTrue(adapter.loadStatus("fooService", attributeName: "getAccount") == 3, "should be equal")
        
        adapter.saveStatus("fooService", attributeName: "getAccount", statusValue: 4, flush: true)
        XCTAssertTrue(adapter.loadStatus("fooService", attributeName: "getAccount") == 4, "should have changed to square")
    }
    
    func testCircuitFactory() {
        let shortCircuit = ShortCircuitFactory.getNSUserDefaultsInstance()
        XCTAssertNotNil(shortCircuit)
    }

    func testCloseCircuit() {
        let number5 = ShortCircuitFactory.getNSUserDefaultsInstance()
        number5.reportSuccess("testService")
        XCTAssertTrue(number5.isAlive("testService"))
        
        // fail 20 times to trip the circuit
        var i = 0
        while (i < 25) {
            number5.malfunction("testService")
            i = i + 1;
        }
        
        XCTAssertFalse(number5.isAlive("testService"), "should be false as circuit should be open")
        
        number5.reportSuccess("testService")
        XCTAssertTrue(number5.isAlive("testService"))
    }
    
    func testTimeout() {
        
        let number5 = ShortCircuitFactory.getNSUserDefaultsInstance(5, retryTimeout: 5)
        
        // fail 20 times to trip the circuit
        var i = 0
        while (i < 10) {
            number5.malfunction("testService")
            i = i + 1;
        }
        
        XCTAssertFalse(number5.isAlive("testService"), "should be false as circuit should be open")
        
        sleep(10);
        
        XCTAssertTrue(number5.isAlive("testService"), "should be true allowing one thread to retry")
    }
}
