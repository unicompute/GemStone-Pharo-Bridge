Class {
	#name : 'GbsMigrationPlanEntry',
	#superclass : 'Object',
	#instVars : [
		'sourceName',
		'sourceProxy',
		'sourceVersion',
		'sourceNumberOfVersions',
		'targetName',
		'targetProxy',
		'instanceCount'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsMigrationPlanEntry class >> sourceName: aSourceName proxy: aSourceProxy version: aVersion numberOfVersions: aCount targetName: aTargetName targetProxy: aTargetProxy count: anInteger [
	^ self new
		sourceName: aSourceName;
		sourceProxy: aSourceProxy;
		sourceVersion: aVersion;
		sourceNumberOfVersions: aCount;
		targetName: aTargetName;
		targetProxy: aTargetProxy;
		instanceCount: anInteger;
		yourself
]

{ #category : 'querying' }
GbsMigrationPlanEntry >> hasAffectedInstances [
	^ self instanceCount > 0
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> instanceCount [
	^ instanceCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> instanceCount: anInteger [
	instanceCount := anInteger ifNil: [ 0 ]
]

{ #category : 'printing' }
GbsMigrationPlanEntry >> printOn: aStream [
	aStream
		nextPutAll: self sourceName;
		nextPutAll: ' -> ';
		nextPutAll: self targetName;
		nextPutAll: ' (';
		print: self instanceCount;
		nextPut: $)
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> sourceHolder [
	^ GbxClassHolder
		name: self sourceName
		proxy: self sourceProxy
		version: self sourceVersion
		numberOfVersions: self sourceNumberOfVersions
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> sourceName [
	^ sourceName
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> sourceName: aString [
	sourceName := aString
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> sourceNumberOfVersions [
	^ sourceNumberOfVersions ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> sourceNumberOfVersions: anInteger [
	sourceNumberOfVersions := anInteger ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> sourceProxy [
	^ sourceProxy
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> sourceProxy: aProxy [
	sourceProxy := aProxy
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> sourceVersion [
	^ sourceVersion ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> sourceVersion: anInteger [
	sourceVersion := anInteger ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> targetHolder [
	^ GbxClassHolder
		name: self targetName
		proxy: self targetProxy
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> targetName [
	^ targetName
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> targetName: aString [
	targetName := aString
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> targetProxy [
	^ targetProxy
]

{ #category : 'accessing' }
GbsMigrationPlanEntry >> targetProxy: aProxy [
	targetProxy := aProxy
]
