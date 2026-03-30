Class {
	#name : 'GbxRuntimeOverrideSpec',
	#superclass : 'GbxAbstractOverrideSpec',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxRuntimeOverrideSpec class >> overridesPackageName [
	^ 'GbsRuntimeOverrides'
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> spec832 [
	<version: '8.3.2'>
	^ GbxOverrideSet
		destinationPackageName: self overridesPackageName
		classOverrides: #()
		variableOverrides: #()
		methodOverrides: (OrderedCollection new
				add: (GbxMethodOverride
							behavior: Bag
							selector: #add:withOccurrences:
							crc: 1268044848
							edits: (OrderedCollection new
									add: (GbxOverrideEditCopy count: 447);
									add: (GbxOverrideEditInsert string: 'self gbxConsiderModified.	"Force self to be modified, thus marked dirty if it''s a GBS replicate"
	');
									add: (GbxOverrideEditCopy count: 10);
									yourself));
				add: (GbxMethodOverride
							behavior: Bag
							selector: #remove:ifAbsent:
							crc: 2108386237
							edits: (OrderedCollection new
									add: (GbxOverrideEditCopy count: 521);
									add: (GbxOverrideEditInsert string: 'self gbxConsiderModified.
	');
									add: (GbxOverrideEditCopy count: 10);
									yourself));
				add: (GbxMethodOverride
							behavior: Bag
							selector: #removeAllOccurrencesOf:ifAbsent:
							crc: 3655069410
							edits: (OrderedCollection new
									add: (GbxOverrideEditCopy count: 150);
									add: (GbxOverrideEditDelete count: 1);
									add: (GbxOverrideEditInsert string: '| objectPresent result |
	objectPresent := true.	"Assume until proven otherwise."
	result := ');
									add: (GbxOverrideEditCopy count: 28);
									add: (GbxOverrideEditDelete count: 1);
									add: (GbxOverrideEditInsert string: '
				');
									add: (GbxOverrideEditCopy count: 9);
									add: (GbxOverrideEditInsert string: ' 
					[objectPresent :=');
									add: (GbxOverrideEditCopy count: 1);
									add: (GbxOverrideEditInsert string: 'false.
					');
									add: (GbxOverrideEditCopy count: 6);
									add: (GbxOverrideEditInsert string: ' value].
	objectPresent ifTrue: [self gbxConsiderModified].	"Force self to be modifed, thus marked dirty if a GBS replicate."
	^result');
									yourself));
				add: (GbxMethodOverride
							behavior: IdentityDictionary
							selector: #at:put:
							crc: 4013936043
							edits: (OrderedCollection new
									add: (GbxOverrideEditCopy count: 354);
									add: (GbxOverrideEditInsert string: '
			');
									add: (GbxOverrideEditCopy count: 32);
									add: (GbxOverrideEditInsert string: '.
			self gbxConsiderModified	"Force self to be modifed, thus marked dirty if I''m a GBS replicate"');
									add: (GbxOverrideEditCopy count: 10);
									yourself));
				yourself)
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> spec911 [
	<version: '9.1.1'>
	^ GbxOverrideSet
		destinationPackageName: self overridesPackageName
		classOverrides: #()
		variableOverrides: #()
		methodOverrides: (OrderedCollection new
				add: (GbxMethodOverride
							behavior: Bag
							selector: #add:withOccurrences:
							crc: 1268044848
							edits: (OrderedCollection new
									add: (GbxOverrideEditCopy count: 266);
									add: (GbxOverrideEditDelete count: 1);
									add: (GbxOverrideEditCopy count: 49);
									add: (GbxOverrideEditDelete count: 3);
									add: (GbxOverrideEditInsert string: ' ');
									add: (GbxOverrideEditCopy count: 13);
									add: (GbxOverrideEditDelete count: 3);
									add: (GbxOverrideEditInsert string: ' ');
									add: (GbxOverrideEditCopy count: 14);
									add: (GbxOverrideEditDelete count: 1);
									add: (GbxOverrideEditInsert string: '
				');
									add: (GbxOverrideEditCopy count: 96);
									add: (GbxOverrideEditInsert string: '	self gbxConsiderModified.');
									add: (GbxOverrideEditCopy count: 1);
									add: (GbxOverrideEditInsert string: '"Force self to be modified, thus marked dirty if it''s a GBS replicate"
	');
									add: (GbxOverrideEditCopy count: 10);
									yourself));
				add: (GbxMethodOverride
							behavior: Bag
							selector: #remove:ifAbsent:
							crc: 2108386237
							edits: (OrderedCollection new
									add: (GbxOverrideEditCopy count: 42);
									add: (GbxOverrideEditDelete count: 2);
									add: (GbxOverrideEditCopy count: 474);
									add: (GbxOverrideEditInsert string: '.
	self gbxConsiderModified');
									add: (GbxOverrideEditCopy count: 13);
									yourself));
				add: (GbxMethodOverride
							behavior: Bag
							selector: #removeAllOccurrencesOf:ifAbsent:
							crc: 3655069410
							edits: (OrderedCollection new
									add: (GbxOverrideEditCopy count: 150);
									add: (GbxOverrideEditDelete count: 1);
									add: (GbxOverrideEditInsert string: '| objectPresent result |
	objectPresent := true.	"Assume until proven otherwise."
	result := ');
									add: (GbxOverrideEditCopy count: 28);
									add: (GbxOverrideEditDelete count: 1);
									add: (GbxOverrideEditInsert string: '
				');
									add: (GbxOverrideEditCopy count: 9);
									add: (GbxOverrideEditInsert string: ' 
					[objectPresent :=');
									add: (GbxOverrideEditCopy count: 1);
									add: (GbxOverrideEditInsert string: 'false.
					');
									add: (GbxOverrideEditCopy count: 6);
									add: (GbxOverrideEditInsert string: ' value].
	objectPresent ifTrue: [self gbxConsiderModified].	"Force self to be modifed, thus marked dirty if a GBS replicate."
	^result');
									yourself));
				add: (GbxMethodOverride
							behavior: IdentityDictionary
							selector: #at:put:
							crc: 4013936043
							edits: (OrderedCollection new
									add: (GbxOverrideEditCopy count: 56);
									add: (GbxOverrideEditDelete count: 1);
									add: (GbxOverrideEditCopy count: 23);
									add: (GbxOverrideEditDelete count: 1);
									add: (GbxOverrideEditInsert string: '
		');
									add: (GbxOverrideEditCopy count: 273);
									add: (GbxOverrideEditInsert string: '
			');
									add: (GbxOverrideEditCopy count: 32);
									add: (GbxOverrideEditInsert string: '.
			self gbxConsiderModified	"Force self to be modifed, thus marked dirty if I''m a GBS replicate"');
									add: (GbxOverrideEditCopy count: 10);
									yourself));
				yourself)
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> spec921 [
	<version: '9.2.1'>
	^ self spec911
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> spec93 [
	<version: '9.3'>
	^ GbxOverrideSet
		destinationPackageName: self overridesPackageName
		classOverrides: #()
		variableOverrides: #()
		methodOverrides: (OrderedCollection new
				add: (GbxMethodOverride
							behavior: Bag
							selector: #add:withOccurrences:
							crc: 1268044848
							edits: (OrderedCollection new
									add: (GbxOverrideEditCopy count: 447);
									add: (GbxOverrideEditInsert string: 'self gbxConsiderModified.	"Force self to be modified, thus marked dirty if it''s a GBS replicate"
	');
									add: (GbxOverrideEditCopy count: 10);
									yourself));
				add: (GbxMethodOverride
							behavior: Bag
							selector: #remove:ifAbsent:
							crc: 2108386237
							edits: (OrderedCollection new
									add: (GbxOverrideEditCopy count: 42);
									add: (GbxOverrideEditDelete count: 2);
									add: (GbxOverrideEditCopy count: 474);
									add: (GbxOverrideEditInsert string: '.
	self gbxConsiderModified');
									add: (GbxOverrideEditCopy count: 13);
									yourself));
				add: (GbxMethodOverride
							behavior: Bag
							selector: #removeAllOccurrencesOf:ifAbsent:
							crc: 3655069410
							edits: (OrderedCollection new
									add: (GbxOverrideEditCopy count: 150);
									add: (GbxOverrideEditDelete count: 1);
									add: (GbxOverrideEditInsert string: '| objectPresent result |
	objectPresent := true.	"Assume until proven otherwise."
	result := ');
									add: (GbxOverrideEditCopy count: 28);
									add: (GbxOverrideEditDelete count: 1);
									add: (GbxOverrideEditInsert string: '
				');
									add: (GbxOverrideEditCopy count: 9);
									add: (GbxOverrideEditInsert string: ' 
					[objectPresent :=');
									add: (GbxOverrideEditCopy count: 1);
									add: (GbxOverrideEditInsert string: 'false.
					');
									add: (GbxOverrideEditCopy count: 6);
									add: (GbxOverrideEditInsert string: ' value].
	objectPresent ifTrue: [self gbxConsiderModified].	"Force self to be modifed, thus marked dirty if a GBS replicate."
	^result');
									yourself));
				add: (GbxMethodOverride
							behavior: IdentityDictionary
							selector: #at:put:
							crc: 4013936043
							edits: (OrderedCollection new
									add: (GbxOverrideEditCopy count: 354);
									add: (GbxOverrideEditInsert string: '
			');
									add: (GbxOverrideEditCopy count: 32);
									add: (GbxOverrideEditInsert string: '.
			self gbxConsiderModified	"Force self to be modifed, thus marked dirty if I''m a GBS replicate"');
									add: (GbxOverrideEditCopy count: 10);
									yourself));
				yourself)
]
