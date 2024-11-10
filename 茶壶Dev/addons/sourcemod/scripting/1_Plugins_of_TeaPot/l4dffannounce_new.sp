/* Plugin Template generated by Pawn Studio */
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <multicolors>

public Plugin myinfo = 
{
	name = "L4D FF Announce Plugin",
	author = "Frustian,MopeCup",
	description = "Adds Friendly Fire Announcements",
	version = "1.5",
	url = ""
}
//cvar handles
ConVar FFenabled;
ConVar AnnounceType;
//Various global variables
int DamageCache[MAXPLAYERS+1][MAXPLAYERS+1]; //Used to temporarily store Friendly Fire Damage between teammates
Handle FFTimer[MAXPLAYERS+1]; //Used to be able to disable the FF timer when they do more FF
bool FFActive[MAXPLAYERS+1]; //Stores whether players are in a state of friendly firing teammates
ConVar directorready;

public void OnPluginStart()
{
	CreateConVar("l4d_ff_announce_version", "1.4", "FF announce Version",FCVAR_SPONLY|FCVAR_NOTIFY);
	FFenabled = CreateConVar("l4d_ff_announce_enable", "1", "Enable Announcing Friendly Fire",FCVAR_SPONLY|FCVAR_NOTIFY);
	AnnounceType = CreateConVar("l4d_ff_announce_type", "4", "Changes how ff announce displays FF damage (1:In chat; 2: In Hint Box; 3: In center text, 4: In chat but all)",FCVAR_SPONLY);

	AutoExecConfig(true, "l4dffannounce");

	HookEvent("player_hurt", Event_HurtConcise, EventHookMode_Post);
	directorready = FindConVar("director_ready_duration");
}

public Action Event_HurtConcise(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetEventInt(event, "attackerentid");
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!GetConVarInt(FFenabled) || !GetConVarInt(directorready) || attacker > MaxClients || attacker < 1 || !IsClientConnected(attacker) || !IsClientInGame(attacker) || IsFakeClient(attacker) || GetClientTeam(attacker) != 2 || !IsClientInGame(victim) || !IsClientConnected(victim) || GetClientTeam(victim) != 2)
		return Plugin_Handled;  //if director_ready_duration is 0, it usually means that the game is in a ready up state like downtown1's ready up mod.  This allows me to disable the FF messages in ready up.
	int damage = GetEventInt(event, "dmg_health");
	if (FFActive[attacker])  //If the player is already friendly firing teammates, resets the announce timer and adds to the damage
	{
		Handle pack;
		DamageCache[attacker][victim] += damage;
		KillTimer(FFTimer[attacker]);
		FFTimer[attacker] = CreateDataTimer(1.0, AnnounceFF, pack);
		WritePackCell(pack,attacker);
	}
	else //If it's the first friendly fire by that player, it will start the announce timer and store the damage done.
	{
		DamageCache[attacker][victim] = damage;
		Handle pack;
		FFActive[attacker] = true;
		FFTimer[attacker] = CreateDataTimer(1.0, AnnounceFF, pack);
		WritePackCell(pack,attacker);
		for (int i = 1; i < 19; i++)
		{
			if (i != attacker && i != victim)
			{
				DamageCache[attacker][i] = 0;
			}
		}
	}

	return Plugin_Continue;
}
public Action AnnounceFF(Handle timer, Handle pack) //Called if the attacker did not friendly fire recently, and announces all FF they did
{
	char victim[128];
	char attacker[128];
	ResetPack(pack);
	int attackerc = ReadPackCell(pack);
	FFActive[attackerc] = false;
	if (IsClientInGame(attackerc) && IsClientConnected(attackerc) && !IsFakeClient(attackerc))
		GetClientName(attackerc, attacker, sizeof(attacker));
	else
		attacker = "Disconnected Player";
	for (int i = 1; i < MaxClients; i++)
	{
		if (DamageCache[attackerc][i] != 0 && attackerc != i)
		{
			if (IsClientInGame(i) && IsClientConnected(i))
			{
				GetClientName(i, victim, sizeof(victim));
				switch(GetConVarInt(AnnounceType))
				{
					case 1:
					{
						if (IsClientInGame(attackerc) && IsClientConnected(attackerc) && !IsFakeClient(attackerc))
							CPrintToChat(attackerc, "{olive}[提示] {blue}你对 {green}%s {blue}造成 {green}%d {blue}点友伤", victim, DamageCache[attackerc][i]);
						if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
							CPrintToChat(i, "{olive}[提示] {green}%s {blue}对你造成 {green}%d {blue}点友伤",attacker,DamageCache[attackerc][i]);
					}
					case 2:
					{
						if (IsClientInGame(attackerc) && IsClientConnected(attackerc) && !IsFakeClient(attackerc))
							PrintHintText(attackerc, "[提示] 你对 %s 造成 %d 点友伤", victim, DamageCache[attackerc][i]);
						if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
							PrintHintText(i, "[提示] %s 对你造成 %d 点友伤",attacker,DamageCache[attackerc][i]);
					}
					case 3:
					{
						if (IsClientInGame(attackerc) && IsClientConnected(attackerc) && !IsFakeClient(attackerc))
							PrintCenterText(attackerc, "[提示] 你对 %s 造成 %d 点友伤", victim, DamageCache[attackerc][i]);
						if (IsClientInGame(i) && IsClientConnected(i) && !IsFakeClient(i))
							PrintCenterText(i, "[提示] %s 对你造成 %d 点友伤",attacker,DamageCache[attackerc][i]);
					}
					case 4:
					{
						if(IsClientInGame(attackerc) && IsClientConnected(attackerc) && !IsFakeClient(attackerc))
							CPrintToChatAll("{olive}[提示] {green}%s{blue}对 {green}%s {blue}造成 {green}%d {blue}点友伤", attacker, victim, DamageCache[attackerc][i]);
					}
				}
			}
			DamageCache[attackerc][i] = 0;
		}
	}

	return Plugin_Stop;
}