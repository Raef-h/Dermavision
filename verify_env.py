import os
import sys

def check_import(module_name):
    try:
        __import__(module_name)
        print(f"[OK] {module_name} imported successfully.")
        return True
    except ImportError:
        print(f"[FAIL] {module_name} not found. Please run: pip install -r requirements.txt")
        return False

def check_kaggle():
    kaggle_path = os.path.expanduser('~/.kaggle/kaggle.json')
    if os.path.exists(kaggle_path):
        print(f"[OK] existing kaggle.json found at {kaggle_path}")
        return True
    elif 'KAGGLE_USERNAME' in os.environ and 'KAGGLE_KEY' in os.environ:
        print(f"[OK] Kaggle environment variables set.")
        return True
    else:
        print(f"[WARN] No kaggle.json found at {kaggle_path} and no env vars set.")
        print("       Dataset download in 01_DataSetup.ipynb will fail unless you set this up.")
        return False

def check_backup_dir():
    backup_dir = 'backup/DermaVision'
    try:
        os.makedirs(backup_dir, exist_ok=True)
        test_file = os.path.join(backup_dir, 'test_write.txt')
        with open(test_file, 'w') as f:
            f.write("test")
        os.remove(test_file)
        print(f"[OK] Backup directory {backup_dir} is writable.")
        return True
    except Exception as e:
        print(f"[FAIL] Backup directory {backup_dir} is NOT writable: {e}")
        return False

def main():
    print("Verifying Local Environment for DermaVision...")
    print("-" * 40)
    
    all_good = True
    
    # Check dependencies
    required_modules = ['tensorflow', 'pandas', 'numpy', 'matplotlib', 'sklearn', 'PIL', 'tqdm', 'flwr']
    for module in required_modules:
        if not check_import(module):
            all_good = False
            
    # Check Kaggle
    if not check_kaggle():
        # Not a hard failure, but warning
        pass
        
    # Check Backup
    if not check_backup_dir():
        all_good = False
        
    print("-" * 40)
    if all_good:
        print("Environment setup looks good! You can proceed with running the notebooks.")
    else:
        print("There were some issues. Please fix them before proceeding.")

if __name__ == "__main__":
    main()
