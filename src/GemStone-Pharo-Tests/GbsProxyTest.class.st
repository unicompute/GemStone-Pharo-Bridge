Class {
	#name : 'GbsProxyTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbsProxyTest >> testProxyState [
    | myProxy dummySession |
    
    dummySession := Object new.
    "This calls the class-side method we just fixed"
    myProxy := GbsProxy oop: 12345 session: dummySession.
    
    self assert: myProxy oop equals: 12345.
    self assert: myProxy session equals: dummySession.
    self assert: myProxy isNotNil. "<- The trap awaits!"
]
