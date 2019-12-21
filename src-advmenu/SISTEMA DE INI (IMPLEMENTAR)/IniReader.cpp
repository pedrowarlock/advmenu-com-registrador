#include "IniReader.h"
#include <fstream>
#include <string>
#include <iostream>
#include <vector>
#include <string.h>
#include <stdio.h>

static std::vector<std::string> split(std::string str,std::string sep){
    char* cstr=const_cast<char*>(str.c_str());
    char* current;
    std::vector<std::string> arr;
    current=strtok(cstr,sep.c_str());
    while(current!=NULL){
        arr.push_back(current);
        current=strtok(NULL,sep.c_str());
    }
    return arr;
}

IniReader::IniReader(const char* filename)
{
    ParseIniFile(filename);
}

void IniReader::ParseIniFile(const char* filename)
{
    std::fstream file (filename);
    std::string line;
    struct IniSection* iniSection;
    while (std::getline(file, line)) {
        if (line[0] == '[') {
            iniSection = new IniSection();
            this->m_sections.push_back(iniSection);
            iniSection->sectionName = line.substr(1, line.size( ) - 2);
        }
        else {
            iniSection->sectionKeys.push_back(ParseIniLine(line));
        }
    }
}

struct IniKey IniReader::ParseIniLine(std::string line)
{
    IniKey key;
    std::vector<std::string> values = split(line, "=");
    key.left = values[0];
    key.right = values[1];
    return key;
}


struct IniSection* IniReader::getIniSection(std::string section_name)
{
    for (size_t i = 0; i < m_sections.size(); ++i) {
        if (m_sections[i]->sectionName == section_name) {
            return m_sections[i];
        }
    }
    return NULL;
}


IniReader::~IniReader()
{
    size_t arrsize = this->m_sections.size();
    for (size_t i = 0; i < arrsize; ++i) {
        delete m_sections[i];
    }

    for (size_t i = 0; i < arrsize; ++i) {
        m_sections.clear();
    }
}
