#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\common.hpp"

/*
Class: AI.CmdrAI.CmdrAction.CmdrAction
The base class for all commander actions. An Action is defined as any behaviour the commander can
choose whether to perform. 
In general the actions are parameterized and scored based on relevance and the commanders current strategy.
The scoring can be a complex as required, but in the end is reduced down to a single number that can be 
used in comparison between actions of the same type, and other types of the same priority level (see CmdrAI
for how this works).
The behaviour of the action is defined by a state machine, defined by a set of ActionStateTransitions and a 
set of associated variables (kind of like a blackboard system).
Usually one or more pieces of intel will be associated with a CmdrAction to allow them to be discoverable
by other commanders.

e.g. An action for a garrison to attack an outpost could be parameterized by the specific garrison and
     outpost, and scored based on how much the commander wants to control that outpost, how close the garrison is
     to it, and how well the garrison is predicted to do when fighting the enemy at the outpost.

Parent: <RefCounted>
*/
CLASS("CmdrAction", "RefCounted")

	// The priority of this action in relation to other actions of the same or different type.
	VARIABLE_ATTR("scorePriority", [ATTR_PRIVATE]);
	// The resourcing available for this action.
	VARIABLE_ATTR("scoreResource", [ATTR_PRIVATE]);
	// How strongly this action correlates with the current strategy.
	VARIABLE_ATTR("scoreStrategy", [ATTR_PRIVATE]);
	// How close to being complete this action is (>1)
	VARIABLE_ATTR("scoreCompleteness", [ATTR_PRIVATE]);

	// State transition functions
	VARIABLE_ATTR("transitions", [ATTR_PRIVATE]);

	// Registered AST_VARs. AST_VARs should be registered when they can be modified by any of the 
	// ASTs, so that they can be saved and restored during simulation (don't want simulation 
	// to effect real world actions).
	VARIABLE_ATTR("variables", [ATTR_PRIVATE]);
	// AST_VARs saved during simulation, to be restored afterwards.
	VARIABLE_ATTR("variablesStack", [ATTR_PRIVATE]);
	// Garrisons associated with this action, so we can automatically unassign this action from them 
	// when it is finished.
	VARIABLE_ATTR("garrisons", [ATTR_PRIVATE]);

	// Current AST state of this action
	VARIABLE_ATTR("state", [ATTR_GET_ONLY]);

	// Intel object associated with this action
	VARIABLE_ATTR("intel", [ATTR_GET_ONLY]);

	METHOD("new") {
		params [P_THISOBJECT];
		T_SETV("scorePriority", 1);
		T_SETV("scoreResource", 1);
		T_SETV("scoreStrategy", 1);
		T_SETV("scoreCompleteness", 1);
		T_SETV("state", CMDR_ACTION_STATE_START);
		T_SETV("transitions", []);
		T_SETV("variables", []);
		T_SETV("variablesStack", []);
		T_SETV("garrisons", []);
		T_SETV("intel", NULL_OBJECT);
	} ENDMETHOD;

	METHOD("delete") {
		params [P_THISOBJECT];
		T_PRVAR(garrisons);

		// Clean up this action from the garrisons it is assigned to
		{
			if(CALLM(_x, "getAction", []) == _thisObject) then {
				CALLM(_x, "clearAction", []);
			} else {
				OOP_WARNING_MSG("Garrison %1 was registered with action %2 but no longer has the action assigned", [_x ARG _thisObject]);
			};
		} foreach +_garrisons;

		T_PRVAR(intel);
		if(!IS_NULL_OBJECT(_intel)) then {
			DELETE(_intel);
		};
	} ENDMETHOD;

	/*
	Method: (protected) setScore
	Unpacks a score array (4 element number vector) into the individual scoring properties.

	Parameters:	
		_scoreVec - Array of Number, the score vector to assign
	*/
	/* protected */ METHOD("setScore") {
		params [P_THISOBJECT, P_ARRAY("_scoreVec")];
		T_SETV("scorePriority", GET_SCORE_PRIORITY(_scoreVec));
		T_SETV("scoreResource", GET_SCORE_RESOURCE(_scoreVec));
		T_SETV("scoreStrategy", GET_SCORE_STRATEGY(_scoreVec));
		T_SETV("scoreCompleteness", GET_SCORE_COMPLETENESS(_scoreVec));
	} ENDMETHOD;

	/*
	Method: (protected virtual) createTransitions
	Create the ASTs for the action and assign them to the transitions member variable.
	We do NOT do this in the constructor, because it is only required for actions that will
	definiely be used, and the vast majority of actions that are created are just speculative
	(they are scored and then discarded if the score is too low).
	*/
	/* protected virtual */ METHOD("createTransitions") {
		params [P_THISOBJECT];
	} ENDMETHOD;
	
	/*
	Method: registerGarrison
	Registers a garrison that has this action assigned to it, so we can automatically unassign 
	this action from it when it is finished (helps with cleanup).
	
	Parameters:
		_garrison - <Model.GarrisonModel>
	*/
	/*protected */ METHOD("registerGarrison") {
		params [P_THISOBJECT, P_OOP_OBJECT("_garrison")];
		ASSERT_OBJECT_CLASS(_garrison, "GarrisonModel");
		T_PRVAR(garrisons);
		_garrisons pushBack _garrison;
	} ENDMETHOD;

	/*
	Method: unregisterGarrison
	Remove a garrison from the list for which we will automatically an assign this action when 
	it is finished.
	
	Parameters:
		_garrison - <Model.GarrisonModel>
	*/
	/*protected */ METHOD("unregisterGarrison") {
		params [P_THISOBJECT, P_OOP_OBJECT("_garrison")];
		ASSERT_OBJECT_CLASS(_garrison, "GarrisonModel");
		T_PRVAR(garrisons);
		private _idx = _garrisons find _garrison;
		if(_idx == NOT_FOUND) exitWith {
			OOP_WARNING_MSG("Garrison %1 is not registered with action %2, so can't be unregistered", [_garrison ARG _thisObject]);
		};
		_garrisons deleteAt _idx;
	} ENDMETHOD;

	/*
	Method: (protected) addIntelToGarrison
	Add the intel object of this action to a specific garrison.
	
	Parameters:
		_garrison - <Model.GarrisonModel>, the garrion to assign the intel to.
	*/
	/*protected */ METHOD("addIntelToGarrison") {
		params [P_THISOBJECT, P_OOP_OBJECT("_garrison")];
		ASSERT_OBJECT_CLASS(_garrison, "GarrisonModel");
		if(CALLM(_garrison, "isActual", [])) then {
			T_PRVAR(intel);

			// Bail if null
			if (!IS_NULL_OBJECT(_intel)) then { // Because it can be objNull
				private _actual = GETV(_garrison, "actual");
				// It will make sure itself that it doesn't add duplicates of intel
				CALLM2(_actual, "postMethodAsync", "addIntel", [_intel]); 
				//CALLM1(_actual, "addIntel", _intel);
				
				// TODO: implement this Sparker. 
				// 	NOTES: Make Garrison.addIntel add the intel to the occupied location as well.
				// 	NOTES: Make Garrison.addIntel only add if it isn't already there because this will happen often.
				// CALLM2(_actual, "postMethodAsync", "addIntel", [_intel]);
			};
		};
	} ENDMETHOD;

	/*
	Method: (protected) addIntelAt
	Add the intel object of this action to garrisons in an area specified.
	
	Parameters:
		_world - <Model.WorldModel>, the world model in which to look for garrisons.
		_pos - Position, the center of the area in which we are placing intel.
		_radius - Number, default 2000, the radius in meters in which we are placing intel.
	*/
	/*protected */ METHOD("addIntelAt") {
		params [P_THISOBJECT, P_OOP_OBJECT("_world"), P_POSITION("_pos"), ["_radius", 2000, [0]]];
		ASSERT_OBJECT_CLASS(_world, "WorldModel");
		{
			_x params ["_distance", "_garrison"];
			private _chance =  1 - (_distance / _radius) ^ 2 + 0.1;
			if(_chance > random 1) then {
				T_CALLM("addIntelToGarrison", [_garrison]);
			};
		} forEach CALLM(_world, "getNearestGarrisons", [_pos ARG _radius]);
	} ENDMETHOD;	

	/*
	Method: (virtual) updateScore
	Called by <AI.CmdrAI.CmdrAI> when evaluating potential actions. It should use the world states and settings this
	action was initialized with to evaluate its subjective value, and then set the score* member variables 
	appropriately.
	
	Parameters:
		_worldNow - <Model.WorldModel>, simulation of world in its current state possibly with some instantaneous actions applied (e.g. resource allocation).
		_worldFuture - <Model.WorldModel>, simulation of world in its predicted state once all currently planned actions are complete.
	*/
	/* virtual */ METHOD("updateScore") {
		params [P_THISOBJECT, P_OOP_OBJECT("_worldNow"), P_OOP_OBJECT("_worldFuture")];
	} ENDMETHOD;

	/*protected */ METHOD("getFinalScore") {
		params [P_THISOBJECT];
		T_PRVAR(scorePriority);
		T_PRVAR(scoreResource);
		T_PRVAR(scoreStrategy);
		T_PRVAR(scoreCompleteness);
		// TODO: what is the correct to combine these scores?
		// Should we try to get them all from 0 to 1?
		// Maybe we want R*(iP + jS + kC)?
		_scorePriority * _scoreResource * _scoreStrategy * _scoreCompleteness
	} ENDMETHOD;

	/*
	Method: (protected) createVariable
	Creates and registers an <AST_VAR> variable for use with this actions ASTs. The registration ensures that the 
	value of the variable is saved and restored when performing simulations using this action. It is only required 
	if the value can be changed by any of the ASTs themselves. If it can't then you can just directly create 
	an <AST_VAR> without calling this function.
	
	Parameters:
		_initialValue - Any, initial value for the variable to hold.
	
	Returns: <AST_VAR> reference to the newly created and registered variable.
	*/
	/* protected */ METHOD("createVariable") {
		params [P_THISOBJECT, P_DYNAMIC("_initialValue")];
		T_PRVAR(variables);
		private _var = MAKE_AST_VAR(_initialValue);
		_variables pushBack _var;
		_var
	} ENDMETHOD;
	
	// Returns (after creating if necessary) the ASTs of this action.
	/* private */ METHOD("getTransitions") {
		params [P_THISOBJECT];
		T_PRVAR(transitions);
		if(count _transitions == 0) then {
			_transitions = T_CALLM("createTransitions", []);
			T_SETV("transitions", _transitions);
		};
		_transitions
	} ENDMETHOD;

	/*
	Method: applyToSim
	Apply applicable ASTs to the specified world sim. What is applicable depends on 
	current state, the type of world and the behaviour of the ASTs. Future world sims can 
	have all ASTs applied until END state is reached, as ASTs should implement simulation of their 
	final results. Now world sims can only have instantaneous AST results applied (e.g. allocating resources, 
	splitting a Garrison, assigning an action), so will usually not transition to END state.
	
	Parameters:	
		_world - <Model.WorldModel>, world to apply simulation of this action to. Sim worlds only, not real.
	
	Returns: <CMDR_ACTION_STATE>, the state after applying all applicable ASTs
	*/
	METHOD("applyToSim") {
		params [P_THISOBJECT, P_OOP_OBJECT("_world")];
		T_PRVAR(state);
		private _transitions = T_CALLM("getTransitions", []);
		ASSERT_MSG(count _transitions > 0, "CmdrAction hasn't got any _transitions assigned");

		T_CALLM("pushVariables", []);

		private _worldType = GETV(_world, "type");
		ASSERT_MSG(_worldType != WORLD_TYPE_REAL, "Cannot applyToSim on real world!");
		while {_state != CMDR_ACTION_STATE_END} do {
			private _newState = CALLSM("ActionStateTransition", "selectAndApply", [_world ARG _state ARG _transitions]);
			// State transitions are allowed to fail for NOW world sim (so they can limit changes to those that would happen instantly)
			ASSERT_MSG(_worldType == WORLD_TYPE_SIM_NOW or _newState != _state, format (["Couldn't apply action %1 to sim future, stuck in state %2" ARG _thisObject ARG _state]));
			if(_newState == _state) exitWith {};
			_state = _newState;
		};

		T_CALLM("popVariables", []);
		// We don't update to the new state, this is just a simulation, but return it for information purposes
		_state
	} ENDMETHOD;

	// Push the values of all registered variables.
	/* private */ METHOD("pushVariables") {
		params [P_THISOBJECT];
		T_PRVAR(variables);
		T_PRVAR(variablesStack);
		
		// Copy the variable contents and push onto stack. This will NOT deepcopy arrays. They should never be modified, only replaced.
		//_variablesStack pushBack (_variables apply { MAKE_AST_VAR(GET_AST_VAR(_x)) });
		//_variablesStack pushBack +_variables;
		_variablesStack pushBack (_variables apply { +_x });
	} ENDMETHOD;

	// Pop the values of all registered variables.
	/* private */ METHOD("popVariables") {
		params [P_THISOBJECT];
		T_PRVAR(variables);
		T_PRVAR(variablesStack);
		
		ASSERT_MSG(count _variablesStack > 0, "Variables stack is empty");

		// pop the copy of the variables
		private _copy = _variablesStack deleteAt (count _variablesStack - 1);
		// copy the values back into the variable array
		{
			SET_AST_VAR(_variables select _forEachIndex, GET_AST_VAR(_x));
		} forEach _copy;
	} ENDMETHOD;

	/*
	Method: update
	Attempt to progress with this action in a real world model.
	
	Parameters:
		_world - <Model.WorldModel>, real world to update this action for. Sim worlds are not valid.
	*/
	METHOD("update") {
		params [P_THISOBJECT, P_OOP_OBJECT("_world")];

		ASSERT_MSG(CALLM(_world, "isReal", []), "Should only update CmdrActions on non sim world. Use applySim in sim worlds");

		T_PRVAR(state);
		private _transitions = T_CALLM("getTransitions", []);
		ASSERT_MSG(count _transitions > 0, "CmdrAction hasn't got any _transitions assigned");

		private _oldState = CMDR_ACTION_STATE_NONE;
		// Apply states until we are blocked.
		while {_state != _oldState} do 
		{
			_oldState = _state;
			_state = CALLSM("ActionStateTransition", "selectAndApply", [_world ARG _oldState ARG _transitions]);
		};
		T_SETV("state", _state);

		T_CALLM("updateIntel", [_world]);

		#ifdef DEBUG_CMDRAI
		T_CALLM("debugDraw", [_world]);
		#endif
	} ENDMETHOD;

	/*
	Method: isComplete
	Is this action complete? i.e. reached state <CMDR_ACTION_STATE.CMDR_ACTION_STATE_END>
	Returns: Boolean, true if the action is complete.
	*/
	METHOD("isComplete") {
		params [P_THISOBJECT];
		T_GETV("state") == CMDR_ACTION_STATE_END
	} ENDMETHOD;

	/*
	Method: (protected virtual) updateIntel
	Implement to update intel object. 
	
	Parameters:
		_world - <Model.WorldModel>, real world model that is being used.
	*/
	/* protected virtual */ METHOD("updateIntel") {
		params [P_THISOBJECT, P_OOP_OBJECT("_world")];
	} ENDMETHOD;

	/*
	Method: (protected virtual) getLabel
	Implement to generate debug label for map marker for this action. 
	
	Parameters:	
		_world - <Model.WorldModel>, real world model that is being used.
	*/
	/* protected virtual */ METHOD("getLabel") {
		params [P_THISOBJECT, P_OOP_OBJECT("_world")];
		""
	} ENDMETHOD;

	/*
	Method: (protected virtual) debugDraw
	Implement to perform debug drawing (e.g. update a marker).
	*/
	/* protected virtual */ METHOD("debugDraw") {
		params [P_THISOBJECT];
	} ENDMETHOD;

	// Toolkit for scoring actions -----------------------------------------

	/*
	Method: (static) calcDistanceFalloff
	Get a value that falls off from 1 to 0 with distance, scaled by k.
	0m = 1, 2000m = 0.5, 4000m = 0.25, 6000m = 0.2, 10000m = 0.0385
	See https://www.desmos.com/calculator/59i3cltsfr
	
	Parameters:
		_from - Position, distance to calculate from
		_to - Position, distance to calculate to
		_k - Number, optional, factor that scales falloff amount, see description for examples.
	
	Returns: Number, value in 0 to 1 range representing the falloff that should be applied for the specified positions.
	*/
	STATIC_METHOD("calcDistanceFalloff") {
		params [P_THISCLASS, P_POSITION("_from"), P_POSITION("_to"), "_k"];
		private _kf = if(isNil "_k") then { 1 } else { _k };
		// See https://www.desmos.com/calculator/59i3cltsfr
		private _distScaled = 0.0005 * (_from distance _to) * _kf;
		(1 / (1 + _distScaled * _distScaled))
	} ENDMETHOD;

	/*
	Method: (virtual) getRecordSerial
	Returns a serialized CmdrActionRecord associated with this action.
	Derived classes should implement this to have proper support for client's UI.
	
	Parameters:	
		_world - <Model.WorldModel>, real world model that is being used.
	*/
	/* virtual */ METHOD("getRecordSerial") {
		params [P_THISOBJECT, P_OOP_OBJECT("_garModel"), P_OOP_OBJECT("_world")];

		// Return [] by default
		[]
	} ENDMETHOD;
	
ENDCLASS;


// Unit test
#ifdef _SQF_VM

// Test AST Variables

["AST_VAR", {
	private _var = MAKE_AST_VAR(-1);
	private _var2 = _var;

	["AST_VAR is an array length 1", count _var == 1] call test_Assert;
	["AST_VAR content correct", _var#0 == -1] call test_Assert;
	["GET_AST_VAR", GET_AST_VAR(_var) == -1] call test_Assert;
	SET_AST_VAR(_var, 1);
	["SET_AST_VAR", GET_AST_VAR(_var) == 1] call test_Assert;
	["AST_VAR share value works", GET_AST_VAR(_var2) == 1] call test_Assert;
}] call test_AddTest;

#define CMDR_ACTION_STATE_KILLED CMDR_ACTION_STATE_CUSTOM+1
#define CMDR_ACTION_STATE_FAILED CMDR_ACTION_STATE_CUSTOM+2

// Dummy test classes
CLASS("AST_KillGarrisonSetVar", "ActionStateTransition")
	VARIABLE("garrisonId");
	VARIABLE("var");
	VARIABLE("newVal");

	METHOD("new") {
		params [P_THISOBJECT, P_NUMBER("_garrisonId"), P_AST_VAR("_var"), P_DYNAMIC("_newVal")];
		T_SETV("garrisonId", _garrisonId);
		T_SETV("var", _var);
		T_SETV("newVal", _newVal);
		T_SETV("fromStates", [CMDR_ACTION_STATE_START]);
	} ENDMETHOD;

	/* virtual */ METHOD("isAvailable") { 
		params [P_THISOBJECT, P_STRING("_world")];
		T_PRVAR(garrisonId);
		private _garrison = CALLM(_world, "getGarrison", [_garrisonId]);
		!(isNil "_garrison")
	} ENDMETHOD;

	/* virtual */ METHOD("apply") { 
		params [P_THISOBJECT, P_STRING("_world")];

		// Kill the garrison - this should be preserved after applySim
		T_PRVAR(garrisonId);
		private _garrison = CALLM(_world, "getGarrison", [_garrisonId]);
		CALLM(_garrison, "killed", []);

		// Apply the change to the AST var - this should be reverted after applySim
		T_PRVAR(newVal);
		T_SET_AST_VAR("var", _newVal);

		CMDR_ACTION_STATE_KILLED
	} ENDMETHOD;
ENDCLASS;

CLASS("AST_TestVariable", "ActionStateTransition")
	VARIABLE("var");
	VARIABLE("compareVal");

	METHOD("new") {
		params [P_THISOBJECT, P_AST_VAR("_var"), P_DYNAMIC("_compareVal")];
		T_SETV("fromStates", [CMDR_ACTION_STATE_KILLED]);
		T_SETV("var", _var);
		T_SETV("compareVal", _compareVal);
	} ENDMETHOD;

	/* virtual */ METHOD("apply") { 
		params [P_THISOBJECT, P_STRING("_world")];
		T_PRVAR(compareVal);
		if(T_GET_AST_VAR("var") isEqualTo _compareVal) then {
			CMDR_ACTION_STATE_END
		} else {
			CMDR_ACTION_STATE_FAILED
		}
	} ENDMETHOD;
ENDCLASS;

["CmdrAction.new", {
	private _obj = NEW("CmdrAction", []);
	
	private _class = OBJECT_PARENT_CLASS_STR(_obj);
	["Object exists", !(isNil "_class")] call test_Assert;
	["Initial state is correct", GETV(_obj, "state") == CMDR_ACTION_STATE_START] call test_Assert;
}] call test_AddTest;

["CmdrAction.delete", {
	private _obj = NEW("CmdrAction", []);
	DELETE(_obj);
	isNil { OBJECT_PARENT_CLASS_STR(_obj) }
}] call test_AddTest;

["CmdrAction.registerGarrison, unregisterGarrison", {
	private _world = NEW("WorldModel", [WORLD_TYPE_SIM_NOW]);
	private _thisObject = NEW("CmdrAction", []);
	private _garrison = NEW("GarrisonModel", [_world ARG "<undefined>"]);

	CALLM(_garrison, "setAction", [_thisObject]);
	["Garrison registered correctly", (GETV(_thisObject, "garrisons") find _garrison) != NOT_FOUND] call test_Assert;
	
	DELETE(_garrison);
	["Garrison unregistered correctly", (GETV(_thisObject, "garrisons") find _garrison) == NOT_FOUND] call test_Assert;

	_garrison = NEW("GarrisonModel", [_world ARG "<undefined>"]);
	CALLM(_garrison, "setAction", [_thisObject]);
	["Garrison registered correctly 2", (GETV(_thisObject, "garrisons") find _garrison) != NOT_FOUND] call test_Assert;
	DELETE(_thisObject);
	["Action cleared from garrison on delete", CALLM(_garrison, "getAction", []) == NULL_OBJECT] call test_Assert;
}] call test_AddTest;

["CmdrAction.createVariable, pushVariables, popVariables", {
	private _thisObject = NEW("CmdrAction", []);
	private _var = CALLM(_thisObject, "createVariable", [0]);
	private _var2 = CALLM(_thisObject, "createVariable", [["test"]]);
	["Var is of correct form", _var isEqualTo [0]] call test_Assert;
	["Var2 is of correct form", _var2 isEqualTo [["test"]]] call test_Assert;
	CALLM(_thisObject, "pushVariables", []);
	SET_AST_VAR(_var, 1);
	GET_AST_VAR(_var2) set [0, "check"];
	["Var is changed before popVariables", _var isEqualTo [1]] call test_Assert;
	["Var2 is changed before popVariables", _var2 isEqualTo [["check"]]] call test_Assert;
	CALLM(_thisObject, "popVariables", []);
	["Var is restored after popVariables", _var isEqualTo [0]] call test_Assert;
	["Var2 is restored after popVariables", _var2 isEqualTo [["test"]]] call test_Assert;
}] call test_AddTest;

["CmdrAction.getFinalScore", {
	private _obj = NEW("CmdrAction", []);
	CALLM(_obj, "getFinalScore", []) == 1
}] call test_AddTest;

["CmdrAction.applyToSim", {
	private _world = NEW("WorldModel", [WORLD_TYPE_SIM_NOW]);
	private _garrison = NEW("GarrisonModel", [_world ARG "<undefined>"]);
	private _thisObject = NEW("CmdrAction", []);
	private _testVar = CALLM(_thisObject, "createVariable", ["original"]);
	private _asts = [
		NEW("AST_KillGarrisonSetVar", 
			[GETV(_garrison, "id")]+
			[_testVar]+
			["modified"]
		),
		NEW("AST_TestVariable", 
			[_testVar]+
			["modified"]
		)
	];

	SETV(_thisObject, "transitions", _asts);

	["Transitions correct", GETV(_thisObject, "transitions") isEqualTo _asts] call test_Assert;

	private _finalState = CALLM(_thisObject, "applyToSim", [_world]);
	["applyToSim applied state to sim correctly", CALLM(_garrison, "isDead", [])] call test_Assert;
	["applyToSim modified variables internally correctly", _finalState == CMDR_ACTION_STATE_END] call test_Assert;
	["applyToSim reverted action variables correctly", GET_AST_VAR(_testVar) isEqualTo "original"] call test_Assert;
}] call test_AddTest;

#endif