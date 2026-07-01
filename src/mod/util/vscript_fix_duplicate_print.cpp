#include "mod.h"
#include "vscript/ivscript.h"
#include "util/scope.h"

namespace Mod::Util::VScript_Fix_Duplicate_Print
{
	// CSquirrelVM::PrintFunc calls both V_vsnprintf and Log, so
	//  we early return Log to avoid duplicate server prints.

	RefCount rc_PrintFunc;
	DETOUR_DECL_MEMBER(void, CSquirrelVM_PrintFunc, IScriptVM *pVM, const char *s, va_list args)
	{
		SCOPED_INCREMENT(rc_PrintFunc);
		DETOUR_MEMBER_CALL(pVM, s, args);
	}

	DETOUR_DECL_STATIC(void, Log, const char *pMsgFormat, va_list args)
	{
		if (rc_PrintFunc > 0)
			return;
		DETOUR_STATIC_CALL(pMsgFormat, args);
	}

	class CMod : public IMod
	{
	public:
		CMod() : IMod("Util:VScript_Fix_Duplicate_Print")
		{
			MOD_ADD_DETOUR_STATIC(Log, "Log");
			MOD_ADD_DETOUR_MEMBER(CSquirrelVM_PrintFunc, "CSquirrelVM::PrintFunc");
		}
	};
	CMod s_Mod;

	ConVar cvar_enable("sig_util_vscript_fix_duplicate_print", "0", FCVAR_NOTIFY,
		"Utility: Fix VScript prints occurring twice on dedicated servers.",
		[](IConVar *pConVar, const char *pOldValue, float flOldValue){
			s_Mod.Toggle(static_cast<ConVar *>(pConVar)->GetBool());
		});
}
