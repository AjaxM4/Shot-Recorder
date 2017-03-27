/*
	Author: AjaxM 
	Date Created: 10/12/2016 15:43
	Last Updated: 08/02/2017
	Time Took For Creation: 47 Minutes
	Script Description: Records all bullets shots with appropriate bodyparts
*/
#include <a_samp>
#include <a_mysql>
#include <i-zcmd>

// *** MySQL
new mysql;
// *** MYSQL Configurations
#define    MYSQL_HOST        "localhost" // host
#define    MYSQL_USER        "" // User
#define    MYSQL_DATABASE    "" // Database
#define    MYSQL_PASSWORD    "" // Password
// *** Body Parts
#define WEAPON_BODY_PART_CHEST 3
#define WEAPON_BODY_PART_TORSO 4
#define WEAPON_BODY_PART_LEFT_ARM 5
#define WEAPON_BODY_PART_RIGHT_ARM 6
#define WEAPON_BODY_PART_LEFT_LEG 7
#define WEAPON_BODY_PART_RIGHT_LEG 8
#define WEAPON_BODY_PART_HEAD 9
// *** Forwards
forward CheckAccount(playerid);
forward LoadPlayerShots(playerid);
forward OnShotRecorderRegister(playerid);
// *** Bodypart & Dialog Datas
enum
{
    DIALOG_ShotStatsDialog
};

enum PlayerData
{
    ID,
    Chest,
    Torso,
    LeftArm,
    RightArm,
    LeftLeg,
    RightLeg,
    Head,
    Missed
};


new pInfo[MAX_PLAYERS][PlayerData];

// *** Start of main scripts

// *** Callbacks

public OnFilterScriptInit()
{
	// 'Load' message

    print("\n----------------------------------");
    print("aShotRecorder by AjaxM - Loaded!\n");
    print("----------------------------------\n");
	
    // MySQL - Printing Errors & Connections
    mysql_log(LOG_ALL);
    mysql = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DATABASE, MYSQL_PASSWORD);
    if(mysql_errno() != 0)
    {
        printf("[MySQL] The connection has failed.");
    }
    else
    {
        printf("[MySQL] The connection was successful.");
    }
	return 1;
}

public OnPlayerConnect(playerid)
{
    new query[128];
    mysql_format(mysql, query, sizeof(query), "SELECT `ID` FROM `ShotRecords` WHERE `Name` = '%e' LIMIT 1", pName(playerid));
    mysql_tquery(mysql, query, "CheckAccount", "i", playerid);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    SavePlayerShots(playerid);
    return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float: amount, weaponid, bodypart)
{
    if(issuerid != INVALID_PLAYER_ID)
	  {
	      switch(bodypart)
	        {
		    case WEAPON_BODY_PART_CHEST: pInfo[issuerid][Chest] += 1;
		    case WEAPON_BODY_PART_TORSO: pInfo[issuerid][Torso] += 1;
		    case WEAPON_BODY_PART_LEFT_ARM: pInfo[issuerid][LeftArm] += 1;
		    case WEAPON_BODY_PART_RIGHT_ARM: pInfo[issuerid][RightArm] += 1;
		    case WEAPON_BODY_PART_LEFT_LEG: pInfo[issuerid][RightLeg] += 1;
		    case WEAPON_BODY_PART_RIGHT_LEG: pInfo[issuerid][LeftLeg] += 1;
		    case WEAPON_BODY_PART_HEAD: pInfo[issuerid][Head] += 1;
	        }
    }
    return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
    if(hittype == BULLET_HIT_TYPE_NONE)
    {
        pInfo[playerid][Missed] += 1;
    }
    return 1;
}

// *** Command(s)

CMD:shots(playerid, params[])
{
	if(isnull(params))
	{
	  new str[1024], OverallShots = pInfo[playerid][Chest] + pInfo[playerid][Torso] + pInfo[playerid][LeftArm] + pInfo[playerid][RightArm] + pInfo[playerid][LeftLeg] + pInfo[playerid][RightLeg] + pInfo[playerid][Head] + pInfo[playerid][Missed];
	  format(str, sizeof(str), "Chest: %d \n Torso: %d \n Left Arm: %d \n Right Arm: %d \n Left Leg: %d \n Right Leg: %d \n Head: %d \n Missed: %d \n Overall shots: %d",
		pInfo[playerid][Chest],
		pInfo[playerid][Torso],
		pInfo[playerid][LeftArm],
		pInfo[playerid][RightArm],
		pInfo[playerid][LeftLeg],
		pInfo[playerid][RightLeg],
		pInfo[playerid][Head],
		pInfo[playerid][Missed],
		OverallShots);
		ShowPlayerDialog(playerid, DIALOG_ShotStatsDialog, DIALOG_STYLE_MSGBOX, "Shot statistics", str, "Close", "");
	}
	else
	{
	  if(!IsPlayerConnected(strval(params))) return SendClientMessage(playerid, 0xFF0000FF, "Error: That player is NOT connected!");
	  new str[1024], OverallPlayerShots = pInfo[strval(params)][Chest] + pInfo[strval(params)][Torso] + pInfo[strval(params)][LeftArm] + pInfo[strval(params)][RightArm] + pInfo[strval(params)][LeftLeg] + pInfo[strval(params)][RightLeg] + pInfo[strval(params)][Head] + pInfo[strval(params)][Missed];
	  format(str, sizeof(str), "Chest: %d \n Torso: %d \n Left Arm: %d \n Right Arm: %d \n Left Leg: %d \n Right Leg: %d \n Head: %d \n Missed shots: %d \n Overall player shots: %d",
		pInfo[strval(params)][Chest],
		pInfo[strval(params)][Torso],
		pInfo[strval(params)][LeftArm],
		pInfo[strval(params)][RightArm],
		pInfo[strval(params)][LeftLeg],
		pInfo[strval(params)][RightLeg],
		pInfo[strval(params)][Head],
		pInfo[strval(params)][Missed],
		OverallPlayerShots);
		format(str, sizeof(str), "Showing shot statistics for player %s!", pName(strval(params)));
		SendClientMessage(playerid, 0xFF0000FF, str);
		ShowPlayerDialog(playerid, DIALOG_ShotStatsDialog, DIALOG_STYLE_MSGBOX, "Shot statistics", str, "Close", "");
	}
	return 1;
}

// *** Functions & Others

public CheckAccount(playerid) // Checks if he has a record already
{
    new rows, fields, query[178];
    cache_get_data(rows, fields, mysql);
    if(rows)
    {
        pInfo[playerid][ID] = cache_get_field_content_int(0, "ID");
        mysql_format(mysql, query, sizeof(query), "SELECT * FROM `ShotRecords` WHERE `Name` = '%e' LIMIT 1", pName(playerid));
        mysql_tquery(mysql, query, "LoadPlayerShots", "i", playerid);
    }
    else
    {
        mysql_format(mysql, query, sizeof(query), "INSERT INTO `ShotRecords` (`Name`, `Chest`, `Torso`,`LeftArm`, `RightArm`, `LeftLeg`, `RightLeg`, `Head`, `Missed`) VALUES ('%e', 0, 0, 0, 0, 0, 0, 0, 0)", pName(playerid));
        mysql_tquery(mysql, query, "OnShotRecorderRegister", "i", playerid);
    }
    return 1;
}

public LoadPlayerShots(playerid) // Loading all the shots
{
    pInfo[playerid][Chest] = cache_get_field_content_int(0, "Chest");
    pInfo[playerid][Torso] = cache_get_field_content_int(0, "Torso");
    pInfo[playerid][LeftArm] = cache_get_field_content_int(0, "LeftArm");
    pInfo[playerid][RightArm] = cache_get_field_content_int(0, "RightArm");
    pInfo[playerid][LeftLeg] = cache_get_field_content_int(0, "LeftLeg");
    pInfo[playerid][RightLeg] = cache_get_field_content_int(0, "RightLeg");
    pInfo[playerid][Head] = cache_get_field_content_int(0, "Head");
    pInfo[playerid][Missed] = cache_get_field_content_int(0, "Missed");
    return 1;
}

public OnShotRecorderRegister(playerid) // For Debugging
{
    pInfo[playerid][ID] = cache_insert_id();
    return 1;
}

SavePlayerShots(playerid) // Saving all the shots
{
    new query[2024];
    mysql_format(mysql, query, sizeof(query), "UPDATE `ShotRecords` SET `Chest` = %d, `Torso` = %d, `LeftArm` = %d, `RightArm` = %d, `LeftLeg` = %d, `RightLeg` = %d, `Head` = %d, `Missed` = %d WHERE `ID` = %d",
    pInfo[playerid][Chest],
    pInfo[playerid][Torso],
    pInfo[playerid][LeftArm],
    pInfo[playerid][RightArm],
    pInfo[playerid][LeftLeg],
    pInfo[playerid][RightLeg],
    pInfo[playerid][Head],
    pInfo[playerid][Missed],
    pInfo[playerid][ID]);
    mysql_tquery(mysql, query, "", "");
    return 1;
}

pName(playerid)
{
    new pN[MAX_PLAYER_NAME];
    GetPlayerName(playerid, pN, sizeof(pN));
    return pN;
}

/*

	 *** MySQL - Table SQL

CREATE TABLE `YOUR_PORT_HERE`.`ShotRecords`(
	`ID` INT(15) NOT NULL AUTO_INCREMENT ,
	`Name` VARCHAR(25) NOT NULL ,
	`Chest` INT(11) NOT NULL ,
	`Torso` INT(11) NOT NULL ,
	`LeftArm` INT(11) NOT NULL ,
	`RightArm` INT(11) NOT NULL ,
	`LeftLeg` INT(11) NOT NULL ,
	`RightLeg` INT(11) NOT NULL ,
	`Head` INT(11) NOT NULL ,
	`Missed` INT(255) NOT NULL ,
	PRIMARY KEY  (`ID`))
	ENGINE = InnoDB;

*/
