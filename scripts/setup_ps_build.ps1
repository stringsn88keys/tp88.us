# iwr https://tp88.us/setup_ps_build.ps1 -Outfile setup_ps_build.ps1

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

#set-executionpolicy unrestricted
choco install git
refreshenv

mkdir c:\projects
cd c:\projects
git clone https://github.com/chef/chef-powershell-shim
cd chef-powershell-shim
git checkout tp/debug-ffi-yajl
.\.expeditor\build_gems.ps1
# manually delete c:\hab\studios\projects--chef-powershell-shim
.\.expeditor\manual_gem_release.ps1
