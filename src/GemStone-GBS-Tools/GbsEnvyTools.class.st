Class {
	#name : 'GbsEnvyTools',
	#superclass : 'Object',
	#classInstVars : [
		'currentEnvySession',
		'isEnvyEnabled'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'class initialization' }
GbsEnvyTools class >> initialize [
	isEnvyEnabled := false.
]

{ #category : 'accessing' }
GbsEnvyTools class >> currentEnvySession [
	^ currentEnvySession
]

{ #category : 'accessing' }
GbsEnvyTools class >> currentEnvySession: aSession [
	currentEnvySession := aSession
]

{ #category : 'accessing' }
GbsEnvyTools class >> isEnvyEnabled [
	^ isEnvyEnabled
]

{ #category : 'accessing' }
GbsEnvyTools class >> isEnvyEnabled: aBoolean [
	isEnvyEnabled := aBoolean
]

{ #category : 'loading' }
GbsEnvyTools class >> loadApplication: appName from: repositoryPath [
	"Load an application from Envy repository"
	| script |
	
	isEnvyEnabled ifFalse: [
		^ self error: 'Envy integration not enabled'.
	].
	
	script := '[
		| app |
		app := Application loadNamed: ''', appName, ''' from: ''', repositoryPath, '''.
		app load.
		app loaded
	] value'.
	
	currentEnvySession ifNotNil: [
		^ currentEnvySession executeAndFetch: script.
	].
	
	^ nil
]

{ #category : 'loading' }
GbsEnvyTools class >> loadClass: className from: appName [
	"Load a class from Envy application"
	| script |
	
	isEnvyEnabled ifFalse: [
		^ self error: 'Envy integration not enabled'.
	].
	
	script := '[
		| app cls |
		app := Application named: ''', appName, '''.
		cls := app definitionFor: ''', className, '''.
		cls load.
		cls loaded
	] value'.
	
	currentEnvySession ifNotNil: [
		^ currentEnvySession executeAndFetch: script.
	].
	
	^ nil
]

{ #category : 'saving' }
GbsEnvyTools class >> saveClass: className to: appName [
	"Save a class to Envy application"
	| script |
	
	isEnvyEnabled ifFalse: [
		^ self error: 'Envy integration not enabled'.
	].
	
	script := '[
		| app cls |
		app := Application named: ''', appName, '''.
		cls := Smalltalk at: #', className, '.
		app addDefinitionFor: cls.
		app save.
		true
	] value'.
	
	currentEnvySession ifNotNil: [
		^ currentEnvySession executeAndFetch: script.
	].
	
	^ nil
]

{ #category : 'browsing' }
GbsEnvyTools class >> browseApplications [
	"Browse Envy applications"
	| script |
	
	isEnvyEnabled ifFalse: [
		^ self error: 'Envy integration not enabled'.
	].
	
	script := '[
		Application allInstances collect: [ :app | app name ]
	] value'.
	
	currentEnvySession ifNotNil: [
		^ currentEnvySession executeAndFetch: script.
	].
	
	^ nil
]
