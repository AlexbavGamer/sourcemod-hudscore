#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Alexbav"
#define PLUGIN_VERSION "1.0.6"
#define PLUGIN_NAME "Hud Scoreboard"
#define UPDATE_URL "https://raw.githubusercontent.com/AlexbavGamer/sourcemod-hudscore/main/updatefile.txt"

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <updater>

#include "hudscore/classes.sp"

Handle:Timers[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

HudScore Scores[MAXPLAYERS] = {};

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

Handle Hud;

new Handle:g_hud_ct_text;
new Handle:g_hud_t_text;
new Handle:g_hud_show_rounds;
new Handle:g_hud_enabled;

new Handle:h_MP_RestartGame = INVALID_HANDLE;

char T_Text[256] = "T";
char CT_Text[256] = "CT";
bool Show_Rounds = true;

int T_Wins = 0;
int CT_Wins = 0;
int Rounds = 1;
new bool:global_option_hud = true;
new bool:option_show_hud[MAXPLAYERS + 1] = {true, ...};
new Handle:cookie_show_hud = INVALID_HANDLE;

public void OnPluginStart()
{
	PrintToServer("[%s]: Loaded Version: %s", PLUGIN_NAME, PLUGIN_VERSION);
	LoadTranslations("common.phrases");
	LoadTranslations("hudscore.phrases");
	CreateConfig();
	RegAdminCmd("sm_enablehud", Command_EnableHud, ADMFLAG_GENERIC, "Enable/Disable Hud Scoreboard");
	RegAdminCmd("sm_enableround", Command_EnableRound, ADMFLAG_GENERIC, "Enable/Disable Round Scoreboard");
	HookConVarChange(g_hud_ct_text, OnConVarChanged);
	HookConVarChange(g_hud_t_text, OnConVarChanged);
	HookConVarChange(g_hud_show_rounds, OnConVarChanged);
	h_MP_RestartGame = FindConVar("mp_restartgame");
	if(h_MP_RestartGame != INVALID_HANDLE) {
		HookConVarChange(h_MP_RestartGame, OnRestartGame);
	}
	if(LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
	Hud = CreateHudSynchronizer();
	
	cookie_show_hud = RegClientCookie("Show Hud Scoreboard On/Off", "", CookieAccess_Private);
	new info;
	SetCookieMenuItem(CookieMenuHandler_ShowHud, any:info, "Show Hud Scoreboard");
	
	/*for (new i = 1; i < MaxClients; i++) {
		if(IsClientValid(i)) {
			if(Scores[i] == null) {
				HudScore score = new HudScore(i);
				score.Display(ShowHudScore);
				Scores[i] = score;
			}
		}
	}*/
}

public OnRestartGame(Handle cvar, const char[] oldVar, const char[] newVar) {
	if(StrEqual(newVar, "1")) {
		Rounds = 1;
		T_Wins = 0;
		CT_Wins = 0;
	}
}

public Action Updater_OnPluginDownloading() {
	PrintToServer("[%s]: Updating plugin..", PLUGIN_NAME);
	
	return Plugin_Handled;
}

public Action Command_EnableHud(int client, int args)
{
	decl String:status[32];
	decl String:buffer[32];
	SetConVarBool(g_hud_enabled, !global_option_hud);
	if(global_option_hud) {
		Format(status, sizeof(status), "%T", "On", client);
	} else {
		Format(status, sizeof(status), "%T", "Off", client);
	}
	Format(buffer, sizeof(buffer), "%T: %s", "CommandHud", client, status);
	PrintToChatAll(buffer);
	return Plugin_Handled;
}

public Action Command_EnableRound(int client, int args) {
	decl String:status[32];
	decl String:buffer[32];
	SetConVarBool(g_hud_show_rounds, !Show_Rounds);
	if(Show_Rounds) {
		Format(status, sizeof(status), "%T", "On", client);
	} else {
		Format(status, sizeof(status), "%T", "Off", client);
	}
	Format(buffer, sizeof(buffer), "%T: %s", "CommandRound", client, status);
	PrintToChatAll(buffer);
	return Plugin_Handled;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if(convar) {
		if(convar == g_hud_ct_text) {
			Format(CT_Text, sizeof(CT_Text), "%s", newValue);
		}
		else if(convar == g_hud_t_text) {
			Format(T_Text, sizeof(T_Text), "%s", newValue);
		}
		else if(convar == g_hud_show_rounds) {
			Show_Rounds = GetConVarBool(g_hud_show_rounds);
		}
		else if(convar == g_hud_enabled) {
			global_option_hud = GetConVarBool(g_hud_enabled);
		}
	}
}

public void StopHud() {
	for (new i = 1; i < MaxClients; i++) {
		if(Scores[i] != null) {
			HudScore score = Scores[i];
			score.StopTimer();
		}
	}
}

public bool IsClientValid(int clientId) {
	return IsClientConnected(clientId) && IsClientInGame(clientId) && !IsFakeClient(clientId);
}

public void DisplayHud() {
	for (new i = 1; i < MaxClients; i++) {
		if(IsClientValid(i) && Timers[i] == INVALID_HANDLE) {
			HudScore score = new HudScore(i);	
			if(Scores[i] == null) {
				Scores[i] = score;
			} else {
				score = Scores[i];
			}
			score.Display(ShowHudScore);
		}		
	}
}

public CookieMenuHandler_ShowHud(int client, CookieMenuAction:action, any:info, String:buffer[], int maxlen) {
	if(action == CookieMenuAction_DisplayOption) 
	{
		decl String:status[32];
		if(option_show_hud[client]) {
			Format(status, sizeof(status), "%T", "On", client);
		} else {
			Format(status, sizeof(status), "%T", "Off", client);
		}
		Format(buffer, maxlen, "%T: %s", "Show Hud Scoreboard", client, status);
	} else {
		if(global_option_hud) {
			option_show_hud[client] = !option_show_hud[client];
			if(option_show_hud[client]) {
				SetClientCookie(client, cookie_show_hud, "On");
			}
			else 
			{
				SetClientCookie(client, cookie_show_hud, "Off");
			}
		} else {
			PrintToChat(client, "Scoreboard Hud está desativado no servidor no momento.");
		}
		ShowCookieMenu(client);
	}
}

public OnClientCookiesCached(client) {
	option_show_hud[client] = GetCookieShowHud(client);
}

bool GetCookieShowHud(client) {
	char buffer[256];
	GetClientCookie(client, cookie_show_hud, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}

public OnLibraryAdded(const char[] name) {
	if(StrEqual(name, "updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Action Updater_OnPluginChecking() {
	PrintToServer("[%s] Checking Plugin Updates...", PLUGIN_NAME);
	return Plugin_Handled;
}

public Updater_OnPluginUpdated() {
	PrintToServer("[%s] Plugin Updated...", PLUGIN_NAME);
	ReloadPlugin(GetMyHandle());
}

public void CreateConfig() {
	g_hud_ct_text = CreateConVar("g_hud_ct_text", "CT", "Display Text for CT Team");
	g_hud_t_text = CreateConVar("g_hud_t_text", "T", "Display Text for T Team");
	g_hud_enabled = CreateConVar("g_hud_enabled", "1", "Display Hud Scoreboard if enabled");
	g_hud_show_rounds = CreateConVar("g_hud_show_rounds", "1");
	AutoExecConfig(true, "HudScoreboard");
}

public void OnConfigsExecuted() {
	GetConVarString(g_hud_ct_text, CT_Text, sizeof(CT_Text));
	GetConVarString(g_hud_t_text, T_Text, sizeof(T_Text));
}

public bool OnClientConnect(int clientId, char[] reject, int maxlen) 
{
	if(!IsClientInGame(clientId) && IsFakeClient(clientId)) 
	{
		return false;
	}
	
	if(Scores[clientId] == null) 
	{
		HudScore score = new HudScore(clientId);
		Scores[clientId] = score;
	}
	return true;
}

public void OnClientDisconnect(int clientId) {
	if(Scores[clientId]) {
		Scores[clientId].StopTimer();
		delete Timers[clientId];
	}
}

public void OnMapStart() {
	Rounds = 1;
	T_Wins = GetTeamScore(2);
	CT_Wins = GetTeamScore(3);
}

public void OnMapEnd() {

}


public Action CS_OnTerminateRound(float delay, any reason) {
	Rounds++;
	T_Wins = GetTeamScore(2);
	CT_Wins = GetTeamScore(3);
	DisplayHud();
}

public Action ShowHudScore(Handle timer, int clientId) 
{
	if(IsClientInGame(clientId) && !IsFakeClient(clientId)) 
	{	
		char Message[256];
		if(Show_Rounds) 
		{
			Format(Message, sizeof(Message), "Equipe %s %dx%d Equipe %s\nRound %d", CT_Text, CT_Wins, T_Wins, T_Text, Rounds);
		} else {
			Format(Message, sizeof(Message), "Equipe %s %dx%d Equipe %s", CT_Text, CT_Wins, T_Wins, T_Text);
		}
		SetHudTextParams(-1.0, 0.1, 2.0, 255, 255, 255, 255, 1, 10.0, 1.0, 1.0);
		ShowSyncHudText(clientId, Hud, Message);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}