Class {
	#name : 'GbxStatArchiver',
	#superclass : 'Object',
	#instVars : [
		'stream',
		'resources',
		'sampleMs',
		'nextInstanceId',
		'writeProtect'
	],
	#classVars : [
		'ArchiveVersion',
		'HeaderToken',
		'TypeToken',
		'InstanceCreateToken',
		'SampleToken',
		'IntTimestampToken',
		'MaxByteResourceInstId',
		'ShortResourceInstIdToken',
		'IntResourceInstIdToken',
		'IllegalResourceInstIdToken',
		'IllegalValueToken',
		'DeleteToken',
		'CompactValue2Token',
		'TypeByte8',
		'TypeShort16',
		'TypeInt32',
		'TypeLong64',
		'TypeFloat',
		'TypeDouble',
		'MaxShortVal',
		'JavaEpochStart',
		'Max1ByteCompactValue',
		'Min1ByteCompactValue',
		'Max2ByteCompactValue',
		'Min2ByteCompactValue'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'defaults' }
GbxStatArchiver class >> defaultStatFileName [
	| stamp |

	stamp := DateAndTime now printString.
	stamp := (stamp copyReplaceAll: ' ' with: '-')
		copyReplaceAll: ':' with: '.'.
	^ 'GBSStatArchive-', stamp, '.gfs'
]

{ #category : 'initialize-release' }
GbxStatArchiver class >> initialize [
	ArchiveVersion := 4.
	HeaderToken := 77.
	TypeToken := 1.
	InstanceCreateToken := 2.
	SampleToken := 0.
	IntTimestampToken := 65535.
	MaxByteResourceInstId := 252.
	ShortResourceInstIdToken := 253.
	IntResourceInstIdToken := 254.
	IllegalResourceInstIdToken := 255.
	IllegalValueToken := 255.
	DeleteToken := 3.
	CompactValue2Token := 128.
	TypeByte8 := 3.
	TypeShort16 := 4.
	TypeInt32 := 5.
	TypeLong64 := 6.
	TypeFloat := 7.
	TypeDouble := 8.
	MaxShortVal := 65535.
	JavaEpochStart := 0.
	Max1ByteCompactValue := 127.
	Min1ByteCompactValue := -121.
	Max2ByteCompactValue := 32767.
	Min2ByteCompactValue := -32768
]

{ #category : 'instance creation' }
GbxStatArchiver class >> new [
	ArchiveVersion ifNil: [ self initialize ].
	^ self newNamed: self defaultStatFileName
]

{ #category : 'instance creation' }
GbxStatArchiver class >> newNamed: filename [
	| file |

	ArchiveVersion ifNil: [ self initialize ].
	file := FileSystem workingDirectory / filename.
	file exists ifTrue: [ self error: 'A file named ', filename, ' already exists' ].
	^ self basicNew initializeWithFile: file
]

{ #category : 'constants' }
GbxStatArchiver class >> TypeByte8 [
	TypeByte8 ifNil: [ self initialize ].
	^ TypeByte8
]

{ #category : 'constants' }
GbxStatArchiver class >> TypeDouble [
	TypeDouble ifNil: [ self initialize ].
	^ TypeDouble
]

{ #category : 'constants' }
GbxStatArchiver class >> TypeFloat [
	TypeFloat ifNil: [ self initialize ].
	^ TypeFloat
]

{ #category : 'constants' }
GbxStatArchiver class >> TypeInt32 [
	TypeInt32 ifNil: [ self initialize ].
	^ TypeInt32
]

{ #category : 'constants' }
GbxStatArchiver class >> TypeLong64 [
	TypeLong64 ifNil: [ self initialize ].
	^ TypeLong64
]

{ #category : 'constants' }
GbxStatArchiver class >> TypeShort16 [
	TypeShort16 ifNil: [ self initialize ].
	^ TypeShort16
]

{ #category : 'public api' }
GbxStatArchiver >> addStatResource: statResource [
	| description |

	statResource ifNil: [ ^ self ].
	description := statResource instanceDescription.
	writeProtect critical: [
		self basicAddStatResource: statResource instanceDescription: description ]
]

{ #category : 'private' }
GbxStatArchiver >> basicAddStatResource: statResource instanceDescription: instanceDescription [
	statResource ifNil: [ ^ self ].
	(resources includes: statResource) ifTrue: [ ^ self ].
	statResource instanceId: nextInstanceId.
	nextInstanceId := nextInstanceId + 1.
	self writeResourceInstanceInformationFor: statResource instanceDescription: instanceDescription.
	resources add: statResource
]

{ #category : 'public api' }
GbxStatArchiver >> close [
	writeProtect critical: [
		stream ifNotNil: [ stream close. stream := nil ].
		resources ifNotNil: [ resources do: [ :resource | resource closedArchive ] ] ]
]

{ #category : 'initialize-release' }
GbxStatArchiver >> createStreamOn: aFile [
	^ aFile binaryWriteStream
]

{ #category : 'initialize-release' }
GbxStatArchiver >> initializeWithFile: aFile [
	writeProtect := Semaphore forMutualExclusion.
	writeProtect critical: [
		stream := self createStreamOn: aFile.
		resources := IdentitySet new.
		nextInstanceId := 0.
		self writeProlog.
		self
			basicAddStatResource: GbxObjectMemoryStatResource singleton
			instanceDescription: GbxObjectMemoryStatResource singleton instanceDescription.
		self
			basicAddStatResource: GBSM statResource
			instanceDescription: GBSM statResource instanceDescription.
		GBSM loggedInSessions do: [ :session |
			(session respondsTo: #statResource) ifTrue: [
				self
					basicAddStatResource: session statResource
					instanceDescription: session statResource instanceDescription ] ] ].
	^ self
]

{ #category : 'public api' }
GbxStatArchiver >> removeStatResource: statResource [
	| removed |

	statResource ifNil: [ ^ nil ].
	writeProtect critical: [
		removed := resources remove: statResource ifAbsent: [ nil ].
		removed ifNotNil: [ self writeResourceDeleted: statResource ] ].
	^ removed
]

{ #category : 'private' }
GbxStatArchiver >> writeBoolean: aBoolean [
	aBoolean
		ifTrue: [ self writeByte: 1 ]
		ifFalse: [ self writeByte: 0 ]
]

{ #category : 'private' }
GbxStatArchiver >> writeByte: byte [
	| toWrite |

	toWrite := byte.
	byte < 0 ifTrue: [ toWrite := 256 + byte ].
	stream nextPut: toWrite
]

{ #category : 'private' }
GbxStatArchiver >> writeCompressedNumber: num [
	| buffer idx value |

	(num between: Min1ByteCompactValue and: Max1ByteCompactValue)
		ifTrue: [ ^ self writeByte: num ].
	(num between: Min2ByteCompactValue and: Max2ByteCompactValue)
		ifTrue: [
			self writeByte: CompactValue2Token.
			^ self writeShort: num ].
	buffer := Array new: 8.
	idx := 0.
	value := num.
	value < 0
		ifTrue: [
			[ value ~= -1 ] whileTrue: [
				idx := idx + 1.
				buffer at: idx put: (value bitAnd: 16rFF).
				value := value bitShift: -8 ].
			((buffer at: idx) bitAnd: 16r80) = 0 ifTrue: [
				idx := idx + 1.
				buffer at: idx put: -1 ] ]
		ifFalse: [
			[ value = 0 ] whileFalse: [
				idx := idx + 1.
				buffer at: idx put: (value bitAnd: 16rFF).
				value := value bitShift: -8 ].
			((buffer at: idx) bitAnd: 16r80) ~= 0 ifTrue: [
				idx := idx + 1.
				buffer at: idx put: 0 ] ].
	self writeByte: CompactValue2Token + idx - 2.
	idx to: 1 by: -1 do: [ :i | self writeByte: (buffer at: i) ]
]

{ #category : 'private' }
GbxStatArchiver >> writeHeader [
	| currentEpochMs timeZoneOffset directory platform imagePath |

	currentEpochMs := Time millisecondClockValue.
	timeZoneOffset := [ DateAndTime now offset asSeconds * 1000 ]
		on: Error
		do: [ :ex | 0 ].
	directory := FileSystem workingDirectory pathString.
	platform := [ Smalltalk os platformName ]
		on: Error
		do: [ :ex | 'unknown' ].
	imagePath := [ Smalltalk image imageFile asString ]
		on: Error
		do: [ :ex | '' ].
	self writeByte: HeaderToken.
	self writeByte: ArchiveVersion.
	self writeLong: currentEpochMs.
	self writeLong: 0.
	self writeLong: currentEpochMs.
	self writeInt: timeZoneOffset.
	self writeString: DateAndTime now offset printString.
	self writeString: directory.
	self writeString: 'GemStone-Pharo-Bridge'.
	self writeString: platform.
	self writeString: imagePath.
	stream flush
]

{ #category : 'private' }
GbxStatArchiver >> writeInt: anInteger [
	self writeUnsigned: anInteger bytes: 4
]

{ #category : 'private' }
GbxStatArchiver >> writeLong: anInteger [
	self writeUnsigned: anInteger bytes: 8
]

{ #category : 'private' }
GbxStatArchiver >> writeProlog [
	self
		writeHeader;
		writeResourceTypesAndDescriptors
]

{ #category : 'private' }
GbxStatArchiver >> writeResourceDeleted: statResource [
	self
		writeByte: DeleteToken;
		writeInt: statResource instanceId
]

{ #category : 'private' }
GbxStatArchiver >> writeResourceInstanceInformationFor: statResource instanceDescription: instanceDescription [
	self writeByte: InstanceCreateToken.
	self writeInt: statResource instanceId.
	self writeString: instanceDescription.
	self writeLong: 0.
	self writeInt: statResource class resourceTypeId
]

{ #category : 'private' }
GbxStatArchiver >> writeResourceTypesAndDescriptors [
	{
		GbxSessionManagerStatResource.
		GbxSessionStatResource.
		GbxCachedClassStatResource.
		GbxObjectMemoryStatResource
	} do: [ :resourceType |
		self writeByte: TypeToken.
		self writeInt: resourceType resourceTypeId.
		self writeString: resourceType resourceTypeName.
		self writeString: resourceType resourceTypeDescription.
		self writeShort: resourceType numberOfDescriptors.
		resourceType writeDescriptorInformationOn: self ]
]

{ #category : 'public api' }
GbxStatArchiver >> writeSample [
	resources do: [ :resource |
		| instanceId |
		instanceId := resource instanceId.
		instanceId <= MaxByteResourceInstId
			ifTrue: [ self writeByte: instanceId ]
			ifFalse: [
				instanceId > 65535
					ifTrue: [
						self writeByte: IntResourceInstIdToken.
						self writeInt: instanceId ]
					ifFalse: [
						self writeByte: ShortResourceInstIdToken.
						self writeShort: instanceId ] ].
		resource writeSampleTo: self.
		self writeByte: IllegalResourceInstIdToken ].
	self writeByte: IllegalValueToken.
	stream flush
]

{ #category : 'private' }
GbxStatArchiver >> writeSampleHeader [
	| lastSample delta |

	self writeByte: SampleToken.
	lastSample := sampleMs.
	sampleMs := Time millisecondClockValue.
	lastSample ifNil: [ lastSample := sampleMs ].
	delta := sampleMs - lastSample.
	delta < MaxShortVal
		ifTrue: [ self writeShort: delta ]
		ifFalse: [
			self writeShort: IntTimestampToken.
			self writeInt: delta ]
]

{ #category : 'public api' }
GbxStatArchiver >> writeSampleHeaderAndSample [
	writeProtect critical: [
		self
			writeSampleHeader;
			writeSample ]
]

{ #category : 'private' }
GbxStatArchiver >> writeShort: anInteger [
	self writeUnsigned: anInteger bytes: 2
]

{ #category : 'private' }
GbxStatArchiver >> writeString: aString [
	| string |

	string := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	self writeShort: string size.
	string do: [ :character | stream nextPut: character asciiValue ]
]

{ #category : 'private' }
GbxStatArchiver >> writeUnsigned: anInteger bytes: byteCount [
	| normalized mask |

	mask := (1 bitShift: byteCount * 8) - 1.
	normalized := anInteger bitAnd: mask.
	1 to: byteCount do: [ :index |
		| shift |
		shift := (byteCount - index) * 8.
		stream nextPut: ((normalized bitShift: shift negated) bitAnd: 16rFF) ]
]
