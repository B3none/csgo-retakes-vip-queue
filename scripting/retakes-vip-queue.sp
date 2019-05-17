#include <sourcemod>
#include <retakes>

#pragma semicolon 1
#pragma newdecls required

#define MESSAGE_PREFIX "[\x04Retakes\x01]"

public Plugin myinfo =
{
	name = "[Retakes] VIP Queue",
	author = "B3none",
	description = "Allow VIP players to take priority in the queue.",
	version = "1.1.0",
	url = "https://github.com/b3none"
};

public void OnPluginStart()
{
	LoadTranslations("retakes-vip-queue.phrases");
}

public void Retakes_OnPreRoundEnqueue(Handle rankingQueue, Handle waitingQueue)
{
	int vip;
	
	vip = FindAdminInArray(waitingQueue);
	
	int count;
	while (vip != -1)
	{
		PQ_Enqueue(rankingQueue, vip, 0);
		Queue_Drop(waitingQueue, vip);
		count++;
		
		vip = FindAdminInArray(waitingQueue);
	}
	
	Handle array_players = CreateArray();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1 && !CheckCommandAccess(i, "skip_queue", ADMFLAG_RESERVATION, false))
		{
			PushArrayCell(array_players, i);
		}
	}
	
	int luck, player;
	while (count > 0 && GetArraySize(array_players) > 0)
	{
		count--;
		
		luck = GetRandomInt(0, GetArraySize(array_players) - 1);
		player = GetArrayCell(array_players, luck);
		
		ChangeClientTeam(player, 1);
		
		PrintToChat(player, "%T", player, "Replaced" MESSAGE_PREFIX);
		
		RemoveFromArray(array_players, luck);
		
		Queue_Enqueue(waitingQueue, player);
	}
	
	delete array_players;
}

int FindAdminInArray(Handle waitingQueue)
{
	if (GetArraySize(waitingQueue) != 0)
	{
		int client = 0;
		int index = 0;
		bool found = false;
		
		while (!found && index < GetArraySize(waitingQueue))
		{
			client = GetArrayCell(waitingQueue, index);
			
			if (CheckCommandAccess(client, "skip_queue", ADMFLAG_RESERVATION, false))
			{
				found = true;
			}
			else
			{
				index++;
			}
		}
		
		return found ? client : -1;
	}
	
	return -1;
} 

void PQ_Enqueue(Handle queueHandle, int client, int value)
{
    int index = PQ_FindClient(queueHandle, client);

    if (index == -1)
    {
        index = GetArraySize(queueHandle);
        PushArrayCell(queueHandle, client);
        SetArrayCell(queueHandle, index, client, 0);
    }

    SetArrayCell(queueHandle, index, value, 1);
}

int PQ_FindClient(Handle queueHandle, int client)
{
    for (int i = 0; i < GetArraySize(queueHandle); i++)
    {
        int c = GetArrayCell(queueHandle, i, 0);
        
        if (client == c)
        {
            return i;
        }
    }
    return -1;
}

void Queue_Enqueue(Handle queueHandle, int client)
{
    if (Queue_Find(queueHandle, client) == -1)
    {
        PushArrayCell(queueHandle, client);
    }
}

int Queue_Find(Handle queueHandle, int client)
{
    return FindValueInArray(queueHandle, client);
}

void Queue_Drop(Handle queueHandle, int client)
{
    int index = Queue_Find(queueHandle, client);
    
    if (index != -1)
    {
        RemoveFromArray(queueHandle, index);
    }
}
