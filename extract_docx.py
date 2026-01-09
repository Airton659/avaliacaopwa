import zipfile
import xml.etree.ElementTree as ET
import sys
import os

def extract_text_from_docx(docx_path):
    """Extract text from a .docx file"""
    try:
        with zipfile.ZipFile(docx_path) as docx:
            xml_content = docx.read('word/document.xml')
            tree = ET.XML(xml_content)

            # Namespace for Word documents
            namespaces = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}

            # Extract all text nodes
            texts = []
            for paragraph in tree.findall('.//w:p', namespaces):
                para_text = []
                for text_elem in paragraph.findall('.//w:t', namespaces):
                    if text_elem.text:
                        para_text.append(text_elem.text)
                if para_text:
                    texts.append(''.join(para_text))

            return '\n'.join(texts)
    except Exception as e:
        return f"Error: {str(e)}"

if __name__ == "__main__":
    folder = r"C:\Users\user\Documents\SAD\avaliacoes"

    # Process ANEXO 1 (Operacional Autoavaliação)
    anexo1_path = os.path.join(folder, "ANEXO 1 OPERACIONAL MODELO.docx")
    print("=" * 80)
    print("ANEXO 1 - AUTOAVALIAÇÃO OPERACIONAL")
    print("=" * 80)
    print(extract_text_from_docx(anexo1_path))
    print("\n\n")

    # Process ANEXO 4 (Gerencial Autoavaliação)
    anexo4_path = os.path.join(folder, "ANEXO 4 GERENCIAL MODELO.docx")
    print("=" * 80)
    print("ANEXO 4 - AUTOAVALIAÇÃO GERENCIAL")
    print("=" * 80)
    print(extract_text_from_docx(anexo4_path))
