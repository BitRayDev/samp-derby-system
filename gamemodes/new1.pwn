
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

new debug_mode = 1;

new
	g_str_least[32],
	g_str_small[256];
//	g_str_big[512],
//	g_str_cmd[2048];
	
new hours, minutes;

new derby;

new derby_start_countdown,
	derby_final_countdown,
	derby_breakdown_countdown,
	derby_spawn_countdown;

new DerbySlots[MAX_DERBY_SLOTS];

enum E_USER
{
	uName[MAX_PLAYER_NAME]
}
new uInfo[MAX_PLAYERS][E_USER];

enum E_TEMP
{
	temp_derby_active,
	temp_derby_score,
	temp_derby_slot_id,
	temp_derby_vehicle_id,
	temp_derby_vehicle_model,
	temp_derby_combo,
	temp_derby_countdown
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
	PlayerText:derby_panel_box[3],
	PlayerText:derby_panel_vehicle,
	PlayerText:derby_panel_time_label,
	PlayerText:derby_panel_time_count,
	PlayerText:derby_panel_score
}
new DerbyPanelTD[MAX_PLAYERS][E_DERBY_PANEL_TD];

new PlayerText:DerbyFinalTD[MAX_PLAYERS][15];
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
                SendClientMessageToAll(COLOR_YELLOW, "[DERBY]: ������� ����������� �� ����� �� �������� �.��� ������. �� ������ 2 ������.");
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
				        TempInfo[DerbySlots[i]][temp_derby_active] = DERBY_STATE_CLOSED;
				        TempInfo[DerbySlots[i]][temp_derby_slot_id] = INVALID_DERBY_SLOT_ID;
				        DerbySlots[i] = -1;
				    }
				    SendClientMessageToAll(COLOR_RED, "[DERBY]: ����� �������� ��-�� �������������� ���������� ����������");
			    }
			    else
			    {
					for(new i; i<MAX_DERBY_SLOTS; i++)
					{
					    if(DerbySlots[i] == -1) continue;
					    if(IsPlayerConnected(DerbySlots[i]) && TempInfo[DerbySlots[i]][temp_derby_active])
					    {

					        new
								playerid = DerbySlots[i],
							 	veh_model = random(7);

					        switch(veh_model)
					        {
					            case 0: TempInfo[playerid][temp_derby_vehicle_model] = 531;
					            case 1: TempInfo[playerid][temp_derby_vehicle_model] = 601;
					            case 2: TempInfo[playerid][temp_derby_vehicle_model] = 568;
					            case 3: TempInfo[playerid][temp_derby_vehicle_model] = 588;
					            case 4: TempInfo[playerid][temp_derby_vehicle_model] = 573;
					            case 5: TempInfo[playerid][temp_derby_vehicle_model] = 556;
					            case 6: TempInfo[playerid][temp_derby_vehicle_model] = 571;
					        }
					        SetPlayerInterior(playerid, 15);
							TempInfo[playerid][temp_derby_vehicle_id] = CreateVehicle(TempInfo[playerid][temp_derby_vehicle_model],DerbySpawnPoints[i][0],DerbySpawnPoints[i][1],DerbySpawnPoints[i][2],DerbySpawnPoints[i][3],-1,-1,0,0);
		                    LinkVehicleToInterior(TempInfo[playerid][temp_derby_vehicle_id], 15);
							DerbyVehicles[TempInfo[playerid][temp_derby_vehicle_id]][derby_vehicle_owner_id] = playerid;
							PutPlayerInVehicle(playerid, TempInfo[playerid][temp_derby_vehicle_id], 0);
                            ShowPlayerDerbyPanel(playerid);
							TogglePlayerControllable(playerid, 0);
							TempInfo[playerid][temp_derby_countdown] = 3;
			            	GameTextForPlayer(playerid, "3", 1000, 4);
					    }
					}
					derby = DERBY_STATE_ACTIVE;
					derby_final_countdown = 20;
				    SendClientMessageToAll(COLOR_YELLOW, "[DERBY]: ����� ��������");
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
	            //insert_sort(DerbySlots);
				
				for(new i; i<MAX_DERBY_SLOTS; i++)
				{
					if(DerbySlots[i] == -1 || !IsPlayerConnected(DerbySlots[i]) || !TempInfo[DerbySlots[i]][temp_derby_active]) continue;

                    SetPlayerCameraPos(DerbySlots[i], 2729.807128, -1760.430297, 45.141902);
					SetPlayerCameraLookAt(DerbySlots[i], 2734.807128, -1760.430664, 45.113151);

					PlayerPlaySound(DerbySlots[i], 31205, 0.0, 0.0, 0.0);

					if(IsValidVehicle(TempInfo[DerbySlots[i]][temp_derby_vehicle_id]))
					{
					    DestroyVehicle(TempInfo[DerbySlots[i]][temp_derby_vehicle_id]);
					    TempInfo[DerbySlots[i]][temp_derby_vehicle_id] = 0;
					}

					SetPlayerPos(DerbySlots[i], 2709.9812,-1758.8921,42.7773);
					SetPlayerInterior(DerbySlots[i], 0);
                    
					if(DerbySlots[0] != -1 && IsPlayerConnected(DerbySlots[0]) && TempInfo[DerbySlots[0]][temp_derby_active])
					{
						PlayerTextDrawSetString(DerbySlots[i], DerbyFinalTD[i][6], uInfo[DerbySlots[0]][uName]);
						format:g_str_least("%d", TempInfo[DerbySlots[0]][temp_derby_score]);
						PlayerTextDrawSetString(DerbySlots[i], DerbyFinalTD[i][9], g_str_least);
					}
					if(DerbySlots[1] != -1 && IsPlayerConnected(DerbySlots[1]) && TempInfo[DerbySlots[1]][temp_derby_active])
					{
						PlayerTextDrawSetString(DerbySlots[i], DerbyFinalTD[i][7], uInfo[DerbySlots[1]][uName]);
						format:g_str_least("%d", TempInfo[DerbySlots[1]][temp_derby_score]);
						PlayerTextDrawSetString(DerbySlots[i], DerbyFinalTD[i][10], g_str_least);
					}
                    if(DerbySlots[2] != -1 && IsPlayerConnected(DerbySlots[2]) && TempInfo[DerbySlots[2]][temp_derby_active])
					{
					    PlayerTextDrawSetString(DerbySlots[i], DerbyFinalTD[i][8], uInfo[DerbySlots[2]][uName]);
						format:g_str_least("%d", TempInfo[DerbySlots[2]][temp_derby_score]);
						PlayerTextDrawSetString(DerbySlots[i], DerbyFinalTD[i][11], g_str_least);
					}
					ShowPlayerDerbyFinal(DerbySlots[i]);
				}
				
				if(DerbySlots[0] != -1 && IsPlayerConnected(DerbySlots[0]) && TempInfo[DerbySlots[0]][temp_derby_active])
				{
					SetPlayerPos(DerbySlots[0], 2737.9714,-1760.4259,45.1107);
					SetPlayerFacingAngle(DerbySlots[0], 90.0);
				}
				if(DerbySlots[1] != -1 && IsPlayerConnected(DerbySlots[1]) && TempInfo[DerbySlots[1]][temp_derby_active])
				{
					SetPlayerPos(DerbySlots[1], 2738.0181,-1759.1765,44.8657);
					SetPlayerFacingAngle(DerbySlots[1], 90.0);
				}
                if(DerbySlots[2] != -1 && IsPlayerConnected(DerbySlots[2]) && TempInfo[DerbySlots[2]][temp_derby_active])
				{
					SetPlayerPos(DerbySlots[2], 2737.9565,-1761.7336,44.4657);
					SetPlayerFacingAngle(DerbySlots[2], 90.0);
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
				    SendClientMessage(i, COLOR_GREEN, "�� ������ �� �������� �� �����");
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
		            if(DerbyRespawnVehicleCounter[i] > 0)
		            {
						DerbyRespawnVehicleCounter[i]--;
					    if(DerbyRespawnVehicleCounter[i] <= 0)
					    {
					        if(IsValidVehicle(TempInfo[i][temp_derby_vehicle_id]))
							{
							    DestroyVehicle(i][temp_derby_vehicle_id]);
							    TempInfo[i][temp_derby_vehicle_id] = 0;
							}
						    HidePlayerDerbyPanel(i);
							TogglePlayerControllable(i, 1);
							new sp = random(6);
							SetPlayerPos(i, DerbyEndSpawnPoints[sp][0], DerbyEndSpawnPoints[sp][1], DerbyEndSpawnPoints[sp][2]);
							SetPlayerFacingAngle(i, DerbyEndSpawnPoints[sp][3]);
							SetCameraBehindPlayer(i);
							DerbySlots[TempInfo[i][temp_derby_slot_id]] = -1;
							TempInfo[i][temp_derby_active] = 0;
							TempInfo[i][temp_derby_slot_id] = INVALID_DERBY_SLOT_ID;
					    }
					}
	            }
		    }
		    else TempInfo[i][temp_derby_active] = 0;
	    }
	}
}
function UpdateTime()
{
	gettime(hours, minutes);
	if(minutes == 10)
	{
	    derby = DERBY_STATE_REGISTRATION;
	    derby_start_countdown = 300;
	    SendClientMessageToAll(COLOR_YELLOW, "[DERBY]: ������� ����������� �� ����� �� �������� �.��� ������. �� ������ 5 �����.");
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
	AddPlayerClass(0, -1398.103515, 937.631164, 1036.479125, 269.1425, 0, 0, 0, 0, 0, 0);
	
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

	LoadPlayerTD(playerid);

	TempInfo[playerid][temp_derby_active] = 0;
	TempInfo[playerid][temp_derby_score] = 0;
	TempInfo[playerid][temp_derby_slot_id] = -1;
	TempInfo[playerid][temp_derby_vehicle_id] = INVALID_VEHICLE_ID;
	TempInfo[playerid][temp_derby_vehicle_model] = 0;
	TempInfo[playerid][temp_derby_combo] = 0;
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(TempInfo[playerid][temp_derby_active])
	{
        TempInfo[playerid][temp_derby_active] = DERBY_STATE_CLOSED;
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
    if(derby == DERBY_STATE_ACTIVE)
	{
	    if(TempInfo[playerid][temp_derby_active])
	    {
	        SetPlayerInterior(playerid, 15);
	        PutPlayerInVehicle(playerid, TempInfo[playerid][temp_derby_vehicle_id], 0);
            TogglePlayerControllable(playerid, 0);
            TempInfo[playerid][temp_derby_countdown] = 3;
            GameTextForPlayer(playerid, "3", 1000, 4);
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
	            TempInfo[playerid][temp_derby_combo] = 0;
	            
	            ResetDerbyVehicleObjects(playerid, vehicleid);
	            
				if(TempInfo[playerid][temp_derby_score] < 0)
					 TempInfo[playerid][temp_derby_score] = 0;

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
			    DerbyRespawnVehicleCounter[playerid] = 20;
			    SendClientMessage(playerid, COLOR_RED, "� ��� ���� 20 ������, ����� ��������� � ���� ����, ����� �� ������ ������������������");
			}
		}
	}
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	/*if(newstate = PLAYER_STATE_ONFOOT && oldstate == PLAYER_STATE_DRIVER)
	{
	    if()
	}*/
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
    SetPlayerInterior(playerid, 15);
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
	        if(IsPlayerConnected(playerid) && TempInfo[playerid][temp_derby_vehicle_id] == vehicleid)
	        {
			    new veh_health = GetVehicleHealthInt(vehicleid);
			    switch(veh_health)
			    {
			        case 0..449: PlayerTextDrawSetPreviewVehCol(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 3, 3);
			        case 450..749: PlayerTextDrawSetPreviewVehCol(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 6, 6);
			        case 750..1000: PlayerTextDrawSetPreviewVehCol(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 16, 16);
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
							format:g_str_small("�� ������� ���������������� �� �����. ��� �����: %d", i);
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
        			SendClientMessage(playerid, COLOR_GREEN, "�� ������ �� �������� �� �����");
        			return 1;
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
	
	DerbyFinalTD[playerid][0] = CreatePlayerTextDraw(playerid, 245.0, 385.0, "20.000$");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][0], 0.444666, 2.525037);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][0], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][0], -1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][0], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][0], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][0], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][0], 1);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][0], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][0], 0);

	DerbyFinalTD[playerid][1] = CreatePlayerTextDraw(playerid, 320.0, 385.0, "30.000$");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][1], 0.444666, 2.525037);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][1], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][1], -1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][1], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][1], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][1], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][1], 1);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][1], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][1], 0);

	DerbyFinalTD[playerid][2] = CreatePlayerTextDraw(playerid, 400.0, 385.0, "10.000$");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][2], 0.444666, 2.525037);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][2], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][2], -1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][2], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][2], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][2], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][2], 1);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][2], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][2], 0);

	DerbyFinalTD[playerid][3] = CreatePlayerTextDraw(playerid, 320.0, 350.0, "1");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][3], 0.444666, 2.525037);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][3], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][3], -65281);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][3], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][3], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][3], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][3], 1);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][3], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][3], 0);

	DerbyFinalTD[playerid][4] = CreatePlayerTextDraw(playerid, 245.0, 350.0, "2");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][4], 0.444666, 2.525037);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][4], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][4], -1061109505);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][4], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][4], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][4], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][4], 1);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][4], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][4], 0);

	DerbyFinalTD[playerid][5] = CreatePlayerTextDraw(playerid, 400.0, 350.0, "3");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][5], 0.444666, 2.525037);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][5], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][5], -1523963137);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][5], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][5], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][5], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][5], 1);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][5], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][5], 0);

	DerbyFinalTD[playerid][6] = CreatePlayerTextDraw(playerid, 320.0, 110.0, "Nick_name");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][6], 0.20, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][6], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][6], -1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][6], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][6], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][6], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][6], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][6], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][6], 0);

	DerbyFinalTD[playerid][7] = CreatePlayerTextDraw(playerid, 245.0, 140.0, "Nick_name");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][7], 0.20, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][7], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][7], -1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][7], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][7], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][7], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][7], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][7], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][7], 0);

	DerbyFinalTD[playerid][8] = CreatePlayerTextDraw(playerid, 400.0, 140.0, "Nick_name");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][8], 0.20, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][8], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][8], -1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][8], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][8], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][8], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][8], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][8], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][8], 0);

	DerbyFinalTD[playerid][9] = CreatePlayerTextDraw(playerid, 320.0, 125.0, "21000");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][9], 0.251333, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][9], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][9], -1378294017);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][9], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][9], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][9], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][9], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][9], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][9], 0);

	DerbyFinalTD[playerid][10] = CreatePlayerTextDraw(playerid, 245.0, 155.0, "21000");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][10], 0.251333, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][10], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][10], -1378294017);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][10], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][10], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][10], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][10], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][10], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][10], 0);

	DerbyFinalTD[playerid][11] = CreatePlayerTextDraw(playerid, 400.0, 155.0, "21000");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][11], 0.251333, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][11], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][11], -1378294017);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][11], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][11], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][11], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][11], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][11], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][11], 0);

	DerbyFinalTD[playerid][12] = CreatePlayerTextDraw(playerid, 245.0, 405.0, "200");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][12], 0.251333, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][12], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][12], -1378294017);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][12], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][12], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][12], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][12], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][12], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][12], 0);

	DerbyFinalTD[playerid][13] = CreatePlayerTextDraw(playerid, 320.0, 405.0, "300");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][13], 0.251333, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][13], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][13], -1378294017);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][13], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][13], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][13], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][13], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][13], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][13], 0);

	DerbyFinalTD[playerid][14] = CreatePlayerTextDraw(playerid, 400.0, 405.0, "100");
	PlayerTextDrawLetterSize(playerid, DerbyFinalTD[playerid][14], 0.251333, 1.604148);
	PlayerTextDrawAlignment(playerid, DerbyFinalTD[playerid][14], 2);
	PlayerTextDrawColor(playerid, DerbyFinalTD[playerid][14], -1378294017);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][14], 0);
	PlayerTextDrawSetOutline(playerid, DerbyFinalTD[playerid][14], 1);
	PlayerTextDrawBackgroundColor(playerid, DerbyFinalTD[playerid][14], 255);
	PlayerTextDrawFont(playerid, DerbyFinalTD[playerid][14], 2);
	PlayerTextDrawSetProportional(playerid, DerbyFinalTD[playerid][14], 1);
	PlayerTextDrawSetShadow(playerid, DerbyFinalTD[playerid][14], 0);
	
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
	PlayerTextDrawSetShadow(playerid, BlackScreen[playerid], 0);
}

stock ShowPlayerDerbyFinal(playerid)
{
	for(new i; i<15; i++) PlayerTextDrawShow(playerid, DerbyFinalTD[playerid][i]);
	return 1;
}

stock HidePlayerDerbyFinal(playerid)
{
	for(new i; i<15; i++) PlayerTextDrawHide(playerid, DerbyFinalTD[playerid][i]);
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
    if(derby == DERBY_STATE_REGISTRATION)
	{
	    new derby_minutes = derby_start_countdown/60,
			derby_seconds = derby_start_countdown%60;

	    format:g_str_least("%02d:%02d", derby_minutes, derby_seconds);
		PlayerTextDrawSetString(playerid, DerbyPanelTD[playerid][derby_panel_time_count], g_str_least);
		
		PlayerTextDrawSetPreviewVehCol(playerid, DerbyPanelTD[playerid][derby_panel_vehicle], 1, 1);
		
		PlayerTextDrawSetString(playerid, DerbyPanelTD[playerid][derby_panel_score], "0");
	}
	
	if(derby == DERBY_STATE_ACTIVE)
	{
	    new derby_minutes = derby_final_countdown/60,
			derby_seconds = derby_final_countdown%60;

	    format:g_str_least("%02d:%02d", derby_minutes, derby_seconds);
		PlayerTextDrawSetString(playerid, DerbyPanelTD[playerid][derby_panel_time_count], g_str_least);
		
	    format:g_str_least("%d", TempInfo[playerid][temp_derby_score]);
	    PlayerTextDrawSetString(playerid, DerbyPanelTD[playerid][derby_panel_score], g_str_least);
	}

	for(new i; i<3; i++) PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_box][i]);
	PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_vehicle]);
	PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_time_label]);
	PlayerTextDrawShow(playerid, DerbyPanelTD[playerid][derby_panel_time_count]);
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
    if(sscanf(params, "ddd", params[0],params[1],params[2])) return SendClientMessage(playerid, -1, "{BEBEBE}�������������: /veh [id ������] {���� 1} {���� 2}");
    {
        if(params[1] > 126 || params[1] < 0 || params[2] > 126 || params[2] < 0) return SendClientMessage(playerid, -1, "ID ����� �� 0 �� 126!");
        GetPlayerPos(playerid,pX,pY,pZ);
        new vehid = CreateVehicle(params[0],pX+2,pY,pZ,0.0,params[1],params[2],0,0);
        LinkVehicleToInterior(vehid, GetPlayerInterior(playerid));
        PutPlayerInVehicle(playerid, vehid, 0);
        format(string,sizeof(string),"{696969}[!] {1E90FF}�� ������� ���������� �%d",params[0]);
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
    SendClientMessageToAll(COLOR_YELLOW, "[DERBY]: ������� ����������� �� ����� �� �������� �.��� ������.");
    return 1;
}
CMD:startderby(playerid, params[])
{
    if(!debug_mode) return 1;
    if(sscanf(params, "d", params[0])) 
        params[0] = 120;

    derby = DERBY_STATE_ACTIVE;
    for(new i; i<MAX_DERBY_SLOTS; i++)
	{
	    if(DerbySlots[i] == -1) continue;
	    if(IsPlayerConnected(DerbySlots[i]) && TempInfo[DerbySlots[i]][temp_derby_active])
	    {

	        new
				player_id = DerbySlots[i],
			 	veh_model = random(7);

	        switch(veh_model)
	        {
	            case 0: TempInfo[player_id][temp_derby_vehicle_model] = 531;
	            case 1: TempInfo[player_id][temp_derby_vehicle_model] = 601;
	            case 2: TempInfo[player_id][temp_derby_vehicle_model] = 568;
	            case 3: TempInfo[player_id][temp_derby_vehicle_model] = 588;
	            case 4: TempInfo[player_id][temp_derby_vehicle_model] = 573;
	            case 5: TempInfo[player_id][temp_derby_vehicle_model] = 556;
	            case 6: TempInfo[player_id][temp_derby_vehicle_model] = 571;
	        }
      		SetPlayerInterior(player_id, 15);
			TempInfo[player_id][temp_derby_vehicle_id] = CreateVehicle(TempInfo[player_id][temp_derby_vehicle_model],DerbySpawnPoints[i][0],DerbySpawnPoints[i][1],DerbySpawnPoints[i][2],DerbySpawnPoints[i][3],-1,-1,0,0);
			LinkVehicleToInterior(TempInfo[player_id][temp_derby_vehicle_id], 15);
			DerbyVehicles[TempInfo[player_id][temp_derby_vehicle_id]][derby_vehicle_owner_id] = player_id;
			PutPlayerInVehicle(player_id, TempInfo[player_id][temp_derby_vehicle_id], 0);
            ShowPlayerDerbyPanel(player_id);
			TogglePlayerControllable(player_id, 0);
			TempInfo[player_id][temp_derby_countdown] = 3;
        	GameTextForPlayer(player_id, "3", 1000, 4);
	    }
	}
	derby_final_countdown = params[0];
	SendClientMessageToAll(COLOR_YELLOW, "[DERBY]: ����� ��������");
	return 1;
}
