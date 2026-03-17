Class {
	#name : 'GbxBasicCache',
	#superclass : 'GbxCollectionCache',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'building collections' }
GbxBasicCache >> cacheArrayInterval: anInterval
[
	"grab using basicAt: rather than using one of the superclass methods"

	| resultArray newElements delta |
	GBSM showBusyWhile: 
			[resultArray := delegate session
						unsynchronizedEvaluate: '
	| gbxValueNames gbxValues gbxWriteStream gbxClasses gbxClassNames gbxIsClass gbxArray |
	gbxValues := Array new.
	gbxClasses := Array new.
	gbxClassNames := Array new.
	gbxIsClass := Array new.
	'
								, anInterval first printString , ' to: '
								, anInterval last printString
									, ' do:[:idx |
		| obj |
		obj := self _primitiveAt: idx + self class instSize.
		gbxValues add: obj.
		gbxClasses add: obj class asOop.
		gbxClassNames add: obj class name.
		gbxIsClass add: obj class isMeta].		
	gbxValueNames := Array new.
	gbxValues	 do:[:gbxObject | | gbxClass |'
									, GbxInspectionWrapperWithSession enhancedRemotePrintString
									, '
	gbxValueNames add: gbxWriteStream contents.
	].
	gbxValues := gbxValues collect:[:ea | ea asOop].
	gbxArray := Array new.
	gbxArray add: gbxValues;
		add: gbxValueNames;
		add: gbxClasses;
		add: gbxClassNames;
		add: gbxIsClass.
	gbxArray	'
						context: delegate.
			self extractOopInfoFrom: resultArray.
			newElements := ((1 to: valueNames size) collect: 
							[:idx1 |
							| element dlg |
							element := GbxKeyIndexElement
										of: delegate
										at: (anInterval at: idx1)
										value: (dlg := GbxDelegate oopValue: (valueOops at: idx1)
														session: delegate session)
										valueName: (valueNames at: idx1).
							self wrapperFor: dlg element: element index: idx1])
						asOrderedCollection.
			delta := anInterval first - 1.	"delta between array offsets"
			anInterval
				do: [:idx | elements at: idx put: (newElements at: idx - delta)].
			cachedRanges add: anInterval]
]

{ #category : 'accessing' }
GbxBasicCache >> actualSize
[
	"Answer the number of indexed instance variables in
	 the server personality of the inspected object.
	
	RcIdentityBag's on the server actually override _basicSize (which is a no-no), 
	we can't rely on that to return 0. Hence the special case.

	See bugs
	32631 _primitiveSize doesn't report same as gciFetchSize and
	36018 RcIdentityBag can't say 'aaa' very well
	36122 _primitiveAt: fails for RcIdentityBag's
	44312 BadOffset exception when attempting to inspect a server method (change to #asString in GsNMethod name compare)

	GsNMethod instances have a different size if they are loaded in memory which 
	affects the #_basicSize. The unnamed inst vars are not useful as they are just
	encoded integers. "

	actualSize isNil
		ifTrue: 
			[actualSize := delegate session
						unsynchronizedEvaluate: '
				((self isKindOf: RcIdentityBag) or:[self class name asString = ''GsNMethod'' "cannot just test class because GsNMethod is not defined in 32-bit servers"]) 
					ifTrue:[0]
					ifFalse:[self _basicSize]'
						context: delegate].
	^actualSize
]

