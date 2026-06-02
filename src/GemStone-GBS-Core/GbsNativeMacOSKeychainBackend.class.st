Class {
	#name : 'GbsNativeMacOSKeychainBackend',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'accessing' }
GbsNativeMacOSKeychainBackend class >> isAvailable [
	^ self new isAvailable
]

{ #category : 'accessing' }
GbsNativeMacOSKeychainBackend class >> secretAt: accountName service: serviceName [
	^ self new secretAt: accountName service: serviceName
]

{ #category : 'accessing' }
GbsNativeMacOSKeychainBackend class >> secretAt: accountName put: secretString service: serviceName [
	^ self new
		secretAt: accountName
		put: secretString
		service: serviceName
]

{ #category : 'accessing' }
GbsNativeMacOSKeychainBackend class >> deleteSecretAt: accountName service: serviceName [
	^ self new deleteSecretAt: accountName service: serviceName
]

{ #category : 'constants' }
GbsNativeMacOSKeychainBackend >> coreFoundationLibraryName [
	^ '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation'
]

{ #category : 'constants' }
GbsNativeMacOSKeychainBackend >> duplicateItemStatus [
	^ -25299
]

{ #category : 'private' }
GbsNativeMacOSKeychainBackend >> externalAddressFromPointerInteger: pointerInteger [
	pointerInteger = 0 ifTrue: [ ^ nil ].
	^ ExternalAddress fromAddress: pointerInteger
]

{ #category : 'private' }
GbsNativeMacOSKeychainBackend >> findGenericPasswordForAccount: accountName service: serviceName passwordLength: passwordLengthPointer passwordData: passwordDataPointer itemRef: itemRefPointer [
	^ self
		withCStringFor: serviceName
		do: [ :serviceCString :serviceLength |
			self
				withCStringFor: accountName
				do: [ :accountCString :accountLength |
					self
						secKeychainFindGenericPasswordIn: nil
						serviceLength: serviceLength
						service: serviceCString
						accountLength: accountLength
						account: accountCString
						passwordLength: passwordLengthPointer
						passwordData: passwordDataPointer
						itemRef: itemRefPointer ] ]
]

{ #category : 'constants' }
GbsNativeMacOSKeychainBackend >> itemNotFoundStatus [
	^ -25300
]

{ #category : 'private' }
GbsNativeMacOSKeychainBackend >> itemRefForAccount: accountName service: serviceName [
	| itemRefPointer status itemRefPointerInteger |
	itemRefPointer := ExternalAddress allocate: self pointerSize.
	self zeroExternalAddress: itemRefPointer bytes: self pointerSize.
	^ [
		status := self
			findGenericPasswordForAccount: accountName
			service: serviceName
			passwordLength: nil
			passwordData: nil
			itemRef: itemRefPointer.
		status = self itemNotFoundStatus ifTrue: [ ^ nil ].
		self signalStatus: status label: 'Could not find GemStone session secret in macOS Keychain'.
		itemRefPointerInteger := self pointerIntegerAt: itemRefPointer.
		self externalAddressFromPointerInteger: itemRefPointerInteger
	] ensure: [ itemRefPointer free ]
]

{ #category : 'testing' }
GbsNativeMacOSKeychainBackend >> isAvailable [
	^ self isMacOS and: [ self securityLibraryExists ]
]

{ #category : 'testing' }
GbsNativeMacOSKeychainBackend >> isMacOS [
	| os |
	os := [ Smalltalk os ]
		on: Error
		do: [ nil ].
	os ifNil: [ ^ self securityLibraryExists ].
	(os respondsTo: #isMacOS) ifTrue: [ ^ os isMacOS ].
	(os respondsTo: #platformName) ifTrue: [
		^ os platformName asString asLowercase includesSubstring: 'mac' ].
	^ self securityLibraryExists
]

{ #category : 'constants' }
GbsNativeMacOSKeychainBackend >> noErrStatus [
	^ 0
]

{ #category : 'private' }
GbsNativeMacOSKeychainBackend >> passwordBytesFromPointer: pointerInteger length: byteCount [
	| address bytes |
	byteCount = 0 ifTrue: [ ^ ByteArray new ].
	address := self externalAddressFromPointerInteger: pointerInteger.
	address ifNil: [ self error: 'macOS Keychain returned a null secret pointer.' ].
	bytes := ByteArray new: byteCount.
	1 to: byteCount do: [ :index |
		bytes at: index put: (address unsignedByteAt: index) ].
	^ bytes
]

{ #category : 'constants' }
GbsNativeMacOSKeychainBackend >> pointerSize [
	^ 8
]

{ #category : 'private' }
GbsNativeMacOSKeychainBackend >> pointerIntegerAt: pointerAddress [
	^ pointerAddress
		integerAt: 1
		size: self pointerSize
		signed: false
]

{ #category : 'releasing' }
GbsNativeMacOSKeychainBackend >> releaseItemRefPointer: pointerInteger [
	| address |
	pointerInteger = 0 ifTrue: [ ^ self ].
	address := self externalAddressFromPointerInteger: pointerInteger.
	address ifNotNil: [ self cfRelease: address ].
	^ self
]

{ #category : 'accessing' }
GbsNativeMacOSKeychainBackend >> secretAt: accountName service: serviceName [
	| passwordLengthPointer passwordDataPointer itemRefPointer status passwordLength passwordDataPointerInteger itemRefPointerInteger bytes |
	self signalUnsupportedIfUnavailable.
	passwordLengthPointer := ExternalAddress allocate: 4.
	passwordDataPointer := ExternalAddress allocate: self pointerSize.
	itemRefPointer := ExternalAddress allocate: self pointerSize.
	passwordDataPointerInteger := 0.
	itemRefPointerInteger := 0.
	self zeroExternalAddress: passwordLengthPointer bytes: 4.
	self zeroExternalAddress: passwordDataPointer bytes: self pointerSize.
	self zeroExternalAddress: itemRefPointer bytes: self pointerSize.
	^ [
		status := self
			findGenericPasswordForAccount: accountName
			service: serviceName
			passwordLength: passwordLengthPointer
			passwordData: passwordDataPointer
			itemRef: itemRefPointer.
		status = self itemNotFoundStatus ifTrue: [ ^ nil ].
		self signalStatus: status label: 'Could not read GemStone session secret from macOS Keychain'.
		passwordLength := self uint32At: passwordLengthPointer.
		passwordDataPointerInteger := self pointerIntegerAt: passwordDataPointer.
		itemRefPointerInteger := self pointerIntegerAt: itemRefPointer.
		bytes := self
			passwordBytesFromPointer: passwordDataPointerInteger
			length: passwordLength.
		self stringFromUTF8Bytes: bytes
	] ensure: [
		passwordDataPointerInteger = 0 ifFalse: [
			self
				secKeychainItemFreeContentAttributes: nil
				data: (self externalAddressFromPointerInteger: passwordDataPointerInteger) ].
		self releaseItemRefPointer: itemRefPointerInteger.
		passwordLengthPointer free.
		passwordDataPointer free.
		itemRefPointer free ]
]

{ #category : 'accessing' }
GbsNativeMacOSKeychainBackend >> secretAt: accountName put: secretString service: serviceName [
	| itemRefPointer status itemRefPointerInteger |
	self signalUnsupportedIfUnavailable.
	itemRefPointer := ExternalAddress allocate: self pointerSize.
	itemRefPointerInteger := 0.
	self zeroExternalAddress: itemRefPointer bytes: self pointerSize.
	^ [
		self
			withCStringFor: serviceName
			do: [ :serviceCString :serviceLength |
				self
					withCStringFor: accountName
					do: [ :accountCString :accountLength |
						self
							withBytesFor: secretString
							do: [ :secretBytes :secretLength |
								status := self
									secKeychainAddGenericPasswordIn: nil
									serviceLength: serviceLength
									service: serviceCString
									accountLength: accountLength
									account: accountCString
									passwordLength: secretLength
									passwordData: secretBytes
									itemRef: itemRefPointer.
								itemRefPointerInteger := self pointerIntegerAt: itemRefPointer.
								status = self duplicateItemStatus
									ifTrue: [
										self releaseItemRefPointer: itemRefPointerInteger.
										itemRefPointerInteger := 0.
										self
											updateSecretAt: accountName
											putBytes: secretBytes
											byteCount: secretLength
											service: serviceName ]
									ifFalse: [
										self signalStatus: status label: 'Could not store GemStone session secret in macOS Keychain' ] ] ] ].
		secretString
	] ensure: [
		self releaseItemRefPointer: itemRefPointerInteger.
		itemRefPointer free ]
]

{ #category : 'accessing' }
GbsNativeMacOSKeychainBackend >> deleteSecretAt: accountName service: serviceName [
	| itemRef status |
	self signalUnsupportedIfUnavailable.
	itemRef := self itemRefForAccount: accountName service: serviceName.
	itemRef ifNil: [ ^ self ].
	[
		status := self secKeychainItemDelete: itemRef.
		(status = self noErrStatus or: [ status = self itemNotFoundStatus ])
			ifFalse: [ self signalStatus: status label: 'Could not delete GemStone session secret from macOS Keychain' ].
		^ self
	] ensure: [ self cfRelease: itemRef ]
]

{ #category : 'ffi' }
GbsNativeMacOSKeychainBackend >> cfRelease: cfObject [
	^ self
		ffiCall: #(void CFRelease(void* cfObject))
		module: self coreFoundationLibraryName
		options: #( + optNonThreaded )
]

{ #category : 'constants' }
GbsNativeMacOSKeychainBackend >> securityLibraryName [
	^ '/System/Library/Frameworks/Security.framework/Security'
]

{ #category : 'testing' }
GbsNativeMacOSKeychainBackend >> securityLibraryExists [
	^ [ self securityLibraryName asFileReference exists ]
		on: Error
		do: [ false ]
]

{ #category : 'ffi' }
GbsNativeMacOSKeychainBackend >> secKeychainAddGenericPasswordIn: keychain serviceLength: serviceLength service: serviceBytes accountLength: accountLength account: accountBytes passwordLength: passwordLength passwordData: passwordData itemRef: itemRefPointer [
	^ self
		ffiCall: #(int SecKeychainAddGenericPassword(void* keychain, uint serviceLength, void* serviceBytes, uint accountLength, void* accountBytes, uint passwordLength, void* passwordData, void* itemRefPointer))
		module: self securityLibraryName
		options: #( + optNonThreaded )
]

{ #category : 'ffi' }
GbsNativeMacOSKeychainBackend >> secKeychainFindGenericPasswordIn: keychain serviceLength: serviceLength service: serviceBytes accountLength: accountLength account: accountBytes passwordLength: passwordLengthPointer passwordData: passwordDataPointer itemRef: itemRefPointer [
	^ self
		ffiCall: #(int SecKeychainFindGenericPassword(void* keychain, uint serviceLength, void* serviceBytes, uint accountLength, void* accountBytes, void* passwordLengthPointer, void* passwordDataPointer, void* itemRefPointer))
		module: self securityLibraryName
		options: #( + optNonThreaded )
]

{ #category : 'ffi' }
GbsNativeMacOSKeychainBackend >> secKeychainItemDelete: itemRef [
	^ self
		ffiCall: #(int SecKeychainItemDelete(void* itemRef))
		module: self securityLibraryName
		options: #( + optNonThreaded )
]

{ #category : 'ffi' }
GbsNativeMacOSKeychainBackend >> secKeychainItemFreeContentAttributes: attributes data: dataPointer [
	^ self
		ffiCall: #(int SecKeychainItemFreeContent(void* attributes, void* dataPointer))
		module: self securityLibraryName
		options: #( + optNonThreaded )
]

{ #category : 'ffi' }
GbsNativeMacOSKeychainBackend >> secKeychainItemModifyAttributesAndData: itemRef attributes: attributes length: byteCount data: dataPointer [
	^ self
		ffiCall: #(int SecKeychainItemModifyAttributesAndData(void* itemRef, void* attributes, uint byteCount, void* dataPointer))
		module: self securityLibraryName
		options: #( + optNonThreaded )
]

{ #category : 'errors' }
GbsNativeMacOSKeychainBackend >> signalStatus: status label: labelString [
	status = self noErrStatus ifTrue: [ ^ status ].
	self error: labelString, ' (Security.framework status ', status asString, ').'
]

{ #category : 'errors' }
GbsNativeMacOSKeychainBackend >> signalUnsupportedIfUnavailable [
	self isAvailable ifFalse: [
		self error: 'Native macOS Keychain backend is not available on this platform.' ].
	^ self
]

{ #category : 'private' }
GbsNativeMacOSKeychainBackend >> stringFromUTF8Bytes: byteArray [
	(byteArray respondsTo: #utf8Decoded) ifTrue: [ ^ byteArray utf8Decoded ].
	^ byteArray asString
]

{ #category : 'private' }
GbsNativeMacOSKeychainBackend >> uint32At: pointerAddress [
	^ pointerAddress
		integerAt: 1
		size: 4
		signed: false
]

{ #category : 'private' }
GbsNativeMacOSKeychainBackend >> updateSecretAt: accountName putBytes: secretBytes byteCount: secretLength service: serviceName [
	| itemRef status |
	itemRef := self itemRefForAccount: accountName service: serviceName.
	itemRef ifNil: [ self error: 'Could not find existing GemStone session secret in macOS Keychain.' ].
	[
		status := self
			secKeychainItemModifyAttributesAndData: itemRef
			attributes: nil
			length: secretLength
			data: secretBytes.
		self signalStatus: status label: 'Could not update GemStone session secret in macOS Keychain'
	] ensure: [ self cfRelease: itemRef ]
]

{ #category : 'private' }
GbsNativeMacOSKeychainBackend >> utf8BytesFor: aString [
	^ aString asString utf8Encoded asByteArray
]

{ #category : 'private' }
GbsNativeMacOSKeychainBackend >> withBytesFor: aString do: aBlock [
	| bytes pointer allocationSize |
	bytes := self utf8BytesFor: aString.
	allocationSize := bytes size max: 1.
	pointer := ExternalAddress allocate: allocationSize.
	^ [
		1 to: bytes size do: [ :index |
			pointer unsignedByteAt: index put: (bytes at: index) ].
		aBlock value: pointer value: bytes size
	] ensure: [ pointer free ]
]

{ #category : 'private' }
GbsNativeMacOSKeychainBackend >> withCStringFor: aString do: aBlock [
	| bytes pointer |
	bytes := self utf8BytesFor: aString.
	pointer := ExternalAddress allocate: bytes size + 1.
	^ [
		1 to: bytes size do: [ :index |
			pointer unsignedByteAt: index put: (bytes at: index) ].
		pointer unsignedByteAt: bytes size + 1 put: 0.
		aBlock value: pointer value: bytes size
	] ensure: [ pointer free ]
]

{ #category : 'private' }
GbsNativeMacOSKeychainBackend >> zeroExternalAddress: anExternalAddress bytes: byteCount [
	1 to: byteCount do: [ :index |
		anExternalAddress unsignedByteAt: index put: 0 ].
	^ anExternalAddress
]
