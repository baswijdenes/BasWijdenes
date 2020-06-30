$roles = "Company Administrator", "SharePoint Service Administrator", "Exchange Service Administrator"

$data = @()

foreach ($role in $roles)

{

$r=Get-MsolRole-RoleName $role

write-output$role

$users=Get-MsolRoleMember-RoleObjectId $r.objectid

$data+=$users

}

$users = Get-user -ResultSize unlimited

foreach ($u in $users)

{

if(!($data.emailaddress-contains$u.UserPrincipalName))

{

write-output$u.UserPrincipalName

Set-user-identity $u.UserPrincipalName-RemotePowerShellEnabled $false

}

else

{

Write-host"USER IS IN DATA"-BackgroundColor Red

}

}