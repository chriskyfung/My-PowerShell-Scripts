# AI Instructions for Developing and Debugging Pester Tests

This document outlines key considerations and common pitfalls when developing and debugging Pester tests for PowerShell scripts, particularly focusing on scenarios involving cmdlet mocking and CSV data handling. This guidance is derived from recent debugging experiences and aims to help maintain efficient and accurate test development.

## 1. Cmdlet Mocking Strategies

When testing PowerShell scripts that interact with the file system or other cmdlets, accurate mocking is crucial for isolation and predictable test results.

### a. Mocking `Get-ChildItem`
- **Purpose:** Simulate file system interactions without touching actual files (except for test setup/teardown in `BeforeAll`/`AfterAll`).
- **Considerations:**
    - The script under test might call `Get-ChildItem` for directories (e.g., `Get-ChildItem -Directory`) and then for files within those directories (e.g., `Get-ChildItem -Path $dir -Filter '*.md' -Recurse`). Ensure your mock handles both scenarios appropriately.
    - The mock should return objects that accurately mimic `System.IO.DirectoryInfo` and `System.IO.FileInfo` objects, especially their `FullName` property, as these are often piped to other cmdlets or used in subsequent logic.

### b. Mocking `Select-String`
- **Purpose:** Control the output of regular expression matching, especially when parsing file contents.
- **`MatchInfo` Object Structure:** A real `Select-String` cmdlet returns `MatchInfo` objects with a specific structure. Your mock **must** replicate this structure precisely for the script under test to process it correctly.
    - **`MatchInfo` Object:** The primary object returned by `Select-String`.
        - **`Path` (string):** The path to the file where the match occurred.
        - **`LineNumber` (int):** The line number where the match occurred.
        - **`Matches` (collection of `Match` objects):** A collection of `System.Text.RegularExpressions.Match` objects. This is crucial for handling multiple matches per line or complex regex.
    - **`Match` Object (within `Matches` collection):** Represents a single regex match.
        - **`Groups` (collection of `Group` objects):** A `System.Text.RegularExpressions.GroupCollection`. This is a 0-indexed collection:
            - **`Groups[0]`:** Represents the entire matched string (the full match).
            - **`Groups[1]`, `Groups[2]`, etc.:** Represent the captured groups defined in your regex (e.g., `(group1)`, `(group2)`).
    - **`Group` Object (within `Groups` collection):** Represents a captured group.
        - **`Value` (string):** The actual string content captured by the group.
- **Example Mock Structure for `Select-String`:**
    ```powershell
    Mock Select-String {
        [PSCustomObject]@{
            Path       = "C:\path	o\Notes.md"
            LineNumber = 1
            Matches    = @(
                [PSCustomObject]@{ # This represents a single Match object
                    Groups = @(
                        [PSCustomObject]@{ Value = "Full Match Content" }, # Group 0: Entire matched string
                        [PSCustomObject]@{ Value = "Captured Group 1" },   # Group 1
                        [PSCustomObject]@{ Value = "Captured Group 2" }    # Group 2
                    )
                }
            )
        }
    } -ParameterFilter { $_.FullName -eq "C:\path	o\Notes.md" }
    ```
- **`ParameterFilter`:** When mocking cmdlets that receive piped input (e.g., `Select-String` receives `FileInfo` objects from `Get-ChildItem`), use `$_ .FullName` in `-ParameterFilter` to match against the full path of the piped object, as `$_ .Path` may not resolve correctly or be present for `FileInfo` objects in certain contexts.

## 2. Debugging Pester Test Failures

Debugging Pester tests, especially with complex mocks, requires systematic inspection.

### a. Utilize `Write-Host` for Inspection
- Temporarily add `Write-Host` statements within your `It` blocks to print the values of variables, mocked outputs, and actual results.
- This helps verify if your mocks are returning the expected data and if the script under test is processing them as anticipated.
- **Example:**
    ```powershell
    Write-Host "--- CSV Content Start ---"
    $csvContent | ForEach-Object { Write-Host $_ }
    Write-Host "--- CSV Content End ---"
    Write-Host "CSV Line (after skip): $($csvLine)"
    Write-Host "Expected LinkText: $($expectedSanitizedLinkText)"
    ```

### b. Command Execution Context in `run_shell_command`
- When using `run_shell_command` to execute PowerShell code, be extremely careful with variable expansion and escaping, especially with `$`.
- If a string contains PowerShell code that itself uses variables (e.g., `$pesterParams`, `$result`), ensure that the `$` is escaped with a backtick (` `) so that the *outer* PowerShell context of `run_shell_command` treats it as a literal, allowing the *inner* PowerShell to interpret it as a variable.
- **Simpler Alternative:** For executing Pester tests, directly calling `Invoke-Pester` within the `run_shell_command` with `-PassThru` and handling the result with a simple `ForEach-Object` for exit code is often less error-prone than complex nested script blocks.
    ```powershell
    powershell.exe -NoProfile -Command "Invoke-Pester -Script 'path/to/test.ps1' -PassThru | ForEach-Object { if ($_.FailedCount -gt 0) { exit 1 } }"
    ```

## 3. CSV Data Handling in Tests

When dealing with CSV output, understanding `Export-Csv` and `Import-Csv` is key.

### a. `Export-Csv` Behavior
- Automatically encloses fields in double quotes (`"`) if they contain commas, spaces, or special characters.
- Doubles any internal double quotes (`"`) within a field (e.g., `"hello"` becomes `"""hello"""`).
- This behavior affects assertions if you're comparing raw string output.

### b. `Import-Csv` for Assertions
- For robust testing of CSV content, always prefer `Import-Csv` to read the generated CSV file.
- `Import-Csv` correctly parses the CSV, handling quoting and escaping, and presents the data as PowerShell objects with properties matching the CSV headers.
- This allows direct assertion on object properties (`$row.PropertyName | Should -Be "ExpectedValue"`) rather than complex string matching on raw CSV lines, which is highly prone to subtle quoting and escaping issues.
- **Avoid:** Using `Get-Content` and `Should -Contain` on raw CSV lines for complex data, as it bypasses the proper CSV parsing and leads to brittle tests.

By adhering to these guidelines, future development and debugging of Pester tests, especially for scripts with file system interactions and structured data output, can be significantly streamlined.