# Default SpectrumNext Template project structure

This repo represents my current starter template for Spectrum Next assembly language projects. Heavily inspired by the blog post [CREATING A Z80 ASSEMBLY DEVELOPMENT ENVIRONMENT ON WINDOWS](https://specnext.dev/tutorials/creating-a-z80-assembly-development-environment-on-windows/). The template and scripts create a self-contained directory structure with the tools to build and execute Z80 code.

## To Use

> **Note**: This template is setup with the assumption you are using Windows 10.

1. Create a GitHub repo that uses this project as a template.

    This template defines a folder structure and provides scripts that will download and extract ZX Spect Next img/roms as well as tools such as CSpect, etc.

1. Clone the new repo locally.

1. Open a **PowerShell** session and change the directory to root of your cloned repo.

1. Execute the **Install-Tools.ps1** script:

    ```powershell
    .\Install-Tools.ps1
    ```

    This script calls two other scripts:

    * Downloads and extracts the latest ZX Next image and roms
    * Downloads CSpect, openal, sjasmplus, and hdfmonkey.
  
1. Open Visual Studio Code and install the **Z80 Macro-Assembler** - I use the problem matcher to highlight errors, etc.

1. In Visual Studio Code, open the **{project-root}** folder.
  
    Source files are contained within the **{project-root}\project\src** folder. 
    The file **<project-root>\.vscode\Tasks.json** contains the following tasks:
  
    * **Compile Assembly** - This is mapped as the default build task, so `CTRL+SHIFT+B` will invoke it and it will use the sjasmplus assembler to process the src files.
    * **Update SDCard** - uses **hdfmonkey** to move the `project.nex` output file onto the CSpect img so it can be accessed from within the CSpect emulator.

      > **Note**: Update this task if you change the name of the .NEX file that is generated.

    * **Launch CSpect** - Calls **Compile Assembly** and **Update SDCard**, then launches CSpect with the updated image. Find the Project.NEX file in the Browser and then you can run it.
