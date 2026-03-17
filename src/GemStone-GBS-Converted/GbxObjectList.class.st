Class {
	#name : #'GbxObjectList',
	#superclass : #'GbxRemoteObject',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'testing' }
GbxObjectList >> isForSession: aGSSession

	"Return true if any of the GbxObjects in this list are for aGSSession"

	^(self forSession: aGSSession) notNil

{ #category : #'testing' }
GbxObjectList >> isReadOnlyObject
	"Private.  If any of the proxies think the client object is a read-only
	 object, then it probably is."

	self do: [:each | each isReadOnlyObject ifTrue: [^true]].
	^false

{ #category : #'selecting' }
GbxObjectList >> notForSession: aGSSession
	"Return all my GbxObjects which are not for session aGSSession.
	 If there are none, return nil.
	 If there is only one, return it.
	 If there are more than one, return a GbxObjectList containing them."

	| result |
	result := OrderedCollection new: self size.
	self
		do: [:each | (each notForSession: aGSSession) isNil ifFalse: [result add: each]].
	result size = 0 ifTrue: [^nil].
	result size = 1 ifTrue: [^result at: 1].
	^self class withAll: result

{ #category : #'selecting' }
GbxObjectList >> forSession: aGSSession
	"If any of my elements is a remote object in the given session, return
	that proxy.  Otherwise, return nil. Like a #detect:ifNone:"

	self do: [:each | (each isForSession: aGSSession) ifTrue: [^each]].
	^nil

{ #category : #'dirty management' }
GbxObjectList >> markStDirty: ignored

	"A Smalltalk object associated with more than one GbxObject should never be marked dirty!"

	self gbsMessenger error: 'Attempt to mark a Smalltalk object dirty for which more than one GbxObject is registered'.
	^false

{ #category : #'dirty management' }
GbxObjectList >> isStDirty

	self do: [:each | each isStDirty ifTrue: [^true]].
	^false

{ #category : #'dirty management' }
GbxObjectList >> markStNotDirty: stObj

	self do: [:each | each markStNotDirty: stObj]

{ #category : #'printing' }
GbxObjectList >> printNameAndSizeOn: aStream 
	super printOn: aStream.
	aStream nextPutAll: ' size: '.
	self size printOn: aStream

{ #category : #'printing' }
GbxObjectList >> printOn: aStream 
	self printNameAndSizeOn: aStream.
	aStream nextPutAll: ' '.
	self asArray printOn: aStream

{ #category : #'private' }
GbxObjectList >> gbxPrintServerOn: aStream 
	aStream cr.
	aStream nextPutAll: 'server = '.
	self printNameAndSizeOn: aStream.
	aStream indentMore.
	[self asArray do: [:delegate | delegate gbxPrintServerOn: aStream]] 
		ensure: [aStream indentLess]

{ #category : #'private' }
GbxObjectList >> gbxPrintClientOn: aStream

	aStream cr.
	aStream printClientHeaderFor: self.
	self printNameAndSizeOn: aStream.
	aStream indentMore.
	[self asArray do: [:delegate | delegate gbxPrintClientOn: aStream]]
		ensure: [aStream indentLess]

{ #category : #'private' }
GbxObjectList >> forAnySingleSession

	"Since the receiver isn't a single proxy, search for a proxy in the current session."
	| proxy |
	proxy := self forSession: GBSM currentSession.
	proxy isNil ifTrue: [
		"Our list doesn't contain a proxy for the current session - grab any"
		proxy := self at: 1.
	].
	^proxy

{ #category : #'private' }
GbxObjectList >> do: aBlock 
	"GBS private. Enumerate over my delegates."

	1 to: self size do: [:index | aBlock value: (self at: index)]

{ #category : #'private' }
GbxObjectList >> printDelegateOn: aStream 
	aStream cr.
	aStream nextPutAll: 'delegate = '.
	self printNameAndSizeOn: aStream.
	aStream indentMore.
	[self asArray do: [:delegate | delegate printDelegateOn: aStream]] 
		ensure: [aStream indentLess]

{ #category : #'private' }
GbxObjectList >> connectingDelegate: newDelegate withClient: anObj 
	"If the receiver contains any delegates for the same session as newDelegate, replace it with newDelegate.  Otherwise, return a concatenation of the receiver and newDelegate."

	| oldDelegate newList |
	oldDelegate := self forSession: newDelegate session.
	oldDelegate isNil 
		ifTrue: 
			["newDelegate is from yet another session - answer a concatenated list"

			newDelegate isReadOnlyObject: self forAnySingleSession isReadOnlyObject.
			^GbxObjectList with: self with: newDelegate].

	"we already contain a delegate from newDelegate's session - replace it with newDelegate"
	newDelegate isReadOnlyObject: oldDelegate isReadOnlyObject.
	newList := self class withAll: self.
	1 to: newList size
		do: 
			[:index | 
			oldDelegate == (newList at: index) 
				ifTrue: 
					[newList at: index put: newDelegate.
					^newList]].
	self gbsMessenger 
		error: 'Error in GBS code. Match should have been found.'

{ #category : #'private' }
GbxObjectList >> gbxDebugPrintOn: aStream 
	self printOn: aStream.
	aStream nextPutAll: ' ('.
	self asArray do: [:ea | ea printDelegateOn: aStream cr].
	aStream nextPutAll: ')'

{ #category : #'private' }
GbxObjectList >> asArray
	"Private. Convert to an array to gain Array behavior.
	 This method is only used for testing, but is
	 general-purpose enough to include in the kernel."

	| answer |
	answer := Array new: self size.
	1 to: self size do: [:index | answer at: index put: (self at: index)].
	^answer

{ #category : #'instance creation' }
GbxObjectList class >> withAll: aCollection 
	| answer |
	answer := self new: aCollection size.
	1 to: aCollection size
		do: [:index | answer at: index put: (aCollection at: index)].
	^answer

{ #category : #'instance creation' }
GbxObjectList class >> with: element1 with: element2 
	"Create a new GbxObjectList with the given elements.  If element1 is an instance of this class, return a new instance that is the concatenation of it with element2."

	(element1 isMemberOf: self) 
		ifTrue: 
			[| newList element1size |
			element1size := element1 size.
			newList := self new: element1size + 1.
			1 to: element1size do: [:i | newList at: i put: (element1 at: i)].
			newList at: element1size + 1 put: element2.
			^newList]
		ifFalse: 
			[^(self new: 2)
				at: 1 put: element1;
				at: 2 put: element2;
				yourself]

