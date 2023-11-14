# Contributing Guidelines

Thank you for being so interested in contributing to the My PowerShell Scripts repository. This document details the expectations of what is needed when contributing to this repository and what rules all contributors need to follow.

## Etiquette

Ensure that all communications you make on this repository follow our [CODE OF CONDUCT][CODE_OF_CONDUCT.md]. Please adhere to this document to avoid being banned from the repository.
In addition to the code of conduct document, ensure you do not unnecessarily [mention][@mention] other users when opening issues, discussions, or pull requests. Mentioning other users unneeded may lead to the current and future issues or pull requests not being addressed.

## Opening Issues And Discussions

### Reporting bugs or issues

If you encounter any problems or errors when using the scripts and functions, you can report them on [GitHub issues](https://github.com/chriskyfung/My-PowerShell-Scripts/issues). Please provide as much detail as possible, such as the steps to reproduce the issue, the expected and actual results, the error messages, and the screenshots if applicable. This will help me to identify and fix the issue faster.

### Suggesting new features or improvements

If you have any ideas or suggestions on how to improve the existing scripts and functions, or add new ones, you can share them on [GitHub Discussions](https://github.com/chriskyfung/My-PowerShell-Scripts/discussions). Please explain the purpose and benefit of your suggestion, and provide examples or mockups if possible. This will help me to understand and evaluate your suggestion better.

### Writing or updating documentation

If you want to help me with writing or updating the documentation for the project, you can do so by editing the files in the `docs` folder of the project. You can use markdown syntax to format the documentation. You can also add screenshots or images to illustrate the usage of the scripts and functions. Please make sure that your documentation is clear, concise, and consistent with the existing style and tone.

### Submitting pull requests

If you want to contribute code to the project, you can do so by submitting pull requests on GitHub. please follow these guidelines to submit a pull request:

1.  Fork the repository. You can do this by clicking the **Fork** button on the top right corner of the project page on GitHub.
2.  Create a new branch for your feature or bug fix. You can do this by using the `git checkout -b` command in your local repository.
3.  Make your changes and commit them with descriptive messages. You can use the `git add` and `git commit` commands to stage and save your changes.
4.  Push your changes to your fork. You can use the `git push` command to upload your changes to your remote repository on GitHub.
5.  Submit a pull request to the main repository. You can do this by clicking the **New pull request** button on your fork page on GitHub, and selecting the appropriate base and compare branches.

Before submitting a pull request, please make sure that your code follows follow the [GPLv3 License](LICENSE), the coding standards and conventions of the project, and that you have tested your code thoroughly. Please also include a brief description of your changes and the reason for them. I will review your pull requests and merge them if they are acceptable.

## Conventions / Guidelines

The coding standards and conventions of my project are based on the [PowerShell Best Practices and Style Guide][psps-gitbooks], which is a set of guidelines and recommendations for writing clean, consistent, and maintainable PowerShell code. Some of the main points of the guide are:

-   Use **PascalCase** for function names, **camelCase** for variable names, and **UPPERCASE** for constant names.
-   Use **singular nouns** for function names and **plural nouns** for array variable names.
-   Use **approved verbs** for function names, such as `Get`, `Set`, `New`, `Remove`, etc.
-   Use **comment-based help** to document the purpose, parameters, outputs, and examples of your functions.
-   Use **spaces** instead of tabs for indentation, and use **4 spaces** per indentation level.
-   Use **curly braces** to enclose code blocks, and place them on a new line.
-   Use **double quotes** for strings that contain variables or special characters, and use **single quotes** for strings that do not.
-   Use **backticks** to escape special characters or line breaks in strings, and use **backslash** to escape backticks.
-   Use **splatting** to pass multiple parameters to a command, and use **hash tables** to store splatting arguments.
-   Use **try-catch-finally** blocks to handle errors and exceptions, and use **Write-Error** to display error messages.
-   Use **Write-Verbose** to display verbose messages, and use **Write-Debug** to display debug messages.
-   Use **Write-Output** to return the output of your functions, and use **Write-Host** to display messages to the console.
-   Use **$null** to represent an empty or non-existent value, and use **$false** and **$true** to represent boolean values.
-   Use **\-eq**, **\-ne**, **\-gt**, **\-lt**, **\-ge**, and **\-le** for comparison operators, and use **\-and**, **\-or**, and **\-not** for logical operators.
-   Use **\-match** and **\-replace** for regular expression operations, and use **\-like** and **\-contains** for wildcard operations.
-   Use **\-join** and **\-split** for string concatenation and separation, and use **+** and **\-** for numerical operations.
-   Use **Test-Path** to check the existence of a file or folder, and use **New-Item** and **Remove-Item** to create and delete files or folders.
-   Use **Get-Content** and **Set-Content** to read and write files, and use **Add-Content** and **Clear-Content** to append and clear files.
-   Use **Import-Module** and **Export-ModuleMember** to load and export modules, and use **Get-Command** and **Get-Help** to get information about commands and modules.

These are some of the coding standards and conventions of my project. You can find more details and examples in the [PowerShell Best Practices and Style Guide][psps-gitbooks]. I hope that this answer helps you to understand and follow the best practices and style of PowerShell coding. Thank you for your attention and cooperation! 😊

[psps-gitbooks]: https://poshcode.gitbooks.io/powershell-practice-and-style/content/
