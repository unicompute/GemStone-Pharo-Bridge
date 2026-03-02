Class {
	#name : 'GbsProxy',
	#superclass : 'ProtoObject',
	#instVars : [
		'oop',
		'session',
		'executor'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'as yet unclassified' }
GbsProxy class >> oop: anInteger session: aGbsSession [

  | proxy |
  proxy := self basicNew.
  proxy oop: anInteger.
  proxy session: aGbsSession.
  ^ proxy
]

{ #category : 'comparing' }
GbsProxy >> = anObject [ ^ self == anObject
]

{ #category : 'comparing' }
GbsProxy >> == anObject [
  "Direct identity check using the Pharo identity primitive"

  <primitive: 110>
  ^ ( anObject isMemberOf: GbsProxy ) and: [
      self oop = anObject oop and: [ self session == anObject session ] ]
]

{ #category : 'conve' }
GbsProxy >> asLocalString [
	"Forces the GemStone server to convert this object to a String, 
	 and then brings those characters across the FFI boundary into a native Pharo String."
	
	| script |
	"We use _objectForOop: to look up the exact object on the server, then send it #asString"
	script := '(Object _objectForOop: ', self oop printString, ') asString'.
	
	"Because session evaluate: uses fetchObject:, the resulting GemStone string 
	 will be automatically unboxed into a Pharo ByteString/WideString!"
	^ self session evaluate: script.
]

{ #category : 'class membership' }
GbsProxy >> class [

  ^ GbsProxy
]

{ #category : 'printing' }
GbsProxy >> doesNotUnderstand: aMessage [
  "Only forward if we have an active session"

  session ifNil: [ ^ super doesNotUnderstand: aMessage ].

  ^ session forwardRemoteMessage: aMessage forOop: self oop
]

{ #category : 'accessing' }
GbsProxy >> executor [

	^ executor
]

{ #category : 'accessing' }
GbsProxy >> executor: anObject [

	executor := anObject
]

{ #category : 'comparing' }
GbsProxy >> hash [ ^ self identityHash
]

{ #category : 'comparing' }
GbsProxy >> identityHash [
    <primitive: 75>
    ^ self oop hash
]

{ #category : 'testing' }
GbsProxy >> ifNil: aBlock [ ^ self
]

{ #category : 'testing' }
GbsProxy >> ifNotNil: aBlock [ ^ aBlock cull: self
]

{ #category : 'inspector' }
GbsProxy >> inspectionRemoteState [

  <inspectorPresentationOrder: 1 title: 'Remote State'>
  | stateString dict lines |
  "Ask GemStone to format the object's class name and instance variables into a key=value string"
  stateString := self session evaluate: '
		| obj strm vars |
		obj := Object _objectForOop: ' , self oop printString , '.
		strm := WriteStream on: String new.
		strm nextPutAll: ''[Class]=''; nextPutAll: obj class name asString; nextPut: Character lf.
		
		vars := obj class allInstVarNames.
		1 to: vars size do: [:i |
			strm nextPutAll: (vars at: i) asString; nextPutAll: ''=''; nextPutAll: (obj instVarAt: i) printString; nextPut: Character lf.
		].
		strm contents
	'.

  "Parse the string back into Pharo associations"
  lines := stateString lines.
  dict := OrderedCollection new.
  dict addAll: ( lines select: [ :line |
          | parts |
          parts := line splitOn: '='.
          parts size = 2
          ] ).
  ^ SpTablePresenter new
      addColumn: ( SpStringTableColumn title: 'Variable' evaluated: [ :assoc | assoc key ] );
      addColumn: ( SpStringTableColumn title: 'Remote Value' evaluated: [ :assoc | assoc value ] );
      items: dict;
      yourself
]

{ #category : 'printing' }
GbsProxy >> inspectorClass [ ^ Smalltalk at: #StInspector ifAbsent: [ self class ]
]

{ #category : 'testing' }
GbsProxy >> isKindOf: aClass [
	"Shield this from doesNotUnderstand:"
	^ (GbsProxy == aClass) or: [ GbsProxy inheritsFrom: aClass ]
]

{ #category : 'testing' }
GbsProxy >> isMemberOf: aClass [
	^ GbsProxy == aClass
]

{ #category : 'testing' }
GbsProxy >> isNil [

  ^ false
]

{ #category : 'testing' }
GbsProxy >> isNotNil [ ^ true
]

{ #category : 'accessing' }
GbsProxy >> oop [

	^ oop
]

{ #category : 'accessing' }
GbsProxy >> oop: anObject [

	oop := anObject
]

{ #category : 'printing' }
GbsProxy >> printOn: aStream [ 
	aStream nextPutAll: 'aGbsProxy(oop: '; print: self oop; nextPut: $)
]

{ #category : 'printing' }
GbsProxy >> printString [ ^ String streamContents: [ :s | self printOn: s ]
]

{ #category : 'class membership' }
GbsProxy >> respondsTo: aSymbol [ ^ GbsProxy includesSelector: aSymbol
]

{ #category : 'accessing' }
GbsProxy >> session [

	^ session
]

{ #category : 'accessing' }
GbsProxy >> session: anObject [

	session := anObject
]

{ #category : 'printing' }
GbsProxy >> stDisplayString [

  ^ self printString
]

{ #category : 'class membership' }
GbsProxy >> yourself [

  ^ self
]
