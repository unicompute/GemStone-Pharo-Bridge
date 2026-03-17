Class {
	#name : #'GbxServerVersion',
	#superclass : #'GbxVersionNumber',
	#instVars : [ #'productCode' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'testing' }
GbxServerVersion >> atLeast64v35

	^self isGemStone64 and: [self >= '3.5']

{ #category : #'testing' }
GbxServerVersion >> isGemStone64
	^productCode == 3

{ #category : #'testing' }
GbxServerVersion >> atLeast64v32

	^self isGemStone64 and: [self >= '3.2']

{ #category : #'testing' }
GbxServerVersion >> is64v350

	^self isGemStone64 and: [self = '3.5.0']

{ #category : #'testing' }
GbxServerVersion >> atLeast64v372

	^self isGemStone64 and: [self >= '3.7.2']

{ #category : #'testing' }
GbxServerVersion >> atLeast64v37

	^self isGemStone64 and: [self >= '3.7']

{ #category : #'testing' }
GbxServerVersion >> supportsImmediateTimes
	"Support for SmallDate, SmallTime, SmallDateAndTime, and SmallScaledDecimal
	was added in GS64 3.6.0. Use this test method for all of these."

	^self atLeast64v36

{ #category : #'testing' }
GbxServerVersion >> atLeast64v36

	^self isGemStone64 and: [self >= '3.6']

{ #category : #'testing' }
GbxServerVersion >> isUnknown
	"Answer true if the server version cannot be determined."

	^false

{ #category : #'limits' }
GbxServerVersion >> largestOop

	^self largestOop64Bit

{ #category : #'limits' }
GbxServerVersion >> largestOop64Bit

	^2 ** 40 - 1

{ #category : #'printing' }
GbxServerVersion >> printOn: aStream 
	productCode isNil 
		ifTrue: [aStream nextPutAll: 'Unknown server product ']
		ifFalse: 
			[aStream 
				nextPutAll: (#('Unsupported ' 'Unsupported ' 'GemStone/S 64-bit ') 
						at: productCode)].
	super printOn: aStream

{ #category : #'private' }
GbxServerVersion >> productCode: anInteger 
	productCode := anInteger

{ #category : #'class initialization' }
GbxServerVersion class >> initialize
	"Current server version must be reset to nil on image startup."

	Current := nil

{ #category : #'private - instance creation' }
GbxServerVersion class >> unknown
	^GbxUnknownServerVersion new

{ #category : #'instance creation' }
GbxServerVersion class >> initializeCurrentFromProductCode: anInteger version: aString
	"Product code 0 and nil version string mean we don't have the library loaded,
	 so answer an UnknownServerVersion.
	 Otherwise initialize the shared variable from the two."

	| productCode versionCode versionString |
	productCode := anInteger.
	versionCode := aString.
	versionCode == nil ifTrue: [^self unknown].
	versionString := versionCode copyFrom: 5 to: versionCode size.
	productCode == 0 ifTrue: [productCode := (self versionString: versionString) > '3' ifTrue: [1] ifFalse: [2]].
	Current := (self versionString: versionString) productCode: productCode.
	^Current

{ #category : #'instance creation' }
GbxServerVersion class >> debugCurrent
	"GbxServerVersion debugCurrent"
	"For debug use, avoid initializing GBSM's C interface.
	If there's no C interface, answer an UnknownServerVersion"

	Current == nil
		ifTrue: 
			[^self
				initializeCurrentFromProductCode: GbxGciCallSequencer noLoadGciProduct
				version: GbxGciCallSequencer noLoadGciVersion].
	^Current

{ #category : #'instance creation' }
GbxServerVersion class >> current
	"GbxServerVersion current"
	"May load the library if it's not loaded."

	Current == nil
		ifTrue: 
			[GbxGciCallSequencer primInterface.
			^self debugCurrent].
	^Current

