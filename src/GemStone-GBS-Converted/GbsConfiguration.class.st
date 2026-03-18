Class {
	#name : 'GbsConfiguration',
	#superclass : 'Object',
	#instVars : [
		'alwaysUseGemCursor',
		'assertionChecks',
		'autoMarkDirty',
		'backupPolling',
		'blockReplicationEnabled',
		'blockReplicationPolicy',
		'blockingProtocolRpc',
		'bulkLoad',
		'clampByCallback',
		'clientMapCapacity',
		'clientMapFinalizerPriority',
		'confirm',
		'connectVerification',
		'connectorNilling',
		'defaultFaultPolicy',
		'deprecationWarnings',
		'eventPollingFrequency',
		'eventPriority',
		'faultLevelLnk',
		'faultLevelRpc',
		'forwarderDebugging',
		'freeSlotsOnStubbing',
		'fullCompression',
		'gcedObjBufferSize',
		'generateClassConnectors',
		'generateClientClasses',
		'generateServerClasses',
		'initialDirtyPoolSize',
		'libraryName',
		'removeInvalidConnectors',
		'replicateExceptions',
		'serverMapLeafCapacity',
		'stubDebugging',
		'traversalBufferSize',
		'useGbsMemoryPolicy',
		'useDiagnosticSpecialConverter',
		'verbose',
		'socketWaitTimeout'
	],
	#classVars : [
		'Current',
		'Defaults'
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'comparing' }
GbsConfiguration >> hash
[
	| hash |
	hash := 0.
	self class parameters 
		do: [:param | hash := hash + (self perform: param) hash].
	^hash
]

{ #category : 'comparing' }
GbsConfiguration >> = aGbsConfiguration 
[
	(aGbsConfiguration isKindOf: GbsConfiguration) ifFalse: [^false].
	self class parameters do: 
			[:param | 
			(self perform: param) = (aGbsConfiguration perform: param) 
				ifFalse: [^false]].
	^true
]

{ #category : 'accessing' }
GbsConfiguration >> eventPriority: anInteger 
[
	"Set the Smalltalk process priority level for GemStone-initiated events.
	The default priority (Processor userSchedulingPriority) is the safest in that a GemStone event such as 'lost OT root' will not interrupt an application process that might be in the middle of accessing the GBS caches.  Such an interruption might corrupt the caches.  This priority level has the adverse side effect that an event will not be processed unless the application process is idle or does a Processor yield.
	Running the eventPriority at a higher level, such as (Processor userInterruptPriority), will ensure that GemStone events are processed when they are received by GemBuilder, at the risk of corrupting the current application process.  The 'lost OT root' event is very likely to modify the transparency caches, and events such as changed object notification, signaled abort, or gem-to-gem notification will execute whatever user-defined Smalltalk block has been supplied for that event."

	eventPriority := anInteger
]

{ #category : 'accessing' }
GbsConfiguration >> alwaysUseGemCursor: aBoolean 
[
	"If aBoolean is true, the gem cursor will be displayed during server operations. 
	If false, the cursor will not be modified. Defaults to true, but some applications
	will want to make it false for more control or to save the time of many cursor 
	switches."

	alwaysUseGemCursor := aBoolean
]

{ #category : 'accessing' }
GbsConfiguration >> generateServerClasses
[
	"Return a Boolean indicating whether GemStone class generation is enabled"

	^generateServerClasses
]

{ #category : 'accessing' }
GbsConfiguration >> connectorNilling
[
	^connectorNilling
]

{ #category : 'accessing' }
GbsConfiguration >> generateClassConnectors: aBool 
[
	"If aBool is set to true, then whenever a Smalltalk or GemStone class is generated, or a same-name class mapping is automatically established, a session-based connector will be created for the class mapping."

	generateClassConnectors := aBool
]

{ #category : 'accessing' }
GbsConfiguration >> useGbsMemoryPolicy
[
	^useGbsMemoryPolicy
]

{ #category : 'accessing' }
GbsConfiguration >> eventPollingFrequency: anInteger 
[
	"Set the event polling frequency (in milliseconds)"

	eventPollingFrequency := anInteger
]

{ #category : 'accessing' }
GbsConfiguration >> traversalBufferSize: anInteger 
[
	"The traversalBufferSize must be a multiple of 8. It must also not be smaller than the MinTraversalBufferSize (2048)"
	traversalBufferSize := (anInteger roundTo: 8) max: MinTraversalBufferSize
]

{ #category : 'accessing' }
GbsConfiguration >> blockingProtocolRpc
[
	^blockingProtocolRpc
]

{ #category : 'accessing' }
GbsConfiguration >> freeSlotsOnStubbing
[
	^freeSlotsOnStubbing
]

{ #category : 'accessing' }
GbsConfiguration >> setValueOf: aParameterName to: aValue 
[
	"Set the current value of the parameter, and answer the value."

	self perform: (aParameterName , ':') asSymbol with: aValue.
	^aValue
]

{ #category : 'accessing' }
GbsConfiguration >> clientMapFinalizerPriority
[
	^clientMapFinalizerPriority
]

{ #category : 'accessing' }
GbsConfiguration >> removeInvalidConnectors
[
	^removeInvalidConnectors
]

{ #category : 'accessing' }
GbsConfiguration >> autoMarkDirty: anObject
[
	autoMarkDirty := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> faultLevelLnk: anInteger
[
	faultLevelLnk := anInteger
]

{ #category : 'accessing' }
GbsConfiguration >> libraryName: anObject
[
	libraryName := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> backupPolling: aBoolean
[

	backupPolling := aBoolean
]

{ #category : 'accessing' }
GbsConfiguration >> generateGSClasses: aBoolean 
[
	"Enable or disable GemStone class generation"

	GbsConfiguration 
		deprecated: 'GbsConfiguration>>generateGSClasses: deprecated August, 2005. Use GbsConfiguration>>generateServerClasses: instead'.
	generateServerClasses := aBoolean
]

{ #category : 'accessing' }
GbsConfiguration >> confirm: aBoolean 
[
	"If <aBoolean> is true, then GBS will prompt for confirmation."

	" GBSM confirm "

	| was |
	was := confirm.
	confirm := aBoolean.
	^was
]

{ #category : 'accessing' }
GbsConfiguration >> defaultFaultPolicy
[
	^defaultFaultPolicy
]

{ #category : 'accessing' }
GbsConfiguration >> gcedObjBufferSize: anObject
[
	gcedObjBufferSize := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> valueOf: aParameterName 
[
	"Answer the current value of the parameter."

	^self perform: aParameterName asSymbol
]

{ #category : 'accessing' }
GbsConfiguration >> fullCompression
[
	^fullCompression
]

{ #category : 'accessing' }
GbsConfiguration >> verbose: aBoolean 
[
	"If aBoolean is true, GemBuilder will put a message on the system transcript when special events occur
	 (logout/login/commit/abort)."

	"GbsConfiguration current verbose: true"

	| was |
	was := verbose.
	verbose := aBoolean == true.
	^was
]

{ #category : 'accessing' }
GbsConfiguration >> bulkLoad
[
	^bulkLoad
]

{ #category : 'accessing' }
GbsConfiguration >> deprecationWarnings
[
	^deprecationWarnings
]

{ #category : 'accessing' }
GbsConfiguration >> socketWaitTimeout: anObject
[

	socketWaitTimeout := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> blockReplicationEnabled: anObject
[
	blockReplicationEnabled := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> faultLevelRpc: anInteger
[
	faultLevelRpc := anInteger
]

{ #category : 'accessing' }
GbsConfiguration >> stubDebugging
[
	"When this value is true, stubs respond to some basic messages locally - such as printOn:, instVarAt:,
	 and class (returns GbxObjectStub) to support debugging.  When it's false, these messages cause
	 the stub to fault into the client image from GemStone."

	^stubDebugging
]

{ #category : 'accessing' }
GbsConfiguration >> replicateExceptions: anObject
[

	replicateExceptions := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> connectVerification: aBoolean 
[
	"If set to true, connectors will verify that they are not redefining an object connection, and class connectors will verify that the class structures match."

	connectVerification := aBoolean
]

{ #category : 'accessing' }
GbsConfiguration >> generateSTClasses: aBool 
[
	"Enable or disable Smalltalk class generation"

	GbsConfiguration 
		deprecated: 'GbsConfiguration>>generateSTClasses: deprecated August, 2005. Use GbsConfiguration>>generateClientClasses: instead'.
	generateClientClasses := aBool
]

{ #category : 'accessing' }
GbsConfiguration >> assertionChecks
[
	^assertionChecks
]

{ #category : 'accessing' }
GbsConfiguration >> eventPriority
[
	"Return the Smalltalk process priority level for GemStone-initiated events"

	^eventPriority
]

{ #category : 'accessing' }
GbsConfiguration >> defaultFor: aParameterName
[

	"answer the default value for the parameter."
	^ self class defaultFor: aParameterName
]

{ #category : 'accessing' }
GbsConfiguration >> clampByCallback: aBoolean
[

	clampByCallback := aBoolean
]

{ #category : 'accessing' }
GbsConfiguration >> generateClientClasses: aBool 
[
	"Enable or disable Smalltalk class generation"

	generateClientClasses := aBool
]

{ #category : 'accessing' }
GbsConfiguration >> alwaysUseGemCursor
[
	^alwaysUseGemCursor
]

{ #category : 'accessing' }
GbsConfiguration >> generateClassConnectors
[
	"If true, then whenever a Smalltalk or GemStone class is generated, or a same-name class mapping is automatically established, a session-based connector will be created for the class mapping."

	^generateClassConnectors
]

{ #category : 'accessing' }
GbsConfiguration >> confirm
[
	^confirm
]

{ #category : 'accessing' }
GbsConfiguration >> eventPollingFrequency
[
	"Return the current event polling frequency (in milliseconds)"

	^eventPollingFrequency
]

{ #category : 'accessing' }
GbsConfiguration >> useDiagnosticSpecialConverter: aBoolean
[

	useDiagnosticSpecialConverter := aBoolean
]

{ #category : 'accessing' }
GbsConfiguration >> forwarderDebugging: aBool 
[
	"Turn debugging support on or off.  When debugging is on (aBool = true), some
	 messages to forwarders, e.g., printOn:, instVarAt:, and class (returns
	 GbsForwarder), will be handled by the forwarders themselves. When it's
	 off (aBool = false), these messages are forwarded to the GemStone object."

	"GbsConfiguration current forwarderDebugging: true"

	"GbsConfiguration current forwarderDebugging: false"

	| was |
	was := forwarderDebugging.
	forwarderDebugging := aBool == true.
	^was
]

{ #category : 'accessing' }
GbsConfiguration >> traversalBufferSize
[
	^traversalBufferSize
]

{ #category : 'accessing' }
GbsConfiguration >> blockReplicationPolicy: anObject
[
	blockReplicationPolicy := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> clientMapCapacity: anObject
[
	clientMapCapacity := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> serverMapLeafCapacity: anInteger 
[
	serverMapLeafCapacity := anInteger
]

{ #category : 'accessing' }
GbsConfiguration >> faultLevelLnk
[
	^faultLevelLnk
]

{ #category : 'accessing' }
GbsConfiguration >> initialDirtyPoolSize: anObject
[
	initialDirtyPoolSize := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> parameters
[

	"answer the list of all parameters for the class"
	^ self class parameters
]

{ #category : 'accessing' }
GbsConfiguration >> backupPolling
[

	^backupPolling
]

{ #category : 'accessing' }
GbsConfiguration >> generateServerClasses: aBoolean 
[
	"Enable or disable GemStone class generation"

	generateServerClasses := aBoolean
]

{ #category : 'accessing' }
GbsConfiguration >> connectorNilling: anObject
[
	connectorNilling := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> generateGSClasses
[
	"Return a Boolean indicating whether GemStone class generation is enabled"

	GbsConfiguration 
		deprecated: 'GbsConfiguration>>generateGSClasses deprecated August, 2005. Use GbsConfiguration>>generateServerClasses instead'.
	^generateServerClasses
]

{ #category : 'accessing' }
GbsConfiguration >> gcedObjBufferSize
[
	^gcedObjBufferSize
]

{ #category : 'accessing' }
GbsConfiguration >> useGbsMemoryPolicy: aBoolean
[

	useGbsMemoryPolicy := aBoolean.
	GBSM checkMemoryPolicy	"I may not be GbsConfiguration current, so just tell GBSM to 'check'"
]

{ #category : 'accessing' }
GbsConfiguration >> freeSlotsOnStubbing: anObject
[
	freeSlotsOnStubbing := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> verbose
[
	"If true, GemBuilder will put a message on the system transcript when special events occur 
	(logout/login/commit/abort)."

	"GbsConfiguration current verbose"

	^verbose
]

{ #category : 'accessing' }
GbsConfiguration >> blockingProtocolRpc: anObject
[
	blockingProtocolRpc := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> clientMapFinalizerPriority: anInteger
[
	clientMapFinalizerPriority := anInteger
]

{ #category : 'accessing' }
GbsConfiguration >> socketWaitTimeout
[

	^socketWaitTimeout
]

{ #category : 'accessing' }
GbsConfiguration >> connectVerification
[
	"If true, connectors will verify that they are not redefining an object connection, and class connectors will verify that the class structures match."

	^connectVerification
]

{ #category : 'accessing' }
GbsConfiguration >> faultLevelRpc
[
	^faultLevelRpc
]

{ #category : 'accessing' }
GbsConfiguration >> removeInvalidConnectors: aBoolean 
[
	"If true, connectors which fail to resolve at login time will automatically be removed from the connector collections.  If false, and if Verbose is true, the user is prompted for their removal.  Otherwise, connector failure raises a signal."

	removeInvalidConnectors := aBoolean
]

{ #category : 'accessing' }
GbsConfiguration >> blockReplicationEnabled
[
	^blockReplicationEnabled
]

{ #category : 'accessing' }
GbsConfiguration >> clampByCallback
[

	^clampByCallback
]

{ #category : 'accessing' }
GbsConfiguration >> replicateExceptions
[

	^replicateExceptions
]

{ #category : 'accessing' }
GbsConfiguration >> defaultFaultPolicy: faultPolicy 
[
	"An object's faultPolicy is either #lazy or #immediate.  If #lazy, when changes to the GemStone
	 counterpart of a client object are discovered, the client object is turned into a stub and will
	 fault back into the client the first time the stub is sent a message.  If an object's faultPolicy
	 is #immediate, the client object will be updated as soon as a change in the GemStone object
	 is discovered.  The defaultFaultPolicy is what is returned by the default implementation of
	 Object>>faultPolicy (which can be reimplemented in subclasses)."

	(faultPolicy == #immediate or: [faultPolicy == #lazy]) 
		ifFalse: [self gbsMessenger error: 'Fault policy must be #lazy or #immediate'].
	defaultFaultPolicy := faultPolicy
]

{ #category : 'accessing' }
GbsConfiguration >> generateSTClasses
[
	"Return a Boolean indicating whether Smalltalk class generation is enabled"

	GbsConfiguration 
		deprecated: 'GbsConfiguration>>generateSTClasses deprecated August, 2005. Use GbsConfiguration>>generateClientClasses instead'.
	^generateClientClasses
]

{ #category : 'accessing' }
GbsConfiguration >> generateClientClasses
[
	"Return a Boolean indicating whether Smalltalk class generation is enabled"

	^generateClientClasses
]

{ #category : 'accessing' }
GbsConfiguration >> bulkLoad: anObject
[
	bulkLoad := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> fullCompression: anObject
[
	fullCompression := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> useDiagnosticSpecialConverter
[
	"If we are running under an asserting VM, we must use the Diagnostic Special Converter.
	 It is optional, but not recommended, when running under a non-asserting VM."

	^useDiagnosticSpecialConverter or: [self isRunningUnderAssertingVM]
]

{ #category : 'accessing' }
GbsConfiguration >> deprecationWarnings: anObject
[
	deprecationWarnings := anObject
]

{ #category : 'accessing' }
GbsConfiguration >> stubDebugging: aBool 
[
	"Turn debugging support on or off.  When debugging is on,  instance methods will allow the Smalltalk debugger to operate among stubs without causing them to fault in the GemStone object."

	"	GbsConfiguration current stubDebugging: true	"

	"	GbsConfiguration current stubDebugging: false	"

	| was |
	was := stubDebugging.
	stubDebugging := aBool == true.
	^was
]

{ #category : 'accessing' }
GbsConfiguration >> blockReplicationPolicy
[
	^blockReplicationPolicy
]

{ #category : 'accessing' }
GbsConfiguration >> forwarderDebugging
[
	"Answer whether forwarder debugging support is on or off.  When debugging is on
	 (ForwarderDebugging = true), some messages to forwarders, e.g., printOn:,
	 instVarAt:, and class (returns GbsForwarder), will be handled by the forwarders
	 themselves.  When it is off (ForwarderDebugging = false), these messages are
	 forwarded to the GemStone object."

	"GbsConfiguration current forwarderDebugging"

	^forwarderDebugging == true
]

{ #category : 'accessing' }
GbsConfiguration >> libraryName
[
	^libraryName
]

{ #category : 'accessing' }
GbsConfiguration >> serverMapLeafCapacity
[
	^serverMapLeafCapacity
]

{ #category : 'accessing' }
GbsConfiguration >> clientMapCapacity
[
	^clientMapCapacity
]

{ #category : 'accessing' }
GbsConfiguration >> initialDirtyPoolSize
[
	^initialDirtyPoolSize
]

{ #category : 'accessing' }
GbsConfiguration >> assertionChecks: aBoolean 
[
	"GbsConfiguration current assertionChecks: false"

	"GbsConfiguration current assertionChecks: true"

	| was |
	was := assertionChecks.
	assertionChecks := aBoolean.
	^was
]

{ #category : 'analyzing' }
GbsConfiguration >> diffsFromDefault
[
	"Return a collection of symbols describing the parameters described by the receiver which differ from a default configuration"

	^self class parameters 
		select: [:param | (self perform: param) ~= (Defaults perform: param)]
]

{ #category : 'applying' }
GbsConfiguration >> applyAndReloginWhile: aBlock
[

	"If the current configuration isn't equal to the receiver, this method logs out all logged in sessions after applying the configuration, logs in one session, and does the same after restoring the configuration."
	| current mustReLogin params |
	current := self class current.
	mustReLogin := (current ~= self) and: [ GBSM isLoggedIn ].
	GBSM isLoggedIn ifTrue: [ params := GBSM currentSession parameters ].
	^[
		self apply.
		mustReLogin ifTrue: [
			self gbsMessenger
				comment: 'Re-login, setting configuration to %1.'
				with: self.
			GBSM loggedInSessions do: [ :s | s logout ].
			params login ].
		aBlock value.

	] ensure:
	[
		current apply.
		mustReLogin ifTrue: [
			self gbsMessenger
				comment: 'Re-login, restoring configuration to %1.'
				with: current.
			GBSM loggedInSessions do: [ :s | s logout ].
			params login
		].
	].
]

{ #category : 'applying' }
GbsConfiguration >> applyWhile: aBlock
[

	| current |
	current := self class current.
	^[
		self apply.
		aBlock value.

	] ensure:
	[
		current apply
	]
]

{ #category : 'applying' }
GbsConfiguration >> apply
[
	" Configure the GBS as described by the receiver.
	NOTE:  Other windows may be interested in this change.  For example, if session
	browsers are open, the status of the 'Login Lnk' button may have to be changed. "

	"GbxConfiguration default apply"

	Current := self.
	GBSM changed: #newConfigParamsInstalled
]

{ #category : 'private' }
GbsConfiguration >> shouldUseBackupPolling
[

	"Default to false only on Windows, since OOB socket byte detection is less reliable on Unix."

	^self class isPlatformWindows not
]

{ #category : 'initialize-release' }
GbsConfiguration >> initialize
[
	"When you change this method, you must also make sure the following are consistent:
		VisualworksSettings class >settings-gemstone>(whatever)
		GbsConfiguration class>>initializeLegalValues (in GbsProgrammingToolsVW) 
		GbsConfiguration class>>initializeHelpStrings (in GbsProgrammingToolsVW)
            getters and setters in GbsConfiguration.
	Keep this method in alphabetical order."

	alwaysUseGemCursor := true.
	assertionChecks := false.
	autoMarkDirty := self class isVisualAgeImage or: [nil respondsTo: #isImmutable].
	backupPolling := self shouldUseBackupPolling.
	blockingProtocolRpc := false.
	blockReplicationEnabled := true.
	blockReplicationPolicy := #replicate.
	bulkLoad := false.
	clampByCallback := false.
	clientMapCapacity := 30000.
	clientMapFinalizerPriority := Processor userBackgroundPriority.
	confirm := true.
	connectorNilling := true.
	connectVerification := false.	"Connector verification slows down login time.  It is useful to turn on periodically, to make sure multiple connectors aren't overwriting each other and verify class structure mappings"
	defaultFaultPolicy := #lazy.
	deprecationWarnings := true.
	eventPollingFrequency := 1000.	"milliseconds"
	eventPriority := Processor userSchedulingPriority.
	faultLevelLnk := 2.
	faultLevelRpc := 4.
	forwarderDebugging := false.
	freeSlotsOnStubbing := true.
	fullCompression := false.
	gcedObjBufferSize := 2000.
	generateClassConnectors := true.	"When replicating an object whose class doesn't exist in the other environment, generate the class"
	generateClientClasses := false.
	generateServerClasses := false.
	initialDirtyPoolSize := 10.	"There are many small dirty sets, and we have to iterate over them, so keep it small."
	libraryName := ''.
	removeInvalidConnectors := false.
	replicateExceptions := false.
	serverMapLeafCapacity := 400.
	socketWaitTimeout := 100.
	stubDebugging := false.
	traversalBufferSize := 250000.
	useGbsMemoryPolicy := true.
	useDiagnosticSpecialConverter := self isRunningUnderAssertingVM.
	verbose := true	"Write significant events to transcript"
]

{ #category : 'printing' }
GbsConfiguration >> storeOn: aStream 
[
	"For a more portable 'fileout' from the timings browser"

	self printOn: aStream
]

{ #category : 'printing' }
GbsConfiguration >> printOn: aStream 
[
	"Describe the receiver in terms of its differences from a default configuration"

	| diffs |
	aStream
		nextPut: $(;
		nextPutAll: self class name;
		nextPutAll: ' default'.
	diffs := self diffsFromDefault.
	diffs do: 
			[:parameter | 
			aStream
				cr;
				tab;
				nextPutAll: parameter , ': ';
				nextPutAll: (self valueOf: parameter) printString;
				nextPut: $;].
	diffs isEmpty 
		ifFalse: 
			[aStream
				cr;
				tab;
				nextPutAll: 'yourself'].
	aStream nextPut: $)
]

{ #category : 'accessing' }
GbsConfiguration class >> gbsBuildTime
[
	"Answer the date and time of the GemBuilder build."

	^Array with:  (Date 
				gbxMonth: 8
				day: 30
				year: 2024)
		with: (Time 
				gbxHours: 16
				minutes: 56
				seconds: 8)
]

{ #category : 'accessing' }
GbsConfiguration class >> sharedLibraryFilename
[

	| config |
	config := self current.
	config libraryName isEmpty ifTrue: [config setDefaultLibraryName].
	^config libraryName
]

{ #category : 'accessing' }
GbsConfiguration class >> gbsBuildName
[
	"Answer the GemBuilder build name
	 in the form '<releaseName> <buildNumber>'."

	^'8.8.1'
]

{ #category : 'accessing' }
GbsConfiguration class >> sharedLibraryExtension
[
	"Answer two-or-three-character extension for shared library name appropriate for the current platform."
	"	GbsConfiguration sharedLibraryExtension.	"

	| osType |
	osType := self osType.
	osType = #win ifTrue: [^'dll'].
	osType = #unix ifTrue: [^'so'].
	^osType	"Unknown"
]

{ #category : 'accessing' }
GbsConfiguration class >> gemCursor
[
	"Answer the cursor that will be shown while waiting for a
	 response from the server, or nil if in a headless image."

	^GScursor
]

{ #category : 'accessing' }
GbsConfiguration class >> gciProductName
[
	"Converts the code returned by GciProduct() to a more readable name"

	| prodCode nameArray |
	nameArray := #('GemStone/S' 'GemStone/S 2G' 'GemStone/S 64').
	prodCode := GbxGciCallSequencer gciProduct.
	(prodCode < 1 or: [prodCode > 3]) 
		ifTrue: 
			[| ver |
			ver := GbxGciCallSequencer gciVersion.
			"strip off the artificially added: GCI-, then turn into a number"
			prodCode := (ver copyFrom: 5 to: ver size) asNumber < 5 
						ifTrue: [2]
						ifFalse: [1]].
	^nameArray at: prodCode
]

{ #category : 'accessing' }
GbsConfiguration class >> gbsServicesVersion
[
	"Answer a gbsBuildName that supports this version.
	Most likely will be the gbsBuildName, but could be a 
	prior version."

	^self gbsBuildName
]

{ #category : 'accessing' }
GbsConfiguration class >> sharedLibraryVersion
[
	"	GbsConfiguration sharedLibraryVersion.	"

	| verString dotPos majorVersion minorVersion |
	verString := GbxGciCallSequencer gciVersion.
	dotPos := verString indexOf: $..	"Always first period if more than one."
	majorVersion := verString at: dotPos - 1.
	minorVersion := verString at: dotPos + 1.
	^String with: majorVersion with: minorVersion
]

{ #category : 'deprecation' }
GbsConfiguration class >> deprecated: message
[
	"If deprecation warnings are enabled, alert the user that they are 
	using a feature that GemStone intends to remove. The given String message 
	should include the approximate date of the first release in which the feature 
	was deprecated, and the feature to migrate to, if any."

	GbsConfiguration current deprecationWarnings
		ifTrue: 
			[self gbsMessenger raise: GbsDeprecatedError
				message: 'Deprecation warnings enabled, detected attempt to use deprecated feature: '
						, message
							, ' This feature may be removed from a future GBS version, though we generally wait at least a year from the date of deprecation.']
]

{ #category : 'class initialization' }
GbsConfiguration class >> postLoad: aParcel
[
	"During parcel load, by default #initialize will be sent. We can't do that here,
	because some of the code needed to run #initialize is in other parcels. Wait until
	the post-load action for the parcel to initialize."

	"Do nothing."
]

{ #category : 'class initialization' }
GbsConfiguration class >> initialize
[
	"Initialize the default configuration values."

	"GbsConfiguration initialize"

	Defaults := GbsConfiguration new.
	Current := GbsConfiguration new
]

{ #category : 'testing' }
GbsConfiguration class >> isVisualAgeImage
[
	" Answer true if we are running a VisualAge image. "

	^false  "Not supported in Pharo"
]

{ #category : 'testing' }
GbsConfiguration class >> osType
[
	"Answer the OS type symbol: #win, #unix, #mac"

	| osName |
	osName := Smalltalk os familyName.
	osName = #MacOS ifTrue: [^#mac].
	osName = #Windows ifTrue: [^#win].
	^#unix  "default for Linux and other Unix variants"
]

{ #category : 'testing' }
GbsConfiguration class >> isPlatformWindows
[
	"GBS private.
	Answer true if we are running on Windows."

	^self osType == #win
]

{ #category : 'testing' }
GbsConfiguration class >> isVisualWorksImage
[
	" Answer true if we are running a VisualWorks image. "

	^ false  "Not supported in Pharo"
]

{ #category : 'testing' }
GbsConfiguration class >> visualWorks: vwBlock visualAge: vaBlock
[

	self isVisualWorksImage ifTrue: [^vwBlock value].
	self isVisualAgeImage ifTrue: [^vaBlock value].
	^vwBlock value  "Default to VisualWorks block in Pharo"
]

{ #category : 'utilities' }
GbsConfiguration class >> gciVersionString
[
	| ver |
	ver := GbxGciCallSequencer gciVersion.
	^ver copyFrom: 5 to: ver size
]

{ #category : 'instance creation' }
GbsConfiguration class >> new
[
	^super new initialize
]

{ #category : 'instance creation' }
GbsConfiguration class >> current
[
	"Returns an instance of GbsConfiguration describing the current GBS configuration"

	" GbsConfiguration current "

	^Current
]

{ #category : 'instance creation' }
GbsConfiguration class >> default
[
	"Returns an instance of GbsConfiguration describing the default GBS configuration"

	"GbsConfiguration default"

	^self new
]

{ #category : 'constants' }
GbsConfiguration class >> defaultFor: aParameterName 
[
	"answer the default value of aParameterName"

	aParameterName isNil ifTrue: [^nil].
	^Defaults perform: aParameterName asSymbol
]

{ #category : 'constants' }
GbsConfiguration class >> version
[
	"Return version information."

	"	self version.	"

	^(Array new: 5)
		at: 1 put: self gbsCopyright;
		at: 2 put: self gbsBuildName;
		at: 3 put: self gbsBuildTime;
		at: 4 put: self stType;
		at: 5 put: GbxServerVersion current printString;
		yourself
]

{ #category : 'constants' }
GbsConfiguration class >> gbsCopyright
[
	"	self gbsCopyright.	"

	^self gbsMessenger
		print: 'GemBuilder for Smalltalk %1 of %2.\Copyright © 1986-%3 by GemTalk Systems.\All rights reserved.\'
		with: self gbsBuildName
		with: self gbsBuildTime first
		with: self gbsBuildTime first year
]

{ #category : 'stack dumping' }
GbsConfiguration class >> dumpAllProcessStacks
[
	"As of June 2006 we prefer you use the new GbsStackDumper. 
	This method is left for backward compatibility."

	^GbsStackDumper dumpAllProcessStacks
]

