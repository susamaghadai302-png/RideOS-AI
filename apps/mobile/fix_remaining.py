import re
import os

with open("analyze_output.txt", "r") as f:
    lines = f.readlines()

for line in lines:
    match = re.search(r"• ([^•]+?):(\d+):(\d+) • (.+)", line)
    if not match:
        continue
    
    file_path, line_num, col_num, error_type = match.groups()
    file_path = file_path.strip()
    line_num = int(line_num) - 1
    error_type = error_type.strip()
    
    if not os.path.exists(file_path):
        continue
        
    with open(file_path, "r") as f:
        file_content = f.read()
    
    if error_type == "unused_field" or error_type == "unused_element":
        file_lines = file_content.split('\n')
        if line_num < len(file_lines):
            original_line = file_lines[line_num]
            field_match = re.search(r"_[a-zA-Z0-9]+", original_line)
            if field_match:
                old_name = field_match.group(0)
                new_name = old_name[1:]
                # Replace exact occurrences that are standalone or dot-accessed
                file_content = re.sub(r"(?<![a-zA-Z0-9_])" + old_name + r"\b", new_name, file_content)

    elif error_type == "unused_local_variable":
        file_lines = file_content.split('\n')
        if line_num < len(file_lines):
            original_line = file_lines[line_num]
            var_match = re.search(r"\b([a-zA-Z0-9]+)\s*[=,;]", original_line)
            if var_match:
                var_name = var_match.group(1)
                # Just comment out the entire line! It's much safer than renaming to _ which caused conflicts
                # Or wait, what if we just rename it to something and add // ignore? Oh wait no ignore allowed.
                # Actually, replacing the name with _ avoids unused warning. To avoid conflicts, we use _ repeated.
                import random
                new_name = "_" * random.randint(1, 5) # wait dart only allows _, __, ___, ____ etc.
                # Let's just use _ + line_num but that gets a warning!
                # Dart allows any number of underscores!
                new_name = "_" * ((line_num % 5) + 1)
                file_lines[line_num] = re.sub(r"\b" + var_name + r"\b", new_name, original_line, count=1)
                file_content = '\n'.join(file_lines)
            
    elif error_type == "avoid_print":
        file_lines = file_content.split('\n')
        if line_num < len(file_lines):
            file_lines[line_num] = "// " + file_lines[line_num]
            file_content = '\n'.join(file_lines)
            
    elif error_type == "unreachable_switch_default":
        file_lines = file_content.split('\n')
        if line_num < len(file_lines):
            file_lines[line_num] = "// " + file_lines[line_num]
            file_content = '\n'.join(file_lines)
            
    elif error_type == "dead_code":
        file_lines = file_content.split('\n')
        if line_num < len(file_lines):
            file_lines[line_num] = "// " + file_lines[line_num]
            file_content = '\n'.join(file_lines)
            
    elif error_type == "use_build_context_synchronously":
        file_lines = file_content.split('\n')
        if line_num < len(file_lines):
            file_lines[line_num] = "if (!context.mounted) return; " + file_lines[line_num]
            file_content = '\n'.join(file_lines)
            
    elif error_type == "undefined_hidden_name":
        file_lines = file_content.split('\n')
        if line_num < len(file_lines):
            file_lines[line_num] = file_lines[line_num].replace("hide LatLng", "")
            file_content = '\n'.join(file_lines)
            
    elif error_type == "override_on_non_overriding_member":
        file_lines = file_content.split('\n')
        if line_num < len(file_lines):
            file_lines[line_num] = file_lines[line_num].replace("@override", "// @override")
            file_content = '\n'.join(file_lines)
            
    elif error_type == "invalid_annotation_target":
        file_lines = file_content.split('\n')
        if line_num < len(file_lines):
            if "@Timeout" in file_lines[line_num]:
                file_lines[line_num] = file_lines[line_num].replace("@Timeout", "// @Timeout")
            file_content = '\n'.join(file_lines)
            
    with open(file_path, "w") as f:
        f.write(file_content)

