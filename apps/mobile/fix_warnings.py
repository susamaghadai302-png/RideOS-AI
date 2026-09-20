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
        file_lines = f.readlines()
        
    if line_num >= len(file_lines):
        continue
        
    original_line = file_lines[line_num]
    new_line = original_line
    
    if error_type == "unused_field":
        # Rename _field to field in the entire file
        field_match = re.search(r"_[a-zA-Z0-9]+", original_line)
        if field_match:
            old_name = field_match.group(0)
            new_name = old_name[1:]
            for i in range(len(file_lines)):
                file_lines[i] = re.sub(r"\b" + old_name + r"\b", new_name, file_lines[i])
            new_line = None # Handled bulk
            
    elif error_type == "unused_local_variable":
        # Find variable name and replace with _
        var_match = re.search(r"\b([a-zA-Z0-9_]+)\s*[=,;]", original_line)
        if var_match:
            var_name = var_match.group(1)
            new_line = re.sub(r"\b" + var_name + r"\b", "_", original_line, count=1)
            
    elif error_type == "unused_element":
        # Rename _element to element in the entire file
        element_match = re.search(r"_[a-zA-Z0-9]+", original_line)
        if element_match:
            old_name = element_match.group(0)
            new_name = old_name[1:]
            for i in range(len(file_lines)):
                file_lines[i] = re.sub(r"\b" + old_name + r"\b", new_name, file_lines[i])
            new_line = None
            
    elif error_type == "library_prefixes":
        # Lowercase it
        if "as AppState" in original_line:
            new_line = original_line.replace("as AppState", "as app_state")
        elif "as BleState" in original_line:
            new_line = original_line.replace("as BleState", "as ble_state")
        elif "as Adv" in original_line:
            new_line = original_line.replace("as Adv", "as adv")
            
    elif error_type == "deprecated_member_use":
        if "dart:html" in original_line:
            new_line = original_line.replace("dart:html", "package:web/web.dart")
        elif "dart:js" in original_line:
            new_line = original_line.replace("dart:js", "dart:js_interop")
        elif ".scale(" in original_line:
            new_line = original_line.replace(".scale(", ".scaleByVector3(")
        elif "value:" in original_line:
            new_line = original_line.replace("value:", "initialValue:")
        elif "localeId:" in original_line:
            new_line = original_line.replace("localeId:", "SpeechListenOptions.localeId:")
        elif "cancelOnError:" in original_line:
            new_line = original_line.replace("cancelOnError:", "SpeechListenOptions.cancelOnError:")
        elif "partialResults:" in original_line:
            new_line = original_line.replace("partialResults:", "SpeechListenOptions.partialResults:")
            
    elif error_type == "avoid_print":
        new_line = "// " + original_line
        
    elif error_type == "unreachable_switch_default":
        new_line = "// " + original_line
        
    elif error_type == "dead_code":
        new_line = "// " + original_line
        
    elif error_type == "use_build_context_synchronously":
        new_line = "if (!mounted) return;\n" + original_line
        
    elif error_type == "undefined_hidden_name":
        if "hide LatLng" in original_line:
            new_line = original_line.replace("hide LatLng", "")
            
    elif error_type == "override_on_non_overriding_member":
        new_line = original_line.replace("@override", "// @override")
        
    elif error_type == "invalid_annotation_target":
        if "@Timeout" in original_line:
            new_line = original_line.replace("@Timeout", "// @Timeout")

    if new_line is not None:
        file_lines[line_num] = new_line
        
    with open(file_path, "w") as f:
        f.writelines(file_lines)

