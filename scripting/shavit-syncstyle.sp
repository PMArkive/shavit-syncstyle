#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <shavit>

#define LEFT 0
#define RIGHT 1
#define YAW 1

ConVar g_hSpecialString;
char g_sSpecialString[stylestrings_t::sSpecialString];

bool g_bAutostrafer[MAXPLAYERS + 1];
float LastAngle[MAXPLAYERS + 1][3];
float AngleDifference[MAXPLAYERS + 1];
int TurnDir[MAXPLAYERS + 1];
int OptiTick[MAXPLAYERS + 1];
int TicksOnGround[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Autostrafe-Style for shavit.", 
	author = "nimmy", 
	description = "Provides Autostrafe style.", 
	version = "1.0.0", 
	url = ""
};

public void OnPluginStart() {
	g_hSpecialString = CreateConVar("autostrafer", "autostrafer", "Special string value to use in shavit-styles.cfg");
	g_hSpecialString.AddChangeHook(ConVar_OnSpecialStringChanged);
	g_hSpecialString.GetString(g_sSpecialString, sizeof(g_sSpecialString));
	AutoExecConfig();
	
	if (GetEngineVersion() == Engine_CSS) {
		g_flSidespeed = 400.0;
	}
}

public void OnClientConnected(int client) {
	g_bAutostrafer[client] = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(IsFakeClient(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || !g_bAutostrafer[client]) {
		return Plugin_Continue;
	}

	MoveType movetype = GetEntityMoveType(client);
	if(movetype == MOVETYPE_NONE || movetype == MOVETYPE_NOCLIP || movetype == MOVETYPE_LADDER || GetEntProp(client, Prop_Data, "m_nWaterLevel") >= 2) {
		return Plugin_Continue;
	}

	if(GetEntityFlags(client) & FL_ONGROUND == FL_ONGROUND) {
		TicksOnGround[client]++;
		if(TicksOnGround[client] > 10) {
            //reset sometihng idk
		} else if ((buttons & IN_JUMP) > 0 && TicksOnGround[client] == 1) {
			TicksOnGround[client] = 0;
		}
	} else {
		TicksOnGround[client] = 0;
	}

	AngleDifference[client] = GetAngleDiff(angles[YAW], LastAngle[client][YAW]);
	if(AngleDifference[client] > 0) {
		TurnDir[client] = LEFT;
	} else if(AngleDifference[client] < 0) {
		TurnDir[client] = RIGHT;
	}

    float temp[3];
    for(int i = 0; i < 3; i++) {
        temp[i] = LastAngle[client][i];
        LastAngle[client][i] = angles[i];
        angles[i] = temp[i];
    }
    if(TicksOnGround[client] == 0) {
    	if(TurnDir[client] == RIGHT) {
    		vel[1] = 400.0;
    		buttons |= IN_MOVERIGHT;
    		buttons &= ~IN_MOVELEFT;
    	} else if(TurnDir[client] == LEFT) {
    		vel[1] = -400.0;
    		buttons |= IN_MOVELEFT;
    		buttons &= ~IN_MOVERIGHT;
    	}
    }
	return Plugin_Changed;
}

public void Shavit_OnStyleChanged(int client, int oldstyle, int newstyle, int track, bool manual) {
	char sStyleSpecial[sizeof(stylestrings_t::sSpecialString)];
	Shavit_GetStyleStrings(newstyle, sSpecialString, sStyleSpecial, sizeof(sStyleSpecial));
	g_bAutostrafer[client] = (StrContains(sStyleSpecial, g_sSpecialString) != -1);
}

public void ConVar_OnSpecialStringChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	convar.GetString(g_sSpecialString, sizeof(g_sSpecialString));
}