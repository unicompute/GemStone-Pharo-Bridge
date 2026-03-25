Class {
	#name : 'GbsNameConnector',
	#superclass : 'GbsConnector',
	#instVars : [
		'stName',
		'gsName',
		'dictionaryName',
		'binding',
		'environment'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsNameConnector class >> stName: aClientName gsName: aServerName [
	^ self new
		stName: aClientName;
		gsName: aServerName;
		yourself
]

{ #category : 'accessing' }
GbsNameConnector >> gsDescription [
	^ self gsName
]

{ #category : 'accessing' }
GbsNameConnector >> gsName [
	^ gsName ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsNameConnector >> gsName: aString [
	gsName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsNameConnector >> stDescription [
	^ self stName
]

{ #category : 'accessing' }
GbsNameConnector >> stName [
	^ stName ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsNameConnector >> stName: aString [
	stName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]
