Class {
	#name : 'GciErrorTest',
	#superclass : 'TestCase',
	#instVars : [
		'session'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GciErrorTest >> setUp [
    super setUp.
    session := GbsSession new.
]

{ #category : 'tests' }
GciErrorTest >> testGciErrorSignaling [
    | mockError |
    "Create a real FFI structure instance"
    mockError := GciError new.
    
    "Manually populate the C-buffer 'message' field for testing"
    mockError message: 'Division by zero'.
    
    self 
        should: [ session signalError: mockError ]
        raise: GbsError
        withExceptionDo: [ :ex | 
            self assert: ex messageText equals: 'Division by zero' ].
]
