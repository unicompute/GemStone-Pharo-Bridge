Class {
	#name : #'GbxStructureSync',
	#superclass : #'GbxRemoteObject',
	#instVars : [ #'gsObj' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'accessing' }
GbxStructureSync >> stObjTable

	StObjTable isNil ifTrue: [StObjTable := GbxLargeIdentityDictionary newWeakValues: 10].
	^StObjTable

{ #category : #'accessing' }
GbxStructureSync >> stObj

	"^stObj"
	^StObjTable at: self otherwise: nil

{ #category : #'printing' }
GbxStructureSync >> gbxDebugPrintOn: aStream

	self printOn: aStream.
	aStream nextPutAll: ' for '.
	gsObj gbxDebugPrintOn: aStream.

{ #category : #'initialization' }
GbxStructureSync >> stObj: st gsObj: gs

	"stObj := st."
	self stObjTable at: self put: st.
	gsObj := gs.

{ #category : #'proxy methods' }
GbxStructureSync >> isReadOnlyObject

	^gsObj isReadOnlyObject

{ #category : #'proxy methods' }
GbxStructureSync >> forSession: aGSSession

	^gsObj forSession: aGSSession

{ #category : #'proxy methods' }
GbxStructureSync >> session

	^gsObj session

{ #category : #'proxy methods' }
GbxStructureSync >> markStDirty: st
	"Mark the top-level object dirty"

	gsObj markStDirty: self stObj

{ #category : #'proxy methods' }
GbxStructureSync >> notForSession: aGSSession

	^gsObj notForSession: aGSSession

{ #category : #'instance creation' }
GbxStructureSync class >> stObj: st gsObj: gs

	^self new stObj: st gsObj: gs

