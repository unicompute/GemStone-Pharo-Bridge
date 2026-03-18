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
		'CompactValue2Token',
		'DeleteToken',
		'HeaderToken',
		'IllegalResourceInstIdToken',
		'IllegalValueToken',
		'InstanceCreateToken',
		'IntResourceInstIdToken',
		'IntTimestampToken',
		'JavaEpochStart',
		'Max1ByteCompactValue',
		'Max2ByteCompactValue',
		'MaxByteResourceInstId',
		'MaxShortVal',
		'Min1ByteCompactValue',
		'Min2ByteCompactValue',
		'SampleToken',
		'ShortResourceInstIdToken',
		'TypeByte8',
		'TypeDouble',
		'TypeFloat',
		'TypeInt32',
		'TypeLong64',
		'TypeShort16',
		'TypeToken'
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'initialize-release' }
GbxStatArchiver >> createStreamOn: aFile
[

	^(aFile withEncoding: #binary) writeStream
]

{ #category : 'initialize-release' }
GbxStatArchiver >> initializeWithFile: aFile
[

	writeProtect := Semaphore forMutualExclusion.
	writeProtect critical: 
			[stream := self createStreamOn: aFile.
			self writeProlog.
			nextInstanceId := 0.
			resources := IdentitySet new.
			self basicAddStatResource: GbxObjectMemoryStatResource singleton
				instanceDescription: GbxObjectMemoryStatResource singleton
						instanceDescription.
			self basicAddStatResource: GBSM statResource
				instanceDescription: GBSM statResource instanceDescription.
			GBSM loggedInSessions do: 
					[:s |
					"Note regarding fix for bug 33133 - even though we're holding writeProtect,
					 it's safe to send instanceDescription at this point in time, because no other 
					 threads have visibility of this archiver."
					self basicAddStatResource: s statResource
						instanceDescription: s statResource instanceDescription]]
]

{ #category : 'public api' }
GbxStatArchiver >> addStatResource: statResource 
[
	"To avoid possible deadlock (bug 33133), get the description before entering writeProtect"

	| description |
	description := statResource instanceDescription.
	writeProtect critical: 
			[self basicAddStatResource: statResource instanceDescription: description]
]

{ #category : 'public api' }
GbxStatArchiver >> removeStatResource: statResource 
[
	| result |
	writeProtect critical: 
			[result := resources remove: statResource ifAbsent: [ nil ].
			self writeResourceDeleted: statResource].
	^result
]

{ #category : 'public api' }
GbxStatArchiver >> writeSampleHeaderAndSample
[
	writeProtect critical: 
			[self
				writeSampleHeader;
				writeSample]
]

{ #category : 'public api' }
GbxStatArchiver >> close
[
	writeProtect critical: 
			[stream close.
			resources do: [:resource | resource closedArchive]]
]

{ #category : 'private' }
GbxStatArchiver >> writeShort: short
[

	"Write the given 16 bit short (as specified in GFS_File_Format.doc)"

	stream nextWordPut: short
]

{ #category : 'private' }
GbxStatArchiver >> writeByte: byte 
[
	"Write the given 8 bit byte (as specified in GFS_File_Format.doc)"

	| toWrite |
	toWrite := byte.
	byte < 0 ifTrue: [ toWrite := 256 + byte ].
	stream nextPut: toWrite
]

{ #category : 'private' }
GbxStatArchiver >> writeCompressedNumber: num
[

	| buffer idx v |
	(num between: Min1ByteCompactValue and: Max1ByteCompactValue)
		ifTrue: [^self writeByte: num].
	(num between: Min2ByteCompactValue and: Max2ByteCompactValue)
		ifTrue: 
			[^self
				writeByte: CompactValue2Token;
				writeShort: num].
	buffer := Array new: 8.
	idx := 0.
	v := num.
	v < 0
		ifTrue: 
			[[v ~~ -1] whileTrue: 
					[idx := idx + 1.
					buffer at: idx put: (v bitAnd: 16rFF).
					v := v bitShift: -8].
			((buffer at: idx) bitAnd: 16r80) == 0
				ifTrue: 
					["If the most significant byte does not have its high order bit set
          			 then add a -1 byte so we know this is a negative number"
					idx := idx + 1.
					buffer at: idx put: -1]]
		ifFalse: 
			[[v == 0] whileFalse: 
					[idx := idx + 1.
					buffer at: idx put: (v bitAnd: 16rFF).
					v := v bitShift: -8	"right shift with sign extension"].
			((buffer at: idx) bitAnd: 16r80) ~~ 0
				ifTrue: 
					["If the most significant byte has its high order bit set
           then add a zero byte so we know this is a positive number"
					idx := idx + 1.
					buffer at: idx put: 0]].
	self gbsMessenger assert: idx > 2
		failure: 'Internal error - expected idx to be greater than 2'.
	self writeByte: CompactValue2Token + idx - 2.
	idx to: 1
		by: -1
		do: [:i | self writeByte: (buffer at: i)]
]

{ #category : 'private' }
GbxStatArchiver >> writeString: string
[
	"Write the given string (as specified in GFS_File_Format.doc)"

	"Can't use the following - it sometimes writes the length as one byte"

	"stream nextStringPut: string"

	"Write the length as two bytes"

	| length |
	length := string size.
	stream nextPut: length // 256.
	stream nextPut: length \\ 256.
	string do: [:char | stream nextPut: char asInteger]
]

{ #category : 'private' }
GbxStatArchiver >> writeInt: int
[

	"Write the given 32 bit int (as specified in GFS_File_Format.doc)"

	stream nextLongPut: int
]

{ #category : 'private' }
GbxStatArchiver >> writeHeader
[
	| currentEpochMs dir |
	currentEpochMs := Time millisecondClockValue - JavaEpochStart.

	"Header token"
	self writeByte: HeaderToken.
	"Archive version"
	self writeByte: ArchiveVersion.
	"Date - Current epoch time in milliseconds."
	self writeLong: currentEpochMs.
	"System id - pid of the process which created the stats"
	self writeLong: OSHandle currentProcessID.
	"System start time - epoch time in milliseconds when the system got started"
	self writeLong: currentEpochMs.	"Don't know how to get image startup time"
	"Time Zone Offset in milliseconds from GMT (positive or negative)"
	self writeInt: (TimeZone default secondsFromGMTAtLocal: Timestamp now) * 1000.
	"Time Zone Id - name of the timezone"
	self writeString: GbsTimeZone current printString.
	"System Directory Path - for this, try to supply the image's current directory"
	dir := (SystemVariable named: 'PWD') value.
	dir isEmpty ifTrue: [dir := Filename currentDirectory asString].
	self writeString: dir.
	"Product Description"
	self writeString: (self gbsMessenger 
				print: 'GemBuilder for Smalltalk %1 of %2'
				with: GbsConfiguration gbsBuildName
				with: GbsConfiguration gbsBuildTime first).
	"Osname and Version"
	self writeString: OSHandle currentPlatformID.
	"Machine Information"
	self writeString: SocketAccessor getHostname.
	stream flush
]

{ #category : 'private' }
GbxStatArchiver >> writeLong: long
[
	"Write the given 64 bit long (as specified in GFS_File_Format.doc)"

	stream nextNumber: 8 "bytes" put: long
]

{ #category : 'private' }
GbxStatArchiver >> writeProlog
[
	self
		writeHeader;
		writeResourceTypesAndDescriptors
]

{ #category : 'private' }
GbxStatArchiver >> writeResourceDeleted: statResource 
[
	GbxStatMonitor instance handlingErrorsDo: 
			[self writeByte: DeleteToken.
			self writeInt: statResource instanceId]
]

{ #category : 'private' }
GbxStatArchiver >> writeResourceInstanceInformationFor: statResource instanceDescription: instanceDescription
[
	"Instance create token"
	"Note: instanceDescription is passed as an argument, instead of this method sedning statResource instanceDescription, to fix a deadlock (bug 33133).  The archiver's writeProtect is held at this point in time, and a session stat resource needs to grab the stObjectCache's semaphore, which can deadlock - so the fix chosen is to send instanceDescription *before* entering the archiver's writeProtect semaphore."

	self writeByte: InstanceCreateToken.
	"Instance id"
	self writeInt: statResource instanceId.
	"Instances Text ID"
	self writeString: instanceDescription.
	"Numeric ID"
	self writeLong: 0.
	"Type ID"
	self writeInt: statResource class resourceTypeId
]

{ #category : 'private' }
GbxStatArchiver >> writeResourceTypesAndDescriptors
[
	"Type information"

	| resourceTypes |
	resourceTypes := Array
				with: GbxSessionManagerStatResource
				with: GbxSessionStatResource
				with: GbxCachedClassStatResource
				with: GbxObjectMemoryStatResource.
	resourceTypes do: 
			[:resourceType |
			"Token to define a new resource type"
			self writeByte: TypeToken.
			"Next, the id for this type"
			self writeInt: resourceType resourceTypeId.
			"Name for this type"
			self writeString: resourceType resourceTypeName.
			"Description"
			self writeString: resourceType resourceTypeDescription.
			"Number of descriptors"
			self writeShort: resourceType numberOfDescriptors.
			resourceType writeDescriptorInformationOn: self]
]

{ #category : 'private' }
GbxStatArchiver >> basicAddStatResource: statResource  instanceDescription: instanceDescription
[
	"This should only be called by methods in this class - it doesn't use writeProtect"

	statResource instanceId: nextInstanceId.
	nextInstanceId := nextInstanceId + 1.
	"Write the meta information to the archive before adding it to resources and
	 making it fair game for sampling"
	self writeResourceInstanceInformationFor: statResource instanceDescription: instanceDescription.
	resources add: statResource
]

{ #category : 'private' }
GbxStatArchiver >> writeSample
[
	"Make sure to call writeSampleHeader before this"

	resources do: 
			[:resource |
			| instanceId |
			instanceId := resource instanceId.
			instanceId <= MaxByteResourceInstId
				ifTrue: [self writeByte: instanceId]
				ifFalse: 
					[instanceId > 65535
						ifTrue: 
							[self writeByte: IntResourceInstIdToken.
							self writeInt: instanceId]
						ifFalse: 
							[self
								writeByte: ShortResourceInstIdToken;
								writeShort: instanceId]].
			resource writeSampleTo: self.
			"End of descriptors for this stat instance"
			self writeByte: IllegalResourceInstIdToken].

	"End of a sample run"
	self writeByte: IllegalValueToken.
	stream flush
]

{ #category : 'private' }
GbxStatArchiver >> writeSampleHeader
[

	"Sample token - marks the start of a sample"
	| lastSampleMs delta |
	self writeByte: SampleToken.
	"Timestamp - Time difference in milliseconds between the current time and last sampled time."
	lastSampleMs := sampleMs.
	sampleMs := Time millisecondClockValue.
	lastSampleMs isNil ifTrue: [ lastSampleMs := sampleMs ].
	delta := sampleMs - lastSampleMs.
	delta < MaxShortVal
		ifTrue: [ self writeShort: delta ]
		ifFalse: [ 
			self writeShort: IntTimestampToken.
			self writeInt: delta ].
]

{ #category : 'private' }
GbxStatArchiver >> writeBoolean: aBoolean
[

	aBoolean
		ifTrue: [ self writeByte: 1 ]
		ifFalse: [ self writeByte: 0 ]
]

{ #category : 'defaults' }
GbxStatArchiver class >> defaultStatFileName
[

	^'GBSStatArchive-' , GbsStackDumper timestampForFilename , '.gfs'
]

{ #category : 'instance creation' }
GbxStatArchiver class >> newNamed: filename
[
	"Return a new GbxStatArchive instance on a new stat archive file 
	 named filename.  Raise an exception if a file already exists by 
	 that name."

	| file |
	file := Filename named: filename.
	file exists ifTrue: [
		^self gbsMessenger error: 'A file named ', filename, ' already exists' ].

	^self basicNew initializeWithFile: file
]

{ #category : 'instance creation' }
GbxStatArchiver class >> named: filename
[
	"Return a new GbxStatArchive instance on a new or existing stat 
	 archive file named filename.  If it's an existing file, statistics will
	 be appended."

	^self gbsMessenger error: 'Not yet implemented'
]

{ #category : 'instance creation' }
GbxStatArchiver class >> new
[
	"Return a new GbxStatArchive instance on a new stat archive file 
	 named GBSStatArchive-YYYY-MM-DD-HH.MM.SS.SSS.gfs"

	^self newNamed: self defaultStatFileName
]

{ #category : 'initialize-release' }
GbxStatArchiver class >> initialize
[
	"GbxStatArchiver initialize"

	"version"

	ArchiveVersion := 4.

	"tokens"
	HeaderToken := 77.
	TypeToken := 1.
	InstanceCreateToken := 2.
	SampleToken := 0.
	IntTimestampToken := 65535.
	MaxByteResourceInstId := 252.
	ShortResourceInstIdToken := 253.
	IntResourceInstIdToken := 254.
	IllegalResourceInstIdToken := 255.
	IllegalValueToken := 255.	"Spec says a byte value -1"
	DeleteToken := 3.
	CompactValue2Token := 128.	"Spec says -128, but it's a byte"

	"types"
	TypeByte8 := 3.
	TypeShort16 := 4.
	TypeInt32 := 5.
	TypeLong64 := 6.
	TypeFloat := 7.
	TypeDouble := 8.

	"constants"
	MaxShortVal := 65535.
	JavaEpochStart := (Timestamp 
				readFromDateAndTime: '1/1/1970 00:00' readStream) asSeconds 
				* 1000.
	Max1ByteCompactValue := 127.
	Min1ByteCompactValue := -121.
	Max2ByteCompactValue := 32767.
	Min2ByteCompactValue := -32768
]

