/*
*/

#define UNIT_DATA_ID_CAT			0
#define UNIT_DATA_ID_SUBCAT			1
#define UNIT_DATA_ID_CLASS_NAME		2
#define UNIT_DATA_ID_OBJECT_HANDLE	3
#define UNIT_DATA_ID_GARRISON		4
#define UNIT_DATA_ID_OWNER			5
#define UNIT_DATA_ID_GROUP			6
#define UNIT_DATA_ID_MUTEX			7
#define UNIT_DATA_ID_AI				8
#define UNIT_DATA_ID_LOADOUT		9
#define UNIT_DATA_ID_BUILD_RESOURCE 10
#define UNIT_DATA_ID_LIMITED_ARSENAL 11
// Data which is set when unit is despawned 
#define UNIT_DATA_ID_POS_ATL		12
#define UNIT_DATA_ID_VECTOR_DIR_UP	13
#define UNIT_DATA_ID_LOCATION		14

#define UNIT_DATA_ID_WEAPONS		15

#define UNIT_DATA_SIZE				16

//								 0, 1,  2,       3,  4, 5,  6,  7,  8,  9, 10, 11, 12,		13,				    14, 15
#define UNIT_DATA_DEFAULT		[0, 0, "", objNull, "", 2, "", [], "", "", 0,  [], [0,0,0], [[0,0,0], [0,0,0]], "", []]

//Class name of Unit class, in case I need to rename it everywhere
#define UNIT_CLASS_NAME "Unit"

// Structure of unit's weapons
#define UNIT_WEAPONS_ID_PRIMARY		0
#define UNIT_WEAPONS_ID_SECONDARY	1

// String names of public variables set on units
#define UNIT_VAR_NAME_STR "__u"
#define UNIT_EFFICIENCY_VAR_NAME_STR "__e"
#define UNIT_EH_KILLED_STR "__u_eh_killed"
#define UNIT_EH_DAMAGE_STR "__u_eh_damage"

#define GET_UNIT_FROM_OBJECT_HANDLE(obj) obj getVariable [UNIT_VAR_NAME_STR, ""]
#define GET_UNIT_EFFICIENCY_FROM_OBJECT_HANDLE(obj) obj getVariable [UNIT_EFFICIENCY_VAR_NAME_STR, T_EFF_null]