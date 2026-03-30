Class {
	#name : 'GbxKeyIndexElement',
	#superclass : 'GbxKeyedElement',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxKeyIndexElement class >> of: anObject at: anIndex value: aValue valueName: aValueName [
	^ self new
		keyDelegate: anIndex;
		keyName: anIndex asString;
		valueDelegate: aValue;
		valueName: aValueName;
		partName: '[', anIndex asString, ']';
		yourself
]
