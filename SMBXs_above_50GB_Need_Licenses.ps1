$data = @()

$mbxs = get-mailbox -ResultSize unlimited -filter { recipienttypedetails -eq "sharedmailbox" }

foreach ($mb in $mbxs)

{

    $dataobject = New-Object psobject

    $stats = Get-MailboxStatistics -Identity $mb.UserPrincipalName

    $dataobject | Add-Member -NotePropertyValue $MB.userprincipalname -NotePropertyName UserPrincipalName

    $dataobject | Add-Member -NotePropertyValue $mb.displayname -NotePropertyName Displayname

    $dataobject | Add-Member -NotePropertyValue $stats.totalitemsize -NotePropertyName Totalsize

    switch -Wildcard ($stats.totalitemsize.value)

    {

        "*GB*"

        {

            $totalitemsize = $stats.TotalItemSize.Value -replace " GB*"

            $totalsize = $totalitemsize.Split(" ")[0]

            if ( [math]::Round($totalsize, 3) -gt 48)

            {

                $dataobject | Add-Member -NotePropertyValue "MAILBOX LIMIT IS REACHED" -NotePropertyName "Mailbox Limit"

            }

            else

            {

                $dataobject | Add-Member -NotePropertyValue "Mailbox is ok" -NotePropertyName "Mailbox Limit"

            }

        }

        "*MB*"

        {

            $dataobject | Add-Member -NotePropertyValue "Mailbox is ok" -NotePropertyName "Mailbox Limit"

        }

        "*KB*"

        {

            $dataobject | Add-Member -NotePropertyValue "Mailbox is ok" -NotePropertyName "Mailbox Limit"

        }

    }

    $data += $dataobject

}

$data | Export-Csv C:\temp\totalitemsize_SMBX-V2.csv -NoTypeInformation