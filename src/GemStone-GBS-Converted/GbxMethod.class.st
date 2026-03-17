Class {
	#name : 'GbxMethod',
	#superclass : 'Object',
	#instVars : [
		'methodDelegate',
		'classDelegate',
		'selector',
		'className'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'TEMPORARY' }
GbxMethod >> doesNotUnderstand: aMessage 
	"If I don't understand a message, send it to my delegate. "

	self gbxFixMe.	"Should implement methods for all places this is being used."
	^methodDelegate perform: aMessage selector withArguments: aMessage arguments

{ #category : 'accessing' }
GbxMethod >> gbxSelector

	^selector

{ #category : 'accessing' }
GbxMethod >> homeMethod
	^self

{ #category : 'accessing' }
GbxMethod >> methodDelegate

	^methodDelegate

{ #category : 'accessing' }
GbxMethod >> fetchClassAndSelector

	| sess array |
	sess := methodDelegate session.
	array := sess
				unsynchronizedEvaluate: '| result | result := Array new: 2. result at: 1 put: self inClass asOop. result at: 2 put: self selector. ^result.'
				context: methodDelegate.
	classDelegate := GbxDelegate oopValue: (array at: 1) session: sess.
	selector := array at: 2

{ #category : 'accessing' }
GbxMethod >> methodClass

	^self classDelegate

{ #category : 'accessing' }
GbxMethod >> classDelegate

	^classDelegate

{ #category : 'accessing' }
GbxMethod >> className

	^className

{ #category : 'testing' }
GbxMethod >> isDoit
	"if this is a user action, the delegate will be oopNil."

	^self methodClass = methodDelegate session oopNil

{ #category : 'testing' }
GbxMethod >> isResident
	"Envy methods respond to this message to mean the
	 method is executable in the current image.  GemStone
	 methods are executable as long as the session is
	 logged in."

	^methodDelegate sessionIsLoggedIn

{ #category : 'remote execution' }
GbxMethod >> performOnGsServer: aSymbol

	^methodDelegate performOnGsServer: aSymbol

{ #category : 'source code' }
GbxMethod >> environment
	"Answer the NameSpace in which this compiled code
	was compiled.  If not known, answer nil. Added for VW5i
	namespaces."

	^nil

{ #category : 'source code' }
GbxMethod >> sourceString
	"Return the source string for the receiver"

	^methodDelegate oopValue = methodDelegate session oopNil oopValue 
		ifTrue: ['<UserAction - source code not available>']
		ifFalse: [(methodDelegate unsynchronizedPerform: #_sourceString) asLocalObject]

{ #category : 'initialize-release' }
GbxMethod >> oopValue: anOop session: aGSSession 
	methodDelegate := GbxDelegate oopValue: anOop session: aGSSession.
	classDelegate := #uninitialized.
	selector := #UnboundMethod.
	className := #'Unknown Class'

{ #category : 'initialize-release' }
GbxMethod >> selector: aSymbol

	selector := aSymbol

{ #category : 'initialize-release' }
GbxMethod >> className: aSymbol

	className := aSymbol

{ #category : 'initialize-release' }
GbxMethod >> classDelegate: aDelegate

	classDelegate := aDelegate

{ #category : 'accessing-literals' }
GbxMethod >> allSymbolLiterals
	"Answer a collection of all the Symbol literals used by
	this method or any submethod, including selectors and
	including Symbol literals embedded within arrays and
	including SpecialSelectors used by this method."
	"if this is a user action, the delegate will be oopNil"

	methodDelegate noCheckSession oopNil = methodDelegate ifTrue: [^OrderedCollection new].
	^(methodDelegate performOnGsServer: #_selectorPool) asOrderedCollection

{ #category : 'instance creation' }
GbxMethod class >> oopValue: anOop session: aGSSession 
	^self new oopValue: anOop session: aGSSession

