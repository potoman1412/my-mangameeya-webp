#include <windows.h>
#include <iostream>

typedef int (__stdcall *PFN_LOADPICTURE)(const wchar_t*, void*);

int wmain(int argc, wchar_t** argv)
{
    if (argc < 2) {
        std::wcout << L"Usage: test_app.exe <image-file.webp>\n";
        return 1;
    }
    const wchar_t* fname = argv[1];
    HMODULE h = LoadLibraryW(L"webp.dll");
    if (!h) {
        std::wcout << L"Failed to load webp.dll (make sure it's in the exe folder)\n";
        return 2;
    }
    auto p = (PFN_LOADPICTURE)GetProcAddress(h, "LoadPicture");
    if (!p) {
        std::wcout << L"LoadPicture export not found in webp.dll\n";
        FreeLibrary(h);
        return 3;
    }
    int r = p(fname, nullptr);
    std::wcout << L"LoadPicture returned: " << r << L"\n";
    FreeLibrary(h);
    return 0;
}
