/* 
	INCLUDE THIS FILE WITH: #include "..\modCompatBools.sqf"

	EXAMPLES:

	if (activeACE) then {
		// ACE active
	} else {
		// ACE not active
	};
	
	File author: Marvis (I think)
	Date: unknown
*/

#define activeCBA (isClass (configfile >> "CfgVehicles" >> "CBA_main_require"))
#define activeACE (isClass (configFile >> "CfgPatches" >> "ace_main"))