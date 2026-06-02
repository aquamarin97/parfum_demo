import os
from pathlib import Path
import pathspec

from development_helper import DevelopmentHelper

if __name__ == "__main__":
    # Analiz edilecek mevcut proje dizini
    current_directory = os.getcwd()
    
    # Çıktının kaydedilmesini istediğin klasör yolu
    # Örn: "C:/Kullanicilar/Raporlar" veya mevcut dizin içinde bir klasör "Outputs"
    target_output_folder = os.path.join(current_directory, "development", "outputs")
    
    DevelopmentHelper.generate_project_structure(current_directory, target_output_folder)