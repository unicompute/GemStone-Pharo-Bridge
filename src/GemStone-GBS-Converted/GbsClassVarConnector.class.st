"
Connects a client class variable to a server class variable. Mirrors VisualWorks GbsClassVarConnector:
cvarName is the client (Smalltalk) class-variable name, gsvarName the server (GemStone) one. When gsvarName
is unset it falls back to cvarName (so the same name on both sides needs only cvarName).
"
Class {
	#name : 'GbsClassVarConnector',
	#superclass : 'GbsNameConnector',
	#instVars : [
		'cvarName',
		'gsvarName'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsClassVarConnector class >> stName: stNm gsName: gsNm cvarName: cvNm [
	"The class variable has the same name in Smalltalk and GemStone."
	^ self stName: stNm gsName: gsNm stvarName: cvNm gsvarName: cvNm
]

{ #category : 'instance creation' }
GbsClassVarConnector class >> stName: stNm gsName: gsNm stvarName: stvNm gsvarName: gsvNm [
	^ self new
		stName: stNm;
		gsName: gsNm;
		cvarName: stvNm;
		gsvarName: gsvNm;
		yourself
]

{ #category : 'accessing' }
GbsClassVarConnector >> cvarName [
	^ cvarName ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsClassVarConnector >> cvarName: aString [
	cvarName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsClassVarConnector >> gsvarName [
	"If gsvarName is unset, use cvarName (same name on both sides)."
	^ gsvarName ifNil: [ self cvarName ] ifNotNil: [ gsvarName ]
]

{ #category : 'accessing' }
GbsClassVarConnector >> gsvarName: aString [
	gsvarName := aString ifNil: [ nil ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsClassVarConnector >> stvarName [
	^ self cvarName asSymbol
]

{ #category : 'accessing' }
GbsClassVarConnector >> variableName [
	^ self gsvarName asSymbol
]

{ #category : 'testing' }
GbsClassVarConnector >> connectsAssociation [
	^ true
]

{ #category : 'printing' }
GbsClassVarConnector >> clientObjDescription [
	^ self stName asString, ' (', self stvarName asString, ')'
]

{ #category : 'printing' }
GbsClassVarConnector >> gsDescription [
	^ self gsName asString, ' (', self gsvarName asString, ')'
]

{ #category : 'printing' }
GbsClassVarConnector >> stDescription [
	^ self stName asString, ' (', self stvarName asString, ')'
]

{ #category : 'printing' }
GbsClassVarConnector >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: ' stvarName: ';
		print: self stvarName;
		nextPutAll: ' gsvarName: ';
		print: self gsvarName
]
