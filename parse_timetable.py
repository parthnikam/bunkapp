import re
import json

# Just an approximation of parsing the timetable, we'll read ocr.txt
# and try to extract sections and their subjects.

def parse():
    with open('ocr.txt', 'r') as f:
        text = f.read()
        
    sections = {}
    current_section = None
    
    lines = text.split('\n')
    for i, line in enumerate(lines):
        match = re.search(r'First Semester:\s*([A-Z])\s*Section', line)
        if match:
            current_section = match.group(1)
            sections[current_section] = {
                'MON': [], 'TUE': [], 'WED': [], 'THU': [], 'FRI': []
            }
            continue
            
        if current_section and line.startswith(('MON', 'TUE', 'WED', 'THU', 'FRI')):
            day = line[:3]
            # Remove day prefix, Break, Lunch Break, --
            cleaned = line[3:].replace('Lunch Break', '').replace('Break', '').replace('--', '')
            # Extract potential subjects (caps words, labs, etc)
            # Find words like FEE, OOPS, CM, CPI, CAEG Lab
            subjects = [s.strip() for s in re.split(r'\s{2,}|\t', cleaned) if s.strip()]
            if not subjects:
                subjects = [s.strip() for s in cleaned.split() if len(s) >= 2]
                
            # Basic filter to remove room numbers
            filtered = []
            for s in subjects:
                if 'AB' not in s and '(' not in s and ')' not in s:
                    filtered.append(s)
                elif 'Lab' in s or 'LAB' in s:
                    filtered.append(s.split('(')[0].strip())
            
            sections[current_section][day] = list(dict.fromkeys(filtered)) # deduplicate
            
    # Output to dart file
    dart_code = "const timetableData = " + json.dumps(sections, indent=2) + ";\n"
    with open('lib/timetable_data.dart', 'w') as f:
        f.write(dart_code)
        
if __name__ == '__main__':
    parse()
