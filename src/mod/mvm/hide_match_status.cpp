#include "mod.h"
#include "stub/baseplayer.h"
#include "stub/tfplayer.h"

namespace Mod::MvM::Hide_Match_Status
{
	// Fixes this bug for MvM https://github.com/ValveSoftware/source-sdk-2013/pull/767.

	DETOUR_DECL_MEMBER(void, CTFPlayer_SetHudHideFlags, int flags)
	{
		flags |= HIDEHUD_MATCH_STATUS;
		DETOUR_MEMBER_CALL(flags);
	}

	DETOUR_DECL_MEMBER(void, CTFPlayer_RemoveHudHideFlags, int flags)
	{
		flags &= ~HIDEHUD_MATCH_STATUS;
		DETOUR_MEMBER_CALL(flags);
	}

	DETOUR_DECL_MEMBER(void, CTFPlayer_StateEnterACTIVE, int mode)
	{
		DETOUR_MEMBER_CALL(mode);
		auto player = reinterpret_cast<CTFPlayer *>(this);
		player->m_Local->m_iHideHUD |= HIDEHUD_MATCH_STATUS;
		return;
	}

	DETOUR_DECL_MEMBER(bool, CBasePlayer_StartObserverMode, int mode)
	{
		bool ret = DETOUR_MEMBER_CALL(mode);
		auto player = reinterpret_cast<CBasePlayer *>(this);
		player->m_Local->m_iHideHUD |= HIDEHUD_MATCH_STATUS;
		return ret;
	}

	class CMod : public IMod
	{
	public:
		CMod() : IMod("MvM:Hide_Match_Status")
		{
			MOD_ADD_DETOUR_MEMBER(CTFPlayer_SetHudHideFlags, "CTFPlayer::SetHudHideFlags");
			MOD_ADD_DETOUR_MEMBER(CTFPlayer_RemoveHudHideFlags, "CTFPlayer::RemoveHudHideFlags");
			MOD_ADD_DETOUR_MEMBER(CTFPlayer_StateEnterACTIVE, "CTFPlayer::StateEnterACTIVE");
			MOD_ADD_DETOUR_MEMBER(CBasePlayer_StartObserverMode, "CBasePlayer::StartObserverMode");
		}
	};
	CMod s_Mod;

	ConVar cvar_enable("sig_mvm_hide_match_status", "0", FCVAR_NOTIFY,
		"Mod: Fix the competitive match status HUD incorrectly drawing in MvM.",
		[](IConVar *pConVar, const char *pOldValue, float flOldValue){
			s_Mod.Toggle(static_cast<ConVar *>(pConVar)->GetBool());
		});
}
