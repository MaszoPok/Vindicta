// This file is defining CmdrAction states. ActionStateTransitions are used by CmdrAction
// to transition between these states. 
// It is perfectly fine to add new values here, you don't have to use these ones, except for:
// CMDR_ACTION_STATE_NONE: used to indicate no change to the current state, return from 
// ActionStateTransition.update when the update didn't cause a state change, e.g. on a long running
// AST that is currently in progress but not yet finished, like a garrison move or wait.
#define CMDR_ACTION_STATE_NONE		-1000
// CMDR_ACTION_STATE_START: always the initial state of a CmdrAction. The first AST should transition
// from this state.
#define CMDR_ACTION_STATE_START 	0
// CMDR_ACTION_STATE_END: indicates the final state of a CmdrAction, once it is completed 
// (successfully or not). The any final ASTs should transition TO this state.
#define CMDR_ACTION_STATE_END 		1
// Used in places to indicate that ALL states are being considered (in whatever context that makes sense).
#define CMDR_ACTION_STATE_ALL 		-1
// Lowest value for custom states, as seen below
#define CMDR_ACTION_STATE_CUSTOM	1000

// Some useful predefined states:
// After a garrison is split into two
#define CMDR_ACTION_STATE_SPLIT								(CMDR_ACTION_STATE_CUSTOM+1)
// When a garrison is ready to move
#define CMDR_ACTION_STATE_READY_TO_MOVE						(CMDR_ACTION_STATE_CUSTOM+2)
// After a garrison has completed a move
#define CMDR_ACTION_STATE_MOVED								(CMDR_ACTION_STATE_CUSTOM+3)
// When a target is dead, could be success or failure state depending on the context (e.g. kill or join)
#define CMDR_ACTION_STATE_TARGET_DEAD						(CMDR_ACTION_STATE_CUSTOM+4)
// When a garrison has arrived somewhere
#define CMDR_ACTION_STATE_ARRIVED 							(CMDR_ACTION_STATE_CUSTOM+5)
// When a garrison has been assigned an action
#define CMDR_ACTION_STATE_ASSIGNED							(CMDR_ACTION_STATE_CUSTOM+6)
// When a garrison should return to base
#define CMDR_ACTION_STATE_RTB								(CMDR_ACTION_STATE_CUSTOM+7)
// After a garrison has successfully returned to base
#define CMDR_ACTION_STATE_RTB_SUCCESS						(CMDR_ACTION_STATE_CUSTOM+8)
// When a garrison needs to select a target for RTB
#define CMDR_ACTION_STATE_RTB_SELECT_TARGET					(CMDR_ACTION_STATE_CUSTOM+9)

// When an AST fails due to an out of range error of some kind
#define CMDR_ACTION_STATE_FAILED_OUT_OF_RANGE 				(CMDR_ACTION_STATE_CUSTOM+10)
// When as AST fails due to a garrison being dead
#define CMDR_ACTION_STATE_FAILED_GARRISON_DEAD 				(CMDR_ACTION_STATE_CUSTOM+11)
// When an AST fails due to a generic time out
#define CMDR_ACTION_STATE_FAILED_TIMEOUT 					(CMDR_ACTION_STATE_CUSTOM+12)

// When the next waypoint in a route should be selected
#define CMDR_ACTION_STATE_NEXT_WAYPOINT 					(CMDR_ACTION_STATE_CUSTOM+13)
// When there are no more waypoints in a route
#define CMDR_ACTION_STATE_FINISHED_WAYPOINTS				(CMDR_ACTION_STATE_CUSTOM+14)

// ActionStateTransition priority values. Potential ASTs are sorted by the priority levels in 
// ascending order and the first valid one is used. You can use any value for priority
// these just define some reasonable defaults.
#define CMDR_ACTION_PRIOR_TOP 		0
#define CMDR_ACTION_PRIOR_HIGH 		1
#define CMDR_ACTION_PRIOR_LOW 		10

// ActionStateTransition variables (AST_VARs):
// These are wrappers for variables so the value can be shared between multiple ActionStateTransitions.
// e.g. An output of one AST can be the input of another (such as the first AST selecting a target and the next 
// AST giving a move order to the target), so the same AST_VAR can be assigned to both. When the first AST
// writes a value to the AST_VAR the other AST sees that change to its input immediately as they 
// both refer to the same underlying value. 
// They also allow the CmdrAction state to be pushed/popped during simulation so that real world actions 
// are not effected.
// Make a new AST_VAR
#define MAKE_AST_VAR(value) [value]
// Get the value from an AST_VAR
#define GET_AST_VAR(wrapper) (if((wrapper select 0) isEqualType {}) then { call (wrapper select 0) } else { (wrapper select 0) })
// Write a value to an AST_VAR
#define SET_AST_VAR(wrapper, value) (wrapper set [0, value])
// Get the value from an AST_VAR that is a member variable of _thisObject.
#define T_GET_AST_VAR(property) (T_GETV(property) select 0)
// Write a value to an AST_VAR that is a member variable of _thisObject.
#define T_SET_AST_VAR(property, value) (T_GETV(property) set [0, value])

// Function variable definition for an AST_VAR
#define P_AST_VAR(paramNameStr) P_ARRAY(paramNameStr)
// Function variable definition for a CMDR_ACTION_STATE
#define P_AST_STATE(paramNameStr) P_NUMBER(paramNameStr)

// Supported CmdrAITarget types (see CmdrAITarget.sqf).
#define TARGET_TYPE_GARRISON 0
#define TARGET_TYPE_LOCATION 1
#define TARGET_TYPE_POSITION 2
#define TARGET_TYPE_CLUSTER  3
#define NULL_TARGET []
#define IS_NULL_TARGET(target) (target isEqualTo [])