Class {
	#name : 'GbxInspectionWrapperWithSession',
	#superclass : 'GbxInspectionWrapper',
	#instVars : [
		'objectText',
		'delegate',
		'remoteClassName',
		'remoteClass',
		'objectIsClass',
		'maxElements',
		'objectSize',
		'cache',
		'basicCache',
		'session',
		'cachedInspectorClasses'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'GemStone extensions' }
GbxInspectionWrapperWithSession >> gbxIsWrapped
[
	^true
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> basicCache: anObject
[
	basicCache := anObject
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> currentObjectSize
[
	"how many objects have we brought across the wire"

	^self objectSize min: maxElements
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> session
[
	^session
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> delegateInspectorExtraAttributes
[
	"the blocks are so that the derived attributes can update themselves with every entry into the field"

	| derivedAttributes isLoggedIn aSession ws differs loggedBlock sessionBlock clientBlock cachedClient |
	derivedAttributes := OrderedCollection new.
	derivedAttributes add: (Tools.Trippy.TextAttribute label: 'gsOop'
				textBlock: [delegate oopValue printString]).
	loggedBlock :=
			[isLoggedIn := delegate
						debugPrintBasicSessionInfoOn: (ws := String new writeStream).
			ws contents].
	loggedBlock value.
	derivedAttributes
		add: (Tools.Trippy.TextAttribute label: 'session' textBlock: loggedBlock);
		add: (Tools.Trippy.TextAttribute label: 'flags'
					textBlock: [self debugPrintFlags]).
	derivedAttributes
		add: (Tools.Trippy.TextAttribute label: 'isSpecial'
					textBlock: [self debugPrintIsSpecial]);
		add: (Tools.Trippy.TextAttribute label: 'isDefunct'
					textBlock: [self debugPrintIsDefunct]).
	aSession := isLoggedIn
				ifTrue: [delegate noCheckSession]
				ifFalse: 
					[| sess |
					sessionBlock :=
							[ws := String new writeStream.
							sess := delegate debugCurrentSessionPrintOn: ws.
							ws contents].
					sessionBlock value.
					derivedAttributes
						add: (Tools.Trippy.TextAttribute label: 'session' textBlock: sessionBlock).
					sess].
	aSession isNil ifTrue: [^derivedAttributes].
	clientBlock :=
			[cachedClient := aSession sessionCritical: [aSession lookupOop: delegate]
						unlessBlocked: [#blocked].
			ws := String new writeStream.
			cachedClient == #blocked
				ifTrue: 
					[differs := false.
					self debugPrintClientBlocked]
				ifFalse: 
					[cachedClient == NotCachedToken
						ifTrue: 
							[differs := true.
							ws nextPutAll: 'Client does not exist']
						ifFalse: 
							[delegate session sessionCritical: 
									[differs := delegate
												debugPrintCachedClientDiffers: cachedClient
												in: aSession
												on: ws]
								unlessBlocked: 
									[differs := false.
									ws nextPutAll: 'Unretrievable GemStone object']].
					ws contents]].
	clientBlock value.
	derivedAttributes
		add: (Tools.Trippy.TextAttribute label: 'client' textBlock: clientBlock).
	differs ifTrue: [^derivedAttributes].
	derivedAttributes add: (Tools.Trippy.TextAttribute label: 'export'
				textBlock: 
					[self
						debugPrintExportInfoLoggedIn: isLoggedIn
						in: aSession
						cachedClient: cachedClient]).
	derivedAttributes add: (Tools.Trippy.TextAttribute label: 'basic'
				textBlock: [self debugPrintBasicIn: aSession cachedClient: cachedClient]).
	^derivedAttributes
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> size
[
	^self currentObjectSize
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> gbxDoItReceiver
[
	^delegate
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> delegate
[
	^delegate
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> basicSize
[
	"used to make sure the basic tab consistently shows the number
	of indexed variables reported by _basicSize"
	
	objectSize
		ifNil:
			[objectSize := [| sess |
			sess := delegate session.
			sess
				sessionCritical:
					[sess unsynchronizedEvaluate: 'self _basicSize' context: delegate]
				unlessBlocked: [0]]
				on: Error
				do: [:ex | 0]].
	^objectSize
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> remoteClass
[
	^remoteClass
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> objectIsClass: anObject
[
	objectIsClass := anObject
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> session: anObject
[
	session := anObject
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> objectSize
[
	"how many objects are available"
	"if we can't get the semaphore, assume no elements as its the only safe thing to do"
	
	objectSize
		ifNil:
			[objectSize := [| sess |
			sess := delegate session.
			sess
				sessionCritical:
					[sess unsynchronizedEvaluate: 'self size' context: delegate]
				unlessBlocked: [0]]
				on: Error
				do: [:ex | 0]].
	^objectSize
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> objectText
[

	^objectText
		ifNil: [objectText := self session evaluate: 'self asQuadByteString' context: delegate]
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> remoteClassName
[
	^remoteClassName
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> delegate: anObject
[
	delegate := anObject
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> remoteClass: anObject
[
	remoteClass := anObject
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> doItReceiver
[
	"This answer isn't correct, but it's expedient.
	You get into trouble if you return an actual proxy here.
	See bug 39781"
	
	^delegate
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> remoteClassName: anObject
[
	remoteClassName := anObject
]

{ #category : 'accessing' }
GbxInspectionWrapperWithSession >> resetObjectSize
[
	objectSize := nil.
	self cache actualSize: nil.
]

{ #category : 'testing' }
GbxInspectionWrapperWithSession >> isSorted
[
	"assuming we're a collection, is our collection sorted?"

	^cache isSorted
]

{ #category : 'testing' }
GbxInspectionWrapperWithSession >> isUncached
[
	"are we cached in the gs cache?"

	| cachedDelegate cachedProxy |
	cachedDelegate := self session cacheAtST: localObject.
	cachedDelegate isNil ifTrue: [^true].
	cachedProxy := session sessionCritical: 
					[session clientObjForDelegate: cachedDelegate otherwise: 'not there']
				unlessBlocked: [^false].
	^(cachedProxy == localObject) not
]

{ #category : 'testing' }
GbxInspectionWrapperWithSession >> objectIsClass
[
	"if we encounter a problem getting the value, just return false"
	
	objectIsClass isNil
		ifTrue:
			[objectIsClass := self delegate == OIllegal
				ifTrue: [false]
				ifFalse:
					[[self session
						sessionCritical:
							[self session
								unsynchronizedEvaluate:
									' self isNil ifTrue:[^false]. self isBehavior and: [self isMeta not]'
								context: self delegate]
						unlessBlocked: [^false]]
						on: GbsError errorSignal
						do: [:ex | ^false]]].
	^objectIsClass
]

{ #category : 'testing' }
GbxInspectionWrapperWithSession >> isUnretrievable
[

	^remoteClassName isNil
]

{ #category : 'private - inspecting' }
GbxInspectionWrapperWithSession >> critical: criticalBlock unlessBlocked: blockedBlock
[
	^session critical: criticalBlock unlessBlocked: blockedBlock
]

{ #category : 'private - inspecting' }
GbxInspectionWrapperWithSession >> gbxInspectorClasses
[

	| superClassInfo |
	cachedInspectorClasses ifNotNil: [^cachedInspectorClasses].
	remoteClass isNil ifTrue: [^Array new].	"if our session was blocked, we won''t have a remote class"
	(self gbxInspectorClassesDictionary at: remoteClass ifAbsent: []) ifNotNil: [:coll | ^cachedInspectorClasses := coll].
	(self gbxInspectorClassesDictionaryByName at: remoteClassName ifAbsent: []) ifNotNil: [:coll | ^cachedInspectorClasses := coll].
	superClassInfo := remoteClass session unsynchronizedEvaluate: 'self allSuperClasses collect:[:cls | cls name asString -> cls asOop]'
				context: remoteClass.
	superClassInfo do: 
			[:assoc |
			"name -> oop"
			| del |
			del := GbxDelegate oopValue: assoc value session: remoteClass session.
			(self gbxInspectorClassesDictionary at: del ifAbsent: []) ifNotNil: [:coll | ^cachedInspectorClasses := coll].
			(self gbxInspectorClassesDictionaryByName at: assoc key ifAbsent: []) ifNotNil: [:coll | ^cachedInspectorClasses := coll]].
	"Does not inherit from Object, use a basic inspector."
	^Array with: GbxBasicInspector
]

{ #category : 'private - inspecting' }
GbxInspectionWrapperWithSession >> debugPrintClientBlocked
[
	| ws |
	ws := String new writeStream.
	delegate debugPrintBasicClientBlockedOn: ws.
	^ws contents
]

{ #category : 'private - inspecting' }
GbxInspectionWrapperWithSession >> delegatePrintString
[

	| ws |
	ws := String new writeStream.
	delegate gbxDebugPrintOn: ws.
	^ws contents
]

{ #category : 'private - inspecting' }
GbxInspectionWrapperWithSession >> debugPrintBasicIn: aSession cachedClient: client
[
	| ws |
	ws := String new writeStream.
	delegate 
		debugPrintBasicClient: client
		in: aSession
		on: ws.
	^ws contents
]

{ #category : 'private - inspecting' }
GbxInspectionWrapperWithSession >> debugPrintIsSpecial
[
	| ws |
	ws := String new writeStream.
	delegate debugPrintBasicIsSpecialOn: ws.
	^ws contents
]

{ #category : 'private - inspecting' }
GbxInspectionWrapperWithSession >> debugPrintIsDefunct
[
	| ws |
	ws := String new writeStream.
	delegate session critical: [delegate debugPrintBasicIsDefunctOn: ws]
		unlessBlocked: [ws nextPutAll: 'Unretrievable GemStone object'].
	^ws contents
]

{ #category : 'private - inspecting' }
GbxInspectionWrapperWithSession >> debugPrintFlags
[

	| ws |
	ws := String new writeStream.
	delegate debugPrintIsStDirtyOn: ws.
	ws cr.
	delegate debugPrintIsROMObjectOn: ws.
	ws cr.
	delegate debugPrintIsIdentityClampedOn: ws.
	^ws contents
]

{ #category : 'private - inspecting' }
GbxInspectionWrapperWithSession >> gbxOldInspect
[
	^delegate gbxOldInspect
]

{ #category : 'private - inspecting' }
GbxInspectionWrapperWithSession >> debugPrintExportInfoLoggedIn: loggedIn in: aSession cachedClient: client
[
	| ws |
	ws := String new writeStream.
	self critical: 
			[delegate 
				debugPrintBasicExportInfoClient: client
				loggedIn: loggedIn
				in: aSession
				on: ws]
		unlessBlocked: [ws nextPutAll: 'Unretrievable GemStone object'].
	^ws contents
]

{ #category : 'initialize-release' }
GbxInspectionWrapperWithSession >> fetchInitialInfoUsingReflection
[
	"Get the object's class, class name, and whether the object is a (non-meta) class, without sending the object any messages. This way will work even if the object being inspected is a proxy that lies when sent #class, such as a ClientForwarder"

	^delegate session
		unsynchronizedEvaluateBlock: '[:object |
		| gbxArray class |
		gbxArray := Array new: 3.
		class := Reflection classOf: object.
		gbxArray at: 1 put: class asOop.
		gbxArray at: 2 put: class name. 
		gbxArray at: 3 put: ( class isMeta ).
		gbxArray]'
		with: delegate
]

{ #category : 'initialize-release' }
GbxInspectionWrapperWithSession >> initialize
[
	maxElements := 200
]

{ #category : 'initialize-release' }
GbxInspectionWrapperWithSession >> fetchInitialInfo
[
	"initial information that can be learned about the remote object should be done here
	 to minimize round trips and handle elegantly the blocked semaphore case

	Set the following state in myself if possible:
		remoteClass   (delegate)
		remoteClassName (String)
		objectIsClass (Boolean)"

	| result |
	
	[delegate session sessionCritical: 
			[result := self fetchInitialInfoUsingReflection.
			self remoteClass: (GbxDelegate oopValue: (result at: 1) session: session).
			self remoteClassName: (result at: 2) asString.
			self objectIsClass: (result at: 3)]
		unlessBlocked: 
			[self remoteClass: nil.
			self remoteClassName: 'Unretrievable Object'.
			self objectIsClass: false]]
			on: Error
			do: 
				[:ex |
				"we got an error getting class information about the delegate. Use Onil as a key for determining what tabs to show"
				self remoteClass: Onil.
				self remoteClassName: 'Unretrievable Object'.
				self objectIsClass: false].
	^#succeeded
]

{ #category : 'user interface' }
GbxInspectionWrapperWithSession >> gbxInspectorClassesDictionaryByName
[

	^(Dictionary new)
		at: 'CollisionBucket'
			put: (Array with: GbxTrippyDictionaryInspector with: GbxBasicInspector);
		yourself
]

{ #category : 'user interface' }
GbxInspectionWrapperWithSession >> inspect
[
	"added to support old inspectors"

	(Tools.Trippy.Inspector useSimpleInspector not and: [session isNil])
		ifTrue: [delegate inspect]
		ifFalse: [super inspect]
]

{ #category : 'user interface' }
GbxInspectionWrapperWithSession >> gbxInspectorClassesDictionary
[
	^(Dictionary new)
		at: OCharacterCollection
			put: (Array 
					with: GbxTextEditorInspector
					with: GbxArrayInspector
					with: GbxBasicInspector);
		at: OSymbol put: (Array with: GbxArrayInspector with: GbxBasicInspector);
		at: OAbstractDictionary
			put: (Array with: GbxTrippyDictionaryInspector with: GbxBasicInspector);
		at: OIdentityBag
			put: (Array with: GbxIdentityBagInspector with: GbxBasicInspector);
		at: OSequenceableCollection
			put: (Array with: GbxArrayInspector with: GbxBasicInspector);
		at: OCollection put: (Array with: GbxSetInspector with: GbxBasicInspector);
		at: OInterval put: (Array with: GbxBasicInspector);
		at: OObject put: (Array with: GbxBasicInspector);
		at: Onil put: Array new;
		yourself
]

{ #category : 'user interface' }
GbxInspectionWrapperWithSession >> inspectorCollaborators
[

	| oc proceed |
	oc := OrderedCollection new.
	oc add: (Tools.Trippy.Collaborator label: #ToGSClass << #gbs >> 'GS Class'
				block: [GBSM showBusyWhile: [self class on: self remoteClass]]).
	self objectIsClass
		ifTrue: 
			[oc add: (Tools.Trippy.Collaborator
						label: #AllInstances << #gbs >> 'All GS Instances'
						block: 
							[proceed := GbxDialog
										choose: 'This will abort the current transaction. Continue and abort?'
										labels: #('Abort and Go To All Instances?' 'Cancel')
										values: #(true false)
										default: true.
							proceed
								ifTrue: 
									[GBSM showBusyWhile: 
											[GbxInspectionWrapper
												on: (self session unsynchronizedExecute: 'self allInstances asArray'
														context: delegate) asForwarder]]
								ifFalse: [Tools.Trippy.InspectorShell gbxCancelToken]])].
	^oc
]

{ #category : 'user interface' }
GbxInspectionWrapperWithSession >> browse
[

	delegate browseHierarchy
]

{ #category : 'updating' }
GbxInspectionWrapperWithSession >> refreshSet
[
	"hand off to the cache for retrieval"

	self resetObjectSize.
	self objectSize = 0 ifTrue: [^#()].
	self cache refreshSet.
	^self cache elements
]

{ #category : 'updating' }
GbxInspectionWrapperWithSession >> refreshIdentityBag
[
	"force a full refresh of the bag. hand off to the cache for retrieval"

	self resetObjectSize.
	self objectSize = 0 ifTrue: [^#()].
	self cache refreshIdentityBag.
	^self cache elements
]

{ #category : 'updating' }
GbxInspectionWrapperWithSession >> refreshText
[
	self resetObjectSize.
	objectText := nil.
	^self objectText
]

{ #category : 'updating' }
GbxInspectionWrapperWithSession >> refreshDictionary
[
	"hand off to the cache for retrieval"

	self resetObjectSize.
	self objectSize = 0 ifTrue: [^#()].
	self cache refreshDictionary.
	^self cache elements
]

{ #category : 'updating' }
GbxInspectionWrapperWithSession >> refreshBasicSet
[
	"hand off to the cache for retrieval"

	self resetObjectSize.
	self objectSize = 0 ifTrue: [^#()].
	self basicCache refreshSet.
	^self basicCache elements
]

{ #category : 'updating' }
GbxInspectionWrapperWithSession >> refreshArray
[
	"hand off to the cache for retrieval"

	self resetObjectSize.
	(self cache actualSize: self objectSize) = 0 ifTrue: [^#()].
	self cache refreshArray.
	^self cache elements
]

{ #category : 'updating' }
GbxInspectionWrapperWithSession >> refreshBasicArray
[
	"hand off to the cache for retrieval"

	self resetObjectSize.
	self basicSize = 0 ifTrue: [^#()].
	self basicCache refreshArray.
	^self basicCache elements
]

{ #category : 'collections' }
GbxInspectionWrapperWithSession >> cacheDictionaryInterval: anInterval
[
	"cache objects in collection in this interval"

	self cache cacheDictionaryInterval: anInterval
]

{ #category : 'collections' }
GbxInspectionWrapperWithSession >> cachedElements
[
	^self cache elements
]

{ #category : 'collections' }
GbxInspectionWrapperWithSession >> cacheArrayInterval: anInterval
[
	self cache cacheArrayInterval: anInterval
]

{ #category : 'collections' }
GbxInspectionWrapperWithSession >> basicNamedVariablesProtectedBy: protected
[
	| instVarNames nameObjArray values valuePrintStrings result |
	self gbxFixMe.	"protected variables haven't been implemented yet"
	nameObjArray := self session unsynchronizedEvaluateBlock: self variablesSourceString with: delegate.
	instVarNames := nameObjArray at: 1.
	values := (nameObjArray at: 2) collect: [:oop | GbxDelegate oopValue: oop session: self session].
	valuePrintStrings := nameObjArray at: 3.
	result := OrderedCollection new.
	1 to: instVarNames size
		do: 
			[:idx |
			result add: (GbxNamedVariable
						of: delegate
						named: (instVarNames at: idx)
						value: (values at: idx)
						cachedPrintString: (valuePrintStrings at: idx)
						index: idx)].
	^result
]

{ #category : 'collections' }
GbxInspectionWrapperWithSession >> cache
[
	cache isNil ifTrue: [cache := GbxCollectionCache on: delegate].
	^cache
]

{ #category : 'collections' }
GbxInspectionWrapperWithSession >> cachedRanges
[
	"pass the request for cached indices off to the GbxCollectionCache"

	^self cache cachedRanges
]

{ #category : 'collections' }
GbxInspectionWrapperWithSession >> basicCache
[
	^basicCache
]

{ #category : 'collections' }
GbxInspectionWrapperWithSession >> cacheSetInterval: anInterval
[
	"cache objects in collection in this interval"

	self cache cacheSetInterval: anInterval
]

{ #category : 'collections' }
GbxInspectionWrapperWithSession >> cacheIdentityBagInterval: anInterval
[
	self cache cacheIdentityBagInterval: anInterval
]

{ #category : 'collections' }
GbxInspectionWrapperWithSession >> variablesSourceString
[

	^' [:gbxOuterObject | | gbxValues gbxNames gbxValuePrintStrings gbxOuterClass |
	gbxNames := Array new.
	gbxValues := Array new.
	gbxValuePrintStrings := Array new.
	gbxOuterClass := Reflection classOf: gbxOuterObject. 
	1 to: gbxOuterClass allInstVarNames size do: [:i | |  gbxObject gbxClass gbxWriteStream |
		gbxObject := Reflection fetchFrom: gbxOuterObject at: i.
		gbxNames add: (gbxOuterClass allInstVarNames at: i).
		gbxValues add: (Reflection oopOf: gbxObject).
'
				, self class enhancedRemotePrintString
					, '
		gbxValuePrintStrings add: gbxWriteStream contents].
	Array with: gbxNames with: gbxValues with: gbxValuePrintStrings]
'
]

{ #category : 'printing' }
GbxInspectionWrapperWithSession >> uncachedPrintString
[
	"determine if we are looking at an uncached proxy (probably a forwarder)"

	^self isUncached ifFalse: [String new] ifTrue: ['Uncached ']
]

{ #category : 'utility' }
GbxInspectionWrapperWithSession class >> enhancedRemotePrintString
[
	"if the object we want to printString can have some useful info attached, do it here. For convenience, we grab the hex value of chars from the server.
	Expected preface: Declare gbxObject, gbxClass, gbxWriteStream. Set gbxObject to the object you want the print string of.
	Expected epilogue: Use gbxWriteStream, eventually getting its contents."

	^'gbxClass := Reflection classOf: gbxObject.
gbxWriteStream := WriteStream on: String new.
"Use a block so we can declare local temporary variables here."
[| gbxFallbackString gbxOriginalPosition |
gbxOriginalPosition := gbxWriteStream position.
gbxFallbackString := gbxClass asString describeClassName.
(gbxClass canUnderstand: #printOn:)
	ifTrue: 
		[[gbxObject printOn: gbxWriteStream]
			on: Error
			do: [:ex |
				gbxWriteStream position = gbxOriginalPosition
					ifTrue: [gbxWriteStream nextPutAll: gbxFallbackString].
				 gbxWriteStream
					nextPutAll: '' <'';
					print: ex class;
					nextPutAll: '' encountered in #printOn:>'']]
	ifFalse: [gbxWriteStream nextPutAll: gbxFallbackString]] value.
(gbxObject isKindOf: Character)
	ifTrue:
		[gbxWriteStream
			space;
			nextPut: $";
			nextPutAll: (gbxObject asInteger printStringRadix: 16 showRadix: true);
			nextPut: $"].'
]

{ #category : 'private-events' }
GbxInspectionWrapperWithSession class >> constructEventsTriggered
[
	^(super constructEventsTriggered)
		add: #objectChanged;
		yourself
]

