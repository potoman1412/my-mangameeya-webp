// webp_dll.cpp
// Wrapper DLL: เมื่อรับคำร้องให้โหลดรูป จะตรวจนามสกุล .webp -> แปลงเป็น .png ชั่วคราว
// แล้วเรียกไปยัง `png.dll` ต้นฉบับเพื่อประมวลผลต่อ

#include <windows.h>
#include <stdint.h>
#include <stdlib.h>
#include <string>
#include <vector>
#include <fstream>
#include <shlwapi.h>

// libwebp headers
#include "webp/decode.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

static HMODULE g_hOrig = NULL;
static std::wstring g_origName = L"png.dll"; // original library name (can be png_orig.dll if you rename)

static void LoadOriginal()
{
    if (g_hOrig) return;
    // Try png_orig.dll first (safer if user renamed original png.dll)
    std::wstring basePath;
    wchar_t buf[MAX_PATH];
    if (GetModuleFileNameW(NULL, buf, MAX_PATH)) {
        std::wstring exePath(buf);
        size_t pos = exePath.find_last_of(L"\\/");
        basePath = (pos==std::wstring::npos) ? L"" : exePath.substr(0,pos+1);
    }
    std::wstring try1 = basePath + L"png_orig.dll";
    g_hOrig = LoadLibraryW(try1.c_str());
    if (!g_hOrig) {
        std::wstring try2 = basePath + L"png.dll";
        g_hOrig = LoadLibraryW(try2.c_str());
    }
}

static std::string WToUtf8(const std::wstring &w)
{
    if (w.empty()) return std::string();
    int n = WideCharToMultiByte(CP_UTF8,0,w.c_str(),-1,NULL,0,NULL,NULL);
    std::string s(n,0);
    WideCharToMultiByte(CP_UTF8,0,w.c_str(),-1,&s[0],n,NULL,NULL);
    if (!s.empty() && s.back()==0) s.pop_back();
    return s;
}

static std::wstring Utf8ToW(const std::string &s)
{
    if (s.empty()) return std::wstring();
    int n = MultiByteToWideChar(CP_UTF8,0,s.c_str(),-1,NULL,0);
    std::wstring w(n,0);
    MultiByteToWideChar(CP_UTF8,0,s.c_str(),-1,&w[0],n);
    if (!w.empty() && w.back()==0) w.pop_back();
    return w;
}

// Convert .webp file (wpath) to PNG written at outPath (UTF-8 paths used by stb)
static int ConvertWebPToPNGPath(const std::wstring &wpath, const std::wstring &woutPath)
{
    std::string inPath = WToUtf8(wpath);
    std::string outPath = WToUtf8(woutPath);
    std::ifstream in(inPath, std::ios::binary | std::ios::ate);
    if (!in) return -2;
    std::streamsize size = in.tellg();
    in.seekg(0, std::ios::beg);
    std::vector<uint8_t> data((size_t)size);
    if (!in.read((char*)data.data(), size)) return -3;
    int width=0, height=0;
    uint8_t* rgba = WebPDecodeRGBA(data.data(), data.size(), &width, &height);
    if (!rgba) return -4;
    int res = stbi_write_png(outPath.c_str(), width, height, 4, rgba, width*4);
    WebPFree(rgba);
    return (res?0:-5);
}

// Helpers to call original functions (best-effort). We assume common signature returning int and taking (const wchar_t*, void*)
typedef int (__stdcall *PFN_GEN_W)(const wchar_t*, void*);

static FARPROC GetOrigProc(const char* name)
{
    LoadOriginal();
    if (!g_hOrig) return NULL;
    return GetProcAddress(g_hOrig, name);
}

extern "C" __declspec(dllexport)
int __stdcall LoadPicture(const wchar_t* filename, void* info)
{
    if (!filename) return -1;
    std::wstring wfname(filename);
    // check extension
    std::wstring ext = PathFindExtensionW((LPWSTR)wfname.c_str());
    for (auto &c : ext) c = towlower(c);
    bool is_webp = (ext == L".webp");

    // If webp -> convert to temporary png
    std::wstring tempPng;
    if (is_webp) {
        wchar_t tmpPath[MAX_PATH];
        if (GetTempPathW(MAX_PATH, tmpPath)==0) return -2;
        // create temp name
        wchar_t tmpFile[MAX_PATH];
        if (GetTempFileNameW(tmpPath, L"wp", 0, tmpFile)==0) return -3;
        // change extension to .png
        PathRenameExtensionW(tmpFile, L".png");
        tempPng = tmpFile;
        int ret = ConvertWebPToPNGPath(wfname, tempPng);
        if (ret != 0) {
            // conversion failed
            return -4;
        }
    }

    // call original LoadPicture (fallback to png.dll)
    FARPROC p = GetOrigProc("LoadPicture");
    if (!p) {
        return -5;
    }
    PFN_GEN_W fn = (PFN_GEN_W)p;
    int result = fn(is_webp ? tempPng.c_str() : filename, info);

    if (is_webp) {
        // optionally delete temp file
        //DeleteFileW(tempPng.c_str());
    }
    return result;
}

extern "C" __declspec(dllexport)
int __stdcall LoadPictureInfo(const wchar_t* filename, void* info)
{
    FARPROC p = GetOrigProc("LoadPictureInfo");
    if (!p) return -1;
    PFN_GEN_W fn = (PFN_GEN_W)p;
    return fn(filename, info);
}

extern "C" __declspec(dllexport)
int __stdcall CheckPicture(const wchar_t* filename)
{
    FARPROC p = GetOrigProc("CheckPicture");
    if (!p) return -1;
    typedef int (__stdcall *PFN_CHK)(const wchar_t*);
    PFN_CHK fn = (PFN_CHK)p;
    // If .webp then return success (handled by this dll)
    std::wstring wfname(filename);
    std::wstring ext = PathFindExtensionW((LPWSTR)wfname.c_str());
    for (auto &c : ext) c = towlower(c);
    if (ext == L".webp") return 1; // indicate supported
    return fn(filename);
}

extern "C" __declspec(dllexport)
int __stdcall GetDllVersion()
{
    FARPROC p = GetOrigProc("GetDllVersion");
    if (!p) return 0;
    typedef int (__stdcall *PFN_VER)();
    PFN_VER fn = (PFN_VER)p;
    return fn();
}

extern "C" __declspec(dllexport)
int __stdcall SavePicture(const wchar_t* filename, void* info)
{
    FARPROC p = GetOrigProc("SavePicture");
    if (!p) return -1;
    PFN_GEN_W fn = (PFN_GEN_W)p;
    return fn(filename, info);
}

// Minimal DllMain
BOOL APIENTRY DllMain(HMODULE hModule,
                      DWORD  ul_reason_for_call,
                      LPVOID lpReserved
                     )
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
        break;
    case DLL_PROCESS_DETACH:
        if (g_hOrig) FreeLibrary(g_hOrig);
        g_hOrig = NULL;
        break;
    }
    return TRUE;
}
