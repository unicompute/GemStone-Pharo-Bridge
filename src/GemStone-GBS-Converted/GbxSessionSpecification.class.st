Class {
	#name : 'GbxSessionSpecification',
	#superclass : 'Object',
	#instVars : [
		'connectors',
		'username',
		'password',
		'sessionClass'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'actions' }
GbxSessionSpecification >> login [
    | interface encPassBuffer success session |
    interface := GbsServerInterface uniqueInstance.
    interface apiGciInit.
    
    encPassBuffer := ExternalAddress allocate: 1024.
    [
        interface apiGciEncrypt: (self password ifNil: [ '' ]) into: encPassBuffer.
        
        interface 
            apiGciSetNet: (self perform: #gemStoneName) 
            host: '' net: '' 
            service: (self gemService ifNil: [ 'gemnetobject' ]).
        
        success := interface 
            apiGciLoginEx: self username 
            pass: encPassBuffer 
            flags: 1 
            context: 0.
        
        success ifFalse: [ ^ self error: 'GemStone Login Failed' ].
        
        session := (sessionClass ifNil: [ GbsSession ]) new.
        session sessionId: 1.
        ^ session
    ] ensure: [ encPassBuffer free ]
]

{ #category : 'accessing' }
GbxSessionSpecification >> password [ ^ password
]

{ #category : 'accessing' }
GbxSessionSpecification >> password: aString [ password := aString
]

{ #category : 'accessing' }
GbxSessionSpecification >> username [ ^ username
]

{ #category : 'accessing' }
GbxSessionSpecification >> username: aString [ username := aString
]
