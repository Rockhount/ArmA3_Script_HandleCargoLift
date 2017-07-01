/*
	Made by Rockhount - HandleCargoLift Script v1.1
	Errors will be written into the rpt and starts with "HandleCargoLift Error:"
	Call:
	["B_Heli_Attack_01_F", "B_Helipilot_F", [1808,1488,50], west, 50, [Truck1], [2093,1890,0], 10, [2095,1092,0], false, true, "CargoHeli1"] execVM "HandleCargoLift.sqf";
	"B_Heli_Attack_01_F" = Classname of the helicopter
	"B_Helipilot_F" = Classname of the crew
	[1808,1488,50] = Spawnposition
	west = Crew-Side
	50 = Flight altitude
	[Truck1, Truck2] = Cargo-Objects
	[2093,1890,0] = Drop-Position
	10 = Time in seconds until the cargo-object gets deleted after it has been dropped(0 for no deletion)
	[2095,1092,0] = Delete-Position, where the pilot flys to get deleted after he lifted all objects.
	false = (Optional) The pilot gets spawned only, instead of the hole crew, true = Pilot, Commander und Gunner gets spawned.
	true = (Optional) The cargo pos gets corrected after it gets dropped, false = Cargo gets left lying.
	"CargoHeli1" = (Optional) Variable that is assigned to the helicopter

	Gemacht von Rockhount - HandleCargoLift Script v1.1
	Fehler werden in die RPT geschrieben und starten mit "HandleCargoLift Error:"
	Aufruf:
	["B_Heli_Attack_01_F", "B_Helipilot_F", [1808,1488,50], west, 50, [Truck1], [2093,1890,0], 10, [2095,1092,0], false, true, "CargoHeli1"] execVM "HandleCargoLift.sqf";
	"B_Heli_Attack_01_F" = Klassenname des Helikopters
	"B_Helipilot_F" = Klassenname der Crew
	[1808,1488,50] = Spawnpunkt
	west = Seite der Besatzung
	50 = Flughöhe
	[Truck1, Truck2] = Abholobjekte
	[2093,1890,0] = Abladepunkt
	10 = Zeit bis zur Löschung des Objectes nach dem Absetzen in Sekunden(0 für keine Löschung)
	[2095,1092,0] = Die Position, an der der Helicopter nach Transport der Objekte fliegt und samt Besatzung gelöscht wird.
	false = (Optional) Statt der gesamten Crew wird nur der Pilot gespawnt, true = Pilot, Commander und Gunner wird gespawnt.
	true = (Optional) Die Position der Fracht wird nach dem Abwurf korrigiert, false = Fracht wird liegen gelassen.
	"CargoHeli1" = (Optional) Variable, die dem Helicopter zugewiesen wird
*/

scopeName "MainScope";
if (isServer) then
{
	private _Local_fnc_SpawnVehicle =
	{
		Params ["_Local_var_Pos", "_Local_var_VehType", "_Local_var_UnitType", "_Local_var_Side", "_Local_var_SpawnFullCrew"];
		private _Local_var_Group = createGroup _Local_var_Side;
		private _Local_var_Vehicle = createVehicle [_Local_var_VehType, _Local_var_Pos, [], 0, if (_Local_var_VehType isKindOf "Air") then {"FLY"} else {"NONE"}];
		_Local_var_Vehicle setPosATL _Local_var_Pos;
		private _Local_var_CurSeatCount = _Local_var_Vehicle emptyPositions "Driver";
		if (_Local_var_CurSeatCount > 0) then
		{
			private _Local_var_CurUnit = _Local_var_Group createUnit [_Local_var_UnitType, [0,0,0], [], 0, "NONE"];
			_Local_var_CurUnit assignAsDriver _Local_var_Vehicle;
			_Local_var_CurUnit moveInDriver _Local_var_Vehicle;
		};
		if (_Local_var_SpawnFullCrew) then
		{
			_Local_var_CurSeatCount = _Local_var_Vehicle emptyPositions "Commander";
			if (_Local_var_CurSeatCount > 0) then
			{
				private _Local_var_CurUnit = _Local_var_Group createUnit [_Local_var_UnitType, [0,0,0], [], 0, "NONE"];
				_Local_var_CurUnit assignAsCommander _Local_var_Vehicle;
				_Local_var_CurUnit moveInCommander _Local_var_Vehicle;
			};
			_Local_var_CurSeatCount = _Local_var_Vehicle emptyPositions "Gunner";
			if (_Local_var_CurSeatCount > 0) then
			{
				private _Local_var_CurUnit = _Local_var_Group createUnit [_Local_var_UnitType, [0,0,0], [], 0, "NONE"];
				_Local_var_CurUnit assignAsGunner _Local_var_Vehicle;
				_Local_var_CurUnit moveInGunner _Local_var_Vehicle;
			};
		};
		_Local_var_Vehicle
	};
	private _Local_fnc_ControlHeight =
	{
		Params ["_Local_var_AirVeh", "_Local_var_FlightAltitude"];
		while {alive _Local_var_AirVeh} do
		{
			if (((getPosATL _Local_var_AirVeh) select 2) <= _Local_var_FlightAltitude) then
			{
				_Local_var_AirVeh setVelocity (velocity _Local_var_AirVeh vectorAdd [0,0,.3]);
			};
			sleep .1;
		};
	};
	private _Local_fnc_ManageRopes =
	{
		if (typeName _this == "ARRAY") then
		{
			Params ["_Local_var_AirVehicle", "_Local_var_Cargo"];
			private _Local_var_AirVehicleSlingLoadPoint = getText (configFile >> "CfgVehicles" >> typeOf _Local_var_AirVehicle >> "slingLoadMemoryPoint");
			private _Local_var_CargoSlingLoadPoints = getArray (configFile >> "CfgVehicles" >> typeOf _Local_var_Cargo >> "slingLoadCargoMemoryPoints");
			private _Local_var_Ropes = [];
			private _Local_var_FakeRope = ropeCreate [_Local_var_AirVehicle, _Local_var_AirVehicleSlingLoadPoint, 1];
			ropeUnwind [_Local_var_FakeRope, 12, _Local_var_AirVehicle distance _Local_var_Cargo];
			sleep ((_Local_var_AirVehicle distance _Local_var_Cargo) / 12);
			ropeDestroy _Local_var_FakeRope;
			{
				private _Local_var_Rope = ropeCreate [_Local_var_AirVehicle, _Local_var_AirVehicleSlingLoadPoint, _Local_var_Cargo, _x, _Local_var_AirVehicle distance _Local_var_Cargo];
				_Local_var_Ropes pushBack _Local_var_Rope;
				ropeUnwind [_Local_var_Rope, 5, (_Local_var_AirVehicle distance _Local_var_Cargo) / 3];
			} forEach _Local_var_CargoSlingLoadPoints;
			sleep ((((_Local_var_AirVehicle distance _Local_var_Cargo) / 3) * 2) / 5);
		}
		else
		{
			Params ["_Local_var_AirVehicle"];
			_Local_var_AirVehicle setVariable ["Object_var_RopeCount", count ropes _Local_var_AirVehicle, false];
			{
				[_x, _Local_var_AirVehicle] spawn
				{
					Params ["_Local_var_Rope", "_Local_var_AirVehicle"];
					ropeUnwind [_Local_var_Rope, 2.5, (getPos _Local_var_AirVehicle) select 2];
					sleep ((((getPos _Local_var_AirVehicle) select 2) - (ropeLength _Local_var_Rope)) / 2.5);
					ropeCut [_Local_var_Rope, (ropeLength _Local_var_Rope) - 1];
					ropeUnwind [_Local_var_Rope, 12, 1];
					sleep (((ropeLength _Local_var_Rope) - 1) / 12);
					ropeDestroy _Local_var_Rope;
					_Local_var_AirVehicle setVariable ["Object_var_RopeCount", (_Local_var_AirVehicle getVariable "Object_var_RopeCount") - 1, false];
				};
			} forEach (ropes _Local_var_AirVehicle);
			waitUntil {sleep 1;(_Local_var_AirVehicle getVariable ["Object_var_RopeCount", 0]) < 1};
		};
	};
	private _Local_fnc_AutoHover =
	{
		Params ["_Local_var_AirVehicle", "_Local_var_Cargo", "_Local_var_CatchPos", "_Local_var_Distance"];
		private _Local_var_Index = 1;
		while {(_Local_var_AirVehicle distance2D _Local_var_CatchPos) > _Local_var_Distance} do
		{
			_Local_var_Dir = ((getDir _Local_var_AirVehicle) + (_Local_var_AirVehicle getRelDir _Local_var_CatchPos));
			_Local_var_AirVehicle setVelocity (velocity _Local_var_AirVehicle vectorAdd [sin _Local_var_Dir * 0.20,cos _Local_var_Dir * 0.20,0]);
			_Local_var_Index = _Local_var_Index + 1;
			if ((_Local_var_Index % 20) == 0) then
			{
				[_Local_var_AirVehicle, _Local_var_Cargo] call _Local_fnc_SearchRealTimeErrors;
			};
			sleep 0.1;
		};
	};
	private _Local_fnc_SearchRealTimeErrors =
	{
		Params ["_Local_var_AirVehicle", "_Local_var_Cargo"];
		if ((isNull _Local_var_Cargo) || {!alive _Local_var_Cargo}) exitWith
		{
			_Local_var_AirVehicle call _Local_fnc_ManageRopes;
			diag_log "HandleCargoLift Error: Cargo got destroyed";
			breakTo "SubScope";
		};
		{
			if ((isNull _x) || {!alive _x}) exitWith
			{
				diag_log "HandleCargoLift Error: Helicopter or Pilot got destroyed";
				breakTo "MainScope";
			};
		} forEach [_Local_var_AirVehicle, driver _Local_var_AirVehicle];
		if (((count (ropes _Local_var_AirVehicle)) > 0) && {(count (ropeAttachedObjects _Local_var_AirVehicle)) == 0}) then
		{
			_Local_var_AirVehicle call _Local_fnc_ManageRopes;
			diag_log "HandleCargoLift Error: Cargo has been lost";
			breakTo "SubScope";
		};
	};
	private _Local_var_Exit = false;
	private _Local_var_CargoObjects = [];
	private _Local_var_AirVehType = if ((count _this > 0) && {typeName (_this select 0) == "STRING"}) then {_this select 0} else {_Local_var_Exit = true;false};
	private _Local_var_AirVehCrewType = if ((count _this > 1) && {typeName (_this select 1) == "STRING"}) then {_this select 1} else {_Local_var_Exit = true;false};
	private _Local_var_SpawnPos = if ((count _this > 2) && {typeName (_this select 2) == "ARRAY"}) then {_this select 2} else {_Local_var_Exit = true;false};
	private _Local_var_CrewSide = if ((count _this > 3) && {typeName (_this select 3) == "SIDE"}) then {_this select 3} else {_Local_var_Exit = true;false};
	private _Local_var_FlightAltitude = if ((count _this > 4) && {typeName (_this select 4) == "SCALAR"}) then {_this select 4} else {_Local_var_Exit = true;false};
	private _Local_var_RAWCargoObjects = if ((count _this > 5) && {typeName (_this select 5) == "ARRAY"}) then {_this select 5} else {_Local_var_Exit = true;false};
	private _Local_var_DropPos = if ((count _this > 6) && {typeName (_this select 6) == "ARRAY"}) then {_this select 6} else {_Local_var_Exit = true;false};
	private _Local_var_CargoDelTime = if ((count _this > 7) && {typeName (_this select 7) == "SCALAR"}) then {_this select 7} else {_Local_var_Exit = true;false};
	private _Local_var_AirVehDelPos = if ((count _this > 8) && {typeName (_this select 8) == "ARRAY"}) then {_this select 8} else {_Local_var_Exit = true;false};
	private _Local_var_SpawnFullCrew = if ((count _this > 9) && {typeName (_this select 9) == "BOOL"}) then {_this select 9} else {false};
	private _Local_var_AdjustPos = if ((count _this > 10) && {typeName (_this select 10) == "BOOL"}) then {_this select 10} else {true};
	private _Local_var_VarName = if ((count _this > 11) && {typeName (_this select 11) == "STRING"}) then {_this select 11} else {""};
	//Error handling
	if ((_Local_var_Exit) || {!(_Local_var_AirVehType isKindOf "Air") || {!(_Local_var_AirVehCrewType isKindOf "Man")}}) exitWith
	{
		diag_log "HandleCargoLift Error: Wrong parameters";
	};
	if (!canSuspend) exitWith 
	{
		diag_log "HandleCargoLift Error: This script does not work in an unscheduled environment";
	};
	if (isNil {getText (configFile >> "CfgVehicles" >> _Local_var_AirVehType >> "slingLoadMemoryPoint")}) exitWith
	{
		diag_log "HandleCargoLift Error: Helicopter have no config entry for slingLoadMemoryPoint";
	};
	{
		_Local_var_CargoObjects pushBackUnique _x;
	} forEach _Local_var_RAWCargoObjects;
	//Transportation
	private _Local_var_AirVehicle = [_Local_var_SpawnPos, _Local_var_AirVehType, _Local_var_AirVehCrewType, _Local_var_CrewSide, _Local_var_SpawnFullCrew] call _Local_fnc_SpawnVehicle;
	private _Local_var_Pilot = driver _Local_var_AirVehicle;
	private _Local_var_Group = group _Local_var_Pilot;
	[_Local_var_AirVehicle, _Local_var_FlightAltitude / 2] spawn _Local_fnc_ControlHeight;
	if (_Local_var_VarName != "") then
	{
		missionNamespace setVariable [_Local_var_VarName, _Local_var_AirVehicle, false];
	};
	{
		scopeName "SubScope";
		if (!isNil {getArray (configFile >> "CfgVehicles" >> typeOf _x >> "slingLoadCargoMemoryPoints")}) then
		{
			private _Local_var_CurDropPos = _Local_var_DropPos findEmptyPosition [1,150,typeOf _x];
			if ((count _Local_var_CurDropPos) == 0) then
			{
				_Local_var_CurDropPos = _Local_var_DropPos findEmptyPosition [1,150];
			};
			private _Local_var_CatchPos = (getPosATL _x) vectorAdd [0,0, _Local_var_FlightAltitude / 2];
			//Flight
			_Local_var_Pilot doMove _Local_var_CatchPos;
			_Local_var_Group setSpeedMode "NORMAL";
			_Local_var_Group setBehaviour "CARELESS";
			_Local_var_AirVehicle flyinheight _Local_var_FlightAltitude;
			waitUntil {sleep 3;[_Local_var_AirVehicle, _x] call _Local_fnc_SearchRealTimeErrors;_Local_var_AirVehicle distance _Local_var_CatchPos < 200};
			//Hover
			_Local_var_Group setSpeedMode "LIMITED";
			_Local_var_AirVehicle flyinheight (_Local_var_FlightAltitude / 2);
			waitUntil {sleep 1;[_Local_var_AirVehicle, _x] call _Local_fnc_SearchRealTimeErrors;((_Local_var_AirVehicle distance2D _Local_var_CatchPos) < 100) || {(speed _Local_var_AirVehicle) < 5}};
			[_Local_var_AirVehicle, _x, _Local_var_CatchPos, 2] call _Local_fnc_AutoHover;
			//Mount
			[_Local_var_AirVehicle, _x] call _Local_fnc_ManageRopes;
			sleep 5;
			//Flight
			_Local_var_AirVehicle flyinheight _Local_var_FlightAltitude;
			_Local_var_Pilot doMove _Local_var_CurDropPos;
			if ((_Local_var_AirVehicle distance2D _Local_var_CurDropPos) > 1000) then
			{
				_Local_var_Group setSpeedMode "NORMAL";
			};
			waitUntil {sleep 3;[_Local_var_AirVehicle, _x] call _Local_fnc_SearchRealTimeErrors;(_Local_var_AirVehicle distance _Local_var_CurDropPos) < 200};
			//Hover
			_Local_var_Group setSpeedMode "LIMITED";
			_Local_var_AirVehicle flyinheight (_Local_var_FlightAltitude / 2);
			waitUntil {sleep 1;[_Local_var_AirVehicle, _x] call _Local_fnc_SearchRealTimeErrors;((_Local_var_AirVehicle distance _Local_var_CurDropPos) < 100) || {(speed _Local_var_AirVehicle) < 5}};
			[_Local_var_AirVehicle, _x, _Local_var_CurDropPos, 2] call _Local_fnc_AutoHover;
			//Drop
			_Local_var_AirVehicle call _Local_fnc_ManageRopes;
			if (_Local_var_AdjustPos) then
			{
				_x enableSimulation false;
				_x setPos _Local_var_CurDropPos;
				_x enableSimulation true;
			};
			sleep 5;
			if (_Local_var_CargoDelTime > 0) then
			{
				[_Local_var_CargoDelTime, _x] spawn
				{
					Params ["_Local_var_Time", "_Local_var_Cargo"];
					sleep _Local_var_Time;
					if (!isNull _Local_var_Cargo) then
					{
						{
							_Local_var_Cargo deleteVehicleCrew _x
						} forEach crew _Local_var_Cargo;
						deleteVehicle _Local_var_Cargo;
					};
				};
			};
		}
		else
		{
			diag_log format["HandleCargoLift Error: %1 have no config entry for slingLoadCargoMemoryPoints", typeOf _x];
		};
	} forEach _Local_var_CargoObjects;
	_Local_var_AirVehicle flyinheight _Local_var_FlightAltitude;
	_Local_var_Pilot doMove _Local_var_AirVehDelPos;
	_Local_var_Group setSpeedMode "NORMAL";
	waitUntil {sleep 1; (_Local_var_AirVehicle distance2D _Local_var_AirVehDelPos) < 500};
	waitUntil {sleep 1; (speed _Local_var_AirVehicle) < 2};
	{
		_Local_var_AirVehicle deleteVehicleCrew _x
	} forEach crew _Local_var_AirVehicle;
	deleteVehicle _Local_var_AirVehicle;
	deleteGroup _Local_var_Group;
};