Class {
	#name : 'Navigator',
	#superclass : 'ApplicationModel',
	#instVars : [
		'visit',
		'shell',
		'inspector',
		'inspectorClasses',
		'inspectorCache',
		'inspectorHolder',
		'initialInspectorClass'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'private' }
Navigator >> refreshInspectorClasses
[
	"because tab labels are dynamic in GemStone inspectors, we have to a bit of ugly coding
	to get them to change properly. Ideally, Trippy would have had its tabLabel class on
	the instance side, unique to each inspector tab"

	| selectionIndex inspectedObj lbl wrappedObject |
	self nilInitialInspector.
	self ignoringInspectorSelectionChange: 
			[inspectorClasses := self objectInspectorClasses.
			wrappedObject := Tools.Trippy.Inspector wrappedOrNot: visit object.
			(GemStone.Gbs.GbxReflection isWrapped: wrappedObject)
				ifTrue: 
					[inspectedObj := wrappedObject inspectedObject.
					inspectedObj isGSObject
						ifTrue: 
							[initialInspectorClass := (inspectorClasses
										select: [:each | 'Gbx*' match: each name]) first]
						ifFalse: 
							[inspectedObj gbxDelegate isNil
								ifFalse: [initialInspectorClass := inspectorClasses first]]].
			self inspectorHolder
				list: (inspectorClasses collect: 
							[:each |
							lbl := (each tabLabel isString or: [each tabLabel isKindOf: UserMessage])
										ifTrue: [(each tabLabel asString copyWithout: $&) asText]
										ifFalse: [each tabLabel asText].
							each == initialInspectorClass
								ifTrue: 
									[lbl := lbl asText
												emphasizeAllWith: (Array with: #bold with: (lbl emphasisAt: lbl size))].
							lbl])
						asList.
			selectionIndex := inspectorClasses indexOf: inspector class.
			self inspectorHolder selectionIndex: selectionIndex.
			inspectorCache := Array new: inspectorClasses size.
			inspectorCache at: selectionIndex put: inspector]
]

{ #category : 'private' }
Navigator >> objectInspectorClasses
[
	"Override to support GemStone server objects.
	 Note that the override discards the WatchLogInspector from the VW implementation.
	 But, that's ok (not!), because it adds it in some other places, but probably not everywhere it's needed."

	| oc obj |
	obj := Inspector wrappedOrNot: visit object.
	oc := (Inspector gbxCautiousInspectorClassesFor: obj) asOrderedCollection.
	^oc asArray
]

{ #category : 'private' }
Navigator >> replaceInspectorWithOneOn: anObject
[
	"GBS: down amongst the parts, make sure that we are using the proper object. wrappers for gbs tabs and client objects for client tabs"

	| newClass newInspector index object |
	inspectorClasses := self objectInspectorClasses.
	newClass := (inspectorClasses includes: inspector class)
		ifTrue: [inspector class]
		ifFalse: [inspectorClasses first].
	object := anObject inspectableObjectFor: newClass.
	newInspector := newClass on: object.
	inspector copyStateTo: newInspector.
	inspector := newInspector.
	builder notNil ifTrue: [self reinstallInspector].
	shell focusObjectChanged.
	self ignoringInspectorSelectionChange:
		[self inspectorHolder list: 
			(inspectorClasses collect: [:each | each tabLabel asString copyWithout: $&]).
		inspectorCache := Array new: inspectorClasses size.
		index := inspectorClasses indexOf: inspector class.
		self inspectorHolder selectionIndex: index.
		inspectorCache at: index put: inspector]
]

{ #category : 'notifications' }
Navigator >> inspectorSelectionChanged
[

	| index newBuilder |
	index := self inspectorHolder selectionIndex.
	inspector := (inspectorCache at: index) isNil
				ifTrue: [self gbxCreateInspectorForObjectAt: index]
				ifFalse: [inspectorCache at: index].
	inspector builder: nil.
	(builder componentAt: #inspector) widget
		client: inspector
		spec: inspector specName
		builder: (newBuilder := builder newSubBuilder).
	inspector installedWith: newBuilder.
	shell focusObjectChanged	"it didn't but the UI update may be needed anyway"
]

{ #category : 'instance creation' }
Navigator class >> visit: aVisit shell: aShell
[
	"GBS: if the visit is a PartVisit, and the object is a delegate. We should rightfully change the part into something more GemStoney. This should only be done if we really want to learn abou the part, say during a dive."

	| inspectorClass object visitsObject |
	visitsObject := Inspector wrappedOrNot: aVisit object.
	inspectorClass := (Inspector gbxCautiousInspectorClassesFor: visitsObject)
				at: 1.
	object := GemStone.Gbs.GbxReflection
				send: #inspectableObjectFor:
				to: visitsObject
				with: inspectorClass
				ifNotUnderstood: [visitsObject].
	^self new
		initialize: aVisit
		shell: aShell
		inspector: (inspectorClass on: object)
]

