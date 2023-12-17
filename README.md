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

## Debug

If you are using Windows 10, it comes with PowerShell 5.1 and Pester 3.4, a testing framework for PowerShell scripts and modules.

- Check the version of PowerShell and Pester you are using on your system by running the following commands in a PowerShell console:

  ```ps
  # Get the PowerShell version
  $PSVersionTable.PSVersion
  # Get the Pester version
  Get-Module -Name Pester -ListAvailable
  ```

For some situations, you might need to upgrade to Pester 5 or later:

- You need to run tests on PowerShell Core or PowerShell 7, which are not fully supported by Pester 4 or earlier versions.
- You want to use the new syntax features, such as `-ForEach` and `-TestCases` parameters, that simplify writing parameterized tests.
- You want to take advantage of the improved performance, discovery, and output of Pester 5, which uses a new test runner and reporter.
- You need to use advanced features, such as code coverage, mocking, or configuration, that have been enhanced or redesigned in Pester 5.
- You want to benefit from the ongoing development and support of Pester 5, which is the main focus of the Pester team and community.

Here are some instructions on how to use Pester, a testing framework for PowerShell, to debug the scripts in this repository.

- To upgrade to Pester 5 or later, you can follow these steps:

  1. If you have an older version of Pester installed, uninstall it by running:
  
     ```ps
     Uninstall-Module -Name Pester -Force
     ```

  2. Install the latest version of Pester by running:
  
     ```ps
     Install-Module -Name Pester -Force -SkipPublisherCheck
     ```

  3. Verify that the installation was successful by running `Get-Module -ListAvailable Pester` again.

- To run all the tests in the repository, navigate to the root folder and run:

  ```ps
  Invoke-Pester
  ```

- To run a specific test file, use the `-Script` parameter:

  ```ps
  Invoke-Pester -Script .\Tests\MyTest.Tests.ps1
  ```

- To run a specific test case, use the `-TestName` parameter:

  ```ps
  Invoke-Pester -TestName 'My test case'
  ```

- To generate a test report in XML format, use the `-OutputFile` and `-OutputFormat` parameters:

  ```ps
  Invoke-Pester -OutputFile .\TestResults.xml -OutputFormat NUnitXml
  ```

- To debug a test case in Visual Studio Code, set a breakpoint in the test file and press <kbd>F5</kbd> to start debugging.

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
