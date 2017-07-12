import sys, os.path, requests, subprocess
from bs4 import BeautifulSoup as Parser
from base64 import b64decode
from hashlib import md5

INSTALLER_LOCATION = '/tmp/YNAB4Setup.exe'
INSTALLER_LOGS_LOCATION = '/tmp/ynab4_install.log'
WINE_YNAB4_LOCATION = os.path.expanduser('~/.wine_YNAB4')
DROPBOX_HOST_DB = os.path.expanduser('~/.dropbox/host.db')


def get_option():
    modes = [('Everything', 'Do Everything'), ('Download', 'Download YNAB4'), ('Install', 'Install YNAB4'), ('Dropbox', 'Configure Dropbox')]
    
    if len(sys.argv) != 2:
        print('Please call the script with one of the following arguments:')
        for n, entry in enumerate(modes):
            print('%d.' % (n+1), modes[n][1])
        exit()
    option = int(sys.argv[1])
    return modes[option-1]  # List starts from 0 but printed options are numbered from 1 for familiarity 

def wine_installed():
    return os.path.isfile('/usr/bin/wine')        

def dropbox_installed():
    # Check if setup is complete ($DROPBOX_INSTALLDIR)   
    return os.path.isfile(DROPBOX_HOST_DB)    

def configure_dropbox():
    with open(DROPBOX_HOST_DB, 'r') as dropbox_host_db:
        dropbox_location = b64decode(dropbox_host_db.readlines()[1])  # it's b64 enconded on the second line of the file
        
    wine_dropbox_dir = '%s/drive_c/users/%s/Application Data/Dropbox' % (WINE_YNAB4_LOCATION, os.environ['USER'])
    
    os.makedirs(wine_dropbox_dir)
    with open(wine_dropbox_dir + '/host.db', 'w') as wine_host_db_file:
        wine_host_db_file.write('0000000000000000000000000000000000000000\n')
        wine_host_db_file.write('QzpcRHJvcGJveA==\n')  # 'C:\\Dropbox'
        
    os.symlink(dropbox_location, WINE_YNAB4_LOCATION + '/drive_c/Dropbox')

def get_latest_version_metadata(metadata_url):
    latest_version_metadata_xml = requests.get(metadata_url)
    return Parser(latest_version_metadata_xml.text, 'lxml')

def download_file(url, download_location):
    with open(download_location, 'wb') as file:
        file.write(requests.get(url, stream=True).content)

def valid_file_md5(file_location, md5hash):
    with open(file_location,'rb') as file_to_verify:
        return md5(file_to_verify.read()).hexdigest().upper() == md5hash.upper()
            
def install_YNAB4(installer_location):
    print("Installer logs will be at '%s'" % INSTALLER_LOGS_LOCATION)
    with open(INSTALLER_LOGS_LOCATION, 'w') as log_file:
        subprocess.call(['/usr/bin/wine', INSTALLER_LOCATION],  # call Wine and pass the installer as an argument
                            env=dict(os.environ, WINEPREFIX=WINE_YNAB4_LOCATION),  # add Wine Prefix to Environment variables
                            stdout=log_file, stderr=subprocess.STDOUT)  # redirect wine output and stderr to the log file


if __name__ == '__main__':    
    option, option_description = get_option()
    
    if option in ('Download', 'Everything'):
        print('Getting url for the latest version of the YNAB4 installer')
        metadata = get_latest_version_metadata('http://classic.youneedabudget.com/dev/ynab4/liveCaptive/Win/update.xml')
        
        print("Downloading the installer to '%s'" % INSTALLER_LOCATION)
        download_file(metadata.exe.url.text, INSTALLER_LOCATION)
        
        print('Verifying the download')    
        if not valid_file_md5(INSTALLER_LOCATION, metadata.exe.md5.text):
            raise ValueError('The downloaded installer seems to be corrupt, try re-downloading it')
    
    if option in ('Install', 'Dropbox', 'Everything'):
        print('Preparing Wine/YNAB4 directory')
        try:
            os.makedirs(WINE_YNAB4_LOCATION)
        except FileExistsError:
            print("Error: The Wine YNAB4 directory ('%s') already exists, aborting install" % WINE_YNAB4_LOCATION)    
                
    if option in ('Dropbox', 'Everything'):
        print('Configuring Dropbox')
        if not dropbox_installed():
            raise ImportError("Dropbox doesn't seem to be installed (not found under '%s')" % DROPBOX_HOST_DB)        
        configure_dropbox()

    if option in ('Install', 'Everything'):
        print('Installing YNAB4')    
        if not wine_installed():
            raise ImportError("Wine doesn't seem to be installed: (not found under /usr/bin/wine)")
        install_YNAB4(INSTALLER_LOCATION)
        
        print("Installation complete, removing installer.\n Log file will still be at '%s'" % INSTALLER_LOGS_LOCATION)
        os.remove(INSTALLER_LOCATION)
