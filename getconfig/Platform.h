/*
Headers collection for procedures
*/

#ifndef __REFIT_PLATFORM_H__
#define __REFIT_PLATFORM_H__

typedef void  VOID;

///
/// 8-byte unsigned value.
///
typedef unsigned long long  UINT64;
///
/// 8-byte signed value.
///
typedef long long           INT64;
///
/// 4-byte unsigned value.
///
typedef unsigned int        UINT32;
///
/// 4-byte signed value.
///
typedef int                 INT32;
///
/// 2-byte unsigned value.
///
typedef unsigned short      UINT16;
///
/// 2-byte Character.  Unless otherwise specified all strings are stored in the
/// UTF-16 encoding format as defined by Unicode 2.1 and ISO/IEC 10646 standards.
///
typedef unsigned short      CHAR16;
///
/// 2-byte signed value.
///
typedef short               INT16;
///
/// Logical Boolean.  1-byte value containing 0 for FALSE or a 1 for TRUE.  Other
/// values are undefined.
///
typedef unsigned char       BOOLEAN;
///
/// 1-byte unsigned value.
///
typedef unsigned char       UINT8;
///
/// 1-byte Character
///
typedef char                CHAR8;
///
/// 1-byte signed value
///
typedef signed char         INT8;

//depending on arch of EFI but for now I will propose to use only EFI64
typedef long long                 INTN;
typedef unsigned long long        UINTN;

#define VERIFY_SIZE_OF(TYPE, Size) extern UINT8 _VerifySizeof##TYPE[(sizeof(TYPE) == (Size)) / (sizeof(TYPE) == (Size))]

//
// Verify that ProcessorBind.h produced UEFI Data Types that are compliant with
// Section 2.3.1 of the UEFI 2.3 Specification.
//
VERIFY_SIZE_OF (BOOLEAN, 1);
VERIFY_SIZE_OF (INT8, 1);
VERIFY_SIZE_OF (UINT8, 1);
VERIFY_SIZE_OF (INT16, 2);
VERIFY_SIZE_OF (UINT16, 2);
VERIFY_SIZE_OF (INT32, 4);
VERIFY_SIZE_OF (UINT32, 4);
VERIFY_SIZE_OF (INT64, 8);
VERIFY_SIZE_OF (UINT64, 8);
VERIFY_SIZE_OF (CHAR8, 1);
VERIFY_SIZE_OF (CHAR16, 2);

#pragma pack(push)
#pragma pack(1)

typedef struct {
    UINT32  Data1;
    UINT16  Data2;
    UINT16  Data3;
    UINT8   Data4[8];
} EFI_GUID;

/**
 Set of Search & replace bytes for VideoBiosPatchBytes().
 **/
typedef struct _VBIOS_PATCH_BYTES {
    VOID    *Find;
    VOID    *Replace;
    UINTN   NumberOfBytes;
} VBIOS_PATCH_BYTES;

typedef struct {
    CHAR8   *Name;
    BOOLEAN  IsPlistPatch;
    UINTN    DataLen;
    UINT8   *Data;
    UINT8   *Patch;
} KEXT_PATCH;

typedef struct {
  
	// SMBIOS TYPE0
	CHAR8	VendorName[64];
	CHAR8	RomVersion[64];
	CHAR8	ReleaseDate[64];
	// SMBIOS TYPE1
	CHAR8	ManufactureName[64];
	CHAR8	ProductName[64];
	CHAR8	VersionNr[64];
	CHAR8	SerialNr[64];
  EFI_GUID SmUUID;
//	CHAR8	Uuid[64];
//	CHAR8	SKUNumber[64];
	CHAR8	FamilyName[64];
  CHAR8 OEMProduct[64];
  CHAR8 OEMVendor[64];
	// SMBIOS TYPE2
	CHAR8	BoardManufactureName[64];
	CHAR8	BoardSerialNumber[64];
	CHAR8	BoardNumber[64]; //Board-ID
	CHAR8	LocationInChassis[64];
  CHAR8 BoardVersion[64];
  CHAR8 OEMBoard[64];
  UINT8 BoardType;
  UINT8 Pad1;
	// SMBIOS TYPE3
  BOOLEAN Mobile;
  UINT8 ChassisType;
	CHAR8	ChassisManufacturer[64];
	CHAR8	ChassisAssetTag[64]; 
	// SMBIOS TYPE4
	UINT32	CpuFreqMHz;
	UINT32	BusSpeed; //in kHz
  BOOLEAN Turbo;
  UINT8   EnabledCores;
  UINT8   Pad2[2];
	// SMBIOS TYPE17
	CHAR8	MemoryManufacturer[64];
	CHAR8	MemorySerialNumber[64];
	CHAR8	MemoryPartNumber[64];
	CHAR8	MemorySpeed[64];
	// SMBIOS TYPE131
	UINT16	CpuType;
  // SMBIOS TYPE132
  UINT16	QPI;
  BOOLEAN TrustSMBIOS;
  BOOLEAN InjectMemoryTables;
  INT8    XMPDetection;
  INT8    reserved;
  
	// OS parameters
	CHAR8 	Language[16];
	CHAR8   BootArgs[256];
	CHAR16	CustomUuid[40];
  CHAR16  DefaultBoot[40];
  UINT16  BacklightLevel;
  BOOLEAN MemoryFix;
	
	// GUI parameters
	BOOLEAN	Debug;
  
	//ACPI
	UINT64	ResetAddr;
	UINT8 	ResetVal;
	BOOLEAN	UseDSDTmini;  
	BOOLEAN	DropSSDT;
	BOOLEAN	GeneratePStates;
  BOOLEAN	GenerateCStates;
  UINT8   PLimitDict;
  UINT8   UnderVoltStep;
  BOOLEAN DoubleFirstState;
  BOOLEAN LpcTune;
  BOOLEAN EnableC2;
  BOOLEAN EnableC4;
  BOOLEAN EnableC6;
  BOOLEAN EnableISS;
  UINT16  C3Latency;
	BOOLEAN	smartUPS;
  BOOLEAN PatchNMI;
	CHAR16	DsdtName[60];
  UINT32  FixDsdt;
  BOOLEAN bDropAPIC;
  BOOLEAN bDropMCFG;
  BOOLEAN bDropHPET;
  BOOLEAN bDropECDT;
  BOOLEAN bDropDMAR;
  BOOLEAN bDropBGRT;
//  BOOLEAN RememberBIOS;
  UINT8   MinMultiplier;
  UINT8   MaxMultiplier;
  UINT8   PluginType;
  
  
  //Injections
  BOOLEAN StringInjector;
  BOOLEAN InjectSystemID;
  BOOLEAN NoCaches;
  BOOLEAN WithKexts;
  
  //Graphics
  UINT16  PCIRootUID;
  BOOLEAN GraphicsInjector;
  BOOLEAN LoadVBios;
  BOOLEAN PatchVBios;
  VBIOS_PATCH_BYTES   *PatchVBiosBytes;
  UINTN   PatchVBiosBytesCount;
#if defined(MDE_CPU_IA32)
  UINT32  align1;
#endif
  BOOLEAN InjectEDID;
  UINT8   *CustomEDID;
  CHAR16  FBName[16];
  UINT16  VideoPorts;
  UINT64  VRAM;
  UINT8   Dcfg[8];
  UINT8   NVCAP[20];
  UINT32  DualLink;
  UINT32  IgPlatform;
 	
  // HDA
  BOOLEAN HDAInjection;
  UINTN   HDALayoutId;
#if defined(MDE_CPU_IA32)
  UINT32  align2;
#endif
  
  // USB DeviceTree injection
  BOOLEAN USBInjection;
  // USB ownership fix
  BOOLEAN USBFixOwnership;
  BOOLEAN InjectClockID;
  
  // LegacyBoot
  CHAR16  LegacyBoot[32];
  
  // KernelAndKextPatches
  BOOLEAN KPDebug;
  BOOLEAN KPKernelCpu;
  BOOLEAN KPLapicPanic;
  BOOLEAN KPKextPatchesNeeded;
  BOOLEAN KPAsusAICPUPM;
  BOOLEAN KPAppleRTC;
  BOOLEAN KextPatchesAllowed;
  CHAR16  *KPATIConnectorsController;
  UINT8   *KPATIConnectorsData;
  UINTN   KPATIConnectorsDataLen;
#if defined(MDE_CPU_IA32)
  UINT32  align3;
#endif
  UINT8   *KPATIConnectorsPatch;
  INT32   NrKexts;
  KEXT_PATCH *KextPatches;
  //Volumes hiding
  BOOLEAN HVHideAllOSX;
  BOOLEAN HVHideAllOSXInstall;
  BOOLEAN HVHideAllRecovery;
  BOOLEAN HVHideDuplicatedBootTarget;
  BOOLEAN HVHideAllWindowsEFI;
  BOOLEAN HVHideAllGrub;
  BOOLEAN HVHideAllGentoo;
  BOOLEAN HVHideAllRedHat;
  BOOLEAN HVHideAllUbuntu;
  BOOLEAN HVHideAllLinuxMint;
  BOOLEAN HVHideAllFedora;
  BOOLEAN HVHideAllSuSe;
  BOOLEAN HVHideAllArch;
  //BOOLEAN HVHideAllUEFI;
  BOOLEAN HVHideOpticalUEFI;
  BOOLEAN HVHideInternalUEFI;
  BOOLEAN HVHideExternalUEFI;
  CHAR16 **HVHideStrings;
  INTN    HVCount;
#if defined(MDE_CPU_IA32)
  UINT32  align4;
#endif
  
  //Pointer
  BOOLEAN PointerEnabled;
  INTN    PointerSpeed;
#if defined(MDE_CPU_IA32)
  UINT32  align5;
#endif
  UINT64  DoubleClickTime;
  BOOLEAN PointerMirror;
  
  // RtVariables
  CHAR8   *RtMLB;
  UINT8   *RtROM;
  UINTN   RtROMLen;
#if defined(MDE_CPU_IA32)
  UINT32  align6;
#endif
  CHAR8   *MountEFI;
  UINT32  LogLineCount;
  CHAR8   *LogEveryBoot;
  
  // Multi-config
  CHAR16  ConfigName[64];
  //Drivers
  INTN     BlackListCount;
#if defined(MDE_CPU_IA32)
  UINT32  align7;
#endif
  CHAR16 **BlackList;

  //SMC keys
  CHAR8  RPlt[8];
  CHAR8  RBr[8];
  UINT8  EPCI[4];
  UINT8  REV[6];  
  
} SETTINGS_DATA;

#endif
