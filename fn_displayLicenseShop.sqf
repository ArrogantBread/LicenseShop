disableSerialization;
#define ME RR_fnc_displayLicenseShop
#include "..\includes.h"
/*
* @File: displayLicenseShop.sqf
* @Author: ArrogantBread
*
* Copyright (C) Nathan "ArrogantBread" Wright  - All Rights Reserved - https://www.WEBSITENAMEHERE.co.uk
* Unauthorized copying of this file, via any medium is strictly prohibited
* without the express permission of Nathan "ArrogantBread" Wright
*/

params [
  ["_mode", "", [""]],
  ["_params", [], [[]]]
];

switch _mode do {
  case "onLoad":
  {
    _params params [
      ["_display", displayNUll, [displayNull]]
    ];

    private _tree = _display displayCtrl IDC_RR_DISPLAYLICENSE_TREE;
    _tree ctrlAddEventHandler ["TreeSelChanged", {["tvSelChange", _this] call ME}];

    private _ctrlPurchase = _display displayCtrl IDC_RR_DISPLAYLICENSE_PURCHASE;
    _ctrlPurchase ctrlAddEventHandler ["ButtonClick", {["purchase", _this] call ME;}];  
    //--- Disable control on load
    _ctrlPurchase ctrlEnable false;
    
    private _ctrlCloseButton = _display displayCtrl IDC_RR_DISPLAYLICENSE_CLOSE;
    _ctrlCloseButton ctrlAddEventHandler ["ButtonClick", {ctrlParent (_this select 0) closeDisplay 0;}];
    
    ["refresh", [_tree]] call ME;
  };
  
  case "tvSelChange":
  {
    _params params [
      ["_ctrlTree", controlNull, [controlNull]],
      ["_path", [], [[]]]
    ];
    
    private _display = ctrlParent _ctrlTree;
    private _ctrlPurchase = _display displayCtrl IDC_RR_DISPLAYLICENSE_PURCHASE;
    private _subIndex = _path select 1;
    
    private _tvData = _ctrlTree tvData _path; 
    
    if (_tvData isEqualTo "") then {
      _ctrlPurchase ctrlEnable false; 
    } else {
      _ctrlPurchase ctrlEnable true; 
    };    
  };

  case "refresh": {
    _params params [
      ["_tree", controlNull, [controlNull]],
      ["_path", [-1], [[-1]]]
    ];
    
    private _display = ctrlParent _tree;
    private _ctrlTree = _display displayCtrl IDC_RR_DISPLAYLICENSE_TREE;
    
    //--- Clear ze tree
    tvClear _tree;
    if !((_path select 0) isEqualTo -1) then {
      private _route = (_path select 0);
      // systemChat format ["curSel %1", _route];
      _ctrlTree tvExpand [_route];
    };
    
    private _cfg = "true" configClasses(missionConfigFile >> "Licenses");
    
    {
      private _typeName = (_x select 0);
      private _typeDisplayName = (_x select 1);
      private _primaryIndex = _tree tvAdd [[], _typeDisplayName];
    
      {
        private _typeStr = getText(_x >> "type");
        
        if (_typeStr isEqualTo _typeName) then {
          private _licenseDisplayName = getText (_x >> "displayName");
          private _licenseVarName = getText (_x >> "variable");
          private _licensePrice = getNumber (_x >> "price");
          
          private _licenseDisplayNameF = format ["%1 - £%2", _licenseDisplayName, [_licensePrice] call life_fnc_numberText];
          private _licenseClassName = format ["license_civ_%1", _licenseVarName];
          
          if !(call (compile _licenseClassName)) then {
            private _subIndex = _tree tvAdd [[_primaryIndex], _licenseDisplayNameF];
            _tree tvSetData [[_primaryIndex, _subIndex], _licenseVarName];
            _tree tvSetValue [[_primaryIndex, _subIndex], _licensePrice];
          };
        };
      } forEach _cfg;
    } forEach RR_license_categories;
  };

  case "purchase":
  {
    _params params [
      ["_ctrlPurchase", controlNull, [controlNull]]
    ];
    
    private _display = ctrlParent _ctrlPurchase;
    private _ctrlTree = _display displayCtrl IDC_RR_DISPLAYLICENSE_TREE;
    private _curSel = tvCurSel _ctrlTree;
    private _curSelData = _ctrlTree tvData _curSel;
    private _curSelPrice = _ctrlTree tvValue _curSel; 
    
    
    //--- Should PROBABLY make this a function, but fuck it...
    if (life_cash < _curSelPrice) exitWith {hint "You do not have anough money to purchase this";};
    life_cash = life_cash - _curSelPrice;
    
    [0] call SOCK_fnc_updatePartial;
    
    titleText[format ["You have purchased %1 for %2", _curSelData,[_curSelPrice] call life_fnc_numberText],"PLAIN"];
    private _formattedLicense = format ["license_civ_%1", _curSelData];
    missionNamespace setVariable [_formattedLicense,true];
    
    [2] call SOCK_fnc_updatePartial;
    
    // closeDialog 0;
    
    ["refresh", [_ctrlTree, _curSel]] call ME;
    //--- Custom notif here...
  };

  case "unLoad":
  {
    RR_license_categories = nil;
  };
};
