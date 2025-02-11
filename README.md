• Global Maximum FPS:
The getMaxFPS() function caches the maximum frames per second available, using the system’s UIScreen maximumFramesPerSecond property. This value is subsequently used when resetting frame rate ranges.

• CADisplayLink Hooks:
The hooks on CADisplayLink ensure that any attempts to set a custom interval or preferred frames per second are overridden, forcing the display link to run at maximum speed (using 0 for preferredFramesPerSecond).

• Metal Layer and Presentation Hooks:
Hooks on CAMetalLayer, CAMetalDrawable, and MTLCommandBuffer force a moderate drawable count and minimize presentation delays by setting the minimum duration to 1.0 / maximum FPS.

• Initialization:
The %ctor block now checks whether the process is an app (using IS_APP) and whether the app should be affected by the tweak (using shouldEnableForBundleIdentifier) before initializing the hooks. This helps avoid potential issues in non-app processes.

• Selective Toggling:
The function shouldEnableForBundleIdentifier(…) reads preferences from a persistent domain (in this case “com.ps.coreanimationhighfps”) and returns NO (thus disabling the tweak) if the current app’s bundle identifier is present in the “CAHighFPS” array. This makes it easy to disable the tweak for apps that may break when the frame rate is pushed higher than 60 fps.
