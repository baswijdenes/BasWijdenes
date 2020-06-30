$mailboxes = get-mailbox -ResultSize unlimited
$data = @()

foreach ($mbx in $mailboxes)

{

$dataobject=New-Object psobject

$dataobject|add-member-NotePropertyName UserPrincipalName -NotePropertyValue $mbx.userprincipalname

$photo=get-userphoto$mbx.userprincipalname

if(!($photo)){

$dataobject|Add-Member-NotePropertyName PhotoEnabled -NotePropertyValue "No"

}else{

$dataobject|Add-Member-NotePropertyName PhotoEnabled -NotePropertyValue "Yes"

}

$Data+=$dataobject

}