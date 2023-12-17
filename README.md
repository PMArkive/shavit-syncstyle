# shavit-syncstyle

### BIG WARNING READ THIS: This plugin will MOST LIKELY (90%) break your SSJ, Jhud, and Strafe Trainer so if you want those to still work, you should use my [replacements](https://github.com/Nimmy2222/bhop-get-stats) for them.

Credits: Kaldun [owner of Kotyata] (help), Rumour (help), Core (idea)

# Directions

In shavit-styles.cfg (cstrike/addons/sourcemod/configs/shavit-styles.cfg) add something along the lines of:
```
 "9"
{
	"name"				"Autosync"
	"shortname"			"AS"
	"command"			"au; as; autosync"
	"clantag"			"AS"
	"rankingmultiplier"	"0.0"
	"specialstring"		"autosync; bash_bypass; ssjtop_bypass"
}
```
Most important part here is just "autosync" being in the special strings section. You can also change what string the plugin
requires in cstrike/cfg/sourcemod/plugin.shavit-syncstyle.cfg. So if you put "arbitarystringhere", then in shavit-styles cfg
special strings, any style with "arbitarystringhere" will have the auto syncer on it.

# Dependencies
* [Shavit Timer](https://github.com/shavitush/bhoptimer)
* [Dhooks](https://forums.alliedmods.net/showpost.php?p=2588686&postcount=589) (Should already be in SourceMod unless you're on an old version)

# Notes
* This is a plugin (for css, csgo died idc) that will automatically sync for you. It works by delaying your mouse input for 1 tick and but syncing your updated mouse movement. This leads to your keypress being 1 tick earlier than your turn tick, which is true perfect sync.
* This is different from an autostrafer you'd find in a TAS plugin, as the mouse input still fully relies on the user (and will not activate in some situations.
* You don't have to press your keys, but you should. It will look smoother on your screen if you do, even if your keypresses are ass.
* You still need to handle W release (not holding W after you jump). So if you do a slide or don't use W release nulls, this can affect your speed.
* It will stop adjusting your sync if you are not moving your mouse in the air, surfing, or 8 ticks after you teleport.
