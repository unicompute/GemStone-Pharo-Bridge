Class {
	#name : 'CoreGbsMethodChangeAnnouncementFixture',
	#superclass : 'Object',
	#instVars : [
		'selector',
		'classAffected'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'instance creation' }
CoreGbsMethodChangeAnnouncementFixture class >> selector: aSelector classAffected: aClass [
	^ self new
		selector: aSelector;
		classAffected: aClass;
		yourself
]

{ #category : 'accessing' }
CoreGbsMethodChangeAnnouncementFixture >> classAffected [
	^ classAffected
]

{ #category : 'accessing' }
CoreGbsMethodChangeAnnouncementFixture >> classAffected: aClass [
	classAffected := aClass
]

{ #category : 'accessing' }
CoreGbsMethodChangeAnnouncementFixture >> selector [
	^ selector
]

{ #category : 'accessing' }
CoreGbsMethodChangeAnnouncementFixture >> selector: aSelector [
	selector := aSelector
]
