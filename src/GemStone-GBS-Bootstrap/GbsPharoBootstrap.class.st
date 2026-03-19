Class {
	#name : 'GbsPharoBootstrap',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'bootstrap' }
GbsPharoBootstrap class >> installCompatibilityAliases
[
	Smalltalk at: #TwoByteString put: WideString.
	Smalltalk at: #FourByteString put: WideString.
	Smalltalk at: #TwoByteSymbol put: WideSymbol.
	Smalltalk at: #FourByteSymbol put: WideSymbol.
	Smalltalk at: #Timestamp put: DateAndTime.
]

{ #category : 'icons' }
GbsPharoBootstrap class >> iconNamed: aSymbol
[
	^ [ UIManager default iconNamed: aSymbol ]
		on: Error
		do: [ nil ]
]

{ #category : 'menus' }
GbsPharoBootstrap class >> loadGemStoneTools
[
	[
		Metacello new
			baseline: 'GemStonePharo';
			repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
			load: 'Tools'.
		UIManager default inform: 'GemStone tools loaded.'
	] on: Error do: [ :ex |
		UIManager default inform: 'GemStone tools load failed: ', ex messageText ]
]

{ #category : 'menus' }
GbsPharoBootstrap class >> menuCommandGemStoneOn: aBuilder
[
	<worldMenu>
	| launcherClass |
	launcherClass := Smalltalk at: #GbsClassicLauncher ifAbsent: [ nil ].
	(launcherClass notNil and: [ launcherClass respondsTo: #menuCommandGemStoneOn: ])
		ifTrue: [ ^ launcherClass menuCommandGemStoneOn: aBuilder ].

	(aBuilder item: #GemStone)
		order: 79.9;
		label: 'GemStone';
		icon: (self iconNamed: #smallConfiguration);
		with: [
			(aBuilder item: #LoadGemStoneTools)
				label: 'Load GemStone Tools';
				action: [ self loadGemStoneTools ].
			(aBuilder item: #GemStoneMenuUnavailable)
				label: 'Launcher unavailable';
				action: [
					UIManager default inform:
						'GemStone tools are not loaded in this image yet.' ].
			(aBuilder item: #AboutGemBuilder)
				label: 'About GemBuilder...';
				action: [
					UIManager default
						inform: 'GemBuilder for Pharo (GemStone-Pharo-Bridge)' ] ]
]
