#ifndef INIREADER_H
#define INIREADER_H
#include <string>
#include <vector>

struct IniKey {
    std::string left;
    std::string right;
};

struct IniSection {
    std::string sectionName;
    std::vector<IniKey> sectionKeys;
};

class IniReader {
public:
    IniReader(const char* filename);
    ~IniReader();
    struct IniSection* getIniSection(std::string section_name);

private:
    std::vector<struct IniSection*> m_sections;

    void ParseIniFile(const char* filename);
    struct IniKey ParseIniLine(std::string line);
};


#endif