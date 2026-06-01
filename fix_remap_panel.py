with open('scripts/ui/remap_panel.gd', 'r') as f:
    lines = f.readlines()

new_lines = []
in_serialize = False
for line in lines:
    if line.startswith('func _serialize_event'):
        in_serialize = True
    elif in_serialize and line.startswith('func _deserialize_event'):
        in_serialize = False

    if in_serialize:
        # device_id and other common input properties
        if line.strip() == 'var d: Dictionary = {}':
            new_lines.append(line)
            new_lines.append('\td["device"] = event.device\n')
            continue
    new_lines.append(line)

lines = new_lines
new_lines = []
in_deserialize = False
for line in lines:
    if line.startswith('func _deserialize_event'):
        in_deserialize = True

    if in_deserialize and line.strip() == 'return e':
        new_lines.append('\t\te.device = int(d.get("device", 0))\n')

    new_lines.append(line)

with open('scripts/ui/remap_panel.gd', 'w') as f:
    f.writelines(new_lines)
