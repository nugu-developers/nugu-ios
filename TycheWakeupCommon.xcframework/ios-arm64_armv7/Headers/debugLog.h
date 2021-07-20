#ifndef __DEBUGLOG_H__
#define __DEBUGLOG_H__

void setNativeDebugOutput(int UseDebugOutput);

#ifdef _DEBUG
 #if defined(_WIN32) && (_MSC_VER == 1200)
void LOGI(const char* tag, const char* fmt, __VA_ARGS__);
 #else
void LOGI(const char* tag, const char* fmt, ...);
 #endif
#else
#define LOGI(...)
#endif

#if defined(_WIN32) && (_MSC_VER == 1200)
void LOGW(const char* tag, const char* fmt, __VA_ARGS__);
void LOGE(const char* tag, const char* fmt, __VA_ARGS__);
#else
void LOGW(const char* tag, const char* fmt, ...);
void LOGE(const char* tag, const char* fmt, ...);
#endif

#endif