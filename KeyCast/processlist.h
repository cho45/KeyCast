#ifndef __KeyCast__processlist__
#define __KeyCast__processlist__

#include <assert.h>
#include <errno.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/sysctl.h>

typedef struct kinfo_proc kinfo_proc;
int GetBSDProcessList(kinfo_proc **procList, size_t *procCount);
bool IsInBSDProcessList(const char name[]);


#endif /* defined(__KeyCast__processlist__) */
