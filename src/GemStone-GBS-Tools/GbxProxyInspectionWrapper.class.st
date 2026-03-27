Class {
	#name : 'GbxProxyInspectionWrapper',
	#superclass : 'GbxInspectionWrapperWithSession',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'user interface' }
GbxProxyInspectionWrapper >> inspectorActions
[
	"add fault-on-demand to stubs. Trigger an event to notify interested parties"

	| oc |
	oc := super inspectorActions asOrderedCollection.
	localObject zzzisStub
		ifTrue: 
			[oc add: (Tools.Trippy.Action label: #Fault << #gbs >> 'Fault'
						block: [self faultStub])].
	^oc asArray
]

{ #category : 'user interface' }
GbxProxyInspectionWrapper >> faultStub
[
	localObject zzzisStub 
		ifTrue: 
			[localObject fault.
			self triggerEvent: #objectChanged]
]

{ #category : 'printing' }
GbxProxyInspectionWrapper >> basicPrintOn: aStream
[
	"proxies should never be immutable. see comment in GbxAbstractProxy isImmutable.
	we want the proxy class also, not the cached remote class"

	aStream nextPutAll: (remoteClassName isNil
				ifTrue: [inspectedObject gbxBasicClass name , ' for Unretrievable Object']
				ifFalse: 
					[self uncachedPrintString , localObject gbxBasicClass printString
						, (remoteClassName first isVowel ifTrue: [' for an '] ifFalse: [' for a '])
							, remoteClassName])
]

{ #category : 'private - inspecting' }
GbxProxyInspectionWrapper >> inspectorClasses
[

	| oc |
	oc := OrderedCollection new.
	oc add: GbxClientBasicProxyInspector.
	oc addAll: self gbxInspectorClasses.
	oc add: GbxDelegateInspector.
	oc add: Tools.Trippy.WatchLogInspector. 
	^self possiblyAddBehaviorInspector: oc
]

{ #category : 'private - inspecting' }
GbxProxyInspectionWrapper >> inspectorClientExtraAttributes
[
	^Array with: (Tools.Trippy.DerivedAttribute 
				label: #identityHash << #gbs >> 'identityHash'
				valueBlock: [self localObjectIdentityHash])
		with: (Tools.Trippy.DerivedAttribute label: #size << #gbs >> 'size'
				valueBlock: [self proxy gbxBasicSize])
]

{ #category : 'private - inspecting' }
GbxProxyInspectionWrapper >> possiblyAddBehaviorInspector: oc
[
	"no action in VW 8.0"

	^oc
]

{ #category : 'accessing' }
GbxProxyInspectionWrapper >> proxy
[
	^localObject
]

{ #category : 'private' }
GbxProxyInspectionWrapper >> localObjectIdentityHash
[
	^localObject identityHash
]

