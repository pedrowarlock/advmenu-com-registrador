#include <iostream>
#include "IniReader.h"

int main() {
    IniReader iniFile ("./advmenu.ini");
    struct IniSection* iniSection = iniFile.getIniSection("REMOVER_EMULADOR");

    std::cout << iniSection->sectionName << std::endl << std::endl; 
    for (auto key : iniSection->sectionKeys) {
        std::cout << key.left << "   =   " << key.right << std::endl;
    }
    //////////////

    iniSection = iniFile.getIniSection("TESTE");

    std::cout << iniSection->sectionName << std::endl << std::endl; 
    for (auto key : iniSection->sectionKeys) {
        std::cout << key.left << "   =   " << key.right << std::endl;
    }
  
    return 0;
}