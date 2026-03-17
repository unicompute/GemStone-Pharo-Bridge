Class {
	#name : #'GbxInspectionWrapperNoSession',
	#superclass : #'GbxInspectionWrapper',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Tools'
}

{ #category : #'accessing' }
GbxInspectionWrapperNoSession >> doItReceiver
	^localObject

{ #category : #'printing' }
GbxInspectionWrapperNoSession >> basicPrintOn: aStream 
	localObject basicPrintOn: aStream

{ #category : #'private - inspecting' }
GbxInspectionWrapperNoSession >> inspectorClasses
	| oc |
	^(localObject zzzisStub or: [localObject zzzisForwarder]) 
		ifTrue: 
			[oc := OrderedCollection new.
			oc add: GbxClientBasicProxyInspector.
			oc]
		ifFalse: [super inspectorClasses]

{ #category : #'private - inspecting' }
GbxInspectionWrapperNoSession >> inspectableObjectFor: aClass 
	^localObject

{ #category : #'initialize-release' }
GbxInspectionWrapperNoSession >> fetchInitialInfo
	"Nothing to fetch -- no session "

