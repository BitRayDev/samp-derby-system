
#include <a_samp>
#include <dc_cmd>
#include <sscanf2>
#include <streamer>
#include <foreach>

#define PRESSED(%0) (((newkeys & (%0))== (%0)) && ((oldkeys & (%0)) != (%0)))
#define function%0(%1) forward %0(%1); public %0(%1)
#define format:%0( %0[0] = EOS,format(%0,sizeof(%0),

#define COLOR_GREY 0xAFAFAFAA
#define COLOR_GREEN 0x33AA33AA
#define COLOR_RED 0xAA3333AA
#define COLOR_YELLOW 0xFFFF00AA
#define COLOR_PINK 0xFFC0CBAA

#define DERBY_STATE_CLOSED 0
#define DERBY_STATE_REGISTRATION 1
#define DERBY_STATE_ACTIVE 2
#define DERBY_STATE_END 3

#define INVALID_DERBY_SLOT_ID -1

#define MAX_DERBY_SLOTS 20
#define MAX_DERBY_CHECKPOINTS 30

#define PANEL_OFFSET_X 5
#define PANEL_OFFSET_Y 10

new debug_mode = 1;

new
	g_str_least[32],
	g_str_small[256];
//	g_str_big[512],
//	g_str_cmd[2048];

new hours, minutes;

new derby
	derby_vehicle_model;

new derby_start_countdown,
	derby_final_countdown,
	derby_breakdown_countdown,
	derby_spawn_countdown;

new DerbySlots[MAX_DERBY_SLOTS];

enum E_USER
{
	uName[MAX_PLAYER_NAME],
	uFamily
}
new uInfo[MAX_PLAYERS][E_USER];

enum E_TEMP
{
	temp_derby_active,
	temp_derby_score,
	temp_derby_slot_id,
	temp_derby_vehicle_id,
	temp_derby_combo,
	temp_derby_countdown,
	temp_derby_panel_shown
}
new TempInfo[MAX_PLAYERS][E_TEMP];

enum E_DERBY_VEHICLE
{
	derby_vehicle_owner_id,
	derby_vehicle_object_model,
	derby_vehicle_object_id[2],
}
new DerbyVehicles[MAX_VEHICLES][E_DERBY_VEHICLE];

enum E_DERBY_PANEL_TD
{
	PlayerText:derby_panel_box[4],
	PlayerText:derby_panel_vehicle[7],
	PlayerText:derby_panel_time,
	PlayerText:derby_panel_health_label,
	PlayerText:derby_panel_health,
	PlayerText:derby_panel_score
}
new DerbyPanelTD[MAX_PLAYERS][E_DERBY_PANEL_TD];

enum E_DERBY_FINAL_TD
{
	PlayerText:derby_final_prize_cash[3],
	PlayerText:derby_final_prize_score[3],
	PlayerText:derby_final_nickname[3],
	PlayerText:derby_final_score[3],
	PlayerText:derby_final_number[3]
}
new PlayerText:DerbyFinalTD[MAX_PLAYERS][E_DERBY_FINAL_TD];
new PlayerText:BlackScreen[MAX_PLAYERS];

new Float:DerbyEndSpawnPoints[][4] =
{
    {2692.5828,-1698.1035,10.4631,41.4748},
	{2698.5574,-1693.2640,10.4909,43.6682},
	{2692.2029,-1708.5809,11.8478,42.6446},
	{2684.3640,-1716.1400,11.8438,50.3945},
	{2704.8298,-1699.1814,11.8438,20.4186},
	{2709.6792,-1688.0750,10.2700,118.0959}
};

new Float:DerbySpawnPoints[MAX_DERBY_SLOTS][4] =
{
	{-1287.6667,1021.8180,1037.4083,122.1156},
	{-1299.3425,1034.9233,1037.6456,138.1873},
	{-1317.9241,1046.0079,1037.8574,151.2104},
	{-1337.2570,1053.9298,1038.0265,156.4878},
	{-1359.5024,1057.3500,1038.1218,169.6453},
	{-1381.5887,1059.0214,1038.1906,179.2072},
	{-1399.8696,1059.2638,1038.2233,176.1832},
	{-1417.8820,1059.4003,1038.2535,178.7021},
	{-1435.5909,1058.4659,1038.2714,188.4406},
	{-1452.9044,1055.4723,1038.2476,198.0472},
	{-1469.3580,1050.3149,1038.1937,201.8360},
	{-1483.2928,1042.7653,1038.0923,212.0681},
	{-1495.9996,1034.9241,1037.9818,220.8628},
	{-1506.2446,1024.1691,1037.8204,235.5809},
	{-1514.6031,1010.7700,1037.6129,247.2609},
	{-1516.4323,998.0482,1037.4070,267.9160},
	{-1515.0474,983.5327,1037.1633,283.9785},
	{-1509.9403,971.0248,1036.9526,299.3123},
	{-1501.3398,961.2137,1036.7723,313.1383},
	{-1491.6329,953.2679,1036.6199,322.8229}
};

new Float:DerbyCheckpoints[MAX_DERBY_CHECKPOINTS][3] =
{
    {-1399.0139,964.6071,1024.5674},
	{-1422.1698,975.6280,1023.6776},
	{-1443.2061,992.2890,1023.8383},
	{-1442.8230,1019.2978,1025.2440},
	{-1414.7262,1025.0275,1025.4056},
	{-1384.6143,1009.4589,1024.0217},
	{-1362.7021,990.2164,1023.6594},
	{-1332.7605,985.0361,1024.7407},
	{-1333.4458,1012.6068,1025.4741},
	{-1364.9530,1012.0371,1024.0232},
	{-1394.7188,1006.4402,1023.9868},
	{-1426.5542,1017.0206,1024.5231},
	{-1456.0406,999.6752,1024.4673},
	{-1440.3750,976.0123,1024.0568},
	{-1410.9220,961.4554,1024.8875},
	{-1375.7255,980.5585,1023.5008},
	{-1400.4647,992.9158,1023.7667},
	{-1429.6744,997.0049,1023.8964},
	{-1424.5634,1017.2564,1024.5229},
	{-1387.0157,1013.2646,1024.1165},
	{-1352.7394,993.4374,1023.6991},
	{-1350.2419,945.0984,1033.5084},
	{-1420.0389,943.9185,1031.8295},
	{-1486.6010,970.7258,1030.6578},
	{-1467.3853,1040.2025,1035.7595},
	{-1392.6830,1049.9323,1035.9950},
	{-1338.5662,1043.1412,1035.2037},
	{-1299.3354,1015.6977,1034.3401},
	{-1295.9789,977.1581,1034.9697},
	{-1408.2019,1004.0309,1023.9672}
};

new DerbyVehicleRespawnCounter[MAX_PLAYERS];

function SecondTimer()
{
	if(derby == DERBY_STATE_REGISTRATION)
	{
		if(derby_start_countdown > 0)
		{
		    derby_start_countdown--;
			if(derby_start_countdown == 120)
			{
                SendClientMessageToAll(COLOR_YELLOW, "[DERBY]: Открыта регистрация на дерби на стадионе г.Лос Сантос. До начала 2 минуты.");
			}
			if(derby_start_countdown <= 0)
			{
			    new derby_player_count;
			    for(new i; i<MAX_DERBY_SLOTS; i++)
			    {
			        if(DerbySlots[i] == -1 || !IsPlayerConnected(DerbySlots[i]) || !TempInfo[DerbySlots[i]][temp_derby_active]) continue;
			        derby_player_count++;
			    }
			    if(derby_player_count < 4 && !debug_mode)
			    {
			        for(new i; i<MAX_DERBY_SLOTS; i++)
				    {
				        if(DerbySlots[i] == -1 || !IsPlayerConnected(DerbySlots[i]) || !TempInfo[DerbySlots[i]][temp_derby_active]) continue;
				        HidePlayerDerbyPanel(DerbySlots[i]);
				        TempInfo[DerbySlots[i]][temp_derby_active] = DERBY_STATE_CLOSED;
				        TempInfo[DerbySlots[i]][temp_derby_slot_id] = INVALID_DERBY_SLOT_ID;
				        DerbySlots[i] = -1;
				    }
				    SendClientMessageToAll(COLOR_RED, "[DERBY]: Дерби отменено из-за недостаточного количества участников");
			    }
			    else
			    {
			        derby = DERBY_STATE_ACTIVE;
			        
			        switch(random(7))
			        {
			            case 0: derby_vehicle_model = 531;
			            case 1: derby_vehicle_model = 601;
			            case 2: derby_vehicle_model = 568;
			            case 3: derby_vehicle_model = 588;
			            case 4: derby_vehicle_model = 573;
			            case 5: derby_vehicle_model = 556;
			            case 6: derby_vehicle_model = 571;
			        }
			        
					for(new i; i<MAX_DERBY_SLOTS; i++)
					{
					    if(DerbySlots[i] == -1) continue;
					    if(IsPlayerConnected(DerbySlots[i]) && TempInfo[DerbySlots[i]][temp_derby_active])
					    {

					        new
								playerid = DerbySlots[i];

					        SetPlayerInterior(playerid, 15);
							TempInfo[playerid][temp_derby_vehicle_id] = CreateVehicle(derby_vehicle_model,DerbySpawnPoints[i][0],DerbySpawnPoints[i][1],DerbySpawnPoints[i][2],DerbySpawnPoints[i][3],-1,-1,0,0);
		                    LinkVehicleToInterior(TempInfo[playerid][temp_derby_vehicle_id], 15);

                            ShowPlayerDerbyPanel(playerid);

							DerbyVehicles[TempInfo[playerid][temp_derby_vehicle_id]][derby_vehicle_owner_id] = playerid;
							PutPlayerInVehicle(playerid, TempInfo[playerid][temp_derby_vehicle_id], 0);
							TogglePlayerControllable(playerid, 0);
							TempInfo[playerid][temp_derby_countdown] = 3;
			            	GameTextForPlayer(playerid, "3", 1000, 4);
					    }
					}
					derby_final_countdown = 600;
				    SendClientMessageToAll(COLOR_YELLOW, "[DERBY]: Дерби началось");
			    }
			}
		}
	}
	if(derby == DERBY_STATE_ACTIVE)
	{
	    if(derby_final_countdown > 0)
	    {
	        derby_final_countdown--;
	        if(derby_final_countdown <= 0)
	        {
                for(new i; i<MAX_DERBY_SLOTS; i++)
				{
				    if(DerbySlots[i] == -1 || !IsPlayerConnected(DerbySlots[i]) || !TempInfo[DerbySlots[i]][temp_derby_active]) continue;
				    HidePlayerDerbyPanel(DerbySlots[i]);
					DisablePlayerRaceCheckpoint(DerbySlots[i]);
				    PlayerPlaySound(DerbySlots[i], 3200, 0.0, 0.0, 0.0);
				    GameTextForPlayer(DerbySlots[i], "STOP!", 4500, 6);
					TogglePlayerControllable(DerbySlots[i], 0);
				}
				derby_breakdown_countdown = 5;
			}
	    }
	    if(derby_breakdown_countdown > 0)
	    {
	        derby_breakdown_countdown--;
	        if(derby_breakdown_countdown <= 0)
	        {
	            insert_sort(DerbySlots);

				for(new i; i<MAX_DERBY_SLOTS; i++)
				{
					if(DerbySlots[i] == -1 || !IsPlayerConnected(DerbySlots[i]) || !TempInfo[DerbySlots[i]][temp_derby_active]) continue;

                    SetPlayerCameraPos(DerbySlots[i], 2729.807128, -1760.430297, 45.141902);
					SetPlayerCameraLookAt(DerbySlots[i], 2734.807128, -1760.430664, 45.113151);

					PlayerPlaySound(DerbySlots[i], 31205, 0.0, 0.0, 0.0);

					if(IsValidVehicle(TempInfo[DerbySlots[i]][temp_derby_vehicle_id]))
					{
					    DestroyDerbyVehicleObjects(TempInfo[DerbySlots[i]][temp_derby_vehicle_id]);
					    DestroyVehicle(TempInfo[DerbySlots[i]][temp_derby_vehicle_id]);
					    TempInfo[DerbySlots[i]][temp_derby_vehicle_id] = 0;
					}

					SetPlayerPos(DerbySlots[i], 2709.9812,-1758.8921,42.7773);
					SetPlayerInterior(DerbySlots[i], 0);

					ShowPlayerDerbyFinal(DerbySlots[i]);
				}

				if(DerbySlots[0] != -1 && IsPlayerConnected(DerbySlots[0]) && TempInfo[DerbySlots[0]][temp_derby_active])
				{
					SetPlayerPos(DerbySlots[0], 2737.9714,-1760.4259,45.1107);
					SetPlayerFacingAngle(DerbySlots[0], 90.0);
					GivePlayerMoney(DerbySlots[0], 30000);
					SendClientMessage(DerbySlots[0], COLOR_GREEN, "Спасибо за участие в дерби. Вы выиграли 30.000$.");
					if(uInfo[DerbySlots[0]][uFamily])
					    SendClientMessage(DerbySlots[0], COLOR_GREEN, "В вашу семью начислено 300 очков.");

				}
				if(DerbySlots[1] != -1 && IsPlayerConnected(DerbySlots[1]) && TempInfo[DerbySlots[1]][temp_derby_active])
				{
					SetPlayerPos(DerbySlots[1], 2738.0181,-1759.1765,44.8657);
					SetPlayerFacingAngle(DerbySlots[1], 90.0);
					GivePlayerMoney(DerbySlots[1], 20000);
					SendClientMessage(DerbySlots[1], COLOR_GREEN, "Спасибо за участие в дерби. Вы выиграли 20.000$.");
					if(uInfo[DerbySlots[1]][uFamily])
					    SendClientMessage(DerbySlots[1], COLOR_GREEN, "В вашу семью начислено 200 очков.");
				}
                if(DerbySlots[2] != -1 && IsPlayerConnected(DerbySlots[2]) && TempInfo[DerbySlots[2]][temp_derby_active])
				{
					SetPlayerPos(DerbySlots[2], 2737.9565,-1761.7336,44.4657);
					SetPlayerFacingAngle(DerbySlots[2], 90.0);
					GivePlayerMoney(DerbySlots[2], 10000);
					SendClientMessage(DerbySlots[2], COLOR_GREEN, "Спасибо за участие в дерби. Вы выиграли 10.000$.");
					if(uInfo[DerbySlots[2]][uFamily])
					    SendClientMessage(DerbySlots[2], COLOR_GREEN, "В вашу семью начислено 100 очков.");
				}

				derby_spawn_countdown = 10;
				derby = DERBY_STATE_END;
	        }
	    }
	}
	if(derby == DERBY_STATE_END)
	{
	    if(derby_spawn_countdown > 0)
	    {
	        derby_spawn_countdown--;
	        printf("%d", derby_spawn_countdown);
	        if(derby_spawn_countdown <= 0)
	        {
                for(new i; i<MAX_DERBY_SLOTS; i++)
				{
				    if(DerbySlots[i] == -1 || !IsPlayerConnected(DerbySlots[i]) || !TempInfo[DerbySlots[i]][temp_derby_active]) continue;
				    HidePlayerDerbyFinal(DerbySlots[i]);
					TogglePlayerControllable(DerbySlots[i], 1);
					new sp = random(6);
					SetPlayerPos(DerbySlots[i], DerbyEndSpawnPoints[sp][0], DerbyEndSpawnPoints[sp][1], DerbyEndSpawnPoints[sp][2]);
					SetPlayerFacingAngle(DerbySlots[i], DerbyEndSpawnPoints[sp][3]);
					SetCameraBehindPlayer(DerbySlots[i]);
					TempInfo[DerbySlots[i]][temp_derby_active] = 0;
					TempInfo[DerbySlots[i]][temp_derby_slot_id] = INVALID_DERBY_SLOT_ID;
					DerbySlots[i] = -1;
				}
				derby = DERBY_STATE_CLOSED;
			}
	    }
	}
	foreach(new i:Player)
	{
	    if(TempInfo[i][temp_derby_active])
    	{
		    if(derby == DERBY_STATE_REGISTRATION)
	     	{
          	    new derby_minutes = derby_start_countdown/60,
		 			derby_seconds = derby_start_countdown%60;

			    format:g_str_least("%02d:%02d", derby_minutes, derby_seconds);
			    PlayerTextDrawSetString(i, DerbyPanelTD[i][derby_panel_time_count], g_str_least);

			    if(!IsPlayerInRangeOfPoint(i, 100.0, 2695.6340, -1704.7819, 11.8438))
			    {
			        HidePlayerDerbyPanel(i);
				    TempInfo[i][temp_derby_active] = DERBY_STATE_CLOSED;
				    if(DerbySlots[TempInfo[i][temp_derby_slot_id]] == i)
				    {
				        DerbySlots[TempInfo[i][temp_derby_slot_id]] = -1;
				    }
				    TempInfo[i][temp_derby_slot_id] = INVALID_DERBY_SLOT_ID;
				    SendClientMessage(i, COLOR_GREEN, "Вы больше не записаны на дерби");
				}
		    }
		    else if(derby == DERBY_STATE_ACTIVE)
		    {
	            new derby_minutes = derby_final_countdown/60,
		 			derby_seconds = derby_final_countdown%60;

	            format:g_str_least("%02d:%02d", derby_minutes, derby_seconds);
			    PlayerTextDrawSetString(i, DerbyPanelTD[i][derby_panel_time_count], g_str_least);

			    format:g_str_least("%d", TempInfo[i][temp_derby_score]);
			    PlayerTextDrawSetString(i, DerbyPanelTD[i][derby_panel_score], g_str_least);

	            if(TempInfo[i][temp_derby_countdown] > 0)
	            {
	                TempInfo[i][temp_derby_countdown]--;
					switch(TempInfo[i][temp_derby_countdown])
					{
	                	case 3: GameTextForPlayer(i, "3", 1000, 4);
	                	case 2: GameTextForPlayer(i, "2", 1000, 4);
	                	case 1: GameTextForPlayer(i, "1", 1000, 4);
	                	default:
						{
						    new checkpoint_id = random(30);
	     					SetPlayerRaceCheckpoint(i, 2, DerbyCheckpoints[checkpoint_id][0], DerbyCheckpoints[checkpoint_id][1], DerbyCheckpoints[checkpoint_id][2], 0.0, 0.0, 0.0, 7.5);
						    TogglePlayerControllable(i, 1);
							GameTextForPlayer(i, "GO!", 1000, 4);
						}
					}
	            }
	            if(GetPlayerVehicleID(i) != TempInfo[i][temp_derby_vehicle_id])
	            {
		            if(DerbyVehicleRespawnCounter[i] > 0)
		            {
						DerbyVehicleRespawnCounter[i]--;
					    if(DerbyVehicleRespawnCounter[i] <= 0)
					    {
					        if(IsValidVehicle(TempInfo[i][temp_derby_vehicle_id]))
							{
							    DestroyDerbyVehicleObjects(TempInfo[i][temp_derby_vehicle_id]);
							    DestroyVehicle(TempInfo[i][temp_derby_vehicle_id]);
							    TempInfo[i][temp_derby_vehicle_id] = 0;
							}
						    HidePlayerDerbyPanel(i);
							TogglePlayerControllable(i, 1);
							new sp = random(6);
							SetPlayerInterior(i, 0);
							SetPlayerPos(i, DerbyEndSpawnPoints[sp][0], DerbyEndSpawnPoints[sp][1], DerbyEndSpawnPoints[sp][2]);
							SetPlayerFacingAngle(i, DerbyEndSpawnPoints[sp][3]);
							SetCameraBehindPlayer(i);
							DerbySlots[TempInfo[i][temp_derby_slot_id]] = -1;
							TempInfo[i][temp_derby_active] = 0;
							TempInfo[i][temp_derby_slot_id] = INVALID_DERBY_SLOT_ID;
							SendClientMessage(i, COLOR_RED, "Вы были дисквалифицированы.");
					    }
					}
	            }
		    }
	    }
	}
}
function UpdateTime()
{
	gettime(hours, minutes);
	if(minutes == 10 && derby == DERBY_STATE_CLOSED)
	{
	    derby = DERBY_STATE_REGISTRATION;
	    derby_start_countdown = 300;
	    SendClientMessageToAll(COLOR_YELLOW, "[DERBY]: Открыта регистрация на дерби на стадионе г.Лос Сантос. До начала 5 минут.");
	}
}

main()
{
	print("\n----------------------------------");
	print(" Derby System For Expand Role Play");
	print("----------------------------------\n");
}


public OnGameModeInit()
{
	LoadMap();
    SetTimer("SecondTimer", 1000, true);
    SetTimer("UpdateTime", 1000*60, true);
	SetGameModeText("Expand Test");
	AddPlayerClass(0, 2695.6340, -1704.7819, 11.8438, 269.1425, 0, 0, 0, 0, 0, 0);

	Create3DTextLabel("Левый 'ALT'\nРегистрация/Снятие с дерби", 0xFFA500FF, 2695.6340, -1704.7819, 11.8438, 20.0, 0, 0);

	for(new i; i<MAX_DERBY_SLOTS; i++)
		DerbySlots[i] = -1;
	return 1;
}

public OnGameModeExit()
{
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SetPlayerPos(playerid, -1398.103515, 937.631164, 1036.479125);
	SetPlayerCameraPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraLookAt(playerid, 1958.3783, 1343.1572, 15.3746);
	return 1;
}


public OnPlayerConnect(playerid)
{
	GetPlayerName(playerid, uInfo[playerid][uName], MAX_PLAYER_NAME);
	uInfo[playerid][uFamily] = random(2);
	
	LoadPlayerTD(playerid);

	TempInfo[playerid][temp_derby_active] = 0;
	TempInfo[playerid][temp_derby_score] = 0;
	TempInfo[playerid][temp_derby_slot_id] = -1;
	TempInfo[playerid][temp_derby_vehicle_id] = INVALID_VEHICLE_ID;
	TempInfo[playerid][temp_derby_combo] = 0;
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(TempInfo[playerid][temp_derby_active])
	{
        TempInfo[playerid][temp_derby_active] = DERBY_STATE_CLOSED;
        
        if(IsValidVehicle(TempInfo[playerid][temp_derby_vehicle_id]))
		{
		    DestroyDerbyVehicleObjects(TempInfo[playerid][temp_derby_vehicle_id]);
		    DestroyVehicle(TempInfo[playerid][temp_derby_vehicle_id]);
		    TempInfo[playerid][temp_derby_vehicle_id] = 0;
		}
        
	    if(DerbySlots[TempInfo[playerid][temp_derby_slot_id]] == playerid)
	    {
	        DerbySlots[TempInfo[playerid][temp_derby_slot_id]] = -1;
	    }
	    TempInfo[playerid][temp_derby_slot_id] = INVALID_DERBY_SLOT_ID;
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
    SetPlayerSkin(playerid, random(300)+1);
    if(derby == DERBY_STATE_ACTIVE)
	{
		if(TempInfo[playerid][temp_derby_active])
	   	{
	   	    new vehicleid = TempInfo[playerid][temp_derby_vehicle_id];
	   	    TempInfo[playerid][temp_derby_score] -= 1000;
	   	    if(TempInfo[playerid][temp_derby_score] < 0)
					 TempInfo[playerid][temp_derby_score] = 0;
            GameTextForPlayer(playerid, "~r~-1000", 2000, 6);
            TempInfo[playerid][temp_derby_combo] = 0;
	   	    SetVehicleToRespawn(vehicleid);
            ResetDerbyVehicleObjects(playerid, vehicleid);
	            
	    	/*SetVehicleToRespawn(vehicleid);
	        SetPlayerInterior(playerid, 15);
	        PutPlayerInVehicle(playerid, TempInfo[playerid][temp_derby_vehicle_id], 0);
            TogglePlayerControllable(playerid, 0);
            TempInfo[playerid][temp_derby_countdown] = 3;
            GameTextForPlayer(playerid, "3", 1000, 4);*/
	    }
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
    if(derby == DERBY_STATE_ACTIVE)
	{
	    if(DerbyVehicles[vehicleid][derby_vehicle_owner_id] != -1)
	    {
	        new playerid = DerbyVehicles[vehicleid][derby_vehicle_owner_id];
	        if(IsPlayerConnected(playerid) && GetPlayerState(playerid) != PLAYER_STATE_WASTED && TempInfo[playerid][temp_derby_vehicle_id] == vehicleid)
	        {
	            PutPlayerInVehicle(playerid, vehicleid, 0);
	            TogglePlayerControllable(playerid, 0);
	            TempInfo[playerid][temp_derby_countdown] = 3;
	            GameTextForPlayer(playerid, "3", 1000, 4);
	        }
	    }
	}
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	if(derby == DERBY_STATE_ACTIVE)
	{
	    if(DerbyVehicles[vehicleid][derby_vehicle_owner_id] != -1)
	    {
	        new playerid = DerbyVehicles[vehicleid][derby_vehicle_owner_id];
	        if(IsPlayerConnected(playerid) && TempInfo[playerid][temp_derby_vehicle_id] == vehicleid)
	        {
	            TempInfo[playerid][temp_derby_score] -= 1000;
	            
	            if(TempInfo[playerid][temp_derby_score] < 0)
					 TempInfo[playerid][temp_derby_score] = 0;
	            
	            TempInfo[playerid][temp_derby_combo] = 0;

	            ResetDerbyVehicleObjects(playerid, vehicleid);

	            GameTextForPlayer(playerid, "~r~-1000", 2000, 6);
	            SetVehicleToRespawn(vehicleid);
	        }
	        else
				DerbyVehicles[vehicleid][derby_vehicle_owner_id] = -1;
	    }
	}
	return 1;
}

public OnPlayerText(playerid, text[])
{
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	if (strcmp("/mycommand", cmdtext, true, 10) == 0)
	{
		// Do something here
		return 1;
	}
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	if(derby == DERBY_STATE_ACTIVE)
	{
		if(TempInfo[playerid][temp_derby_active])
		{
			if(vehicleid == TempInfo[playerid][temp_derby_vehicle_id])
			{
		   	    TempInfo[playerid][temp_derby_score] -= 1000;
		   	    if(TempInfo[playerid][temp_derby_score] < 0)
						 TempInfo[playerid][temp_derby_score] = 0;
	            GameTextForPlayer(playerid, "~r~-1000", 2000, 6);
	            TempInfo[playerid][temp_derby_combo] = 0;
		   	    SetVehicleToRespawn(vehicleid);
	            ResetDerbyVehicleObjects(playerid, vehicleid);
			}
		}
	}
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(derby == DERBY_STATE_ACTIVE)
	{
	    if(TempInfo[playerid][temp_derby_active])
	    {
			if(newstate == PLAYER_STATE_DRIVER && oldstate == PLAYER_STATE_ONFOOT)
			{
			    if(GetPlayerVehicleID(playerid) != TempInfo[playerid][temp_derby_vehicle_id])
			    {
			        RemovePlayerFromVehicle(playerid);
			        SendClientMessage(playerid, COLOR_RED, "Это не ваш автомобиль. Вернитесь в свой, иначе вы будете дисквалифицированы.");
			    }
			}
		}
	}
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	if(derby == DERBY_STATE_ACTIVE)
	{
		if(TempInfo[playerid][temp_derby_active] && GetPlayerVehicleID(playerid) == TempInfo[playerid][temp_derby_vehicle_id])
		{
		    new
		        vehicleid = TempInfo[playerid][temp_derby_vehicle_id],
				Float:veh_health,
				random_score = random(6),
				final_score,
				checkpoint_id = random(30);
            GetVehicleHealth(vehicleid, veh_health);

            veh_health += 200;
            if(veh_health > 1000)
				veh_health = 1000;

			SetVehicleHealth(vehicleid, veh_health);

			switch(random_score)
			{
			    case 0: final_score = 500;
			    case 1: final_score = 600;
			    case 2: final_score = 700;
			    case 3: final_score = 800;
			    case 4: final_score = 900;
			    case 5: final_score = 1000;
			}
			TempInfo[playerid][temp_derby_score] += final_score;

			ResetDerbyVehicleObjects(playerid, vehicleid);

			TempInfo[playerid][temp_derby_combo]++;

			if(TempInfo[playerid][temp_derby_combo] == 3)
			{
				AddVehicleComponent(vehicleid, 1009);
				format:g_str_least("~g~COMBO!~n~+%d", final_score);
			}
			else
			    format:g_str_least("~g~+%d", final_score);

			GameTextForPlayer(playerid, g_str_least, 5000, 6);

			SetPlayerRaceCheckpoint(playerid, 2, DerbyCheckpoints[checkpoint_id][0], DerbyCheckpoints[checkpoint_id][1], DerbyCheckpoints[checkpoint_id][2], 0.0, 0.0, 0.0, 7.5);
		}
	}
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
    SetPlayerInterior(playerid, 0);
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnVehicleDamageStatusUpdate(vehicleid)
{
    if(derby == DERBY_STATE_ACTIVE)
	{
	    if(DerbyVehicles[vehicleid][derby_vehicle_owner_id] != -1)
	    {
	        new playerid = DerbyVehicles[vehicleid][derby_vehicle_owner_id];
	        if(IsPlayerConnected(playerid) && TempInfo[playerid][temp_derby_vehicle_id] == vehicleid && TempInfo[playerid][temp_derby_panel_shown])
	        {
			    new veh_health = GetVehicleHealthInt(vehicleid);
			    switch(veh_health)
			    {
			        case 0..449: PlayerTextDrawBoxColor(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 0xFF000075);
			        case 450..749: PlayerTextDrawBoxColor(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 0xFFFF0075);
			        case 750..1000: PlayerTextDrawBoxColor(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 0x00800075);
			    }
				PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle]);
		    }
		}
    }
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(PRESSED(KEY_WALK))
	{
	    if(IsPlayerInRangeOfPoint(playerid, 1.5, 2695.6340, -1704.7819, 11.8438))
	    {
	        if(derby == DERBY_STATE_REGISTRATION)
	        {
	            if(!TempInfo[playerid][temp_derby_active])
	            {
					for(new i; i<MAX_DERBY_SLOTS; i++)
					{
					    if(DerbySlots[i] == -1)
						{
						    DerbySlots[i] = playerid;
							TempInfo[playerid][temp_derby_active] = DERBY_STATE_REGISTRATION;
							TempInfo[playerid][temp_derby_slot_id] = i;
							TempInfo[playerid][temp_derby_score] = 0;
							TempInfo[playerid][temp_derby_combo] = 0;
							format:g_str_small("Вы успешно зарегистрированы на дерби. Ваш номер: %d", i+1);
                            ShowPlayerDerbyPanel(playerid);
							SendClientMessage(playerid, COLOR_GREEN, g_str_small);
							return 1;
						}
					}
				}
				else if(TempInfo[playerid][temp_derby_active] == DERBY_STATE_REGISTRATION)
				{
				    TempInfo[playerid][temp_derby_active] = DERBY_STATE_CLOSED;
				    if(DerbySlots[TempInfo[playerid][temp_derby_slot_id]] == playerid)
				    {
				        DerbySlots[TempInfo[playerid][temp_derby_slot_id]] = -1;
				    }
				    TempInfo[playerid][temp_derby_slot_id] = INVALID_DERBY_SLOT_ID;
				    HidePlayerDerbyPanel(playerid);
        			SendClientMessage(playerid, COLOR_GREEN, "Вы больше не записаны на дерби");
        			return 1;
				}
			}
	    }
	}
	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if(hittype == BULLET_HIT_TYPE_VEHICLE)
	{
	    new vehicleid = hitid;
	    if(derby == DERBY_STATE_ACTIVE)
		{
		    if(DerbyVehicles[vehicleid][derby_vehicle_owner_id] != -1)
		    {
		        new targetid = DerbyVehicles[vehicleid][derby_vehicle_owner_id];
		        if(IsPlayerConnected(targetid) && TempInfo[targetid][temp_derby_vehicle_id] == vehicleid && TempInfo[playerid][temp_derby_panel_shown])
		        {
				    new veh_health = GetVehicleHealthInt(vehicleid);
				    switch(veh_health)
				    {
				        case 0..449: PlayerTextDrawBoxColor(targetid, DerbyPanelTD[targetid][derby_panel_box][1], 0xFF000075);
				        case 450..749: PlayerTextDrawBoxColor(targetid, DerbyPanelTD[targetid][derby_panel_box][1], 0xFFFF0075);
				        case 750..1000: PlayerTextDrawBoxColor(targetid, DerbyPanelTD[targetid][derby_panel_box][1], 0x00800075);
				    }
					PlayerTextDrawShow(targetid, DerbyPanelTD[targetid][derby_panel_vehicle]);
			    }
			}
	    }
	}
    return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

stock LoadMap()
{
    CreateObject(964, 2737.95605, -1759.21301, 42.9, 0.00, 0.00, 0.00); //object (CJ_METAL_CRATE) (1)
	CreateObject(964, 2737.91211, -1760.50195, 43.145, 0.00, 0.00, 0.00); //object (CJ_METAL_CRATE) (2)
	CreateObject(964, 2737.96191, -1761.78296, 42.5, 0.00, 0.00, 0.00); //object (CJ_METAL_CRATE) (3)
}

stock LoadPlayerTD(playerid)
{
    DerbyPanelTD[playerid][derby_panel_box][0] = CreatePlayerTextDraw(playerid, 532.268310+PANEL_OFFSET_X, 181.318481+PANEL_OFFSET_Y, "box");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 0.000000, 1.179330);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 600.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_box][0], -1);
	PlayerTextDrawUseBox(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 1);
	PlayerTextDrawBoxColor(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 572661573);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 1);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 0);
	
	DerbyPanelTD[playerid][derby_panel_box][1] = CreatePlayerTextDraw(playerid, 569.601440+PANEL_OFFSET_X, 198.219543+PANEL_OFFSET_Y, "box");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 0.000000, 1.211669);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 599.010986, 0.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_box][1], -1);
	PlayerTextDrawUseBox(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 1);
	PlayerTextDrawBoxColor(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 8388741);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 1);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 0);
	
	DerbyPanelTD[playerid][derby_panel_box][2] = CreatePlayerTextDraw(playerid, 566.072082+PANEL_OFFSET_X, 218.020721+PANEL_OFFSET_Y, "box");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 0.000000, 1.325338);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 0.000000, 37.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 2);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_box][2], -1);
	PlayerTextDrawUseBox(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 1);
	PlayerTextDrawBoxColor(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 572661552);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 1);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 0);

	DerbyPanelTD[playerid][derby_panel_box][3] = CreatePlayerTextDraw(playerid, 530.268188+PANEL_OFFSET_X, 178.414764+PANEL_OFFSET_Y, "box");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_box][3], 0.000000, 3.745996);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_box][3], 602.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_box][3], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_box][3], -1);
	PlayerTextDrawUseBox(playerid, DerbyPanelTD[playerid][derby_panel_box][3], 1);
	PlayerTextDrawBoxColor(playerid, DerbyPanelTD[playerid][derby_panel_box][3], 572661536);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_box][3], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_box][3], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_box][3], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_box][3], 1);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_box][3], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_box][3], 0);

	DerbyPanelTD[playerid][derby_panel_vehicle][0] = CreatePlayerTextDraw(playerid, 521.999694+PANEL_OFFSET_X, 105.326042+PANEL_OFFSET_Y, "");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][0], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][0], 89.000000, 98.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][0], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][0], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][0], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][0], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][0], 0);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][0], 5);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][0], 0);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][0], 0);
	PlayerTextDrawSetPreviewModel(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][0], 531);
	PlayerTextDrawSetPreviewRot(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][0], 0.000000, 0.000000, -90.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][0], 1, 1);
	
	DerbyPanelTD[playerid][derby_panel_vehicle][1] = CreatePlayerTextDraw(playerid, 521.999694+PANEL_OFFSET_X, 117.325859+PANEL_OFFSET_Y, "");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][1], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][1], 89.000000, 98.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][1], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][1], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][1], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][1], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][1], 0);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][1], 5);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][1], 0);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][1], 0);
	PlayerTextDrawSetPreviewModel(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][1], 601);
	PlayerTextDrawSetPreviewRot(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][1], 0.000000, 0.000000, -90.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][1], 1, 1);

	DerbyPanelTD[playerid][derby_panel_vehicle][2] = CreatePlayerTextDraw(playerid, 527.198425+PANEL_OFFSET_X, 111.325950+PANEL_OFFSET_Y, "");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][2], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][2], 89.000000, 98.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][2], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][2], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][2], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][2], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][2], 0);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][2], 5);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][2], 0);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][2], 0);
	PlayerTextDrawSetPreviewModel(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][2], 568);
	PlayerTextDrawSetPreviewRot(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][2], 0.000000, 0.000000, -90.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][2], 1, 1);

	DerbyPanelTD[playerid][derby_panel_vehicle][3] = CreatePlayerTextDraw(playerid, 519.200378+PANEL_OFFSET_X, 116.525871+PANEL_OFFSET_Y, "");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][3], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][3], 89.000000, 98.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][3], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][3], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][3], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][3], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][3], 0);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][3], 5);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][3], 0);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][3], 0);
	PlayerTextDrawSetPreviewModel(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][3], 588);
	PlayerTextDrawSetPreviewRot(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][3], 0.000000, 0.000000, -90.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][3], 1, 1);

	DerbyPanelTD[playerid][derby_panel_vehicle][4] = CreatePlayerTextDraw(playerid, 520.999938+PANEL_OFFSET_X, 107.926002+PANEL_OFFSET_Y, "");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][4], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][4], 89.000000, 98.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][4], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][4], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][4], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][4], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][4], 0);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][4], 5);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][4], 0);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][4], 0);
	PlayerTextDrawSetPreviewModel(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][4], 573);
	PlayerTextDrawSetPreviewRot(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][4], 0.000000, 0.000000, -90.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][4], 1, 1);

	DerbyPanelTD[playerid][derby_panel_vehicle][5] = CreatePlayerTextDraw(playerid, 520.999938+PANEL_OFFSET_X, 108.225997+PANEL_OFFSET_Y, "");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][5], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][5], 89.000000, 98.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][5], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][5], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][5], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][5], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][5], 0);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][5], 5);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][5], 0);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][5], 0);
	PlayerTextDrawSetPreviewModel(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][5], 556);
	PlayerTextDrawSetPreviewRot(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][5], 0.000000, 0.000000, -90.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][5], 1, 1);

	DerbyPanelTD[playerid][derby_panel_vehicle][6] = CreatePlayerTextDraw(playerid, 520.999938+PANEL_OFFSET_X, 116.925865+PANEL_OFFSET_Y, "");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][6], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][6], 89.000000, 98.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][6], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][6], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][6], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][6], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][6], 0);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][6], 5);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][6], 0);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][6], 0);
	PlayerTextDrawSetPreviewModel(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][6], 571);
	PlayerTextDrawSetPreviewRot(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][6], 0.000000, 0.000000, -90.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][6], 1, 1);
	
	DerbyPanelTD[playerid][derby_panel_number] = CreatePlayerTextDraw(playerid, 564.000000+PANEL_OFFSET_X, 151.836990+PANEL_OFFSET_Y, "10");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_number], 0.272000, 1.338666);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_number], 2);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_number], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_number], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_number], -1);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_number], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_number], 3);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_number], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_number], 0);

	DerbyPanelTD[playerid][derby_panel_score] = CreatePlayerTextDraw(playerid, 566.242370+PANEL_OFFSET_X, 180.159179+PANEL_OFFSET_Y, "26000");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_score], 0.205333, 1.293037);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_score], 2);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_score], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_score], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_score], -1);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_score], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_score], 2);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_score], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_score], 0);

	DerbyPanelTD[playerid][derby_panel_health_label] = CreatePlayerTextDraw(playerid, 533.551086+PANEL_OFFSET_X, 197.281448+PANEL_OFFSET_Y, "Health");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_health_label], 0.205333, 1.293037);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_health_label], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_health_label], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_health_label], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_health_label], -1);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_health_label], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_health_label], 2);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_health_label], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_health_label], 0);

	DerbyPanelTD[playerid][derby_panel_health] = CreatePlayerTextDraw(playerid, 597.734680+PANEL_OFFSET_X, 196.860198+PANEL_OFFSET_Y, "956_HP");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_health], 0.205333, 1.293037);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_health], 3);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_health], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_health], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_health], -1);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_health], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_health], 2);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_health], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_health], 0);

	DerbyPanelTD[playerid][derby_panel_time] = CreatePlayerTextDraw(playerid, 565.815429+PANEL_OFFSET_X, 216.018524+PANEL_OFFSET_Y, "10:25");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_time], 0.284666, 1.608297);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_time], 2);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_time], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_time], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_time], -1);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_time], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_time], 1);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_time], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_time], 0);

	

	

/*
//=====================================
    DerbyPanelTD[playerid][derby_panel_box][0] = CreatePlayerTextDraw(playerid, 22.666698, 169.137435, "box");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 0.000000, 6.733333);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 110.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_box][0], -1);
	PlayerTextDrawUseBox(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 1);
	PlayerTextDrawBoxColor(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 101);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 1);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_box][0], 0);

	DerbyPanelTD[playerid][derby_panel_box][1] = CreatePlayerTextDraw(playerid, 22.666698, 236.441543, "box");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 0.000000, 2.233336);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 110.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_box][1], -1);
	PlayerTextDrawUseBox(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 1);
	PlayerTextDrawBoxColor(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 101);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 1);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 0);

	DerbyPanelTD[playerid][derby_panel_box][2] = CreatePlayerTextDraw(playerid, 22.666698, 263.004516, "box");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 0.000000, 2.233336);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 110.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_box][2], -1);
	PlayerTextDrawUseBox(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 1);
	PlayerTextDrawBoxColor(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 101);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 1);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_box][2], 0);

	DerbyPanelTD[playerid][derby_panel_vehicle] = CreatePlayerTextDraw(playerid, 25.299989, 133.272552, "");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 0.000000, 0.000000);
	PlayerTextDrawTextSize(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 92.000000, 127.000000);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 0);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 0);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 5);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 0);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 0);
	PlayerTextDrawSetPreviewModel(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 504);
	PlayerTextDrawSetPreviewRot(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], -10.000000, 0.000000, -30.000000, 1.000000);
	PlayerTextDrawSetPreviewVehCol(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 1, 1);

	DerbyPanelTD[playerid][derby_panel_time_label] = CreatePlayerTextDraw(playerid, 26.833274, 237.718505, "Time");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_time_label], 0.250666, 1.728592);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_time_label], 1);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_time_label], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_time_label], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_time_label], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_time_label], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_time_label], 2);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_time_label], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_time_label], 0);

	DerbyPanelTD[playerid][derby_panel_time_count] = CreatePlayerTextDraw(playerid, 105.132179, 237.718505, "11:43");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_time_count], 0.250666, 1.728592);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_time_count], 3);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_time_count], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_time_count], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_time_count], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_time_count], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_time_count], 2);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_time_count], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_time_count], 0);

	DerbyPanelTD[playerid][derby_panel_score] = CreatePlayerTextDraw(playerid, 66.198829, 264.237060, "350");
	PlayerTextDrawLetterSize(playerid, DerbyPanelTD[playerid][derby_panel_score], 0.250666, 1.728592);
	PlayerTextDrawAlignment(playerid, DerbyPanelTD[playerid][derby_panel_score], 2);
	PlayerTextDrawColor(playerid, DerbyPanelTD[playerid][derby_panel_score], -1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_score], 0);
	PlayerTextDrawSetOutline(playerid, DerbyPanelTD[playerid][derby_panel_score], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyPanelTD[playerid][derby_panel_score], 255);
	PlayerTextDrawFont(playerid, DerbyPanelTD[playerid][derby_panel_score], 2);
	PlayerTextDrawSetProportional(playerid, DerbyPanelTD[playerid][derby_panel_score], 1);
	PlayerTextDrawSetShadow(playerid, DerbyPanelTD[playerid][derby_panel_score], 0);

	DerbyFinalTD[playerid][derby_final_prize_cash][0] = CreatePlayerTextDraw(playerid, 320.0, 385.0, "30.000$");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][0], 0.444666, 2.525037);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][0], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][0], -1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][0], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][0], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][0], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][0], 1);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][0], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][0], 0);

	DerbyFinalTD[playerid][derby_final_prize_cash][1] = CreatePlayerTextDraw(playerid, 245.0, 385.0, "20.000$");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][1], 0.444666, 2.525037);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][1], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][1], -1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][1], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][1], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][1], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][1], 1);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][1], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][1], 0);

	DerbyFinalTD[playerid][derby_final_prize_cash][2] = CreatePlayerTextDraw(playerid, 400.0, 385.0, "10.000$");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][2], 0.444666, 2.525037);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][2], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][2], -1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][2], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][2], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][2], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][2], 1);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][2], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][2], 0);

	DerbyFinalTD[playerid][derby_final_number][0] = CreatePlayerTextDraw(playerid, 320.0, 350.0, "1");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_number][0], 0.444666, 2.525037);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_number][0], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_number][0], -65281);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_number][0], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_number][0], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_number][0], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_number][0], 1);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_number][0], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_number][0], 0);

	DerbyFinalTD[playerid][derby_final_number][1] = CreatePlayerTextDraw(playerid, 245.0, 350.0, "2");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_number][1], 0.444666, 2.525037);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_number][1], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_number][1], -1061109505);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_number][1], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_number][1], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_number][1], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_number][1], 1);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_number][1], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_number][1], 0);

	DerbyFinalTD[playerid][derby_final_number][2] = CreatePlayerTextDraw(playerid, 400.0, 350.0, "3");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_number][2], 0.444666, 2.525037);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_number][2], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_number][2], -1523963137);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_number][2], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_number][2], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_number][2], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_number][2], 1);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_number][2], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_number][2], 0);
	
	DerbyFinalTD[playerid][derby_final_nickname][0] = CreatePlayerTextDraw(playerid, 320.0, 110.0, "Nick_name");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_nickname][0], 0.20, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_nickname][0], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_nickname][0], -1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_nickname][0], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_nickname][0], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_nickname][0], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_nickname][0], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_nickname][0], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_nickname][0], 0);
	
	DerbyFinalTD[playerid][derby_final_nickname][1] = CreatePlayerTextDraw(playerid, 245.0, 140.0, "Nick_name");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_nickname][1], 0.20, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_nickname][1], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_nickname][1], -1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_nickname][1], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_nickname][1], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_nickname][1], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_nickname][1], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_nickname][1], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_nickname][1], 0);

	DerbyFinalTD[playerid][derby_final_nickname][2] = CreatePlayerTextDraw(playerid, 400.0, 140.0, "Nick_name");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_nickname][2], 0.20, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_nickname][2], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_nickname][2], -1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_nickname][2], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_nickname][2], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_nickname][2], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_nickname][2], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_nickname][2], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_nickname][2], 0);

	DerbyFinalTD[playerid][derby_final_score][0] = CreatePlayerTextDraw(playerid, 320.0, 125.0, "21000");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_score][0], 0.251333, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_score][0], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_score][0], -1378294017);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_score][0], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_score][0], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_score][0], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_score][0], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_score][0], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_score][0], 0);

	DerbyFinalTD[playerid][derby_final_score][1] = CreatePlayerTextDraw(playerid, 245.0, 155.0, "21000");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_score][1], 0.251333, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_score][1], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_score][1], -1378294017);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_score][1], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_score][1], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_score][1], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_score][1], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_score][1], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_score][1], 0);

	DerbyFinalTD[playerid][derby_final_score][2] = CreatePlayerTextDraw(playerid, 400.0, 155.0, "21000");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_score][2], 0.251333, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_score][2], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_score][2], -1378294017);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_score][2], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_score][2], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_score][2], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_score][2], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_score][2], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_score][2], 0);

	DerbyFinalTD[playerid][derby_final_prize_score][1] = CreatePlayerTextDraw(playerid, 245.0, 405.0, "200");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_prize_score][1], 0.251333, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_prize_score][1], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_prize_score][1], -1378294017);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_prize_score][1], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_prize_score][1], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_prize_score][1], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_prize_score][1], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_prize_score][1], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_prize_score][1], 0);

	DerbyFinalTD[playerid][derby_final_prize_score][0] = CreatePlayerTextDraw(playerid, 320.0, 405.0, "300");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_prize_score][0], 0.251333, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_prize_score][0], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_prize_score][0], -1378294017);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_prize_score][0], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_prize_score][0], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_prize_score][0], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_prize_score][0], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_prize_score][0], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_prize_score][0], 0);

	DerbyFinalTD[playerid][derby_final_prize_score][2] = CreatePlayerTextDraw(playerid, 400.0, 405.0, "100");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][derby_final_prize_score][2], 0.251333, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][derby_final_prize_score][2], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][derby_final_prize_score][2], -1378294017);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_prize_score][2], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][derby_final_prize_score][2], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][derby_final_prize_score][2], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][derby_final_prize_score][2], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][derby_final_prize_score][2], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][derby_final_prize_score][2], 0);

	BlackScreen[playerid] = CreatePlayerTextDraw(playerid, -0.000008, -0.070345, "box");
	PlayerTextDrawLetterSize(playerid, BlackScreen[playerid], 0.000000, 50.099967);
	PlayerTextDrawTextSize(playerid, BlackScreen[playerid], 640.000000, 0.000000);
	PlayerTextDrawAlignment(playerid, BlackScreen[playerid], 1);
	PlayerTextDrawColor(playerid, BlackScreen[playerid], -1);
	PlayerTextDrawUseBox(playerid, BlackScreen[playerid], 1);
	PlayerTextDrawBoxColor(playerid, BlackScreen[playerid], 0xffffff00);
	PlayerTextDrawSetShadow(playerid, BlackScreen[playerid], 0);
	PlayerTextDrawSetOutline(playerid, BlackScreen[playerid], 0);
	PlayerTextDrawBackgroundColor(playerid, BlackScreen[playerid], 255);
	PlayerTextDrawFont(playerid, BlackScreen[playerid], 1);
	PlayerTextDrawSetProportional(playerid, BlackScreen[playerid], 1);
	PlayerTextDrawSetShadow(playerid, BlackScreen[playerid], 0);*/
}

stock ShowPlayerDerbyFinal(playerid)
{
    for(new i; i<3; i++)
    {
		if(DerbySlots[i] != -1 && IsPlayerConnected(DerbySlots[i]) && TempInfo[DerbySlots[i]][temp_derby_active])
		{
		    PlayerTextDrawSetString(playerid, DerbyFinalTD[playerid][derby_final_nickname][i], uInfo[DerbySlots[i]][uName]);
			format:g_str_least("%d", TempInfo[DerbySlots[i]][temp_derby_score]);
			PlayerTextDrawSetString(playerid, DerbyFinalTD[playerid][derby_final_score][i], g_str_least);
						
			PlayerTextDrawShow(playerid, DerbyFinalTD[playerid][derby_final_nickname][i]);
			PlayerTextDrawShow(playerid, DerbyFinalTD[playerid][derby_final_score][i]);
			PlayerTextDrawShow(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][i]);
			if(uInfo[DerbySlots[i]][uFamily])
				PlayerTextDrawShow(playerid, DerbyFinalTD[playerid][derby_final_prize_score][i]);
		}
		PlayerTextDrawShow(playerid, DerbyFinalTD[playerid][derby_final_number][i]);
	}
	return 1;
}

stock HidePlayerDerbyFinal(playerid)
{
	for(new i; i<3; i++)
	{
		PlayerTextDrawHide(playerid, DerbyFinalTD[playerid][derby_final_nickname][i]);
		PlayerTextDrawHide(playerid, DerbyFinalTD[playerid][derby_final_score][i]);
		PlayerTextDrawHide(playerid, DerbyFinalTD[playerid][derby_final_prize_cash][i]);
		PlayerTextDrawHide(playerid, DerbyFinalTD[playerid][derby_final_prize_score][i]);
		PlayerTextDrawHide(playerid, DerbyFinalTD[playerid][derby_final_number][i]);
	}
	return 1;
}

stock ResetDerbyVehicleObjects(playerid, vehicleid)
{
	new vehicle_model = GetVehicleModel(vehicleid);
    switch(TempInfo[playerid][temp_derby_score])
	{
	    case 0..1999: DestroyDerbyVehicleObjects(vehicleid);
	    case 2000..7999:
	    {
			if(DerbyVehicles[vehicleid][derby_vehicle_object_model] != 19620)
			{
			    DestroyDerbyVehicleObjects(vehicleid);
				DerbyVehicles[vehicleid][derby_vehicle_object_id][0] = CreateObject(19620, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
				switch(vehicle_model)
				{
				    case 531: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, 1.446998, 0.414999, 0.000000, 0.000000, 0.000000);
				    case 601: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, 1.579998, 1.524998, 0.000000, 0.000000, 0.000000);
				    case 568: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, 0.000000, 0.759999, 0.000000, 0.000000, 0.000000);
				    case 588: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, 2.685014, 1.914998, 0.000000, 0.000000, 0.000000);
				    case 573: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, 2.545010, 1.559998, 0.000000, 0.000000, 0.000000);
				    case 556: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, 0.000000, 1.709998, 0.000000, 0.000000, 0.000000);
				    case 571: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, 0.819999, -0.110000, 0.000000, 0.000000, 0.000000);
				}
                DerbyVehicles[vehicleid][derby_vehicle_object_model] = 19620;
			}
	    }
	    case 8000..13999:
	    {
			if(DerbyVehicles[vehicleid][derby_vehicle_object_model] != 18648)
			{
			    DestroyDerbyVehicleObjects(vehicleid);
				DerbyVehicles[vehicleid][derby_vehicle_object_id][0] = CreateObject(18648, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
				DerbyVehicles[vehicleid][derby_vehicle_object_id][1] = CreateObject(18648, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
				switch(vehicle_model)
				{
				    case 531:
				    {
				        AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, -0.434999, 0.000000, -0.439999, 0.000000, 0.000000, 0.000000); //Object Model: 18648 |
						AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][1], vehicleid, 0.479999, 0.000000, -0.374999, 0.000000, 0.000000, 0.000000); //Object Model: 18648 |
				    }
				    case 601:
				    {
                    	AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, -0.724999, 0.000000, -0.180000, 0.000000, 0.000000, 0.000000); //Object Model: 18648 |
						AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][1], vehicleid, 0.724999, 0.000000, -0.189999, 0.000000, 0.000000, 0.000000); //Object Model: 18648 |
				    }
				    case 568:
				    {
                        AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.374999, 0.000000, -0.404999, 0.000000, 0.000000, 0.000000); //Object Model: 18648 |
						AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][1], vehicleid, -0.354999, 0.000000, -0.384999, 0.000000, 0.000000, 0.000000); //Object Model: 18648 |
				    }
				    case 588:
				    {
                        AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 1.349998, 0.000000, -0.554999, 0.000000, 0.000000, 0.000000); //Object Model: 18648 |
						AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][1], vehicleid, -1.369998, 0.000000, -0.554999, 0.000000, 0.000000, 0.000000); //Object Model: 18648 |
				    }
				    case 573:
				    {
                        AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 1.119999, 0.000000, -0.784999, 0.000000, 0.000000, 0.000000); //Object Model: 18648 |
						AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][1], vehicleid, -1.104999, 0.000000, -0.784999, 0.000000, 0.000000, 0.000000); //Object Model: 18648 |
				    }
				    case 556:
				    {
                        AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.984999, 0.000000, -0.554999, 0.000000, 0.000000, 0.000000); //Object Model: 18648 |
						AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][1], vehicleid, -0.884999, 0.000000, -0.554999, 0.000000, 0.000000, 0.000000); //Object Model: 18648 |
				    }
				    case 571:
				    {
                        AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, -0.359999, 0.000000, -0.224999, 0.000000, 0.000000, 0.000000); //Object Model: 18648 |
						AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][1], vehicleid, 0.384999, 0.000000, -0.224999, 0.000000, 0.000000, 0.000000); //Object Model: 18648 |
				    }
				}
                DerbyVehicles[vehicleid][derby_vehicle_object_model] = 18648;
			}
	    }
	    case 14000..19999:
	    {
			if(DerbyVehicles[vehicleid][derby_vehicle_object_model] != 11245)
			{
			    DestroyDerbyVehicleObjects(vehicleid);
				DerbyVehicles[vehicleid][derby_vehicle_object_id][0] = CreateObject(11245, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
				switch(vehicle_model)
				{
				    case 531: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, -0.029999, -2.750015, 1.444998, -0.000001, -29.144989, -90.449951); //Object Model: 11245 |
				    case 601: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, -2.451008, 1.589998, 0.000000, -22.109996, -90.449951); //Object Model: 11245 |
				    case 568: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.105000, -2.490009, 1.189999, 0.000000, -23.114995, -85.424964); //Object Model: 11245 |
				    case 588: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, -3.270027, 3.095023, 0.000000, -16.080001, -90.047920); //Object Model: 11245 |
				    case 573: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, -2.480009, 1.159999, 0.000000, -20.099998, -90.047920); //Object Model: 11245 |
				    case 556: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, -2.009998, 1.144999, 0.000000, -16.079999, -90.047920); //Object Model: 11245 |
				    case 571: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, -1.994998, 2.290004, 0.000000, -52.260009, -90.047920); //Object Model: 11245 |
				}
                DerbyVehicles[vehicleid][derby_vehicle_object_model] = 11245;
			}
	    }
	    default:
	    {
	        if(DerbyVehicles[vehicleid][derby_vehicle_object_model] != 2935)
			{
			    DestroyDerbyVehicleObjects(vehicleid);
				DerbyVehicles[vehicleid][derby_vehicle_object_id][0] = CreateObject(2935, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
				switch(vehicle_model)
				{
				    case 531: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, -0.135000, 0.704999, 0.000000, 0.000000, 0.000000); //Object Model: 2935 |
				    case 601: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, 0.000000, 0.839999, 0.000000, 0.000000, 0.000000); //Object Model: 2935 |
				    case 568: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, 0.000000, 0.734999, 0.000000, 0.000000, 0.000000); //Object Model: 2935 |
				    case 588: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, -0.294999, 0.889999, 0.000000, 0.000000, 0.000000); //Object Model: 2935 |
				    case 573: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, 0.000000, 0.219999, 0.000000, 0.000000, 0.000000); //Object Model: 2935 |
				    case 556: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, 0.000000, 0.319999, 0.000000, 0.000000, 0.000000); //Object Model: 2935 |
				    case 571: AttachObjectToVehicle(DerbyVehicles[vehicleid][derby_vehicle_object_id][0], vehicleid, 0.000000, 0.000000, 1.314998, 0.000000, 0.000000, 0.000000); //Object Model: 2935 |
				}
                DerbyVehicles[vehicleid][derby_vehicle_object_model] = 2935;
			}
	    }
	}
}

stock DestroyDerbyVehicleObjects(vehicleid)
{
	for(new i; i<2; i++)
	{
	    if(DerbyVehicles[vehicleid][derby_vehicle_object_id][i] != 0 && IsValidObject(DerbyVehicles[vehicleid][derby_vehicle_object_id][i]))
	    {
			DestroyObject(DerbyVehicles[vehicleid][derby_vehicle_object_id][i]);
            DerbyVehicles[vehicleid][derby_vehicle_object_id][i] = 0;
            DerbyVehicles[vehicleid][derby_vehicle_object_model] = 0;
	    }
    }
}

stock ShowPlayerDerbyPanel(playerid)
{
	TempInfo[playerid][temp_derby_panel_shown] = 1;
    if(derby == DERBY_STATE_REGISTRATION)
	{
	    new derby_minutes = derby_start_countdown/60,
			derby_seconds = derby_start_countdown%60;

	    format:g_str_least("%02d:%02d", derby_minutes, derby_seconds);
		PlayerTextDrawSetString(playerid, DerbyPanelTD[playerid][derby_panel_time], g_str_least);

		PlayerTextDrawSetString(playerid, DerbyPanelTD[playerid][derby_panel_score], "0");
	}

 	if(derby == DERBY_STATE_ACTIVE)
	{
	    new derby_minutes = derby_final_countdown/60,
			derby_seconds = derby_final_countdown%60;

	    format:g_str_least("%02d:%02d", derby_minutes, derby_seconds);
		PlayerTextDrawSetString(playerid, DerbyPanelTD[playerid][derby_panel_time_count], g_str_least);

		switch(derby_vehicle_model)
		{
        	case 531: PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][0]);
        	case 601: PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][1]);
        	case 568: PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][2]);
        	case 588: PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][3]);
        	case 573: PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][4]);
        	case 556: PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][5]);
        	case 571: PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle][6]);
        }

        PlayerTextDrawBoxColor(playerid, DerbyPanelTD[playerid][derby_panel_box][1], 0x00800075);

	    format:g_str_least("%d", TempInfo[playerid][temp_derby_score]);
	    PlayerTextDrawSetString(playerid, DerbyPanelTD[playerid][derby_panel_score], g_str_least);
	}

	for(new i; i<4; i++) PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_box][i]);
	PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_time]);
	PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_health_label]);
	PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_health]);
	PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_score]);
	return 1;
}

stock insert_sort(array[], const size = sizeof(array))
{
    for(new i = size-2, j, key; i >= 0; i--)
    {
        key = array[i];
        if(key == -1 || !IsPlayerConnected(key) || !TempInfo[key][temp_derby_active])
        {
	        for(j = i + 1; j < size && array[j] != -1; j++)
	        {
	   			array[j - 1] = array[j];
	        }
        }
		else
		{
	        for(j = i + 1; j < size && array[j] != -1 && TempInfo[array[j]][temp_derby_score] > TempInfo[key][temp_derby_score] ; j++)
	        {
	   			array[j - 1] = array[j];
	        }
        }
        array[j - 1] = key;
    }
}

stock HidePlayerDerbyPanel(playerid)
{
    TempInfo[playerid][temp_derby_panel_shown] = 0;
	for(new i; i<3; i++) PlayerTextDrawHide(playerid, DerbyPanelTD[playerid][derby_panel_box][i]);
	PlayerTextDrawHide(playerid, DerbyPanelTD[playerid][derby_panel_vehicle]);
	PlayerTextDrawHide(playerid, DerbyPanelTD[playerid][derby_panel_time_label]);
	PlayerTextDrawHide(playerid, DerbyPanelTD[playerid][derby_panel_time_count]);
	PlayerTextDrawHide(playerid, DerbyPanelTD[playerid][derby_panel_score]);
	return 1;
}

stock GetVehicleHealthInt(vehicleid)
{
	new Float:veh_hp;
	GetVehicleHealth(vehicleid, veh_hp);
	return floatround(veh_hp, floatround_round);
}

CMD:veh(playerid,params[])
{
    new string[145];
    new Float:pX,Float:pY,Float:pZ;
    if(sscanf(params, "ddd", params[0],params[1],params[2])) return SendClientMessage(playerid, -1, "{BEBEBE}Использование: /veh [id машины] {цвет 1} {цвет 2}");
    {
        if(params[1] > 126 || params[1] < 0 || params[2] > 126 || params[2] < 0) return SendClientMessage(playerid, -1, "ID цвета от 0 до 126!");
        GetPlayerPos(playerid,pX,pY,pZ);
        new vehid = CreateVehicle(params[0],pX+2,pY,pZ,0.0,params[1],params[2],0,0);
        LinkVehicleToInterior(vehid, GetPlayerInterior(playerid));
        PutPlayerInVehicle(playerid, vehid, 0);
        format(string,sizeof(string),"{696969}[!] {1E90FF}Вы создали автомобиль №%d",params[0]);
        SendClientMessage(playerid,-1,string);
    }
    return 1;
}
CMD:tp(playerid)
{
	SetPlayerPos(playerid, -1398.103515, 937.631164, 1036.479125);
	SetPlayerInterior(playerid, 15);
	return 1;
}
CMD:stadium(playerid)
{
	SetPlayerPos(playerid, 2695.6340, -1704.7819, 11.8438);
	SetPlayerInterior(playerid, 0);
	return 1;
}
CMD:startregistr(playerid, params[])
{
	if(!debug_mode) return 1;
    if(sscanf(params, "d", params[0]))
        params[0] = 30;

    derby_start_countdown = params[0];
    derby = DERBY_STATE_REGISTRATION;
    SendClientMessageToAll(COLOR_YELLOW, "[DERBY]: Открыта регистрация на дерби на стадионе г.Лос Сантос.");
    return 1;
}
CMD:debug(playerid)
{
	debug_mode = !debug_mode;
	if(debug_mode)
	    SendClientMessageToAll(COLOR_GREEN, "> DEBUG MODE ON <");
	else
	    SendClientMessageToAll(COLOR_RED, "> DEBUG MODE OFF <");
}
CMD:startderby(playerid, params[])
{
    if(!debug_mode) return 1;
    if(sscanf(params, "d", params[0]))
        params[0] = 120;

    derby = DERBY_STATE_ACTIVE;
    
    switch(random(7))
    {
        case 0: derby_vehicle_model = 531;
        case 1: derby_vehicle_model = 601;
        case 2: derby_vehicle_model = 568;
        case 3: derby_vehicle_model = 588;
        case 4: derby_vehicle_model = 573;
        case 5: derby_vehicle_model = 556;
        case 6: derby_vehicle_model = 571;
    }
    
    for(new i; i<MAX_DERBY_SLOTS; i++)
	{
	    if(DerbySlots[i] == -1) continue;
	    if(IsPlayerConnected(DerbySlots[i]) && TempInfo[DerbySlots[i]][temp_derby_active])
	    {
	        new
				player_id = DerbySlots[i];
	        
      		SetPlayerInterior(player_id, 15);
			TempInfo[player_id][temp_derby_vehicle_id] = CreateVehicle(derby_vehicle_model,DerbySpawnPoints[i][0],DerbySpawnPoints[i][1],DerbySpawnPoints[i][2],DerbySpawnPoints[i][3],-1,-1,0,0);
			LinkVehicleToInterior(TempInfo[player_id][temp_derby_vehicle_id], 15);

			DerbyVehicles[TempInfo[player_id][temp_derby_vehicle_id]][derby_vehicle_owner_id] = player_id;
			PutPlayerInVehicle(player_id, TempInfo[player_id][temp_derby_vehicle_id], 0);
			TogglePlayerControllable(player_id, 0);
			TempInfo[player_id][temp_derby_countdown] = 3;
        	GameTextForPlayer(player_id, "3", 1000, 4);
	    }
	}
	derby_final_countdown = params[0];
	SendClientMessageToAll(COLOR_YELLOW, "[DERBY]: Дерби началось");
	return 1;
}
CMD:restart(playerid)
{
	SendRconCommand("gmx");
	return 1;
}
