Class {
	#name : 'GbsBrowserTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbsBrowserTest >> testFetchRemoteClasses [
	| session script rawData classes |
	
	session := GbsSessionParameters currentSession.
	(session isNil or: [ session isConnected not ]) ifTrue: [
		self skip: 'Requires an active GemStone session' ].
	
	script := '[
		| dict classNames stream |
		dict := System myUserProfile symbolList objectNamed: #Globals.
		classNames := dict keys select: [ :each | (dict at: each) isBehavior ].
		stream := WriteStream on: String new.
		classNames asSortedCollection do: [ :cls | stream nextPutAll: cls asString; lf ].
		stream contents
	] value'.
	
	rawData := session executeAndFetch: script.
	self assert: rawData isNotNil.
	self deny: (rawData beginsWith: 'Error:').
	
	"1. Split the string"
	classes := rawData splitOn: Character lf.
	
	"2. CRITICAL FIX: Trim all invisible carriage returns/spaces from C-strings!!"
	classes := classes collect: [ :each | each trimBoth ].
	classes := classes reject: [ :each | each isEmpty ].
	
	"3. Print to your Remote Transcript so you can actually SEE the data!"
	Transcript show: 'Fetched ', classes size asString, ' classes from GemStone!'; cr.
	Transcript show: 'First 5 classes: ', (classes copyFrom: 1 to: 5) printString; cr.
	
	"4. Assertions"
	self assert: classes isNotEmpty description: 'No classes were found in Globals'.
	self assert: (classes includes: 'Association') description: 'Standard classes are missing!'.
]
