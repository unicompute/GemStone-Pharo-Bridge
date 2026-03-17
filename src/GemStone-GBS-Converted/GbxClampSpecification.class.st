Class {
	#name : 'GbxClampSpecification',
	#superclass : 'Object',
	#instVars : [
		'idClamps',
		'classClamps',
		'instVarLevels',
		'addSubleafHeaders',
		'instVarLevelsSelector',
		'traversalCallBackSelector',
		'valueClamps',
		'environmentId'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxClampSpecification >> idClamps: anObject

	idClamps := anObject.
	self markDirty

{ #category : 'accessing' }
GbxClampSpecification >> addSubleafHeaders

	^addSubleafHeaders

{ #category : 'accessing' }
GbxClampSpecification >> traversalCallBackSelector

	^traversalCallBackSelector

{ #category : 'accessing' }
GbxClampSpecification >> idClamps

	^idClamps

{ #category : 'accessing' }
GbxClampSpecification >> replaceInstVarLevelsForClass: clientClass with: levelsArray

	levelsArray == nil
		ifTrue: [instVarLevels removeKeyIfPresent: clientClass]
		ifFalse: [instVarLevels at: clientClass put: levelsArray]

{ #category : 'accessing' }
GbxClampSpecification >> environmentId

	^environmentId

{ #category : 'accessing' }
GbxClampSpecification >> removeInstVarLevelsForClass: aClientClass

	instVarLevels removeKeyIfPresent: aClientClass

{ #category : 'accessing' }
GbxClampSpecification >> classClamps: anObject

	classClamps := anObject.
	self markDirty

{ #category : 'accessing' }
GbxClampSpecification >> instVarLevelsSelector: aSymbolOrNil

	instVarLevelsSelector := aSymbolOrNil.
	self markDirty

{ #category : 'accessing' }
GbxClampSpecification >> classClamps

	^classClamps

{ #category : 'accessing' }
GbxClampSpecification >> instVarLevels: anObject

	instVarLevels := anObject.
	self markDirty

{ #category : 'accessing' }
GbxClampSpecification >> valueClamps

	^valueClamps

{ #category : 'initialize-release' }
GbxClampSpecification >> initialize

	addSubleafHeaders := true.
	traversalCallBackSelector := #_gbsTraversalCallback.
	environmentId := 0.
	self markDirty

{ #category : 'instance creation' }
GbxClampSpecification class >> newWithIdentityClampsHolder: idClamps classClamps: classClamps

	| inst |
	inst := self new initialize.
	inst
		idClamps: idClamps;
		classClamps: classClamps;
		instVarLevels: GbxFastIdentityKeyValueDictionary new.
	^inst

