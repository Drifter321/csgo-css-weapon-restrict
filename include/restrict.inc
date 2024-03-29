#if defined _restrict_included
  #endinput
#endif
#define _restrict_included

#include "cstrike_weapons.inc"

enum RoundType
{
	RoundType_None,
	RoundType_Pistol,
	RoundType_Knife,
	RoundType_Warmup
}

enum CanBuyResult
{
	CanBuy_Block, //block buy but notify
	CanBuy_BlockDontDisplay, //block buy and notifications
	CanBuy_Allow //Allow buy
};

#define WEAPONARRAYSIZE 80

/**
 * Called when CanBuyWeapon is fired. 
 * 
 * @param	client		Client index
 * @param	team		Team index
 * @param	id			Weapon id that is being attempted to be bought
 * @param	result		default result
 * 
 * Return Plugin_Continue to ignore Plugin_Changed if result was changed Plugin_Handled and higher to block.
 */
forward Action Restrict_OnCanBuyWeapon(int client, int team, CSWeaponID id, CanBuyResult &result);

/**
 * Called when CanPickupWeapon is fired 
 * 
 * @param	client		Client index
 * @param	team		Team index
 * @param	id			Weapon id that is being attempted to be pickedup
 * @param	result		default result
 * 
 * Return Plugin_Continue to ignore Plugin_Changed if result was changed Plugin_Handled and higher to block.
 */
forward Action Restrict_OnCanPickupWeapon(int client, int team, CSWeaponID id, bool &result);

/**
 * Called when PlayRestrictSound is fired
 * 
 * @param	client		Client index
 * @param	id			Weapon id
 * @param	sound		default sound
 * 
 * Return Plugin_Continue to ignore Plugin_Changed if sound (make sure the sound is already cached and in downloads table) was changed Plugin_Handled and higher to block.
 */
forward Action Restrict_OnPlayRestrictSound(int client, CSWeaponID id, char sound[256]);

/**
 * Called when warmup round has started.
 */
forward void Restrict_OnWarmupStart_Post();

/**
 * Called when warmup round has ended.
 */
forward void Restrict_OnWarmupEnd_Post();

/**
 * Refunds money according to the weapon. 
 * 
 * @param	client		Client index
 * @param	id			Weapon id of the weapon money is being refunded for
 * 
 * @error	Invalid client or invalid id.
 * @noreturn
 */
native void Restrict_RefundMoney(int client, CSWeaponID id);

/**
 * Removes x (count) amount of a certain weapon on a team 
 * 
 * @param	count		Amount to remove
 * @param	team		Team index
 * @param	id			Weapon id to remove
 * 
 * @error	Invalid client or invalid id or invalid team.
 * @noreturn
 */
native void Restrict_RemoveRandom(int count, int team, CSWeaponID id);

/**
 * Gets count of a certain weapon on a team
 * 
 * @param	team		Team index
 * @param	id			Weapon id to get count for
 * 
 * @error	Invalid id or invalid team.
 * @return	Count of the weapon on the team
 */
native int Restrict_GetTeamWeaponCount(int team, CSWeaponID id);

/**
 * Get the restrict value for weapon for the specified team
 * 
 * @param	team		Team index
 * @param	id			Weapon id to get value for
 * 
 * @error	Invalid id or invalid team.
 * @return 	Value of the restriction.
 */
native int Restrict_GetRestrictValue(int team, CSWeaponID id);

/**
 * Get the id for a weapon (Extended)
 * 
 * @param	weapon		Weapon string to get id for
 * 
 * @error	Invalid id or invalid team.
 * @return 	Weapon id or WEAPON_NONE if could not be found.
 */
native CSWeaponID Restrict_GetWeaponIDExtended(const char [] weapon);

/**
 * Get grenade count on client
 * 
 * @param	client		Client index
 * @param	id			Weapon id
 * 
 * @error	Invalid id or invalid client.
 * @return 	Grenade count for specified gernade for the client.
 */
native int Restrict_GetClientGrenadeCount(int client, CSWeaponID id);

/**
 * Get weapon id of the clients weapon slot.
 * 
 * @param	client		Client index
 * @param	slot		Weapon slot
 * 
 * @error	Invalid slot or invalid client.
 * @return 	Weapon id for the clients weapon on the slot. WEAPON_NONE will be returned if no weapon exists
 */
native CSWeaponID Restrict_GetWeaponIDFromSlot(int client, WeaponSlot slot);

/**
 * Removes special item from client (defuser, vest, vest and helmet, night vision)
 * 
 * @param	client		Client index
 * @param	id			Weapon id
 * 
 * @error	Invalid id or invalid client.
 * @return 	true if removed false if not found
 */
native bool Restrict_RemoveSpecialItem(int client, CSWeaponID id);

/**
 * Checks if a client can buy the weapon
 * 
 * @param	client		Client index
 * @param	team		Team index
 * @param	id			Weapon id
 * @param 	blockhook	True to block forward from being called
 * 
 * @error	Invalid id or invalid client or invalid team.
 * @return 	true if client can buy the weapon false otherwise.
 */
native CanBuyResult Restrict_CanBuyWeapon(int client, int team, CSWeaponID id, bool blockhook = false);

/**
 * Checks if a client can pickup the weapon
 * 
 * @param	client		Client index
 * @param	team		Team index
 * @param	id			Weapon id
 * @param 	blockhook	True to block forward from being called
 * 
 * @error	Invalid id or invalid client or invalid team.
 * @return 	true if client can pickup the weapon false otherwise.
 */
native bool Restrict_CanPickupWeapon(int client, int team, CSWeaponID id, bool blockhook = false);

/**
 * Checks if it is a special round.
 * 
 * @return 	true if special round is active false otherwise.
 */
native bool Restrict_IsSpecialRound();

/**
 * Checks if it is warmup round
 * 
 * @return 	true if it is warmup false otherwise.
 */
native bool Restrict_IsWarmupRound();

/**
 * Checks if a client has a special item
 * 
 * @param	client		Client index
 * @param	id			Weapon id
 * 
 * @error	Invalid id or invalid client.
 * @return 	true if client has the special item or false otherwise.
 * @note	This will return false if it is a normal weapon.
 */
native bool Restrict_HasSpecialItem(int client, CSWeaponID id);

/**
 * Sets a restriction for specified team
 * 
 * @param	id			Weapon id
 * @param	team		Team index
 * @param	amount		Value to set restriction at
 * @param	override	True to add weapon to override
 * 
 * @error	Invalid id or invalid team.
 * @return 	true if restriction was applied false otherwise
 * @note	This will return false only if the Weapon id is invalid for the team
 */
native bool Restrict_SetRestriction(CSWeaponID id, int team, int amount, bool override = true);

/**
 * Sets a group restriction for specified team
 * 
 * @param	group		Weapon group
 * @param	team		Team index
 * @param	amount		Value to set restriction at
 * @param	override	True to add weapon's to override
 * 
 * @error	Invalid group or invalid team.
 * @return 	true if restrictions were applied false otherwise
 * @note	Should never return false
 */
native bool Restrict_SetGroupRestriction(WeaponType group, int team, int amount, bool override = true);

/**
 * Returns the round type
 * 
 * @return 	Current round type.
 */
native RoundType Restrict_GetRoundType();

/**
 * Checks player weapons and removes accordingly
 * 
 * @noreturn
 */
native void Restrict_CheckPlayerWeapons();

/**
 * Drops and removes clients weapon
 * 
 * @param	client		Client index
 * @param	weaponIndex	Weapon index to drop and remove
 * 
 * @error	Invalid client or weapon index.
 * @return 	true if weapon was removed false otherwise
 */
native bool Restrict_RemoveWeaponDrop(int client, int weaponIndex);

/**
 * Checks if client has immunity and restrict immunity is enabled
 * 
 * @param	client		Client index
 * 
 * @error	Invalid client.
 * @return 	true if client passes immunity check (Is immune) false otherwise
 * @note	This will return false if restrict immunity is disabled.
 */
native bool Restrict_ImmunityCheck(int client);

/**
 * Checks if weapon is allowed for special round
 * 
 * @param	id		Weapon id
 * 
 * @error	Invalid id.
 * @return 	true if allowed for special round false otherwise
 * @note	This also works for warmup rounds
 */
native bool Restrict_AllowedForSpecialRound(CSWeaponID id);

/**
 * Plays weapon restrict sound
 * 
 * @param	client	Client index
 * @param	id		Weapon id
 * 
 * @error	Invalid client or invalid id.
 * @noreturn
 */
native void Restrict_PlayRestrictSound(int client, CSWeaponID id);

/**
 * Adds weapon to override for specific team
 * 
 * @param	team	Team index
 * @param	id		Weapon id
 * 
 * @error	Invalid team or invalid id.
 * @noreturn
 */
native void Restrict_AddToOverride(int team, CSWeaponID id);

/**
 * Removes weapon from specific teams override
 * 
 * @param	team	Team index
 * @param	id		Weapon id
 * 
 * @error	Invalid team or invalid id.
 * @noreturn
 */
native void Restrict_RemoveFromOverride(int team, CSWeaponID id);

/**
 * Checks if weapon is in override for the specified team
 * 
 * @param	team	Team index
 * @param	id		Weapon id
 * 
 * @error	Invalid team or invalid id.
 * @return	True if weapon is in override false otherwise.
 */
native bool Restrict_IsWeaponInOverride(int team, CSWeaponID id);

/**
 * Checks if the weapon is the warmup weapon
 * 
 * @param id		Weapon id to check
 * 
 * @error	Invalid weapon id.
 * @return	True if the weapon is the warmup weapon, false otherwise.
 * @note	Will return false if it is not warmup.
 */
native bool Restrict_IsWarmupWeapon(CSWeaponID id);

public SharedPlugin __pl_restrict = 
{
	name = "weaponrestrict",
	file = "weapon_restrict.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_restrict_SetNTVOptional()
{
	MarkNativeAsOptional("Restrict_RefundMoney");
	MarkNativeAsOptional("Restrict_RemoveRandom");
	MarkNativeAsOptional("Restrict_GetTeamWeaponCount");
	MarkNativeAsOptional("Restrict_GetRestrictValue");
	MarkNativeAsOptional("Restrict_GetWeaponIDExtended");
	MarkNativeAsOptional("Restrict_GetClientGrenadeCount");
	MarkNativeAsOptional("Restrict_GetWeaponIDFromSlot");
	MarkNativeAsOptional("Restrict_RemoveSpecialItem");
	MarkNativeAsOptional("Restrict_CanBuyWeapon");
	MarkNativeAsOptional("Restrict_CanPickupWeapon");
	MarkNativeAsOptional("Restrict_IsSpecialRound");
	MarkNativeAsOptional("Restrict_IsWarmupRound");
	MarkNativeAsOptional("Restrict_HasSpecialItem");
	MarkNativeAsOptional("Restrict_SetRestriction");
	MarkNativeAsOptional("Restrict_SetGroupRestriction");
	MarkNativeAsOptional("Restrict_GetRoundType");
	MarkNativeAsOptional("Restrict_CheckPlayerWeapons");
	MarkNativeAsOptional("Restrict_RemoveWeaponDrop");
	MarkNativeAsOptional("Restrict_ImmunityCheck");
	MarkNativeAsOptional("Restrict_AllowedForSpecialRound");
	MarkNativeAsOptional("Restrict_PlayRestrictSound");
	MarkNativeAsOptional("Restrict_AddToOverride");
	MarkNativeAsOptional("Restrict_RemoveFromOverride");
	MarkNativeAsOptional("Restrict_IsWeaponInOverride");
	MarkNativeAsOptional("Restrict_IsWarmupWeapon");
}
#endif