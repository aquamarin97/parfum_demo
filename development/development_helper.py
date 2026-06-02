import os
from pathlib import Path
import pathspec


class DevelopmentHelper:
    def load_gitignore_spec(startpath):
        """.gitignore dosyasını okur ve pathspec nesnesi döner."""
        gitignore_path = os.path.join(startpath, '.gitignore')
        if os.path.exists(gitignore_path):
            with open(gitignore_path, 'r', encoding='utf-8') as f:
                lines = f.read().splitlines()
            # Boş satırları ve yorum satırlarını temizle
            lines = [line for line in lines if line.strip() and not line.strip().startswith('#')]
            return pathspec.PathSpec.from_lines('gitwildmatch', lines)
        return None

    def generate_project_structure(startpath, output_folder, output_filename="project_structure.txt"):
        """
        .gitignore kurallarına uyarak tüm proje yapısını çıkarır 
        Base64 veya string olarak değil, doğrudan belirtilen klasöre .txt olarak kaydeder.
        """
        start_path_obj = Path(startpath).resolve()
        spec = DevelopmentHelper.load_gitignore_spec(start_path_obj)
        
        output_lines = []
        output_lines.append(f"Project Structure for: {start_path_obj}")
        output_lines.append(".\n")
        
        for root, dirs, files in os.walk(start_path_obj):
            root_path = Path(root).resolve()
            
            # startpath'e göre bağıl yolu (relative path) al
            try:
                rel_root = root_path.relative_to(start_path_obj)
            except ValueError:
                continue

            # .git klasörünü varsayılan olarak her zaman ele
            if '.git' in dirs:
                dirs.remove('.git')

            # Gitignore kontrolü (Klasörler için)
            # os.walk'un alt klasörlere girmesini engellemek için dirs[:] modifikasyonu yapıyoruz
            if spec:
                valid_dirs = []
                for d in dirs:
                    # pathspec kuralları için klasörlerin sonuna '/' koymak mantıklıdır
                    rel_dir_path = str(rel_root / d) + '/'
                    if not spec.match_file(rel_dir_path):
                        valid_dirs.append(d)
                dirs[:] = valid_dirs
            
            # Gitignore kontrolü (Dosyalar için)
            valid_files = []
            for f in files:
                rel_file_path = str(rel_root / f)
                if spec and spec.match_file(rel_file_path):
                    continue
                valid_files.append(f)
                
            level = len(rel_root.parts) if rel_root != Path('.') else 0
            indent = '    ' * level
            
            # Mevcut klasör adını yazdır (Kök dizin değilse)
            if root_path != start_path_obj:
                output_lines.append(f"{indent}├── {root_path.name}/")
                
            # Klasör içindeki geçerli dosyaları yazdır
            sub_indent = '    ' * (level + 1)
            for i, f in enumerate(valid_files):
                connector = "└── " if i == len(valid_files) - 1 else "├── "
                output_lines.append(f"{sub_indent}{connector}{f}")

        # Çıktı klasörünü oluştur ve dosyayı kaydet
        os.makedirs(output_folder, exist_ok=True)
        target_file_path = os.path.join(output_folder, output_filename)
        
        with open(target_file_path, 'w', encoding='utf-8') as out_file:
            out_file.write("\n".join(output_lines))
            
        print(f"Rapor başarıyla kaydedildi: {os.path.abspath(target_file_path)}")

