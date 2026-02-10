import os

file_path = r'c:\Users\user\Documents\SAD\lib\services\pdf_service.dart'

try:
    with open(file_path, 'rb') as f:
        content = f.read()
    
    # Debug: Print file size
    print(f"File size: {len(content)} bytes")
    
    # The error was around offset 78809. Let's look at that area.
    offset = 78809
    start = max(0, offset - 20)
    end = min(len(content), offset + 20)
    
    print(f"Bytes around {offset}: {content[start:end]}")
    
    # The fix: Decode carefully, filtering out invalid sequences
    # WE use 'ignore' to drop bytes that are not valid UTF-8 start/continuation bytes
    decoded = content.decode('utf-8', errors='ignore')
    
    # Re-encode to pure UTF-8 to formatted file
    clean_content = decoded.encode('utf-8')
    
    with open(file_path, 'wb') as f:
        f.write(clean_content)
        
    print(f"File rewritten. New size: {len(clean_content)} bytes")
    print("Corrupted bytes removed.")

except Exception as e:
    print(f"Error: {e}")
