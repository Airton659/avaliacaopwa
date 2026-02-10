import os

files_to_fix = [
    r'c:\Users\user\Documents\SAD\lib\services\pdf_service.dart',
    r'c:\Users\user\Documents\SAD\lib\screens\central_impressao_screen.dart',
    r'c:\Users\user\Documents\SAD\lib\screens\tabs\tab_impressoes_avaliacao.dart',
    r'c:\Users\user\Documents\SAD\lib\screens\tabs\tab_encerramento_ciclo.dart'
]

for file_path in files_to_fix:
    if not os.path.exists(file_path):
        print(f"Skipping {file_path} (not found)")
        continue
        
    try:
        with open(file_path, 'rb') as f:
            content = f.read()
        
        decoded = content.decode('utf-8', errors='replace')
        
        # Clean nulls which indicate UTF-16
        if '\x00' in decoded:
            print(f"Fixing {os.path.basename(file_path)}: UTF-16/Binary contamination removed.")
            decoded = decoded.replace('\x00', '')
        
        # Clean BOM
        if '\ufeff' in decoded:
            print(f"Fixing {os.path.basename(file_path)}: BOM removed.")
            decoded = decoded.replace('\ufeff', '')
            
        # Ensure we write back as clean UTF-8
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(decoded)
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")

print("Done.")
