private ["_part_out","_part_in","_qty_out","_qty_in","_qty","_bos","_bag","_class","_started","_finished","_animState","_isMedic","_num_removed","_needed","_activatingPlayer","_buy_o_sell","_textPartIn","_textPartOut","_traderID"];
//		   [part_out,part_in, qty_out, qty_in,];

if(TradeInprogress) exitWith { cutText [localize 'STR_EPOCH_PLAYER_8' , "PLAIN DOWN"]; };
TradeInprogress = true;

_activatingPlayer = _this select 1;

_part_out = (_this select 3) select 0;
_part_in = (_this select 3) select 1;
_qty_out = (_this select 3) select 2;
_qty_in = (_this select 3) select 3;
_buy_o_sell = (_this select 3) select 4;
_textPartIn = (_this select 3) select 5;
_textPartOut = (_this select 3) select 6;
_traderID = (_this select 3) select 7;
_bos = 0;

if(_buy_o_sell == "buy") then {
	_qty = {_x == _part_in} count magazines player;
} else {
	_bos = 1;
	_qty = 0;
	_bag = unitBackpack player;
	_class = typeOf _bag;
	if(_class == _part_in) then {
		_qty = 1;
	};
};

if (_qty >= _qty_in) then {

	cutText [localize 'STR_EPOCH_PLAYER_128', "PLAIN DOWN"];
	 
	// force animation 
	player playActionNow "Medic";
	
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

	if (!_finished) exitWith { 
		r_interrupt = false;
		if (vehicle player == player) then {
			[objNull, player, rSwitchMove,""] call RE;
			player playActionNow "stop";
		};
		cutText [localize 'STR_EPOCH_PLAYER_24' , "PLAIN DOWN"];
	};

	if (_finished) then {

		// Double check we still have parts
		if(_buy_o_sell == "buy") then {
			_qty = {_x == _part_in} count magazines player;
		} else {
			_qty = 0;
			_bag = unitBackpack player;
			_class = typeOf _bag;
			if(_class == _part_in) then {
				_qty = 1;
			};
		};

		if (_qty >= _qty_in) then {

			//["dayzTradeObject",[_activatingPlayer,_traderID,_bos]] call callRpcProcedure;
			dayzTradeObject = [_activatingPlayer,_traderID,_bos];
			publicVariableServer  "dayzTradeObject";
	
			//diag_log format["DEBUG Starting to wait for answer: %1", dayzTradeObject];

			waitUntil {!isNil "dayzTradeResult"};

			//diag_log format["DEBUG Complete Trade: %1", dayzTradeResult];

			if(dayzTradeResult == "PASS") then {

				if(_buy_o_sell == "buy") then {

					_num_removed = ([player,_part_in,_qty_in] call BIS_fnc_invRemove);
					if(_num_removed == _qty_in) then {
						removeBackpack player;
						player addBackpack _part_out;
					};
				} else {
					// Sell
					if((typeOf (unitBackpack player)) == _part_in) then {
						removeBackpack player;
						for "_x" from 1 to _qty_out do {
							player addMagazine _part_out;
						};
					};
				};

				cutText [format[(localize 'STR_EPOCH_PLAYER_137'),_qty_in,_textPartIn,_qty_out,_textPartOut], "PLAIN DOWN"];

				{player removeAction _x} forEach s_player_parts;s_player_parts = [];
				s_player_parts_crtl = -1;
	
			} else {
				cutText [format[(localize 'STR_EPOCH_PLAYER_132'),_textPartOut] , "PLAIN DOWN"];
			};
			dayzTradeResult = nil;
		};
	};
	
} else {
	_needed =  _qty_in - _qty;
	cutText [format[(localize 'STR_EPOCH_PLAYER_133'),_needed,_textPartIn] , "PLAIN DOWN"];
};

TradeInprogress = false;