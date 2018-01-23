cmd = "Invoke-Sqlcmd -Query \"$QUERY$\""

if !node['mssql']['sysadmins'].nil? && node['mssql']['sysadmins'].size != 0
  sysadmins = node['mssql']['sysadmins'].split(',')
  
    for sysadminuser in sysadmins
      if !sysadminuser["\\"]
        sysadminuser = "#{ENV['COMPUTERNAME']}" + "\\" + "#{sysadminuser}"
      end
        sqlcmd = "IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = '#{sysadminuser}')
        CREATE LOGIN [#{sysadminuser}] FROM WINDOWS WITH DEFAULT_DATABASE=master
        ALTER SERVER ROLE [sysadmin] ADD MEMBER [#{sysadminuser}]"

        cmd = cmd.gsub("$QUERY$",sqlcmd)
        powershell_script 'add_sysadmins' do
          code <<-EOH
          Import-Module "C:\\Program Files (x86)\\Microsoft SQL Server\\130\\Tools\\PowerShell\\Modules\\Sqlps" -DisableNameChecking
          #{cmd}
          EOH
        end
    end
end

password = node['mssql']['password']
sqlcmd = "IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'sa')
ALTER LOGIN sa WITH PASSWORD=N'#{password}'"
cmd = cmd.gsub("$QUERY$",sqlcmd)
powershell_script 'modify_sa_pwd' do
  code <<-EOH
  Import-Module "C:\\Program Files (x86)\\Microsoft SQL Server\\130\\Tools\\PowerShell\\Modules\\Sqlps" -DisableNameChecking
  #{cmd}
  EOH
end
