# TheBrain PowerShell Scripts

This folder contains some PowerShell scripts that can interact with [TheBrain](https://thebrain.com/), a mind mapping software that allows you to organize and link your digital information.

## Table of Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Disclaimer](#disclaimer)
- [Contributing](#contributing)
- [Credits](#credits)
- [License](#license)

## Requirements

- PowerShell 5.1 or higher (Recommended)
- PSSQLite module (1.1.0 or later)
- TheBrain 13 for Windows

## Installation
To use the scripts in this repository, follow these steps:

1. Clone the repository to your local machine using the following command:

   ```ps
   git clone https://github.com/chriskyfung/My-PowerShell-Scripts.git
   ```

2. Navigate to the "theBrain" folder.

3. **Verify the dependencies**: To check if the required module has been installed, you can open your PowerShell terminal and run the following command:

    ```powershell
    Get-Module -ListAvailable -Name PSSQLite
    ```

    This command will list all the available versions of the PSSQLite module installed on your system. If it is installed, it will display the version number and other details of the module.

    If PSSQLite is not installed, it will not return any output. You can use the following command to install the PSSQLite 1.1.0 module:

    ```powershell
    Install-Module -Name PSSQLite -RequiredVersion 1.1.0
    ```

## Usage
Once the repository is cloned and the "theBrain" folder is accessed, you can run the PowerShell scripts by executing the following command in PowerShell:

```powershell
.\script_name.ps1
```

## Disclaimer

These scripts are provided as-is, without any warranty or support. Use them at your own risk. I am not affiliated with TheBrain Technologies or responsible for any damage or data loss that may occur from using these scripts.

## Contributing

We welcome contributions from the community. To contribute to this project, please follow these guidelines:

1.  Fork the repository.
2.  Create a new branch for your feature or bug fix.
3.  Make your changes and commit them with descriptive messages.
4.  Push your changes to your fork.
5.  Submit a pull request to the main repository.

## Credits

This project uses the following open-source packages:

- [PSSQLite](https://github.com/RamblingCookieMonster/PSSQLite): A PowerShell module to interact with SQLite databases.

This project wouldn't be possible without the hard work and dedication of the contributors to the above projects. We thank them for their contribution to the open source community.

## License

The project is licensed under the GPLv3 License. See the [License](/LICENSE) file for details.
