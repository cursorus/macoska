#import <Preferences/PSListController.h>
#import <spawn.h>

@interface MCKRootListController : PSListController
@end

@implementation MCKRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)respring {
    const char *paths[] = {"/var/jb/usr/bin/sbreload", "/usr/bin/sbreload"};
    char *const args[] = {"sbreload", NULL};
    for (int i = 0; i < 2; i++) {
        pid_t pid;
        if (posix_spawn(&pid, paths[i], NULL, NULL, args, NULL) == 0) break;
    }
}

@end
