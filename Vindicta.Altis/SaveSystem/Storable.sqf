#include "..\OOP_Light\OOP_Light.h"

/*
Class: Storable
Base class for classes which support saving and loading features
*/

CLASS("Storable", "")

	// - - - - VIRTUAL METHODS - - - - -
	// These might be overriden to customize saving of objects

	// Must return true on success
	/* virtual */ METHOD("preSerialize") {
		params [P_THISOBJECT, P_OOP_OBJECT("_storage")];
		
		// Call method of all base classes
		//CALL_CLASS_METHOD(... , _thisObject, "preSerialize", [_storage]);

		true
	} ENDMETHOD;

	// Returns an array, does not have to be a deep copy
	// Must return nil on failure
	// By default it serializes variables with ATTR_SAVE attribute
	/* virtual */ METHOD("serializeForStorage") {
		params [P_THISOBJECT];
		SERIALIZE_ATTR(_thisObject, ATTR_SAVE);
	} ENDMETHOD;

	// Must return true on success
	/* virtual */ METHOD("postSerialize") {
		params [P_THISOBJECT, P_OOP_OBJECT("_storage")];
		
		// Call method of all base classes
		//CALL_CLASS_METHOD(... , _thisObject, "postSerialize", [_storage]);
		
		true
	} ENDMETHOD;

	// These methods must return true on success
	/* virtual */ METHOD("preDeserialize") {
		params [P_THISOBJECT, P_OOP_OBJECT("_storage")];

		// Call method of all base classes
		//CALL_CLASS_METHOD(... , _thisObject, "preDeserialize", [_storage]);

		true
	} ENDMETHOD;

	// Must deserialize from an array into this object
	// By default it deserializes variables with ATTR_SAVE attribute
	/* virtual */ METHOD("deserializeFromStorage") {
		params [P_THISOBJECT, P_ARRAY("_serial")];
		DESERIALIZE_ATTR(_thisObject, _serial, ATTR_SAVE);
		true
	} ENDMETHOD;

	/* virtual */ METHOD("postDeserialize") {
		params [P_THISOBJECT, P_OOP_OBJECT("_storage")];

		// Call method of all base classes
		//CALL_CLASS_METHOD(... , _thisObject, "postDeserialize", [_storage]);

		true
	} ENDMETHOD;

	/* virtual */ STATIC_METHOD("saveStaticVariables") {
		params [P_THISCLASS, P_OOP_OBJECT("_storage")];
		OOP_ERROR_1("saveStaticVariables is not implemented for %1", _thisClass);
	} ENDMETHOD;

	/* virtual */ STATIC_METHOD("loadStaticVariables") {
		params [P_THISCLASS, P_OOP_OBJECT("_storage")];
		OOP_ERROR_1("saveStaticVariables is not implemented for %1", _thisClass);
	} ENDMETHOD;

ENDCLASS;