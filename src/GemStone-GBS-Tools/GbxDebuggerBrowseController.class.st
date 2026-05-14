Class {
	#name : 'GbxDebuggerBrowseController',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'browsing' }
GbxDebuggerBrowseController class >> browseClass: aDelegate [
	| newBrowser aClass remoteClass |
	aDelegate ifNil: [ ^ nil ].
	newBrowser := Smalltalk at: #GbxHierarchyBrowser ifAbsent: [ ^ nil ].
	newBrowser ifNil: [ ^ nil ].
	newBrowser := newBrowser new.
	newBrowser session: aDelegate session.
	remoteClass := aDelegate remoteClass.
	remoteClass ifNil: [ ^ nil ].
	(remoteClass unsynchronizedPerformOnGsServer: #isMeta)
		ifTrue: [ remoteClass := aDelegate ].
	aClass := (Smalltalk at: #GbxClassHolder ifAbsent: [ ^ nil ])
		name: (remoteClass unsynchronizedPerformOnGsServer: #name)
		proxy: remoteClass.
	newBrowser myClass: aClass.
	newBrowser classList: nil
		class: aClass
		protocolList: nil
		protocol: nil
		methodList: nil
		selectedMethods: nil.
	^ newBrowser
]

{ #category : 'browsing' }
GbxDebuggerBrowseController class >> browseMethod: delegate [
	| newBrowser result classHolder |
	delegate ifNil: [ ^ nil ].
	delegate session ifNil: [ ^ nil ].
	result := GbsRemoteExecutionDispatcher
		fetchCommandBody: '
		| method displayClass className sel protocol isMeta result |
		method := self selector isNil ifTrue:[self homeMethod] ifFalse:[self].
		displayClass := method inClass thisClass.
		className := displayClass name.
		sel := method selector.
		protocol := method inClass categoryOfSelector: sel.
		isMeta := method inClass isMeta.
		result := Array new.
		result add: displayClass asOop;
			add: className;
			add: sel;
			add: protocol;
			add: isMeta.
		result
	'
		literalBindings: Dictionary new
		oopBindings: Dictionary new
		in: delegate session
		context: delegate.
	result ifNil: [ ^ nil ].
	newBrowser := Smalltalk at: #GbxHierarchyBrowser ifAbsent: [ ^ nil ].
	newBrowser ifNil: [ ^ nil ].
	newBrowser := newBrowser new.
	newBrowser session: delegate session.
	classHolder := (Smalltalk at: #GbxClassHolder ifAbsent: [ ^ nil ])
		name: (result at: 2)
		proxy: (Smalltalk at: #GbxDelegate ifAbsent: [ ^ nil ])
			oopValue: (result at: 1)
			session: delegate session.
	newBrowser myClass: classHolder.
	newBrowser classList: nil
		class: classHolder
		protocolList: nil
		protocol: (result at: 4)
		methodList: nil
		selectedMethods: (Array with:
			(Smalltalk at: #GbxCompiledMethodHolder ifAbsent: [ ^ nil ])
				name: (result at: 3)).
	(result at: 5) ifTrue: [
		newBrowser initalizeMetaTabsToIndex: 2 ].
	^ newBrowser
]
