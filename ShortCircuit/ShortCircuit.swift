//
//  ShortCircuit.swift
//  ShortCircuit
//
//  Created by Louie Penaflor on 10/28/15.
//
//

import Foundation

@objc
protocol CircuitBreakerProtocol {
    func isAvailable (serviceName: String) -> Bool
    func reportFailure (serviceName: String) -> Void
    func reportSuccess (serviceName: String) -> Void
    
    // Number 5
    func isAlive (serviceName: String) -> Bool
    func malfunction (serviceName: String) -> Void
    func reportAlive (serviceName: String) -> Void
}

@objc
protocol CircuitBreakerStorageProtocol {
    func loadStatus(serviceName: String, attributeName: String) -> Int
    func saveStatus(serviceName: String, attributeName: String, statusValue: Int, flush: Bool) -> Void
}

@objc
class ShortCircuitFactory : NSObject {
    
    static func getNSUserDefaultsInstance(maxFailures:Int = 20, retryTimeout:Int = 20) -> CircuitBreakerProtocol {
        let storage = NSUserDefaultsAdapter()
        return ShortCircuit(storage: storage, maxFailures: maxFailures, retryTimeout: retryTimeout)
    }
}

@objc
class ShortCircuit : NSObject, CircuitBreakerProtocol {
    
    var storageAdapter:CircuitBreakerStorageProtocol
    
    var defaultMaxFailures:Int
    
    // how many seconds we should wait before retry
    var defaultRetryTimeout:Int
    
    var settings:[String: [String: Int]]
    
    init (storage: CircuitBreakerStorageProtocol, maxFailures:Int = 20, retryTimeout:Int = 60) {
        self.storageAdapter = storage
        self.defaultMaxFailures = maxFailures
        self.defaultRetryTimeout = retryTimeout
        self.settings = [:]
    }

    /**
    * Use this method only if you want to add server specific threshold and retry timeout.
    *
    * @param String           serviceName
    * @param Int              maxFailures  default threshold, if service fails this many times will be disabled
    * @param Int              retryTimeout how many seconds should we wait before retry
    * @return CircuitBreaker
    */
    func setServiceSettings(serviceName:String, maxFailures:Int, retryTimeout:Int) -> CircuitBreakerProtocol {
        self.settings[serviceName]? = ["maxFailures": (maxFailures != 0) ? maxFailures : self.defaultMaxFailures]
        self.settings[serviceName]? = ["retryTimeout": (retryTimeout != 0) ? retryTimeout : self.defaultRetryTimeout]
        return self;
    }

    func getSetting(serviceName:String, settingName:String) -> Int {
        if (self.settings[serviceName] == nil) {
            self.settings.updateValue([:], forKey: serviceName)
            self.settings[serviceName]!.updateValue(self.defaultMaxFailures, forKey: "maxFailures")
            self.settings[serviceName]!.updateValue(self.defaultRetryTimeout, forKey: "retryTimeout")
        }
        return self.settings[serviceName]![settingName]!
    }
    
    func getMaxFailures(serviceName:String) -> Int {
        return self.getSetting(serviceName, settingName: "maxFailures")
    }
    
    func getRetryTimeout(serviceName:String) -> Int {
        return self.getSetting(serviceName, settingName: "retryTimeout")
    }
    
    func getFailures(serviceName:String) -> Int {
        return self.storageAdapter.loadStatus(serviceName, attributeName: "failures")
    }
    
    func getLastTest(serviceName:String) -> Int {
        return self.storageAdapter.loadStatus(serviceName, attributeName: "lastTest")
    }
    
    func setFailures(serviceName:String, newValue:Int) {
        self.storageAdapter.saveStatus(serviceName, attributeName: "failures", statusValue: newValue, flush: false)
        self.storageAdapter.saveStatus(serviceName, attributeName: "lastTest", statusValue: Int(NSDate().timeIntervalSince1970), flush: true)
    }
    
    func isAlive (serviceName: String) -> Bool {
        let failures = self.getFailures(serviceName)
        let maxFailures = self.getMaxFailures(serviceName)
        
        if (failures < maxFailures) {
            // this is what happens most of the time so we evaluate first
            return true;
        } else {
            let lastTest = self.getLastTest(serviceName)
            let retryTimeout = self.getRetryTimeout(serviceName)
            if (lastTest + retryTimeout < Int(NSDate().timeIntervalSince1970)) {
                // Once the retryTimeout has hit, we have to allow one
                // thread to try to connect again. To prevent all other threads
                // from flooding we update the time first
                // and then try to connect. If server db is dead only one thread will hang
                // waiting for the connection. Others will get updated timeout from stats.
                //
                // 'Race condition' is between first thread getting into this line and
                // time it takes to store the settings. In that time other threads will
                // also be entering this statement. Even on very busy servers it
                // wont allow more than a few requests to get through before stats are updated.
                //
                // updating lastTest
                self.setFailures(serviceName, newValue: failures)
                // allowing this thread to try to connect to the resource
                return true;
            } else {
                return false;
            }
        }
    }
    
    func malfunction (serviceName: String) -> Void {
        self.setFailures(serviceName, newValue: self.getFailures(serviceName) + 1)
    }
    
    func reportAlive (serviceName: String) -> Void {
        let failures = self.getFailures(serviceName)
        let maxFailures = self.getMaxFailures(serviceName)
        if (failures > maxFailures) {
            // there were more failures than max failures
            // we have to reset failures count to max-1
            self.setFailures(serviceName, newValue: maxFailures - 1)
        } else if (failures > 0) {
            // if we are between max and 0 we decrease by 1 on each
            // success so we will go down to 0 after some time
            // but we are still more sensitive to failures
            self.setFailures(serviceName, newValue: failures - 1)
        } else {
            // if there are no failures reported we do not
            // have to do anything on success (system operational)
        }
    }
    
    func isAvailable (serviceName: String) -> Bool {
        return self.isAlive(serviceName)
    }
    
    func reportFailure (serviceName: String) -> Void {
        self.malfunction(serviceName)
    }
    
    func reportSuccess (serviceName: String) -> Void {
        self.reportAlive(serviceName)
    }
}

@objc
class BaseAdapter : NSObject, CircuitBreakerStorageProtocol {
 
    /**
     how long the stats array should persist in cache
    */
    var ttl:Int
    
    /**
    String cache key prefix
    */
    var cachePrefix:String = "ShortCircuit"
    
    init (ttl: Int = 3600, cachePrefix: String = "") {
        self.ttl = ttl
        if (!cachePrefix.isEmpty) {
            self.cachePrefix = cachePrefix;
        }
    }
    
    func loadStatus(serviceName: String, attributeName: String) -> Int {

        self.checkExtention()
        
        let stats = self.load(self.cachePrefix + serviceName + attributeName);
        return stats;
    }
    
    func saveStatus(serviceName: String, attributeName: String, statusValue: Int, flush: Bool) {
        self.checkExtention()
        
        self.save(self.cachePrefix + serviceName + attributeName, statusValue: statusValue, ttl: self.ttl);
    }
    
    func checkExtention() {
        preconditionFailure("Must be overridden by subclass")
    }
    
    func load(key:String) -> Int {
        preconditionFailure("Must be overridden by subclass")
    }
    
    func save(key:String, statusValue:Int, ttl: Int) {
        preconditionFailure("Must be overridden by subclass")
    }
}

@objc
class DummyAdapter : NSObject, CircuitBreakerStorageProtocol {
    
    var data : [String: [String:Int]] = [:]
    
    func loadStatus(serviceName: String, attributeName: String) -> Int {
        if ((data["\(serviceName)"]?["\(attributeName)"]) != nil) {
            return data[serviceName]![attributeName]!
        }
        return -1
    }
    
    func saveStatus(serviceName: String, attributeName: String, statusValue: Int, flush: Bool) {
        if (self.data["\(serviceName)"] != nil) {
            self.data["\(serviceName)"]!["\(attributeName)"] = statusValue
        } else {
            self.data.updateValue([attributeName: statusValue], forKey: serviceName)
        }
        
    }
}

@objc
class NSUserDefaultsAdapter : BaseAdapter {
    
    override init (ttl: Int = 3600, cachePrefix: String = "") {
        super.init(ttl: ttl, cachePrefix: cachePrefix);
    }
    
    override func checkExtention() {
        // nothing to do as NSUserDefaults cannot be nil
    }
    
    override func load(key:String) -> Int {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if userDefaults.objectForKey(key) != nil {
            return userDefaults.integerForKey(key)
        }
        return -1
    }
    
    override func save(key:String, statusValue:Int, ttl: Int) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setInteger(statusValue, forKey: key)
        userDefaults.synchronize()
    }
}