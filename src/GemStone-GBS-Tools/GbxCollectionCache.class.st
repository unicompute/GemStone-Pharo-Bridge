Class {
	#name : 'GbxCollectionCache',
	#superclass : 'Object',
	#instVars : [
		'elements',
		'delegate',
		'actualSize',
		'initialBufferSize',
		'cachedRanges',
		'valueOops',
		'valueNames',
		'classOops',
		'classNames',
		'isClass',
		'keyOops',
		'keyNames',
		'keyClassOops',
		'keyClassNames',
		'keyIsClass'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'execution strings' }
GbxCollectionCache >> setExecutionString: anInterval 
	"The general algorithm for larger collections is to iterate over the collection using a do: loop starting at 1 each time. When we get within the interval window, suck out the elements until we're outside the window again. Then return immediately. This avoids the penalty of creating a temporary sequenceable object which could get stuck onto disk.
	"

	^'|  gbxValueNames gbxValues gbxObject gbxCounter gbxWriteStream gbxClass gbxClasses gbxClassNames gbxIsClass gbxArray| 
	
	gbxValues := Array new.
	gbxValueNames := Array new.
	gbxClasses := Array new.
	gbxClassNames := Array new.
	gbxIsClass := Array new.
	gbxCounter := 0.
	self do:[:gbxObject |
		gbxCounter := gbxCounter + 1.
		(gbxCounter >= ' 
		, anInterval first printString , ' and:[gbxCounter <= ' 
		, anInterval last printString , ']) ifTrue:[
			gbxValues add: gbxObject.
			' 
		, GbxInspectionWrapperWithSession enhancedRemotePrintString 
			, '
			gbxValueNames add: gbxWriteStream contents.
			gbxClasses add: gbxObject class asOop.
			gbxClassNames add: gbxObject class name.
			gbxIsClass add: gbxObject class isMeta]
		ifFalse:[(gbxCounter > ' 
			, anInterval last printString 
			, ' ) ifTrue:[gbxArray := Array new.
						gbxArray add: (gbxValues collect:[:ea | ea asOop]);
						add: gbxValueNames;
						add: gbxClasses;
						add: gbxClassNames;
						add: gbxIsClass.
						^gbxArray]].
		].
	gbxValues := gbxValues collect:[:ea | ea asOop].
	gbxArray := Array new.
	gbxArray add: gbxValues;
		add: gbxValueNames;
		add: gbxClasses;
		add: gbxClassNames;
		add: gbxIsClass.
	gbxArray
'

{ #category : 'execution strings' }
GbxCollectionCache >> sortedExecutionString: anInterval
	"sort anything less than 2000 elements, nothing larger for performance and page size reasons. "

	^'| gbxValueNames gbxValues gbxObject gbxClass gbxWriteStream gbxXPrintString gbxYPrintString gbxClasses gbxClassNames gbxIsClass gbxArray |
		gbxClasses := Array new.
		gbxClassNames := Array new.
		gbxIsClass := Array new.
		gbxValues := self asSortedCollection:[:x :y | 
			gbxObject := x.  
			'
		, GbxInspectionWrapperWithSession enhancedRemotePrintString
			, '
			gbxXPrintString := gbxWriteStream contents.
			gbxObject := y. 
			'
			, GbxInspectionWrapperWithSession enhancedRemotePrintString
			, '
			gbxYPrintString := gbxWriteStream contents. 
			gbxXPrintString <= gbxYPrintString].
		gbxValueNames := Array new. 
		gbxValues := gbxValues asArray.
		gbxValues do:[:gbxObject | 
		'
			, GbxInspectionWrapperWithSession enhancedRemotePrintString
			, '
			gbxValueNames add: gbxWriteStream contents.
			gbxClasses add: gbxObject class asOop.
			gbxClassNames add: gbxObject class name.
			gbxIsClass add: gbxObject class isMeta
			].
	gbxValues := gbxValues collect:[:ea | ea asOop].
	gbxArray := Array new.
	gbxArray add: gbxValues;
		add: gbxValueNames;
		add: gbxClasses;
		add: gbxClassNames;
		add: gbxIsClass.
	gbxArray'

{ #category : 'execution strings' }
GbxCollectionCache >> arrayExecutionString: anInterval 
	^'
	| gbxValueNames gbxValues gbxDiff gbxObject gbxWriteStream gbxClass gbxClasses gbxClassNames gbxIsClass gbxArray  |
	gbxValueNames := Array new: ' 
		, anInterval size printString , '.
	gbxValues := Array new: ' 
		, anInterval size printString , '.
	gbxClasses := Array new: ' 
		, anInterval size printString , '.
	gbxClassNames := Array new: ' 
		, anInterval size printString , '.
	gbxIsClass := Array new: ' 
		, anInterval size printString , '.
	gbxDiff := ' 
		, anInterval first printString , ' - 1.
	' 
		, anInterval first printString , ' to: ' 
		, anInterval last printString , ' do:[:idx |
		gbxObject := self _at: idx.
		' 
		, GbxInspectionWrapperWithSession enhancedRemotePrintString 
			, '
		gbxValueNames at: idx - gbxDiff put: gbxWriteStream contents.
		gbxValues at: idx - gbxDiff put: gbxObject asOop.
		gbxClasses at: idx - gbxDiff put: gbxObject class asOop.
		gbxClassNames at: idx - gbxDiff put: gbxObject class name.
		gbxIsClass at: idx - gbxDiff put: gbxObject class isMeta. ].
	gbxArray := Array new.
	gbxArray add: gbxValues;
		add: gbxValueNames;
		add: gbxClasses;
		add: gbxClassNames;
		add: gbxIsClass.
	gbxArray
	'

{ #category : 'execution strings' }
GbxCollectionCache >> sortedDictionaryExecutionString: anInterval 
	"sort anything less than 2000 keys, nothing larger for performance and page size reasons. "

	^'| gbxKeys gbxKeyNames gbxValueNames gbxValues gbxObject gbxClass gbxWriteStream gbxXPrintString gbxYPrintString 
		gbxSortedCollection gbxValueClasses gbxValueClassNames gbxValueIsClass gbxKeyClasses gbxKeyClassNames gbxKeyIsClass gbxArray |
	gbxSortedCollection := SortedCollection sortBlock: [:x :y |
		gbxObject := x.  
		' 
		, GbxInspectionWrapperWithSession enhancedRemotePrintString 
			, '
		gbxXPrintString := gbxWriteStream contents.
		gbxObject := y. 
		' 
			, GbxInspectionWrapperWithSession enhancedRemotePrintString 
			, '
		gbxYPrintString := gbxWriteStream contents. 
		gbxXPrintString <= gbxYPrintString].
	self keysDo:[:key | gbxSortedCollection add: key].
	gbxKeys := gbxSortedCollection. 
	gbxKeyNames := Array new. 
	gbxValueNames := Array new. 
	gbxValues := Array new.
	gbxValueClasses := Array new.
	gbxValueClassNames := Array new.
	gbxValueIsClass := Array new.
	gbxKeyClasses := Array new.
	gbxKeyClassNames := Array new.
	gbxKeyIsClass := Array new.
	gbxKeys do:[:each | 
		gbxObject := each. 
		' 
			, GbxInspectionWrapperWithSession enhancedRemotePrintString 
			, '
		gbxKeyNames add: gbxWriteStream contents.
		gbxKeyClasses add: gbxObject class asOop.
		gbxKeyClassNames add: gbxObject class name.
		gbxKeyIsClass add: gbxObject class isMeta.
		gbxObject := self at: each.
		gbxValues add: gbxObject.
		' 
			, GbxInspectionWrapperWithSession enhancedRemotePrintString 
			, '
		gbxValueNames add: gbxWriteStream contents.
		gbxValueClasses add: gbxObject class asOop.
		gbxValueClassNames add: gbxObject class name.
		gbxValueIsClass add: gbxObject class isMeta.]. 
	gbxKeys := gbxKeys collect:[:ea | ea asOop].
	gbxValues := gbxValues collect:[:ea | ea asOop].
	gbxArray := Array new.
	gbxArray add: gbxKeys;
		add: gbxKeyNames;
		add: gbxKeyClasses;
		add: gbxKeyClassNames;
		add: gbxKeyIsClass;
		add: gbxValues;
		add: gbxValueNames;
		add: gbxValueClasses;
		add: gbxValueClassNames;
		add: gbxValueIsClass.
		^gbxArray	
'

{ #category : 'execution strings' }
GbxCollectionCache >> dictionaryExecutionString: anInterval 
	"see #setExecutionString: comments for algorithm explanation. This is very similar, except we return delegates and printStrings for the keys as well."

	^'|  gbxKeys gbxKeyNames gbxValueNames gbxValues gbxWriteStream gbxObject gbxClass gbxCounter 
	gbxValueClasses gbxValueClassNames gbxValueIsClass gbxKeyClasses gbxKeyClassNames gbxKeyIsClass gbxArray | 
	gbxKeys := Array new.
	gbxKeyNames := Array new.
	gbxValues := Array new.
	gbxValueNames := Array new.
	gbxValueClasses := Array new.
	gbxValueClassNames := Array new.
	gbxValueIsClass := Array new.
	gbxKeyClasses := Array new.
	gbxKeyClassNames := Array new.
	gbxKeyIsClass := Array new.
	gbxCounter := 0.
	self keysDo:[:each |	 
		gbxCounter := gbxCounter + 1.
		(gbxCounter >= ' 
		, anInterval first printString , ' and:[gbxCounter <= ' 
		, anInterval last printString 
			, ']) ifTrue:[
			gbxObject := each.
			gbxKeys add: gbxObject asOop. 
			gbxKeyClasses add: gbxObject class asOop.
			gbxKeyClassNames add: gbxObject class name.
			gbxKeyIsClass add: gbxObject class isMeta.
			' 
			, GbxInspectionWrapperWithSession enhancedRemotePrintString 
			, '
			gbxKeyNames add: gbxWriteStream contents.
			gbxObject := self at: each.
			gbxValues add: gbxObject asOop.
			' 
			, GbxInspectionWrapperWithSession enhancedRemotePrintString 
			, '
			gbxValueNames add: gbxWriteStream contents.
			gbxValueClasses add: gbxObject class asOop.
			gbxValueClassNames add: gbxObject class name.
			gbxValueIsClass add: gbxObject class isMeta.]
		ifFalse:[(gbxCounter > ' 
			, anInterval last printString 
			, ' ) ifTrue:[	gbxArray := Array new.
						gbxArray add: gbxKeys;
						add: gbxKeyNames;
						add: gbxKeyClasses;
						add: gbxKeyClassNames;
						add: gbxKeyIsClass;
						add: gbxValues;
						add: gbxValueNames;
						add: gbxValueClasses;
						add: gbxValueClassNames;
						add: gbxValueIsClass.
						^gbxArray]].
		].
	gbxArray := Array new.
	gbxArray add: gbxKeys;
		add: gbxKeyNames;
		add: gbxKeyClasses;
		add: gbxKeyClassNames;
		add: gbxKeyIsClass;
		add: gbxValues;
		add: gbxValueNames;
		add: gbxValueClasses;
		add: gbxValueClassNames;
		add: gbxValueIsClass.
		^gbxArray
'

{ #category : 'accessing' }
GbxCollectionCache >> classNames

	^classNames

{ #category : 'accessing' }
GbxCollectionCache >> keyClassOops

	^keyClassOops

{ #category : 'accessing' }
GbxCollectionCache >> delegate

	^delegate

{ #category : 'accessing' }
GbxCollectionCache >> keyIsClass

	^keyIsClass

{ #category : 'accessing' }
GbxCollectionCache >> keyNames

	^keyNames

{ #category : 'accessing' }
GbxCollectionCache >> keyOops

	^keyOops

{ #category : 'accessing' }
GbxCollectionCache >> valueNames

	^valueNames

{ #category : 'accessing' }
GbxCollectionCache >> actualSize
	
	actualSize isNil
		ifTrue:
			[actualSize := delegate session evaluate: 'self size' context: delegate].
	^actualSize

{ #category : 'accessing' }
GbxCollectionCache >> delegate: anObject
	delegate := anObject

{ #category : 'accessing' }
GbxCollectionCache >> actualSize: anObject
	actualSize := anObject

{ #category : 'accessing' }
GbxCollectionCache >> valueOops

	^valueOops

{ #category : 'accessing' }
GbxCollectionCache >> cachedRanges
	"return an array of intervals representing slots in the collection which we should or have returned. This should be an initial range (1..n) and any ranges the user has selected"

	^cachedRanges

{ #category : 'accessing' }
GbxCollectionCache >> classOops

	^classOops

{ #category : 'accessing' }
GbxCollectionCache >> initialBufferSize

	^initialBufferSize

{ #category : 'accessing' }
GbxCollectionCache >> elements
	^elements

{ #category : 'accessing' }
GbxCollectionCache >> isClass

	^isClass

{ #category : 'accessing' }
GbxCollectionCache >> keyClassNames

	^keyClassNames

{ #category : 'testing' }
GbxCollectionCache >> isSorted
	"for collections where we sort on small collections"

	^self actualSize <= 2000

{ #category : 'private' }
GbxCollectionCache >> extractValueObjectsFrom: fetchedValues for: anInterval
	
	^((fetchedValues at: 1) session
		unsynchronizedEvaluate: 'self class isBytes'
		context: (fetchedValues at: 1))
		ifTrue:
			[(fetchedValues at: 1)
				fetch: anInterval size
				bytesAt: 1]
		ifFalse:
			[(fetchedValues at: 1)
				fetch: anInterval size
				OOPsAt: 1]

{ #category : 'caching' }
GbxCollectionCache >> cacheDictionaryInterval: anInterval executionString: aString isSorted: isSorted
	"Errors can occur during the fetch. Handle any unhandlable errors by informing the user that
	the collection cannot be retrieved."

	| resultArray newElements delta |
	
	[resultArray := delegate session unsynchronizedEvaluate: aString
				context: delegate.
	self extractDictionaryOopInfoFrom: resultArray.
	delta := anInterval first - 1.	"delta between array offsets"
	newElements := (1 to: keyNames size) collect: 
					[:idx |
					| keyText textIndex element dlg |
					isSorted
						ifTrue: [keyText := keyNames at: idx]
						ifFalse: 
							[keyText := Text
										fromString: (idx + delta) printString , ': ' , (keyNames at: idx).
							textIndex := keyText indexOf: Character space.
							keyText
								emphasizeFrom: 1
								to: textIndex
								with: (Array with: #bold)].
					element := GbxKeyedElement
								of: delegate
								key: (GbxDelegate oopValue: (keyOops at: idx) session: delegate session)
								keyName: keyText
								value: (dlg := GbxDelegate oopValue: (valueOops at: idx)
												session: delegate session)
								valueName: (valueNames at: idx).
					self wrapperFor: dlg element: element index: idx].
	anInterval
		do: [:idx | elements at: idx put: (newElements at: idx - delta)].
	cachedRanges add: anInterval]
			on: GbsError hostErrorSignal
			do: 
				[:ex |
				cachedRanges := OrderedCollection with: (Interval from: 1 to: 1).
				elements := Array new: 1.
				elements at: 1
					put: (Tools.Trippy.DerivedAttribute
							label: 'An error occured trying to access the object'
							value: ex)]

{ #category : 'caching' }
GbxCollectionCache >> extractDictionaryOopInfoFrom: resultArray

	keyOops := resultArray at: 1.
	keyNames := resultArray at: 2.
	keyClassOops := resultArray at: 3.
	keyClassNames := resultArray at: 4.
	keyIsClass := resultArray at: 5.
	valueOops := resultArray at: 6.
	valueNames := resultArray at: 7.
	classOops := resultArray at: 8.
	classNames := resultArray at: 9.
	isClass := resultArray at: 10

{ #category : 'caching' }
GbxCollectionCache >> cacheDictionaryInterval: anInterval 
	GBSM showBusyWhile: 
			[self 
				cacheDictionaryInterval: anInterval
				executionString: (self isSorted 
						ifTrue: [self sortedDictionaryExecutionString: anInterval]
						ifFalse: [self dictionaryExecutionString: anInterval])
				isSorted: self isSorted]

{ #category : 'caching' }
GbxCollectionCache >> dictionaryWrapperFor: dlg element: element index: idx1

	| wrapper |
	wrapper := GbxReplicateInspectionWrapper new.
	wrapper
		delegate: dlg;
		inspectedObject: dlg.
	wrapper remoteClass: (GbxDelegate oopValue: (classOops at: idx1)
				session: delegate session).
	wrapper remoteClassName: (classNames at: idx1).
	wrapper inspectedObject: dlg.
	wrapper objectIsClass: (isClass at: idx1).
	wrapper session: delegate session.
	wrapper localObject: (wrapper class
				findLocalObjectFromObject: delegate
				delegate: delegate
				sesssion: delegate session).
	element valueDelegate: wrapper.
	^element

{ #category : 'caching' }
GbxCollectionCache >> cacheSetInterval: anInterval 
	"gather up the set elements indexed within the interval. Sort if our array meets the criteria for sorting which is, basically, small collections"

	GBSM showBusyWhile: 
			[self 
				cacheInterval: anInterval
				executionString: (self isSorted 
						ifTrue: [self sortedExecutionString: anInterval]
						ifFalse: [self setExecutionString: anInterval])
				isSorted: self isSorted]

{ #category : 'caching' }
GbxCollectionCache >> cacheArrayInterval: anInterval 
	"gather up the array elements indexed within the interval. never sort sequenceable collections. They already have an order"

	GBSM showBusyWhile: 
			[self 
				cacheInterval: anInterval
				executionString: (self arrayExecutionString: anInterval)
				isSorted: false]

{ #category : 'caching' }
GbxCollectionCache >> cacheInterval: anInterval executionString: aString isSorted: isSorted
	"used for IdentityBags and Sequencable collections. Pass in if it is being sorted or not.
	Errors can occur during the fetch. Handle any unhandlable errors by informing the user that
	the collection cannot be retrieved."

	| resultArray newElements delta |
	
	[resultArray := delegate session unsynchronizedEvaluate: aString
				context: delegate.
	self extractOopInfoFrom: resultArray.
	delta := anInterval first - 1.	"delta between array offsets"
	newElements := ((1 to: valueNames size) collect: 
					[:idx1 |
					| element dlg |
					element := GbxKeyIndexElement
								of: delegate
								at: (isSorted ifTrue: [valueNames at: idx1] ifFalse: [idx1 + delta])
								value: (dlg := GbxDelegate oopValue: (valueOops at: idx1)
												session: delegate session)
								valueName: (valueNames at: idx1).
					self wrapperFor: dlg element: element index: idx1])
				asOrderedCollection.
	anInterval
		do: [:idx | elements at: idx put: (newElements at: idx - delta)].
	cachedRanges add: anInterval]
			on: GbsError hostErrorSignal
			do: 
				[:ex |
				cachedRanges := OrderedCollection with: (Interval from: 1 to: 1).
				elements := Array new: 1.
				elements at: 1
					put: (Tools.Trippy.DerivedAttribute
							label: 'An error occured trying to access the object'
							value: (Array with: ex with: ex messageText))]

{ #category : 'caching' }
GbxCollectionCache >> wrapperFor: dlg element: element index: idx1

	| wrapper |
	wrapper := GbxReplicateInspectionWrapper new.
	wrapper
		delegate: dlg;
		inspectedObject: dlg.
	wrapper remoteClass: (GbxDelegate oopValue: (classOops at: idx1)
				session: delegate session).
	wrapper remoteClassName: (classNames at: idx1) asString.
	wrapper inspectedObject: dlg.
	wrapper objectIsClass: (isClass at: idx1).
	wrapper session: delegate session.
	wrapper localObject: (wrapper class
				findLocalObjectFromObject: delegate
				delegate: delegate
				sesssion: delegate session).
	element valueDelegate: wrapper.
	^element

{ #category : 'caching' }
GbxCollectionCache >> cacheIdentityBagInterval: anInterval 
	"gather up the bag's elements indexed within the interval. bags are never sorted."

	GBSM showBusyWhile: 
			[self 
				cacheInterval: anInterval
				executionString: (self arrayExecutionString: anInterval)
				isSorted: self isSorted]

{ #category : 'caching' }
GbxCollectionCache >> extractOopInfoFrom: resultArray

	valueOops := resultArray at: 1.
	valueNames := resultArray at: 2.
	classOops := resultArray at: 3.
	classNames := resultArray at: 4.
	isClass := resultArray at: 5

{ #category : 'initialize-release' }
GbxCollectionCache >> initialize
	initialBufferSize := 2000.
	cachedRanges := OrderedCollection with: (1 to: initialBufferSize).

{ #category : 'initialize-release' }
GbxCollectionCache >> initializeElements
	elements := Array new: self actualSize.
	1 to: self actualSize do: [:idx | elements at: idx put: idx]

{ #category : 'updating' }
GbxCollectionCache >> refreshDictionary
	"recache everything from scratch"

	self initializeElements.
	^self 
		cacheDictionaryInterval: (1 to: (initialBufferSize min: self actualSize))

{ #category : 'updating' }
GbxCollectionCache >> refreshIdentityBag
	"recache everything from scratch"

	self initializeElements.
	^self 
		cacheIdentityBagInterval: (1 to: (initialBufferSize min: self actualSize))

{ #category : 'updating' }
GbxCollectionCache >> refreshArray
	"recache everything from scratch"

	self initializeElements.
	^self cacheArrayInterval: (1 to: (initialBufferSize min: self actualSize))

{ #category : 'updating' }
GbxCollectionCache >> refreshSet
	"recache everything from scratch"

	self initializeElements.
	^self cacheSetInterval: (1 to: (initialBufferSize min: self actualSize))

{ #category : 'instance creation' }
GbxCollectionCache class >> on: aGbsObject 
	^self new initialize delegate: aGbsObject

