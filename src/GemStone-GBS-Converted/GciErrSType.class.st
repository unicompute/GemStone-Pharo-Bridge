Class {
	#name : 'GciErrSType',
	#superclass : 'FFIExternalObject',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GciErrSType >> exceptionOop [ ^ handle signedLongAt: 17
]

{ #category : 'cleanup' }
GciErrSType >> free [ handle ifNotNil: [ handle free. handle := nil ]
]

{ #category : 'initialization' }
GciErrSType >> initialize [ super initialize. handle := ExternalAddress allocate: 2200. handle autoRelease.
]

{ #category : 'accessing' }
GciErrSType >> message [
    "1. Offset 113 (0-based) takes us to the start of the message array.
     2. readString reads characters until a null terminator is found."
    ^ (handle + 113) readString
]

{ #category : 'accessing' }
GciErrSType >> number [ ^ handle signedLongAt: 105
]
