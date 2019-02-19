#define OOP_ERROR
#include "..\OOP_Light\OOP_Light.h"
#include "..\Message\Message.hpp"
#include "..\MessageTypes.hpp"
#include "Unit.hpp"
#include "..\Undercover\UndercoverMonitor.hpp"

/*
Damage EH for units. Its main job is to send messages to objects.
Fires on the owner of the unit.
*/

#define pr private

params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];

/*
// Code to dump values passed to the event handler
_array = ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint"]; 
_str = "";
{
_str = _str + format ["%1: %2, ", _x, _this select _foreachindex];
} forEach _array;
diag_log _str;
*/

if (side _unit != side _source && isPlayer _source && alive _source) then { 
	_source setVariable [UNDERCOVER_WANTED, true, true];
};

// Disable damage for driving over friendlies
pr _sideUnit = side group _unit;
pr _sideSource = side group _source;
if ((_sideUnit == _sideSource || isNull _source) && /*(_projectile == "") &&*/ (isNull _instigator)) then
{
	0
};