Class {
	#name : 'GbxOopKeyedDictionary',
	#superclass : 'Object',
	#instVars : [
		'numNodeSlots',
		'notCachedToken',
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'node interface' }
GbxOopKeyedDictionary >> replaceNodeAt: index with: newNode
[
	"One of my child nodes has changed size and is asking to be replaced.
	The sender must hold the session's  sessionProtect"

	self basicAt: index put: newNode
]

{ #category : 'TEMPORARY' }
GbxOopKeyedDictionary >> check
[
	
	session hasCriticalAccess ifFalse: [self gbsMessenger error: 'ServerMap access without sessionProtect']
]

{ #category : 'accessing' }
GbxOopKeyedDictionary >> session
[
	^session
]

{ #category : 'accessing' }
GbxOopKeyedDictionary >> session: anObject
[
	session := anObject
]

{ #category : 'accessing' }
GbxOopKeyedDictionary >> size
[
	"Count my elements and answer the number present.
	This operation is relatively expensive, because it must
	enumerate over all nodes."

	| count |
	count := 0.
	self nodesDo: [:node | count := count + node size].
	^count
]

{ #category : 'accessing' }
GbxOopKeyedDictionary >> clientAtOop: oop
[
	"Answer the value at key. If key not present, answer NotCachedToken.
	Keys representing special oops should never appear in the dictionary,
	so always act like they're not there, and if assertion checks are enabled
	raise an error."
	"Sender must hold my session's accessProtect."

	| index node |
	self check.
	index := oop oopNumberHighBytes + 1.
	index > numNodeSlots ifTrue: [^notCachedToken].
	node := self basicAt: index.
	^node == nil ifTrue: [notCachedToken] ifFalse: [node clientAtOop: oop]
]

{ #category : 'accessing' }
GbxOopKeyedDictionary >> atOop: oop putClient: client
[
	"Add an association between the given oop and client object.
	Answer the canonical delegate for the given oop."
	"Sender must hold my session's sessionProtect"

	| index node |
	self check.
	self gbsMessenger
		statusTag: #atOop:putClient:
		message: '%1 atOop: %2 putClientClass: %3 IdentityHash:%4'
		with: self
		with: oop
		with: client gbxBasicClass
		with: client identityHash.
	index := oop oopNumberHighBytes + 1.
	index > numNodeSlots ifTrue: [self growToAtLeast: index].
	node := self basicAt: index.
	node == nil ifTrue: [node := self createNodeAt: index].
	^node atOop: oop putClient: client
]

{ #category : 'auditing' }
GbxOopKeyedDictionary >> unprotectedAudit
[
	"For debugging, soes not acquire sessionProtect so is not safe for general use."

	| results |
	results := GbxServerMapAuditResults new.
	results map: self.
	numNodeSlots ~~ self basicSize
		ifTrue: 
			[results addFailure: (GbxServerMapAuditFailure
						description: 'Bad root size -- numNodeSlots is: '
								, numNodeSlots printString , ' but actual size is: '
								, self basicSize printString)].
	1 to: self basicSize
		do: 
			[:i |
			| node |
			node := self basicAt: i.
			node ~~ nil
				ifTrue: 
					[node
						auditInto: results
						parent: self
						parentIndex: i
						session: session]].
	^results verify
]

{ #category : 'auditing' }
GbxOopKeyedDictionary >> audit
[
	"What can be checked at this level:
     * I am owningDictionary of all nodes
	* Each node's parentOffset is its index in me."

	^session sessionCriticalNoSessionCheck: [self unprotectedAudit]
]

{ #category : 'non-copying' }
GbxOopKeyedDictionary >> copy
[

	self shouldNotImplement
]

{ #category : 'private' }
GbxOopKeyedDictionary >> nodesDo: aBlock
[

	1 to: numNodeSlots
		do: 
			[:i |
			| node |
			node := self basicAt: i.
			node ~~ nil ifTrue: [aBlock value: node]]
]

{ #category : 'private' }
GbxOopKeyedDictionary >> copyEmptyWithCapacity: newSize
[
	"Used when growing"

	| newSelf |
	newSelf := self class basicNew: newSize.
	newSelf
		initialize;
		session: session.
	^newSelf
]

{ #category : 'private' }
GbxOopKeyedDictionary >> growToAtLeast: index
[
	"Grow to accommodate repositories that have had more than a billion objects oop highwater mark. Grow to the power-of-two size necessary to include index. This prevents us growing too many times while still not growing more than twice as big as needed.
	This top-level never shrinks, since its optimum size depends on the oop highwater mark of the repository, which never shrinks."

	| newSize newSelf |
	[numNodeSlots == self basicSize and: [index > numNodeSlots]] gbxAssert.
	newSize := numNodeSlots * 2.
	[newSize < index] whileTrue: [newSize := newSize * 2].
	newSelf := self copyEmptyWithCapacity: newSize.
	1 to: numNodeSlots do: [:i | newSelf basicAt: i put: (self basicAt: i)].
	self become: newSelf
]

{ #category : 'private' }
GbxOopKeyedDictionary >> createNodeAt: index
[
	"Create a node for a 16MObject range of oops"

	[(self basicAt: index) == nil] gbxAssert.
	self basicAt: index
		put: (self nodeClass
				owningMap: self
				parentIndex: index
				initialSize: session configuration serverMapLeafCapacity)
]

{ #category : 'private' }
GbxOopKeyedDictionary >> nodeClass
[

	self subclassResponsibility
]

{ #category : 'removing' }
GbxOopKeyedDictionary >> removeOop: key
[
	"Remove the mapped client object for the oop. Answer the node's response, which differs by subclass, or nil if 
	there is no node (which means that I do not contain an entry with the given key).
	For the server map, this is used only in a few exceptional circumstances. Most explicit unmapping should use #pretendClientIsCollected:. This method will not update the server's export set and referenced set.
	For the behavior map (of replicators) this is used whenever a behavior is unmapped."
	"Sender must hold my session's accessProtect."

	| index node |
	self check.
	index := key oopNumberHighBytes + 1.
	index > numNodeSlots ifTrue: [^nil].
	node := self basicAt: index.
	^node == nil
		ifTrue: [nil]	"Formalize it to make the Code Critic happy."
		ifFalse: [node removeOop: key]
]

{ #category : 'initialize-release' }
GbxOopKeyedDictionary >> initialize
[

	notCachedToken := NotCachedToken.	"NotCachedToken *is* cached, for faster and very frequent access"
	numNodeSlots := self basicSize
]

{ #category : 'instance creation' }
GbxOopKeyedDictionary class >> newForSession: sess
[

	| inst |
	inst := self basicNew: 64.	"Enough for a billion objects, will grow for larger oop highwater marks"
	inst
		initialize;
		session: sess.
	^inst
]

{ #category : 'instance creation' }
GbxOopKeyedDictionary class >> new
[

	^self shouldNotImplement
]

