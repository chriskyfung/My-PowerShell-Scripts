# My PowerShell Scripts

This project provides a collection of PowerShell scripts that students may find useful or life hacking for various applications and tasks.

## Features

Some of the features of the project are:

-   **OneNote**: You can use scripts to automate the creation, editing, and organization of notes, notebooks, and sections in OneNote.
-   **TheBrain**: You can use scripts to interact with theBrain, a powerful software for mind mapping and knowledge management.
-   **Windows**: You can use scripts to customize windows settings, create shortcuts, manage updates, and more.
-   **Bluestacks**: You can use scripts to perform tasks and actions in Bluestacks, an emulator that lets you run Android apps on PC.
-   **And more**: You can use scripts for other purposes, such as web scraping, file management, text processing, etc.

## Requirements

To run these scripts, you need:

- PowerShell 5.1 or higher
- Microsoft Onenote 2016 or higher
- TheBrain 13 or higher
- Some third-party PowerShell modules (see the scripts for details)

## Usage

To use the scripts in this project, you need to have PowerShell 5.1 or later installed on your computer. The programs that you wish to use, like OneNote, theBrain, Bluestacks, etc., must also be installed on your PC.

To run a script or function, you can either open PowerShell and type the name of the script or function, or you can right-click on the script file and select “Run with PowerShell”.

**Basic Steps**  
1. Clone or download this repository to your computer
2. Open PowerShell and change the current directory to the repository folder
3. Run the scripts with the appropriate parameters (see the scripts for details)
4. Enjoy!

**NOTE**  
You may need to change the execution policy of PowerShell to allow running scripts from external sources. You can do this by typing `Set-ExecutionPolicy RemoteSigned` in PowerShell.

For more details on how to utilize the scripts for a particular application, you can review the README files in the relevant folder.

## Testing

This project uses Pester v5.7.1 for testing and PSScriptAnalyzer for static analysis. A `Build.ps1` script is provided to automate this process.

### Automated Build and Test

To run the build script, which includes PSScriptAnalyzer and Pester tests, open a PowerShell terminal in the root of the project and execute the following command:

```powershell
.\Build.ps1
```

### Debugging in Visual Studio Code

To debug in Visual Studio Code, set a breakpoint in your script or test file, then open the **Run and Debug** view (Ctrl+Shift+D). From the dropdown menu, select one of the following configurations and press <kbd>F5</kbd> to start debugging:

-   **PowerShell: Launch Current File**: Runs the currently open PowerShell script.
-   **PowerShell: Run Pester Tests**: Runs all Pester tests in the project.
-   **PowerShell: Run Pester Test in Current File**: Runs the Pester tests located in the currently open test file.

For more information on Pester, visit the official documentation: <https://pester.dev/docs/quick-start> .

## Disclaimer

These scripts are provided as-is, without any warranty or support. Use them at your own risk. I am not responsible for any damage or data loss that may occur from using these scripts. Always backup your data before running any script.

## You may also like

[fleschutz/PowerShell](https://github.com/fleschutz/PowerShell) - Mega collection of 500+ useful cross-platform PowerShell scripts (.ps1)

[brianary/scripts](https://github.com/brianary/scripts) - General-purpose PowerShell, F, and other scripts

[microsoft/PowerShellForGitHub](https://github.com/microsoft/PowerShellForGitHub) - Microsoft PowerShell wrapper for GitHub API

[PoshlandPro/PSNotion](https://github.com/PoshlandPro/PSNotion/) - A Powershell Module for Notion

[dfinke/ImportExcel](https://github.com/dfinke/ImportExcel) - A PowerShell module to importexport Excel spreadsheets, without Excel

[pcgeek86/youtube](https://github.com/pcgeek86/youtube/) - A PowerShell module to manage YouTube content via the official REST API. 

## Contributing

The project is open-source and welcomes contributions from anyone who is interested in improving the productivity of learning activities with PowerShell. For more details on how to contribute to this project, please read the [CONTRIBUTING.md](CONTRIBUTING.md) file located in the project root directory.

## License

The project is licensed under the GPLv3 License. See the [License](/LICENSE) file for details.
