Class {
	#name : 'GbxClientBasicProxyInspector',
	#superclass : 'BasicInspector',
	#instVars : [
		'selfAttribute'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbxClientBasicProxyInspector >> computeSelfAttribute
[
	"Try to print information about our proxy regardless of whether 
	the session semaphore is blocked or if the server object is defunct; 
	for example, inspecting an uncached forwarder which is not flushed"
	"Remember that object is wrapped"

	
	[selfAttribute := GbxDerivedAttribute
				label: 'self'
				value: self object delegate
				printString: (self object isUnretrievable
						ifTrue: [self unretrievableObjectPrintString]
						ifFalse: [self retrievableObjectPrintString])]
			on: Error
			do: 
				[:ex |
				selfAttribute := GbxDerivedAttribute
							label: 'self'
							value: nil
							printString: self defunctPrintString]
]

{ #category : 'accessing' }
GbxClientBasicProxyInspector >> delegateExists: delegate
[
	^[delegate session
		sessionCritical: [delegate exists]
		unlessBlocked: [false]]
		on: Error
		do: [:ex | false]
]

{ #category : 'accessing' }
GbxClientBasicProxyInspector >> selfAttribute
[
	selfAttribute isNil ifTrue: [self computeSelfAttribute].
	^selfAttribute
]

{ #category : 'private printing' }
GbxClientBasicProxyInspector >> retrievableObjectPrintString
[

	| printString |
	printString := self object basicPrintString , ' '.
	(self delegateExists: self object delegate)
		ifTrue: [printString := printString , self enhancedReportPrintString].
	^printString
]

{ #category : 'private printing' }
GbxClientBasicProxyInspector >> unretrievableObjectPrintString
[

	^self object localObject gbxBasicClass name , ' for Unretrievable Object'
]

{ #category : 'private printing' }
GbxClientBasicProxyInspector >> defunctPrintString
[

	^self object basicPrintString , ' <defunct>'
]

{ #category : 'private' }
GbxClientBasicProxyInspector >> refreshSelfAttribute
[
	selfAttribute := nil.
	self selfAttribute
]

{ #category : 'private' }
GbxClientBasicProxyInspector >> enhancedReportPrintString
[

	^self object session
		unsynchronizedEvaluate: ' | gbxWriteStream gbxObject gbxClass |
										gbxObject := self. '
				, GbxInspectionWrapperWithSession enhancedRemotePrintString
					, ' gbxWriteStream contents '
		context: self object delegate
]

{ #category : 'private' }
GbxClientBasicProxyInspector >> doItReceiver
[

	^object proxy
]

{ #category : 'private' }
GbxClientBasicProxyInspector >> refresh
[
	self refreshSelfAttribute.
	super refresh
]

{ #category : 'private' }
GbxClientBasicProxyInspector >> derivedFields
[
	"we use this inspector for dual purposes. 
	For defunct stubs & forwarders and for normal stubs & forwarders.
	normal stubs and forwarders would be wrapped. 
	Maybe defunct ones should be too, but those depend on having a session
	because the ProxyInspectionWrapper is a subclass of InspectionWrapperWithSession.
	Maybe this should be changed"

	^
	[(self object zzzisStub or: [self object zzzisForwarder]) 
		ifTrue: 
			[Array with: (Tools.Trippy.DerivedAttribute 
						label: #identityHash << #gbs >> 'identityHash'
						valueBlock: [object identityHash])
				with: (Tools.Trippy.DerivedAttribute label: #size << #gbs >> 'size'
						valueBlock: [object gbxBasicSize])]
		ifFalse: [object inspectorClientExtraAttributes]] 
			on: MessageNotUnderstood
			do: [:ex | ex return: Array new]
]

{ #category : 'private' }
GbxClientBasicProxyInspector >> partsAtAll: aCollection
[
	^Array 
		with: (fixedFields at: 1)
		with: (fixedFields at: 2)
		with: (fixedFields at: 3)
]

{ #category : 'private' }
GbxClientBasicProxyInspector >> createInsertionUndo: partCollection before: anIndex
[
	"undos not implemented in GemStone inspectors yet"

	self gbxFixMe
]

{ #category : 'testing' }
GbxClientBasicProxyInspector class >> gbxIsGbsInspector
[
	^true
]

