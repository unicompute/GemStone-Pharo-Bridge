Class {
	#name : 'GbxOverrideUtility',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'applying' }
GbxOverrideUtility class >> applyOverrideSet: anOverrideSet [
	(anOverrideSet isNil or: [ anOverrideSet hasNoEffect ]) ifTrue: [ ^ nil ].
	^ anOverrideSet apply
		ifTrue: [ anOverrideSet ]
		ifFalse: [ nil ]
]

{ #category : 'accessing' }
GbxOverrideUtility class >> allOverridesInPackage: aPackage [
	"VisualWorks uses Store package override metadata here. Pharo does not expose an
	 equivalent installed-override model, so generation from a package currently
	 answers no overrides instead of inventing false data."
	^ #()
]

{ #category : 'utilities' }
GbxOverrideUtility class >> crc32OfString: aString [
	| crc polynomial bytes |
	polynomial := 16rEDB88320.
	bytes := (aString isKindOf: ByteArray)
		ifTrue: [ aString ]
		ifFalse: [ aString asString asGemStoneUTF8Bytes ].
	crc := 16rFFFFFFFF.
	bytes do: [ :byte |
		crc := (crc bitXor: byte asInteger) bitAnd: 16rFFFFFFFF.
		1 to: 8 do: [ :ignored |
			crc := ((crc bitAnd: 1) = 1
				ifTrue: [ ((crc bitShift: -1) bitXor: polynomial) ]
				ifFalse: [ crc bitShift: -1 ]) bitAnd: 16rFFFFFFFF ] ].
	^ (crc bitXor: 16rFFFFFFFF) bitAnd: 16rFFFFFFFF
]

{ #category : 'utilities' }
GbxOverrideUtility class >> prepareOverridesForRelease [
	"Release preparation in VisualWorks depends on Store-managed override packages.
	 Pharo does not use that mechanism, so this is intentionally a no-op."
	^ false
]

{ #category : 'accessing' }
GbxOverrideUtility class >> resolvePackageName: aPackageName ifFail: failBlock [
	(aPackageName isNil or: [ aPackageName asString isEmpty ]) ifTrue: [ ^ failBlock value ].
	^ aPackageName asString
]
