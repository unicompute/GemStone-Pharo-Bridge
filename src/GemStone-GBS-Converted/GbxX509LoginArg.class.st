Class {
	#name : 'GbxX509LoginArg',
	#superclass : 'GbxStructure',
	#instVars : [
		'caCert',
		'cert',
		'dirArg',
		'extraGemArgs',
		'logArg',
		'netldiHostOrIp',
		'netldiNameOrPort',
		'privateKey'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'initialize-release' }
GbxX509LoginArg >> allocateData
[
	super allocateData.
	self initialize.
	^self
]

{ #category : 'accessing' }
GbxX509LoginArg >> argsArePemStrings
[
	^self boolAt: 69
]

{ #category : 'accessing' }
GbxX509LoginArg >> argsArePemStrings: aBoolean
[
	self boolAt: 69 put: aBoolean
]

{ #category : 'accessing' }
GbxX509LoginArg >> caCert
[
	^caCert ifNil: [''] ifNotNil: [caCert readString]
]

{ #category : 'accessing' }
GbxX509LoginArg >> caCert: aString
[
	caCert := self allocateCStringFrom: aString.
	self oopAt: 33 put: caCert
]

{ #category : 'accessing' }
GbxX509LoginArg >> cert
[
	^cert ifNil: [''] ifNotNil: [cert readString]
]

{ #category : 'accessing' }
GbxX509LoginArg >> cert: aString
[
	cert := self allocateCStringFrom: aString.
	self oopAt: 25 put: cert
]

{ #category : 'accessing' }
GbxX509LoginArg >> dirArg
[
	^dirArg ifNil: [''] ifNotNil: [dirArg readString]
]

{ #category : 'accessing' }
GbxX509LoginArg >> dirArg: aString
[
	dirArg := self allocateCStringFrom: aString.
	self oopAt: 49 put: dirArg
]

{ #category : 'accessing' }
GbxX509LoginArg >> executedSessionInit
[
	^self boolAt: 73
]

{ #category : 'accessing' }
GbxX509LoginArg >> extraGemArgs
[
	^extraGemArgs ifNil: [''] ifNotNil: [extraGemArgs readString]
]

{ #category : 'accessing' }
GbxX509LoginArg >> extraGemArgs: aString
[
	extraGemArgs := self allocateCStringFrom: aString.
	self oopAt: 41 put: extraGemArgs
]

{ #category : 'initialize-release' }
GbxX509LoginArg >> initialize
[
	^self
		argsArePemStrings: false;
		caCert: '';
		cert: '';
		dirArg: '';
		extraGemArgs: '';
		logArg: '';
		loginFlags: 0;
		netldiHostOrIp: '';
		netldiNameOrPort: '';
		privateKey: '';
		yourself
]

{ #category : 'accessing' }
GbxX509LoginArg >> logArg
[
	^logArg ifNil: [''] ifNotNil: [logArg readString]
]

{ #category : 'accessing' }
GbxX509LoginArg >> logArg: aString
[
	logArg := self allocateCStringFrom: aString.
	self oopAt: 57 put: logArg
]

{ #category : 'accessing' }
GbxX509LoginArg >> loginFlags
[
	^self uint32At: 65
]

{ #category : 'accessing' }
GbxX509LoginArg >> loginFlags: anInteger
[
	self uint32At: 65 put: anInteger
]

{ #category : 'accessing' }
GbxX509LoginArg >> netldiHostOrIp
[
	^netldiHostOrIp ifNil: [''] ifNotNil: [netldiHostOrIp readString]
]

{ #category : 'accessing' }
GbxX509LoginArg >> netldiHostOrIp: aString
[
	netldiHostOrIp := self allocateCStringFrom: aString.
	self oopAt: 1 put: netldiHostOrIp
]

{ #category : 'accessing' }
GbxX509LoginArg >> netldiNameOrPort
[
	^netldiNameOrPort ifNil: [''] ifNotNil: [netldiNameOrPort readString]
]

{ #category : 'accessing' }
GbxX509LoginArg >> netldiNameOrPort: aString
[
	netldiNameOrPort := self allocateCStringFrom: aString.
	self oopAt: 9 put: netldiNameOrPort
]

{ #category : 'printing' }
GbxX509LoginArg >> printOn: aStream indent: indent
[
	aStream tab: indent - 1.
	aStream nextPutAll: self class name , ' with:'.
	aStream crtab: indent.
	aStream nextPutAll: 'netldiHostOrIP = '.
	self netldiHostOrIp printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'netldiNameOrPort = '.
	self netldiNameOrPort printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'privateKey = '.
	self privateKey printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'cert = '.
	self cert printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'caCert = '.
	self caCert printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'extraGemArgs = '.
	self extraGemArgs printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'dirArg = '.
	self dirArg printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'logArg = '.
	self logArg printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'loginFlags = '.
	self loginFlags printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'argsArePemStrings = '.
	self argsArePemStrings printOn: aStream
]

{ #category : 'accessing' }
GbxX509LoginArg >> privateKey
[
	^privateKey ifNil: [''] ifNotNil: [privateKey readString]
]

{ #category : 'accessing' }
GbxX509LoginArg >> privateKey: aString
[
	privateKey := self allocateCStringFrom: aString.
	self oopAt: 17 put: privateKey
]
