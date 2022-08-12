# RDM
Remote Desktop Manger scripting tests

## Scripts

### RDMMigrate.ps1
The script is meant to separate the main folder structure found within the given vault into individual vaults.
It will do so using the following steps:
1. Revocer the name of each of the "Home" folders. (First folder within your folder hierarchy.)
2. Verify if a corresponding vault exist.
    - If none are found, it will create the vault.
3. Document the subfolder hierarchy within the given vault.
4. Replicate it within the corresponding vaults?
5. Document the sessions within the given vault.
6. Copy them over to their corresponding vault.

The script will __COPY__ all the sessions, __NOT MOVE__ the cession. I might add that feature in the future.

#### Parameters:
##### MainVault:
Name of the vault which's content needs to be replicated into various vaults.
> The script will verify if the given name is valid.

##### Log:
Switch that enables all outputs from the script to be logged into a txt file with timestamps.

##### Path:
Allows you to give a custom path / location to the log file. If none are given and the [Log](#log) switch is given, it will generate one automatically at the scipt root.

##### Silent:
Will mute any output to the console. If used with the [Log](#log) it will still write the output in the log file.

## Acknowledgments:
Huge thanks to the [Devolutions Forums](https://forum.devolutions.net/product/rdm-windows) and all the people helping and managing it, for all the debugging and insight they offered.