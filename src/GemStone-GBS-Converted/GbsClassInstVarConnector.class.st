"
Connects a client class-instance variable to a server class-instance variable. Mirrors VisualWorks
GbsClassInstVarConnector: unlike GbsClassVarConnector (which connects a class-variable association), this
connects the *value* of a class-instance variable, so it does not connect an association.
"
Class {
	#name : 'GbsClassInstVarConnector',
	#superclass : 'GbsClassVarConnector',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
GbsClassInstVarConnector >> connectsAssociation [
	"A class-instance variable connector connects a value, not a class-variable association."
	^ false
]

{ #category : 'accessing' }
GbsClassInstVarConnector >> variableKind [
	^ #classInstanceVariable
]

{ #category : 'printing' }
GbsClassInstVarConnector >> gsDescription [
	^ self gsName asString, ' class>>', self gsvarName asString
]

{ #category : 'printing' }
GbsClassInstVarConnector >> stDescription [
	^ self stName asString, ' class>>', self stvarName asString
]
