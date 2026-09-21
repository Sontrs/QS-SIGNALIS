# QS-Signalis
Signalis Inspired tools via QuickShell.

Still needs some polish, but the basics are up and running. Note that this is intentended for *personal* use. If you find this and want to check it out, you'll have to modify some of the files to get it to your liking- like the favorites or logout buttons. Made to be used on Hyprland.

Had help from some robo "friends" since i kinda hate QML- though it isnt entirely built with them.

Theres also Colors schemes on General/ both .conf and .colors. Not related to the tools, but i think they compliment them well enough. 
 
### Currently working:
- App Launcher
- Notifications
- Logout Menu
- Bar (Waybar like. Has: Workspaces, "caffeine" button (idle-inhibit), time/date, backlight %, free disk space, temps, ram, cpu, battery %, audio %, wifi, tray, power button)

### Planned:
- Lockscreen
- Small stuff (OSD, QuickSettings, etc)

It uses around 280 ~ 300 MB of ram sadly. Open to suggestions on how to improve memory usage if possible.

Launcher should be called via hl.dsp.exec_cmd("quickshell ipc call launcher toggle"), or an abstraction like hl.dsp.exec_cmd(defaults.applauncher)

Bar was basically replicated from reihera's "i3-signalis" rice. https://github.com/reihera/i3-signalis

## Modifying
To modify the favorites carousel thats on the top of the launcher, or what the logout buttons do, check:

- Logout: On shell.qml theres four "LogoutButton" fields where you can edit the label, keybind (though keybinds for the logout arent activated by default), the text shown inside the button, and the label on the top of it.
  
- Favorites: On Launcher/Models/FavoritesModel.qml you can find a list with the 6 favorites. You could add more probably- though i just did six to match the game. Either way, here you can edit the name shown on the top of the square, the icon that the app should show, the command that is used to launch the app, and the number shown on the bottom right of the square.

- Bar modules: Handled on each of their corresponding files under Bar/Modules/ respectively. The default values the modules that launch apps on click are the Time/Date module (calcurse), Storage module (baobab), Temperature/Memory/Cpu modules (btop), Volume module (pavucontrol), and the Network module (nm-connection-editor).

## Media

### Bar
<img width="1920" height="38" alt="bar" src="https://github.com/user-attachments/assets/d987eba1-de15-4fe9-9f18-b053c4f5b41b" />

### App Launcher


https://github.com/user-attachments/assets/b051f865-943a-4af1-abaf-61f5d60dc088

### Notifications

Check the Media folder.

### Logout


https://github.com/user-attachments/assets/8cb19577-086e-4c86-bead-ae22707ce334



