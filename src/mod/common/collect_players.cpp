#include "mod.h"
#include "stub/tfplayer.h"

#if defined _LINUX && !defined PLATFORM_64BITS
#include <list>
#include <unordered_set>

// GCC 14 emits 28 local regparm(3) copies and no callable cdecl instance.
// Give extension callers and detours one stable cdecl entry point, preserving
// the SDK's collection semantics and its return value (discarded by the clones).
extern "C" __attribute__((noinline, noclone, visibility("default")))
int SigsegvCollectTFPlayers(CUtlVector<CTFPlayer *> *players, int team, bool alive, bool append)
{
	if (!append) players->RemoveAll();
	for (int index = 1; index <= gpGlobals->maxClients; ++index) {
		auto player = ToTFPlayer(UTIL_PlayerByIndex(index));
		if (player == nullptr || FNullEnt(player->edict()) || !player->IsPlayer()) continue;
		auto info = playerinfomanager->GetPlayerInfo(player->edict());
		if (info == nullptr || !info->IsConnected()) continue;
		if (team != TEAM_ANY && player->GetTeamNumber() != team) continue;
		if (alive && !player->IsAlive()) continue;
		players->AddToTail(player);
	}
	return players->Count();
}

namespace Mod::Common::CollectPlayersCompat
{
	static int __attribute__((regparm(3))) Collect(CUtlVector<CTFPlayer *> *players, int team, bool alive, bool append)
	{
		// Use the indirect thunk so every copy enters the ordinary detour chain.
		return CollectPlayers<CTFPlayer>(players, team, alive, append);
	}

	class CMod : public IMod
	{
	public:
		CMod() : IMod("Common:CollectPlayersCompat") {}
		bool EnableByDefault() override { return true; }

		void PreLoad() override
		{
			m_Trampolines.clear();
			std::unordered_set<void *> addresses;
			LibMgr::ForEachSym(Library::SERVER, [&](const Symbol& symbol) {
				if (symbol.name != "_Z14CollectPlayersI9CTFPlayerEiP10CUtlVectorIPT_10CUtlMemoryIS3_iEEibb.isra.0" ||
					!addresses.insert(symbol.addr).second) return true;
				m_Trampolines.push_back(nullptr);
				std::string name = "CollectPlayers<CTFPlayer> copy " + std::to_string(m_Trampolines.size());
				this->AddDetour(new CDetour(name.c_str(), symbol.addr,
					reinterpret_cast<void *>(&Collect), &m_Trampolines.back()));
				return true;
			}, true);
		}

		bool OnLoad() override
		{
			if (m_Trampolines.empty()) {
				Warning("CollectPlayers compatibility: no supported ELF32 clones found.\n");
				return false;
			}
			Msg("CollectPlayers compatibility: loaded %zu ELF32 clones.\n", m_Trampolines.size());
			return true;
		}

	private:
		// Stable storage for each detour's trampoline slot until UnloadDetours.
		std::list<void *> m_Trampolines;
	};
	CMod s_Mod;
}
#endif
