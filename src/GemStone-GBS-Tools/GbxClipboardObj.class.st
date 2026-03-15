Class {
	#name : 'GbxClipboardObj',
	#superclass : 'Object',
	#classInstVars : [
		'clipboardSessions',
		'clipboardContent'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'class initialization' }
GbxClipboardObj class >> initialize [
	clipboardSessions := OrderedCollection new.
	clipboardContent := nil.
]

{ #category : 'accessing' }
GbxClipboardObj class >> clipboardContent [
	^ clipboardContent
]

{ #category : 'accessing' }
GbxClipboardObj class >> clipboardContent: anObject [
	clipboardContent := anObject
]

{ #category : 'accessing' }
GbxClipboardObj class >> clipboardSessions [
	^ clipboardSessions
]

{ #category : 'testing' }
GbxClipboardObj class >> isEmpty [
	^ clipboardContent isNil
]

{ #category : 'accessing' }
GbxClipboardObj class >> firstClipboardSession [
	^ clipboardSessions ifNotEmpty: [ :sessions | sessions first ] ifEmpty: [ nil ]
]

{ #category : 'clipboard operations' }
GbxClipboardObj class >> newForObj: anObject session: aSession context: aSymbol [
	"Store an object in the clipboard for a specific session"
	clipboardContent := anObject.
	(aSession notNil and: [ (clipboardSessions includes: aSession) not ]) ifTrue: [
		clipboardSessions add: aSession.
	].
]

{ #category : 'clipboard operations' }
GbxClipboardObj class >> getObjectForSession: aSession [
	"Get the clipboard object for a specific session"
	^ clipboardContent
]

{ #category : 'clipboard operations' }
GbxClipboardObj class >> clear [
	"Clear the clipboard"
	clipboardContent := nil.
	clipboardSessions := OrderedCollection new.
]

{ #category : 'clipboard operations' }
GbxClipboardObj class >> copySymbolList: aSymbolList session: aSession [
	"Copy a symbol list to clipboard"
	self newForObj: aSymbolList session: aSession context: #SymbolList.
]

{ #category : 'clipboard operations' }
GbxClipboardObj class >> copyUser: aUser session: aSession [
	"Copy a user profile to clipboard"
	self newForObj: aUser session: aSession context: #User.
]

{ #category : 'clipboard operations' }
GbxClipboardObj class >> copySegment: aSegment session: aSession [
	"Copy a segment to clipboard"
	self newForObj: aSegment session: aSession context: #Segment.
]

{ #category : 'clipboard operations' }
GbxClipboardObj class >> pasteToSession: aSession [
	"Paste clipboard content to a session"
	^ clipboardContent
]
