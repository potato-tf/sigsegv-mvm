#ifdef SE_IS_TF2
#include "mod.h"
#include "stub/tfweaponbase.h"
#include "stub/objects.h"

namespace Mod::Etc::Compensate_Attack_time
{
	DETOUR_DECL_MEMBER(void, CTFWeaponBaseGun_PrimaryAttack)
	{
		auto weapon = reinterpret_cast<CTFWeaponBaseGun *>(this);

		float current_attack = weapon->m_flNextPrimaryAttack;
		float delta_attack = gpGlobals->curtime - current_attack;

		DETOUR_MEMBER_CALL();

		float flFireDelay = weapon->m_flNextPrimaryAttack - gpGlobals->curtime;

		if (delta_attack >= 0.f && delta_attack <= gpGlobals->interval_per_tick)
			weapon->m_flNextPrimaryAttack = current_attack + flFireDelay;
	}

	DETOUR_DECL_MEMBER(void, CObjectSentrygun_Attack)
	{
		// Note that this does not raise the maximum fire rate on sentries.
		auto sentry = reinterpret_cast<CObjectSentrygun *>(this);

		float current_attack = sentry->m_flNextAttack;
		float delta_attack = gpGlobals->curtime - current_attack;

		DETOUR_MEMBER_CALL();

		float fire_interval = sentry->m_flNextAttack - gpGlobals->curtime;

		if (delta_attack >= 0.f && delta_attack <= gpGlobals->interval_per_tick)
			sentry->m_flNextAttack = current_attack + fire_interval;
	}

	class CMod : public IMod
	{
	public:
		CMod() : IMod("Etc:Compensate_Attack_time")
		{
			// We want these to run last so we can ensure get the final value for m_flNextPrimaryAttack.
			MOD_ADD_DETOUR_MEMBER_PRIORITY(CTFWeaponBaseGun_PrimaryAttack, "CTFWeaponBaseGun::PrimaryAttack", LOWEST);
			MOD_ADD_DETOUR_MEMBER_PRIORITY(CObjectSentrygun_Attack, "CObjectSentrygun::Attack", LOWEST);
		}
	};
	CMod s_Mod;

	ConVar cvar_enable("sig_etc_compensate_attack_time", "0", FCVAR_NOTIFY,
		"Etc: Modify the primary attack time interval to prevent incorrect rounding up of the attack interval.",
		[](IConVar *pConVar, const char *pOldValue, float flOldValue){
			s_Mod.Toggle(static_cast<ConVar *>(pConVar)->GetBool());
		});
}
#endif
