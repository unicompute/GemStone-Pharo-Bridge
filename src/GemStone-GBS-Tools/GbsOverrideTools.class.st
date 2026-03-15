Class {
	#name : 'GbsOverrideTools',
	#superclass : 'Object',
	#classInstVars : [
		'overrideSpecs',
		'isOverridesEnabled'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'class initialization' }
GbsOverrideTools class >> initialize [
	overrideSpecs := Dictionary new.
	isOverridesEnabled := true.
]

{ #category : 'accessing' }
GbsOverrideTools class >> isOverridesEnabled [
	^ isOverridesEnabled
]

{ #category : 'accessing' }
GbsOverrideTools class >> isOverridesEnabled: aBoolean [
	isOverridesEnabled := aBoolean
]

{ #category : 'accessing' }
GbsOverrideTools class >> overrideSpecs [
	^ overrideSpecs
]

{ #category : 'overrides' }
GbsOverrideTools class >> registerOverride: spec forClass: className selector: selector [
	"Register an override specification"
	| key |
	
	key := className, '>>', selector asString.
	overrideSpecs at: key put: spec.
]

{ #category : 'overrides' }
GbsOverrideTools class >> removeOverrideForClass: className selector: selector [
	"Remove an override specification"
	| key |
	
	key := className, '>>', selector asString.
	overrideSpecs removeKey: key ifAbsent: [ ].
]

{ #category : 'overrides' }
GbsOverrideTools class >> specForClass: className selector: selector [
	"Get override spec for a method"
	| key |
	
	key := className, '>>', selector asString.
	^ overrideSpecs at: key ifAbsent: [ nil ]
]

{ #category : 'overrides' }
GbsOverrideTools class >> hasOverrideForClass: className selector: selector [
	"Check if there's an override for a method"
	| key |
	
	key := className, '>>', selector asString.
	^ overrideSpecs includesKey: key
]

{ #category : 'overrides' }
GbsOverrideTools class >> applyOverridesFor: anObject [
	"Apply overrides for an object"
	| specs className |
	
	isOverridesEnabled ifFalse: [ ^ anObject ].
	
	className := anObject class name.
	specs := overrideSpecs select: [ :spec :key |
		key beginsWith: className, '>>'
	].
	
	specs keysAndValuesDo: [ :key :spec |
		spec applyTo: anObject.
	].
	
	^ anObject
]
