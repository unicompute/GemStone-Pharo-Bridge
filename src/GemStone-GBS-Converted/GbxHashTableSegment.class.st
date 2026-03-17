Class {
	#name : #'GbxHashTableSegment',
	#superclass : #'Object',
	#instVars : [ #'upperBytes' #'parent' #'parentIndex' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'private-auditing' }
GbxHashTableSegment >> auditParentage: expectedParent index: expectedParentIndex upperBytes: expectedUpperBytes into: results
	"Not all subclasses need to implement this, so it cannot be a subclass responsibility."

{ #category : #'private-auditing' }
GbxHashTableSegment >> auditElementsInto: results session: aSession
	"Not all subclasses need to implement this, so it cannot be a subclass responsibility."

{ #category : #'private-auditing' }
GbxHashTableSegment >> auditNilElementClient: client delegate: del into: results
	"Things checked here:
	* each unused element should have a nil delegate and a nil clientObj"

	results
		assert: client == nil
		node: self
		description: 'element with nil key had a client object of  %1, expected %2.'
		actual: client
		expected: 'nil'.
	results
		assert: del == nil
		node: self
		description: 'element with nil key had a delegate of  %1, expected %2.'
		actual: del
		expected: 'nil'

{ #category : #'auditing' }
GbxHashTableSegment >> auditInto: results parent: expectedParent parentIndex: expectedParentIndex upperBytes: expectedUpperBytes session: aSession
	"Statistics gathered at this level:
	* Number of used elements (those with non-nil key).
	Things checked here:
	* my parent and index agree with those passed in
	* my upperBytes is the same as my parent's
	* needFinalization is a boolean
	* my basic size is correct"

	self
		auditParentage: expectedParent
		index: expectedParentIndex
		upperBytes: expectedUpperBytes
		into: results.
	"* all used elements have keys that are SmallIntegers in the correct range (1 to 2**24, inclusive)
	* all unused elements have nil keys
	* no used element should have a delegate or special for a client object
	* each used element has the correct delegate, or 0
	* each used element that has a non-zero client object should also have a non-zero delegate
	* each unused element should have a nil delegate and a nil clientObj"
	self auditElementsInto: results session: aSession

{ #category : #'private-accessing' }
GbxHashTableSegment >> upperBytes: anObject
	upperBytes := anObject

{ #category : #'private-accessing' }
GbxHashTableSegment >> parent: anObject
	parent := anObject

{ #category : #'private-accessing' }
GbxHashTableSegment >> parentIndex: anObject
	parentIndex := anObject

{ #category : #'private' }
GbxHashTableSegment class >> instanceBasicSize

	self subclassResponsibility

{ #category : #'instance creation' }
GbxHashTableSegment class >> parent: node index: parentIndex upperBytes: upperBytes

	| inst |
	inst := self basicNew: self instanceBasicSize.
	inst
		parent: node;
		initialize;
		parentIndex: parentIndex;
		upperBytes: upperBytes.
	^inst

