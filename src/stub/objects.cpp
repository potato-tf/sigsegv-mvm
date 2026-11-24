#include "stub/objects.h"
#include "mem/extract.h"

#if defined _LINUX

static constexpr uint8_t s_Buf_CObjectSentrygun_FireRocket[] = {
#ifdef PLATFORM_64BITS
	0x48, 0x8d, 0x05, 0x91, 0xf9, 0xaa, 0x00,        // +0x0000 lea     rax, gpGlobals
	0xf3, 0x0f, 0x10, 0x87, 0xc0, 0x0d, 0x00, 0x00,  // +0x0007 movss   xmm0, dword ptr [rdi+0DC0h]
	0x48, 0x8b, 0x00,                                // +0x000f mov     rax, [rax]
	0x0f, 0x2f, 0x40, 0x0c,                          // +0x0012 comiss  xmm0, dword ptr [rax+0Ch]
#else
	// GCC 14 ELF32: load rocket cooldown; resolve gpGlobals through GOT; compare curtime.
	0x8b, 0x75, 0x08, 0xf3, 0x0f, 0x10, 0x86, 0x00,
	0x00, 0x00, 0x00, 0x8d, 0x83, 0x00, 0x00, 0x00,
	0x00, 0x89, 0x85, 0x00, 0x00, 0x00, 0x00, 0x8b,
	0x00, 0x0f, 0x2f, 0x40, 0x0c,
#endif
};

struct CExtract_CObjectSentrygun_FireRocket : public IExtract<uint32_t>
{
	using T = uint32_t;
	
	CExtract_CObjectSentrygun_FireRocket() : IExtract<T>(sizeof(s_Buf_CObjectSentrygun_FireRocket)) {}
	
	virtual bool GetExtractInfo(ByteBuf& buf, ByteBuf& mask) const override
	{
#ifdef PLATFORM_64BITS
		buf.CopyFrom(s_Buf_CObjectSentrygun_FireRocket);

		buf.SetDword(0x00 + 3, (uint32_t)AddrManager::GetAddrOffset("gpGlobals", "CObjectSentrygun::FireRocket", 0x07));
		
		mask.SetRange(0x07 + 4, 4, 0x00);
		mask.SetRange(0x12 + 3, 1, 0x00);

		
		return true;
#else
		buf.CopyFrom(s_Buf_CObjectSentrygun_FireRocket);
		mask.SetRange(0x07, 4, 0x00);
		mask.SetRange(0x0d, 4, 0x00);
		mask.SetRange(0x13, 4, 0x00);
		return true;
#endif
	}
	
	virtual const char *GetFuncName() const override   { return "CObjectSentrygun::FireRocket"; }
	virtual uint32_t GetFuncOffMin() const override    {
		return 0x0000;
	}
	virtual uint32_t GetFuncOffMax() const override    {
#ifdef PLATFORM_64BITS
		return 0x0060;
#else
		return 0x40;
#endif
	}
	virtual uint32_t GetExtractOffset() const override {
#ifdef PLATFORM_64BITS
		return 0x007 + 4;
#else
		return 0x07;
#endif
	}

};

#elif defined _WINDOWS

using CExtract_CObjectSentrygun_FireRocket = IExtractStub;

#endif


IMPL_DATAMAP (int,                CBaseObject, m_nDefaultUpgradeLevel);

IMPL_SENDPROP(int,                CBaseObject, m_iUpgradeLevel,       CBaseObject);
IMPL_SENDPROP(int,                CBaseObject, m_iObjectType,         CBaseObject);
IMPL_SENDPROP(int,                CBaseObject, m_iObjectMode,         CBaseObject);
IMPL_SENDPROP(CHandle<CTFPlayer>, CBaseObject, m_hBuilder,            CBaseObject);
IMPL_SENDPROP(CHandle<CBaseEntity>, CBaseObject, m_hBuiltOnEntity,      CBaseObject);
IMPL_SENDPROP(bool,               CBaseObject, m_bMiniBuilding,       CBaseObject);
IMPL_SENDPROP(bool,               CBaseObject, m_bDisposableBuilding, CBaseObject);
IMPL_SENDPROP(bool,               CBaseObject, m_bBuilding, CBaseObject);
IMPL_SENDPROP(bool,               CBaseObject, m_bDisabled, CBaseObject);
IMPL_SENDPROP(bool,               CBaseObject, m_bPlacing, CBaseObject);
IMPL_SENDPROP(bool,               CBaseObject, m_bCarried, CBaseObject);
IMPL_SENDPROP(bool,               CBaseObject, m_bCarryDeploy, CBaseObject);
IMPL_SENDPROP(int,                CBaseObject, m_iKills, CObjectSentrygun);
IMPL_SENDPROP(Vector,             CBaseObject, m_vecBuildMaxs, CBaseObject);
IMPL_REL_BEFORE(Vector,           CBaseObject, m_vecBuildOrigin, m_vecBuildMaxs, 0, Vector);
IMPL_REL_AFTER(int,               CBaseObject, m_iBuiltOnPoint, m_hBuiltOnEntity);

IMPL_SENDPROP(int,  CObjectSentrygun, m_iAmmoShells,     CObjectSentrygun);
IMPL_REL_AFTER(int,  CObjectSentrygun, m_iMaxAmmoShells,  m_iAmmoShells);
IMPL_SENDPROP(int,  CObjectSentrygun, m_iAmmoRockets,    CObjectSentrygun);
IMPL_REL_AFTER(int,  CObjectSentrygun, m_iMaxAmmoRockets, m_iAmmoRockets);
IMPL_SENDPROP(unsigned int, CObjectSentrygun, m_nShieldLevel, CObjectSentrygun);
IMPL_EXTRACT(float, CObjectSentrygun, m_flNextRocketFire, new CExtract_CObjectSentrygun_FireRocket());
IMPL_SENDPROP(int, CObjectSentrygun, m_bPlayerControlled, CObjectSentrygun);
IMPL_REL_BEFORE(int, CObjectSentrygun, m_flSentryRange, m_bPlayerControlled, 0);
IMPL_SENDPROP(int, CObjectSentrygun, m_iState, CObjectSentrygun);
IMPL_REL_AFTER(float, CObjectSentrygun, m_flNextAttack, m_iState);
IMPL_REL_AFTER(float, CObjectSentrygun, m_flFireRate, m_flNextAttack);
IMPL_SENDPROP(CHandle<CBaseEntity>, CObjectSentrygun, m_hEnemy, CObjectSentrygun);
IMPL_REL_BEFORE(float, CObjectSentrygun, m_flNextRocketAttack, m_hEnemy, 0);

MemberFuncThunk<CBaseObject *, void, float> CBaseObject::ft_SetHealth        ("CBaseObject::SetHealth");
MemberFuncThunk<CBaseObject *, void, float> CBaseObject::ft_SetPlasmaDisabled("CBaseObject::SetPlasmaDisabled");
MemberFuncThunk<CBaseObject *, bool>        CBaseObject::ft_HasSapper        ("CBaseObject::HasSapper");
MemberFuncThunk<CBaseObject *, bool>        CBaseObject::ft_MustBeBuiltOnAttachmentPoint("CBaseObject::MustBeBuiltOnAttachmentPoint");

MemberFuncThunk<CBaseObject *, bool, CTFPlayer *, CBasePlayer *, float &, Vector &> CBaseObject::ft_FindBuildPointOnPlayer("CBaseObject::FindBuildPointOnPlayer");
MemberFuncThunk<CBaseObject *, void, CBaseEntity *, int, Vector &>                  CBaseObject::ft_AttachObjectToObject  ("CBaseObject::AttachObjectToObject");
MemberFuncThunk<CBaseObject *, bool, CBaseEntity *, CBasePlayer *, float &, Vector &, bool> CBaseObject::ft_FindNearestBuildPoint("CBaseObject::FindNearestBuildPoint");

MemberVFuncThunk<CBaseObject *, void, CTFPlayer *>   CBaseObject::vt_StartPlacement               (TypeName<CBaseObject>(), "CBaseObject::StartPlacement");
MemberVFuncThunk<CBaseObject *, bool, CBaseEntity *> CBaseObject::vt_StartBuilding                (TypeName<CBaseObject>(), "CBaseObject::StartBuilding");
MemberVFuncThunk<CBaseObject *, void>                CBaseObject::vt_DetonateObject               (TypeName<CBaseObject>(), "CBaseObject::DetonateObject");
MemberVFuncThunk<CBaseObject *, void>                CBaseObject::vt_InitializeMapPlacedObject    (TypeName<CBaseObject>(), "CBaseObject::InitializeMapPlacedObject");
MemberVFuncThunk<CBaseObject *, void>                CBaseObject::vt_FinishedBuilding             (TypeName<CBaseObject>(), "CBaseObject::FinishedBuilding");
MemberVFuncThunk<CBaseObject *, int>                 CBaseObject::vt_GetMiniBuildingStartingHealth(TypeName<CBaseObject>(), "CBaseObject::GetMiniBuildingStartingHealth");
MemberVFuncThunk<CBaseObject *, int>                 CBaseObject::vt_GetMaxHealthForCurrentLevel  (TypeName<CBaseObject>(), "CBaseObject::GetMaxHealthForCurrentLevel");
MemberVFuncThunk<CBaseObject *, bool>                CBaseObject::vt_IsHostileUpgrade             (TypeName<CBaseObject>(), "CBaseObject::IsHostileUpgrade");


IMPL_DATAMAP(int, CObjectTeleporter, m_iTeleportType);
IMPL_SENDPROP(float, CObjectTeleporter, m_flRechargeTime, CObjectTeleporter);
IMPL_SENDPROP(float, CObjectTeleporter, m_flCurrentRechargeDuration, CObjectTeleporter);
IMPL_SENDPROP(int, CObjectTeleporter, m_iState, CObjectTeleporter);


GlobalThunk<CUtlVector<IBaseObjectAutoList *>> IBaseObjectAutoList::m_IBaseObjectAutoListAutoList("IBaseObjectAutoList::m_IBaseObjectAutoListAutoList");


MemberVFuncThunk<CObjectDispenser *, float> CObjectDispenser::vt_GetDispenserRadius(TypeName<CObjectDispenser>(), "CObjectDispenser::GetDispenserRadius");

MemberVFuncThunk<CObjectSentrygun *, QAngle &> CObjectSentrygun::vt_GetTurretAngles(TypeName<CObjectSentrygun>(), "CObjectSentrygun::GetTurretAngles");
MemberFuncThunk<CObjectSentrygun *, void> CObjectSentrygun::ft_SentryThink("CObjectSentrygun::SentryThink");
