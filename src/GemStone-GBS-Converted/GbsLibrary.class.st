Class {
	#name : 'GbsLibrary',
	#superclass : 'FFILibrary',
	#classInstVars : [
		'MacLibraryName',
		'UnixLibraryName',
		'Win32LibraryName'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing - platform' }
GbsLibrary class >> gemstoneHome [
	| environment fallback |
	environment := (Smalltalk globals at: #OSEnvironment ifAbsent: [ nil ])
		ifNil: [ nil ]
		ifNotNil: [ :envClass |
			(envClass respondsTo: #current)
				ifTrue: [ [ envClass current ] on: Error do: [ nil ] ]
				ifFalse: [
					(envClass respondsTo: #default)
						ifTrue: [ [ envClass default ] on: Error do: [ nil ] ]
						ifFalse: [ nil ] ] ].
	environment ifNil: [
		environment := [ Smalltalk os environment ] on: Error do: [ nil ] ].
	environment ifNotNil: [
		^ environment at: 'GEMSTONE' ifAbsent: [ nil ] ].
	fallback := '/opt/gemstone/product' asFileReference.
	^ fallback exists ifTrue: [ fallback fullName ] ifFalse: [ nil ]
]

{ #category : 'accessing - platform' }
GbsLibrary class >> findLibrary: aPattern in: aDirectory [
	"Search for a library matching aPattern in aDirectory"
	| dir entries |
	aDirectory ifNil: [ ^ nil ].
	dir := aDirectory asFileReference.
	dir exists ifFalse: [ ^ nil ].
	entries := dir files select: [ :each | aPattern match: each basename ].
	entries ifEmpty: [ ^ nil ].
	^ entries first fullName
]

{ #category : 'accessing - platform' }
GbsLibrary class >> macLibraryName [
	| home |
	MacLibraryName ifNotNil: [ ^ MacLibraryName ].
	home := self gemstoneHome.
	home ifNotNil: [ 
		| libDir |
		libDir := home asFileReference / 'lib'.
		(self findLibrary: 'libgcirpc-*-64.dylib' in: libDir) ifNotNil: [ :path | 
			^ MacLibraryName := path ] ].
	^ MacLibraryName := './libgcirpc-3.7.4.3-64.dylib'
]

{ #category : 'accessing - platform' }
GbsLibrary class >> unixLibraryName [
	| home |
	UnixLibraryName ifNotNil: [ ^ UnixLibraryName ].
	home := self gemstoneHome.
	home ifNotNil: [ 
		| libDir |
		libDir := home asFileReference / 'lib'.
		(self findLibrary: 'libgcirpc-*-64.so' in: libDir) ifNotNil: [ :path | 
			^ UnixLibraryName := path ] ].
	^ UnixLibraryName := 'libgcirpc-3.7.4.3-64.so'
]

{ #category : 'accessing - platform' }
GbsLibrary class >> win32LibraryName [
	| home |
	Win32LibraryName ifNotNil: [ ^ Win32LibraryName ].
	home := self gemstoneHome.
	home ifNotNil: [ 
		| libDir |
		libDir := home asFileReference / 'lib'.
		(self findLibrary: 'libgcirpc-*-64.dll' in: libDir) ifNotNil: [ :path | 
			^ Win32LibraryName := path ].
		libDir := home asFileReference / 'bin'.
		(self findLibrary: 'libgcirpc-*-64.dll' in: libDir) ifNotNil: [ :path | 
			^ Win32LibraryName := path ] ].
	^ Win32LibraryName := 'libgcirpc-3.7.4.3-64.dll'
]

{ #category : 'as yet unclassified' }
GbsLibrary class >> macLibraryName: aString [
	MacLibraryName := aString
]

{ #category : 'class initialization' }
GbsLibrary class >> reset [
	MacLibraryName := nil.
	UnixLibraryName := nil.
	Win32LibraryName := nil
]

{ #category : 'accessing - platform' }
GbsLibrary >> macLibraryName [
	^ self class macLibraryName
]

{ #category : 'accessing - platform' }
GbsLibrary >> unixLibraryName [
	^ self class unixLibraryName
]

{ #category : 'accessing - platform' }
GbsLibrary >> win32LibraryName [
	^ self class win32LibraryName
]
