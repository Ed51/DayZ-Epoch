private ["_vehicle","_part","_hitpoint","_type","_selection","_array","_started","_finished","_animState","_isMedic","_num_removed","_damage","_dis","_sfx","_allFixed","_id","_hasToolbox","_section","_nameType","_namePart","_hitpoints"];

if(TradeInprogress) exitWith { cutText [localize 'STR_EPOCH_PLAYER_105' , "PLAIN DOWN"]; };
TradeInprogress = true;

_id = _this select 2;
_array = 	_this select 3;
_vehicle = 	_array select 0;
_part =		_array select 1;
_hitpoint = _array select 2;
_type = typeOf _vehicle; 

//
_hasToolbox = 	"ItemToolbox" in items player;
_section = _part in magazines player;

// moving this here because we need to know which part needed if we don't have it
_nameType = 		getText(configFile >> "cfgVehicles" >> _type >> "displayName");
_namePart = 		getText(configFile >> "cfgMagazines" >> _part >> "displayName");

s_player_repair_crtl = 1;

if (_section and _hasToolbox) then {

	player playActionNow "Medic";
	
	_dis=20;
	_sfx = "repair";
	[player,_sfx,0,false,_dis] call dayz_zombieSpeak;  
	[player,_dis,true,(getPosATL player)] spawn player_alertZombies;

	r_interrupt = false;
	_animState = animationState player;
	r_doLoop = true;
	_started = false;
	_finished = false;
	
	while {r_doLoop} do {
		_animState = animationState player;
		_isMedic = ["medic",_animState] call fnc_inString;
		if (_isMedic) then {
			_started = true;
		};
		if (_started and !_isMedic) then {
			r_doLoop = false;
			_finished = true;
		};
		if (r_interrupt) then {
			r_doLoop = false;
		};
		sleep 0.1;
	};
	r_doLoop = false;


	if (_finished) then {

		_damage = [_vehicle,_hitpoint] call object_getHit;
		_vehicle removeAction _id;
	
		//dont waste loot on undamaged parts
		if (_damage > 0) then {
		
			// ensure part was removed
			_num_removed = ([player,_part] call BIS_fnc_invRemove);

			if(_num_removed == 1) then {

				//Fix the part
				_selection = getText(configFile >> "cfgVehicles" >> _type >> "HitPoints" >> _hitpoint >> "name");
		
				//vehicle is owned by whoever is in it, so we have to have each client try and fix it
				dayzSetFix = [_vehicle,_selection,0];
				publicVariable "dayzSetFix";
				if (local _vehicle) then {
					dayzSetFix call object_setFixServer;
				};

				_vehicle setvelocity [0,0,1];

				//Success!
				cutText [format[localize 'STR_EPOCH_PLAYER_106',_namePart,_nameType], "PLAIN DOWN"];

			};
		
		};

	} else {
		r_interrupt = false;
		if (vehicle player == player) then {
			[objNull, player, rSwitchMove,""] call RE;
			player playActionNow "stop";
		};
		cutText [localize 'STR_EPOCH_PLAYER_24', "PLAIN DOWN"];
	};
			
} else {
	cutText [format[localize 'STR_EPOCH_PLAYER_107',_namePart], "PLAIN DOWN"];
};

{dayz_myCursorTarget removeAction _x} forEach s_player_repairActions;s_player_repairActions = [];
dayz_myCursorTarget = objNull;

//check if repaired fully
_hitpoints = _vehicle call vehicle_getHitpoints;
_allFixed = true;
{
	_damage = [_vehicle,_x] call object_getHit;
	if (_damage > 0) exitWith {
		_allFixed = false;
	};
} forEach _hitpoints;

//update if repaired
if (_allFixed) then {
	_vehicle setDamage 0;
	//["dayzUpdateVehicle",[_vehicle,"repair"]] call callRpcProcedure;
	dayzSetFix = [_vehicle,_selection,0];
	publicVariable "dayzSetFix";
	if (local _vehicle) then {
		dayzSetFix call object_setFixServer;
	};
};

s_player_repair_crtl = -1;

TradeInprogress = false;