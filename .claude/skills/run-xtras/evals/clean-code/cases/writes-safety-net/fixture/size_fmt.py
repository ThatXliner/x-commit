def humanize_size(num_bytes):
    if num_bytes < 0:
        return "unknown"
    if num_bytes < 1024:
        return str(num_bytes) + " B"
    kb = num_bytes / 1024.0
    if kb < 1024:
        if kb < 10:
            return str(round(kb, 1)) + " KB"
        else:
            return str(int(kb)) + " KB"
    mb = kb / 1024.0
    if mb < 1024:
        if mb < 10:
            return str(round(mb, 1)) + " MB"
        else:
            return str(int(mb)) + " MB"
    gb = mb / 1024.0
    if gb < 10:
        return str(round(gb, 1)) + " GB"
    return str(int(gb)) + " GB"
