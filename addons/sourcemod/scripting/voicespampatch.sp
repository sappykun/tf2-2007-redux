/*
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma newdecls required 
#pragma semicolon 1

Address addrNoteSpokeVoiceCommand;
int offsetVoiceSpamCounter;

public Plugin myinfo = 
{
    name = "[TF2] Voice Command Anti-Anti-Spam",
    author = "Sappykun",
    description = "Patches out the voice command spam control added in 2018",
    version = "1.1",
    url = "https://weea.boutique/"
};

public void OnPluginStart()
{
    Handle hConfig = LoadGameConfigFile("tf2.voicespampatch");
    
    if (hConfig == INVALID_HANDLE)
        SetFailState("Could not load gamedata/tf2.voicespampatch.txt");
    
    addrNoteSpokeVoiceCommand = GameConfGetAddress(hConfig, "NoteSpokeVoiceCommand");
    offsetVoiceSpamCounter = GameConfGetOffset(hConfig, "m_iVoiceSpamCounter");
    
    CloseHandle(hConfig);
    
    // There's a spam prevention feature added in 2018 that will increase the
    // voice command delay if you try to use them too often. Spamming voice
    // commands increments a value called m_iVoiceSpamCounter that adds more
    // delay to the next time the server will let you use a voice command.
    // We're just setting the instruction (add 1 to m_iVoiceSpamCounter) to
    // add 0 instead, effectively no-oping it.
    
    int currentValue = LoadFromAddress(addrNoteSpokeVoiceCommand + view_as<Address>(offsetVoiceSpamCounter), NumberType_Int8);
    if (currentValue != 1)
        SetFailState("Expected byte (0x00000001) was actually %X! The gamedata must be out of date.", currentValue);

    StoreToAddress(addrNoteSpokeVoiceCommand + view_as<Address>(offsetVoiceSpamCounter), 0x00, NumberType_Int8);
    
    // Remove the arbitrary 0.1 minimum added in 2017
    
    Handle maxVoiceSpeakCvar = FindConVar("tf_max_voice_speak_delay");
	
    if (maxVoiceSpeakCvar != INVALID_HANDLE)
        SetConVarBounds(maxVoiceSpeakCvar, ConVarBound_Lower, true, -1.0);

    CloseHandle(maxVoiceSpeakCvar);
}

public void OnPluginEnd()
{
	StoreToAddress(addrNoteSpokeVoiceCommand + view_as<Address>(offsetVoiceSpamCounter), 0x01, NumberType_Int8);
}