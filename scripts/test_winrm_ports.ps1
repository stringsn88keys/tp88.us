## Test to see if WinRM ports are reachable on remote server: <b>test_winrm_ports.ps1 <i>ip_address</i></b>
if($args.Count -lt 1)
{
    Write-Host "Usage: test_winrm_ports.ps1 <ip_address>"
    exit
}
Test-NetConnection -ComputerName $args[0] -Port 5985
Test-NetConnection -ComputerName $args[0] -Port 5986
