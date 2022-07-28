//  AppDelegate.m
//  MetaU Capstone Project
//
//  Created by Rodjina Pierre Louis on 7/5/22.
//

#import "AppDelegate.h"
#import "Parse/Parse.h"
#import "MusicSessionHandler.h"
#import "SpotifyiOS/SpotifyiOS.h"
#import "SpotifyiOS/SpotifyAppRemote.h"

@import Parse;
@import ParseLiveQuery;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    ParseClientConfiguration *config = [ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {

            configuration.applicationId = @"h0XnNsrye2OKPXScQlU43EYqgbjzpKHmSfstQXH3";
            configuration.clientKey = @"c2ervpUl9gZIkgVbx0ABEbrUkL4POF2hYA2CWH2k";
            configuration.server = @"https://parseapi.back4app.com";
            NSLog(@"Connecting to: %@", configuration.server);
    }];

    [Parse initializeWithConfiguration:config];

    [self authSpotify];
    
    return YES;
}

- (void)authSpotify {
    NSString *spotifyClientID = @"d45f5e4964984bc49dfb5b2280b8d28c";
    NSURL *spotifyRedirectURL = [NSURL URLWithString:@"metau-summer-2022-capstone-project://callback"];

    self.configuration  = [[SPTConfiguration alloc] initWithClientID:spotifyClientID redirectURL:spotifyRedirectURL];

    // Setup Token Swap
    // Heroku Option
    NSURL *tokenSwapURL = [NSURL URLWithString:@"https://git.heroku.com/metau-capstone.git/api/token"];
    NSURL *tokenRefreshURL = [NSURL URLWithString:@"https://git.heroku.com/metau-capstone.git/api/refresh_token"];
    
    // Local Server Option
//    NSURL *tokenSwapURL = [NSURL URLWithString:@"http://localhost:9292/api/token"];
//    NSURL *tokenRefreshURL = [NSURL URLWithString:@"http://localhost:9292/api/refresh_token"];

    // Glitch Option
//    NSURL *tokenSwapURL = [NSURL URLWithString:@"https://spotify-token-swap.glitch.me/api/token"];
//    NSURL *tokenRefreshURL = [NSURL URLWithString:@"https://spotify-token-swap.glitch.me/api/refresh_token"];

    self.configuration.tokenSwapURL = tokenSwapURL;
    self.configuration.tokenRefreshURL = tokenRefreshURL;

    // Empty Value [@""] -> Resume Playback User Last Track
    // @"spotify:track:20I6sIOMTCkB6w7ryavxtO" -> Resume Example Track
    self.configuration.playURI = @"";

    self.sessionManager = [[SPTSessionManager alloc] initWithConfiguration:self.configuration delegate:self];
    self.sessionManager.delegate = self;

    // Invoke Auth Modal
    SPTScope requestedScope = SPTAppRemoteControlScope;
    [self.sessionManager initiateSessionWithScope:requestedScope options:SPTDefaultAuthorizationOption];

    // Initialize App Remote
    self.appRemote = [[SPTAppRemote alloc] initWithConfiguration:self.configuration logLevel:SPTAppRemoteLogLevelDebug];
    self.appRemote.delegate = self;
    [self.appRemote connect];
}

#pragma mark - UISceneSession lifecycle

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    [self.sessionManager application:app openURL:url options:options];
    return true;
}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    NSLog(@"Scence Discarded");
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"Application Resigned");
    
    if (self.appRemote.isConnected) {
      [self.appRemote disconnect];
        NSLog(@"Disconnecting app remote...");
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"Application Entered Background");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"Application Entered Foreground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"Application Actived");
    
    if (self.appRemote.connectionParameters.accessToken) {
      [self.appRemote connect];
      NSLog(@"Connecting app remote...");
    } else {
        NSLog(@"Failed to connect app remote....");
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"Application Terminated");
}

#pragma mark - SPTSessionManagerDelegate

- (void)sessionManager:(SPTSessionManager *)manager didInitiateSession:(SPTSession *)session
{
    NSLog(@"success: %@", session);
    self.appRemote.connectionParameters.accessToken = session.accessToken;
    [self.appRemote connect];
}

- (void)sessionManager:(SPTSessionManager *)manager didFailWithError:(NSError *)error
{
  NSLog(@"fail: %@", error);
}

- (void)sessionManager:(SPTSessionManager *)manager didRenewSession:(SPTSession *)session
{
  NSLog(@"renewed: %@", session);
}

#pragma mark - SPTAppRemoteDelegate

- (void)appRemoteDidEstablishConnection:(SPTAppRemote *)appRemote
{
  NSLog(@"connected");
    // Sucessful Connection, Can begin issuing commands
    self.appRemote.playerAPI.delegate = (id<SPTAppRemotePlayerStateDelegate>)self;
    [self.appRemote.playerAPI subscribeToPlayerState:^(id _Nullable result, NSError * _Nullable error) {
        if (error) {
          NSLog(@"error: %@", error.localizedDescription);
        } else {
            NSLog(@"Success!");
        }
    }];
}

- (void)appRemote:(SPTAppRemote *)appRemote didDisconnectWithError:(NSError *)error
{
  NSLog(@"disconnected");
}

- (void)appRemote:(SPTAppRemote *)appRemote didFailConnectionAttemptWithError:(NSError *)error
{
  NSLog(@"failed");
}

- (void)playerStateDidChange:(id<SPTAppRemotePlayerState>)playerState
{
    NSLog(@"player state changed");
    NSLog(@"Track name: %@", playerState.track.name);
}

@end
