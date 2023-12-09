#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <shavit>
#include <sdkhooks>
#include <dhooks>

#define LEFT 0
#define RIGHT 1
#define YAW 1

ConVar g_hSpecialString;
DynamicHook TeleportDHook;

char g_sSpecialString[stylestrings_t::sSpecialString];

bool g_bAutostrafer[MAXPLAYERS + 1];
float LastAngle[MAXPLAYERS + 1][3];
float AngleDifference[MAXPLAYERS + 1];
int TurnDir[MAXPLAYERS + 1];
int TicksOnGround[MAXPLAYERS + 1];
int TeleportTick[MAXPLAYERS + 1];
bool InBhop[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Sync style for shavit.", 
	author = "nimmy", 
	description = "Provides sync style.", 
	version = "1.2.0", 
	url = "https://github.com/Nimmy2222/shavit-syncstyle"
};

public void OnPluginStart() {
	g_hSpecialString = CreateConVar("autostrafer", "autostrafer", "Special string value to use in shavit-styles.cfg");
	g_hSpecialString.AddChangeHook(ConVar_OnSpecialStringChanged);
	g_hSpecialString.GetString(g_sSpecialString, sizeof(g_sSpecialString));
	HookEvent("player_jump", Player_Jump);
	InitializeTeleportDHook();
	AutoExecConfig();

	for(int i = 0; i < MaxClients; i++) {
		if(IsValidClient(i)) {
			OnClientPutInServer(i);
		}
	}
}

void InitializeTeleportDHook()
{
	Handle gamedataConf = LoadGameConfigFile("sdktools.games");
	if (gamedataConf == INVALID_HANDLE) {
		LogError("Shavit-Syncstyle: Couldn't load Gamedata: sdktools.games");
	}
	int offset = GameConfGetOffset(gamedataConf, "Teleport");
	if (offset == -1) {
		LogError("Shavit-Syncstyle: Couldn't load Teleport DHook.");
	}

	TeleportDHook = new DynamicHook(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);

	TeleportDHook.AddParam(HookParamType_VectorPtr);
	TeleportDHook.AddParam(HookParamType_VectorPtr);
	TeleportDHook.AddParam(HookParamType_VectorPtr);

	delete gamedataConf;
}

public void Player_Jump(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(!IsValidClient(client) || !g_bAutostrafer[client])
	{
		return;
	}
	InBhop[client] = true;
}

public MRESReturn DHooks_OnTeleport(int client, Handle hParams) {
	if(!IsValidClient(client) || !g_bAutostrafer[client]) {
		return MRES_Ignored;
	}
	TeleportTick[client] = 0;
	InBhop[client] = true; //People stand still during seg for a sec then teleport, need to still act like they have bhopped
	return MRES_Ignored;
}

public void OnClientPutInServer(int client) {
	g_bAutostrafer[client] = false;
	TeleportDHook.HookEntity(Hook_Post, client, DHooks_OnTeleport);
	if(!TeleportDHook) {
		LogError("Failed to Dhook Teleport on client %i.", client);
	}
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
			InBhop[client] = false;
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

	//InBhop and Off Ground are NOT the same thing, dont adjust sync if no movement for segment CPs, give time after teleport for same reason
	if(TicksOnGround[client] == 0 && AngleDifference[client] != 0 && InBhop[client] && TeleportTick[client] > 8) {
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
	TeleportTick[client]++;
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